import 'dart:math';

// Genera nombres de usuario y contraseñas temporales para el alta de
// docentes, estudiantes y padres de familia.
class UserCredentialGenerator {
  static const _accentedChars = 'áéíóúÁÉÍÓÚñÑüÜ';
  static const _plainChars = 'aeiouAEIOUnNuU';

  static String _stripAccents(String input) {
    var out = input;
    for (var i = 0; i < _accentedChars.length; i++) {
      out = out.replaceAll(_accentedChars[i], _plainChars[i]);
    }
    return out;
  }

  static String _clean(String input) {
    final stripped = _stripAccents(input);
    return stripped.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  // Genera un username único con el patrón nombre.apellido, agregando un
  // número secuencial si ya existe (juan.perez, juan.perez1, juan.perez2...).
  static String generateUsername(
    String firstName,
    String lastName,
    Iterable<String> existingUsernames,
  ) {
    final firstWord = _clean(firstName.trim().split(' ').first);
    final lastWordRaw = lastName.trim();
    final lastWord = lastWordRaw.isEmpty
        ? ''
        : _clean(lastWordRaw.split(' ').first);

    final base = lastWord.isEmpty
        ? (firstWord.isEmpty ? 'usuario' : firstWord)
        : '$firstWord.$lastWord';

    final existing = existingUsernames.map((e) => e.toLowerCase()).toSet();
    if (!existing.contains(base)) return base;

    var i = 1;
    while (existing.contains('$base$i')) {
      i++;
    }
    return '$base$i';
  }

  // Genera una contraseña segura de [length] caracteres (10-12) con al
  // menos una mayúscula, una minúscula, un número y un carácter especial.
  static String generatePassword({int length = 11}) {
    assert(length >= 10 && length <= 12);
    const lowers = 'abcdefghijkmnpqrstuvwxyz';
    const uppers = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    const digits = '23456789';
    const symbols = '!@#%&*+-';
    final rnd = Random.secure();

    String pick(String chars) => chars[rnd.nextInt(chars.length)];

    final required = [pick(uppers), pick(lowers), pick(digits), pick(symbols)];
    const allChars = lowers + uppers + digits + symbols;
    final rest = List.generate(length - required.length, (_) => pick(allChars));

    final all = [...required, ...rest];
    all.shuffle(rnd);
    return all.join();
  }

  // Valida que una contraseña elegida por el propio usuario sea lo
  // suficientemente segura. Devuelve null si es válida, o un mensaje de
  // error describiendo el primer requisito que falta.
  static String? validatePasswordStrength(String password) {
    if (password.length < 10) return 'Debe tener al menos 10 caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Debe incluir al menos una mayúscula';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Debe incluir al menos una minúscula';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Debe incluir al menos un número';
    }
    if (!RegExp(r'[!@#$%^&*()_+\-=\[\]{};:,.<>?]').hasMatch(password)) {
      return 'Debe incluir al menos un carácter especial (!@#%&*+-...)';
    }
    return null;
  }
}
