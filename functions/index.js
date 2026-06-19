const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

// Mismas reglas que UserCredentialGenerator.generatePassword() en Flutter:
// 10-12 caracteres, con mayúscula, minúscula, número y símbolo obligatorios.
function generatePassword(length = 11) {
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
  const auth = request.auth;
  if (!auth) {
    throw new HttpsError('unauthenticated', 'Debes iniciar sesión.');
  }

  const callerDoc = await db.collection('users').doc(auth.uid).get();
  const callerRole = callerDoc.data()?.role;
  if (callerRole !== 'admin' && callerRole !== 'coordinator') {
    throw new HttpsError('permission-denied', 'No tienes permiso para restablecer contraseñas.');
  }

  const targetUserId = request.data?.targetUserId;
  if (!targetUserId || typeof targetUserId !== 'string') {
    throw new HttpsError('invalid-argument', 'Falta el id del usuario objetivo.');
  }

  const newPassword = generatePassword();

  try {
    await admin.auth().updateUser(targetUserId, { password: newPassword });
  } catch (e) {
    throw new HttpsError('internal', `No se pudo restablecer la contraseña: ${e.message}`);
  }

  return { password: newPassword };
});
