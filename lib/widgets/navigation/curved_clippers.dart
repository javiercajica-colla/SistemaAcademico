import 'package:flutter/material.dart';

/// Recorta un solo arco elíptico a lo ancho del widget, hundido hacia
/// abajo en el centro — usado por [CurvedHeader]. `curveHeight` es cuánto
/// más "baja" queda la punta del arco respecto a los bordes izquierdo y
/// derecho (30px en el header, según el mockup).
class CurvedBottomClipper extends CustomClipper<Path> {
  const CurvedBottomClipper({this.curveHeight = 30});

  final double curveHeight;

  @override
  Path getClip(Size size) {
    final h = curveHeight.clamp(0.0, size.height);
    final path = Path();
    path.lineTo(0, size.height - h);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - h,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CurvedBottomClipper oldClipper) =>
      oldClipper.curveHeight != curveHeight;
}

/// Espejo vertical de [CurvedBottomClipper]: el arco se levanta hacia
/// arriba en el centro — usado por [CurvedFooter] para cerrar la pantalla
/// con el mismo lenguaje visual del header.
class CurvedTopClipper extends CustomClipper<Path> {
  const CurvedTopClipper({this.curveHeight = 30});

  final double curveHeight;

  @override
  Path getClip(Size size) {
    final h = curveHeight.clamp(0.0, size.height);
    final path = Path();
    path.lineTo(0, h);
    path.quadraticBezierTo(size.width / 2, 0, size.width, h);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CurvedTopClipper oldClipper) =>
      oldClipper.curveHeight != curveHeight;
}
