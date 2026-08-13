// Backend mínimo para Railway: sirve el build de Flutter Web (estático) y
// expone la API administrativa que antes vivía en Firebase Cloud Functions
// (functions/index.js). Se movió aquí porque las Cloud Functions de 2ª
// generación requieren el plan Blaze de Firebase, y el proyecto se quedó en
// el plan Spark (gratuito) alojando el frontend en Railway.
const path = require('path');
const fs = require('fs');
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

// Como requireCallerRole, pero además permite que un usuario modifique su
// propio recurso (targetUserId === su propio uid) sin ser admin/coordinador
// — usado para que cualquiera pueda subir su propia foto de perfil, y un
// admin/coordinador pueda subir la de otro (ver UsersScreen._pickAvatarForUser).
async function requireSelfOrStaffRole(req, res, targetUserId) {
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

  if (decoded.uid === targetUserId) return decoded.uid;

  const callerDoc = await db.collection('users').doc(decoded.uid).get();
  const callerRole = callerDoc.exists ? callerDoc.data()?.role : null;
  if (callerRole !== 'admin' && callerRole !== 'coordinator') {
    fail(res, 403, 'No tienes permiso para modificar la foto de este usuario.');
    return null;
  }

  return decoded.uid;
}

// Directorio de fotos de perfil, montado sobre un Volume persistente de
// Railway (ver Settings → Volumes del servicio) — sin volumen, este path
// vive en el filesystem efímero del contenedor y se pierde en cada
// redeploy. mkdirSync no falla si ya existe (recursive: true).
const AVATARS_DIR = process.env.AVATARS_DIR || '/data/avatars';
fs.mkdirSync(AVATARS_DIR, { recursive: true });

// Los archivos se guardan sin extensión (ver PUT /api/avatar/:userId), así
// que el tipo de imagen se detecta por la firma de los primeros bytes al
// servirlos, en vez de confiar en un nombre de archivo.
function sniffImageContentType(buffer) {
  if (buffer.length >= 3 && buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) {
    return 'image/jpeg';
  }
  if (
    buffer.length >= 4 &&
    buffer[0] === 0x89 &&
    buffer[1] === 0x50 &&
    buffer[2] === 0x4e &&
    buffer[3] === 0x47
  ) {
    return 'image/png';
  }
  if (buffer.length >= 3 && buffer[0] === 0x47 && buffer[1] === 0x49 && buffer[2] === 0x46) {
    return 'image/gif';
  }
  if (
    buffer.length >= 12 &&
    buffer[8] === 0x57 &&
    buffer[9] === 0x45 &&
    buffer[10] === 0x42 &&
    buffer[11] === 0x50
  ) {
    return 'image/webp';
  }
  return 'image/jpeg';
}

// Los ids de usuario vienen del Admin SDK de Firebase Auth (siempre
// alfanuméricos) — se valida igual antes de usarlos en un path de archivo
// para no depender solo de eso y evitar cualquier intento de path traversal
// (p. ej. "..%2f..%2fetc%2fpasswd").
const SAFE_USER_ID = /^[a-zA-Z0-9_-]+$/;

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

app.put(
  '/api/avatar/:userId',
  express.raw({ type: () => true, limit: '5mb' }),
  async (req, res) => {
    try {
      const targetUserId = req.params.userId;
      if (!SAFE_USER_ID.test(targetUserId)) {
        return fail(res, 400, 'Id de usuario inválido.');
      }

      const callerUid = await requireSelfOrStaffRole(req, res, targetUserId);
      if (!callerUid) return; // requireSelfOrStaffRole ya respondió el error.

      const buffer = req.body;
      if (!Buffer.isBuffer(buffer) || buffer.length === 0) {
        return fail(res, 400, 'No se recibió ninguna imagen.');
      }

      await fs.promises.writeFile(path.join(AVATARS_DIR, targetUserId), buffer);
      res.json({ ok: true });
    } catch (error) {
      console.error('Error inesperado en PUT /api/avatar/:userId', error);
      fail(res, 500, `Error inesperado: ${getErrorMessage(error)}`);
    }
  },
);

// Sin autenticación a propósito: es la misma foto que ya se ve dentro de la
// app (avatares en listas, header) y la URL no es adivinable sin conocer un
// uid de Firebase Auth real.
app.get('/avatars/:userId', async (req, res) => {
  if (!SAFE_USER_ID.test(req.params.userId)) return res.status(404).end();
  try {
    const buffer = await fs.promises.readFile(
      path.join(AVATARS_DIR, req.params.userId),
    );
    res.setHeader('Content-Type', sniffImageContentType(buffer));
    res.setHeader('Cache-Control', 'public, max-age=300');
    res.send(buffer);
  } catch {
    res.status(404).end();
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
