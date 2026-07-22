// Backend mínimo para Railway: sirve el build de Flutter Web (estático) y
// expone la API administrativa que antes vivía en Firebase Cloud Functions
// (functions/index.js). Se movió aquí porque las Cloud Functions de 2ª
// generación requieren el plan Blaze de Firebase, y el proyecto se quedó en
// el plan Spark (gratuito) alojando el frontend en Railway.
const path = require('path');
const express = require('express');
const compression = require('compression');
const admin = require('firebase-admin');

const serviceAccountRaw = process.env.FIREBASE_SERVICE_ACCOUNT_KEY;
if (!serviceAccountRaw) {
  throw new Error(
    'Falta la variable de entorno FIREBASE_SERVICE_ACCOUNT_KEY (JSON de la cuenta de servicio de Firebase).',
  );
}
admin.initializeApp({
  credential: admin.credential.cert(JSON.parse(serviceAccountRaw)),
});
const db = admin.firestore();

function getErrorMessage(error) {
  if (typeof error === 'string') return error;
  if (error?.message) return error.message;
  return 'Error desconocido';
}

// Mismas reglas que UserCredentialGenerator.generatePassword() en Flutter:
// 10-12 caracteres, con mayúscula, minúscula, número y símbolo obligatorios.
function generatePassword(length = 12) {
  const lowers = 'abcdefghijkmnpqrstuvwxyz';
  const uppers = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  const digits = '23456789';
  const symbols = '!@#%&*+-';
  const all = lowers + uppers + digits + symbols;

  const pick = (chars) => chars[Math.floor(Math.random() * chars.length)];
  const required = [pick(uppers), pick(lowers), pick(digits), pick(symbols)];
  const rest = Array.from({ length: length - required.length }, () => pick(all));
  const passwordChars = [...required, ...rest];

  for (let i = passwordChars.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [passwordChars[i], passwordChars[j]] = [passwordChars[j], passwordChars[i]];
  }
  return passwordChars.join('');
}

// Envía { error: mensaje } con el status HTTP dado y corta la ejecución.
function fail(res, status, message) {
  res.status(status).json({ error: message });
}

async function requireCallerRole(req, res) {
  const authHeader = req.headers.authorization || '';
  const match = authHeader.match(/^Bearer (.+)$/);
  if (!match) {
    fail(res, 401, 'Debes iniciar sesión.');
    return null;
  }

  let decoded;
  try {
    decoded = await admin.auth().verifyIdToken(match[1]);
  } catch {
    fail(res, 401, 'Tu sesión expiró o no es válida. Vuelve a iniciar sesión.');
    return null;
  }

  const callerDoc = await db.collection('users').doc(decoded.uid).get();
  if (!callerDoc.exists) {
    fail(res, 403, 'No se encontró tu perfil de usuario en la base de datos.');
    return null;
  }

  const callerRole = callerDoc.data()?.role;
  if (callerRole !== 'admin' && callerRole !== 'coordinator') {
    fail(res, 403, 'No tienes permiso para restablecer contraseñas.');
    return null;
  }

  return decoded.uid;
}

const app = express();
app.use(compression());
app.use(express.json());
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'SAMEORIGIN');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  res.setHeader('Permissions-Policy', 'geolocation=(), microphone=(), camera=()');
  next();
});

app.post('/api/admin/reset-password', async (req, res) => {
  try {
    const callerUid = await requireCallerRole(req, res);
    if (!callerUid) return; // requireCallerRole ya respondió el error.

    const targetUserId = req.body?.targetUserId?.trim();
    if (!targetUserId || typeof targetUserId !== 'string') {
      return fail(res, 400, 'Falta el id del usuario objetivo.');
    }

    let targetUser;
    try {
      targetUser = await admin.auth().getUser(targetUserId);
    } catch (error) {
      const message = getErrorMessage(error);
      if (message.includes('user-not-found') || message.includes('not found')) {
        return fail(res, 404, 'No existe una cuenta de autenticación para ese usuario.');
      }
      return fail(res, 500, `No se pudo localizar la cuenta de destino: ${message}`);
    }

    if (!targetUser.email) {
      return fail(res, 400, 'La cuenta objetivo no tiene correo asociado.');
    }

    const newPassword = generatePassword();

    try {
      await admin.auth().updateUser(targetUserId, { password: newPassword });
    } catch (error) {
      const code = error?.code || 'internal-error';
      const message = getErrorMessage(error);
      if (code === 'auth/user-not-found') {
        return fail(res, 404, 'No existe una cuenta de autenticación para ese usuario.');
      }
      if (code === 'auth/invalid-password') {
        return fail(res, 400, 'La contraseña generada no es válida.');
      }
      return fail(res, 500, `No se pudo restablecer la contraseña: ${message}`);
    }

    res.json({ password: newPassword });
  } catch (error) {
    console.error('Error inesperado en /api/admin/reset-password', error);
    fail(res, 500, `Error inesperado: ${getErrorMessage(error)}`);
  }
});

// ───────────────────────── Estático (Flutter Web build) ─────────────────────
const webRoot = path.join(__dirname, 'public');

// index.html y el entrypoint de Flutter no llevan hash en el nombre de
// archivo, así que deben revalidarse siempre (ver nginx.conf original: sin
// esto, el navegador se queda pegado a una versión vieja tras cada deploy).
const noCacheFiles = new Set([
  'index.html',
  'main.dart.js',
  'flutter.js',
  'flutter_bootstrap.js',
  'flutter_service_worker.js',
  'version.json',
  'manifest.json',
]);

app.use(
  express.static(webRoot, {
    setHeaders: (res, filePath) => {
      const name = path.basename(filePath);
      if (noCacheFiles.has(name)) {
        res.setHeader('Cache-Control', 'no-cache');
      } else {
        res.setHeader('Cache-Control', 'public, max-age=3600, must-revalidate');
      }
    },
  }),
);

// Fallback de SPA: cualquier ruta que no sea un archivo real ni /api/* debe
// devolver index.html para que go_router resuelva el deep-link del lado
// del cliente (rutas como /coordinator/dashboard, refresh, atrás/adelante).
app.get(/^(?!\/api\/).*/, (req, res) => {
  res.setHeader('Cache-Control', 'no-cache');
  res.sendFile(path.join(webRoot, 'index.html'));
});

const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log(`Servidor escuchando en el puerto ${port}`);
});
