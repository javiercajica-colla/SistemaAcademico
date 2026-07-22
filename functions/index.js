const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { setGlobalOptions } = require('firebase-functions/v2');
const admin = require('firebase-admin');

setGlobalOptions({ region: 'us-central1' });
admin.initializeApp();
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

// Callable que permite a un coordinador o administrador del sistema
// restablecer la contraseña de cualquier usuario existente. Esto es lo único
// posible con Firebase: la contraseña original NUNCA puede leerse, solo se
// puede sobrescribir con una nueva (que es la que se devuelve al admin).
exports.adminResetUserPassword = onCall(async (request) => {
  try {
    const auth = request.auth;
    if (!auth) {
      throw new HttpsError('unauthenticated', 'Debes iniciar sesión.');
    }

    const callerDoc = await db.collection('users').doc(auth.uid).get();
    if (!callerDoc.exists) {
      throw new HttpsError(
        'permission-denied',
        'No se encontró tu perfil de usuario en la base de datos.',
      );
    }

    const callerRole = callerDoc.data()?.role;
    if (callerRole !== 'admin' && callerRole !== 'coordinator') {
      throw new HttpsError(
        'permission-denied',
        'No tienes permiso para restablecer contraseñas.',
      );
    }

    const targetUserId = request.data?.targetUserId?.trim();
    if (!targetUserId || typeof targetUserId !== 'string') {
      throw new HttpsError('invalid-argument', 'Falta el id del usuario objetivo.');
    }

    let targetUser;
    try {
      targetUser = await admin.auth().getUser(targetUserId);
    } catch (error) {
      const message = getErrorMessage(error);
      if (message.includes('user-not-found') || message.includes('not found')) {
        throw new HttpsError(
          'not-found',
          'No existe una cuenta de autenticación para ese usuario.',
        );
      }
      throw new HttpsError('internal', `No se pudo localizar la cuenta de destino: ${message}`);
    }

    if (!targetUser.email) {
      throw new HttpsError('failed-precondition', 'La cuenta objetivo no tiene correo asociado.');
    }

    const newPassword = generatePassword();

    try {
      await admin.auth().updateUser(targetUserId, { password: newPassword });
    } catch (error) {
      const code = error?.code || 'internal-error';
      const message = getErrorMessage(error);
      if (code === 'auth/user-not-found') {
        throw new HttpsError('not-found', 'No existe una cuenta de autenticación para ese usuario.');
      }
      if (code === 'auth/invalid-password') {
        throw new HttpsError('invalid-argument', 'La contraseña generada no es válida.');
      }
      throw new HttpsError('internal', `No se pudo restablecer la contraseña: ${message}`);
    }

    return { password: newPassword };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError('internal', `Error inesperado: ${getErrorMessage(error)}`);
  }
});
