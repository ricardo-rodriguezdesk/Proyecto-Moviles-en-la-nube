/// Validaciones de formularios reutilizables.
class Validators {
  Validators._();

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Escribe tu correo';
    if (!_emailRegex.hasMatch(v)) return 'Correo no válido';
    return null;
  }

  static String? password(String? value) {
    if ((value ?? '').length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  static String? name(String? value) {
    if ((value ?? '').trim().length < 2) return 'Escribe tu nombre';
    return null;
  }

  static String? Function(String?) confirm(String Function() original) {
    return (value) {
      if (value != original()) return 'Las contraseñas no coinciden';
      return null;
    };
  }
}
