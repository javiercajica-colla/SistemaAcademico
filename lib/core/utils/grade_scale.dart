import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Escala de calificación institucional (Decreto 1290): 1.0 a 5.0, con
/// aprobación mínima en 3.0. Ver `grades_config_screen.dart` ("Escala de
/// Calificación") para los mismos umbrales mostrados al coordinador.
class GradeScale {
  static const double min = 1.0;
  static const double basico = 3.0;
  static const double alto = 4.0;
  static const double superior = 4.6;
  static const double max = 5.0;
}

String performanceLabel(double grade) {
  if (grade <= 0) return '—';
  if (grade >= GradeScale.superior) return 'Superior';
  if (grade >= GradeScale.alto) return 'Alto';
  if (grade >= GradeScale.basico) return 'Básico';
  return 'Bajo';
}

Color performanceColor(double grade) {
  if (grade <= 0) return AppColors.textSecondary;
  if (grade >= GradeScale.superior) return AppColors.primary;
  if (grade >= GradeScale.alto) return AppColors.secondary;
  if (grade >= GradeScale.basico) return AppColors.warning;
  return AppColors.error;
}

/// Código corto de desempeño (Bajo/Básico/Alto/Superior) usado en reportes
/// consolidados por curso, siguiendo la convención BJ/BS/AT/SP.
String performanceCode(double grade) {
  if (grade <= 0) return '-';
  if (grade >= GradeScale.superior) return 'SP';
  if (grade >= GradeScale.alto) return 'AT';
  if (grade >= GradeScale.basico) return 'BS';
  return 'BJ';
}

String performanceCodeForLabel(String label) {
  switch (label) {
    case 'Superior':
      return 'SP';
    case 'Alto':
      return 'AT';
    case 'Básico':
      return 'BS';
    case 'Bajo':
      return 'BJ';
    default:
      return '-';
  }
}
