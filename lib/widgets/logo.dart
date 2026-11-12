import 'package:flutter/material.dart';
import 'package:siwes360/theme/tokens.dart';

/// The SIWES360 mark, drawn rather than loaded from a PNG: a cube of three
/// ruled faces, like the lines of a logbook page. The old PNG had an orange and
/// royal-blue palette and a shadow baked into the image.
class SiwesMark extends StatelessWidget {
  const SiwesMark({super.key, this.size = 72, this.color = Palette.navy});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _MarkPainter(color));
}

/// Mark and wordmark side by side, or stacked.
class SiwesLogo extends StatelessWidget {
  const SiwesLogo({super.key, this.markSize = 56, this.stacked = true, this.tagline});

  final double markSize;
  final bool stacked;
  final String? tagline;

  @override
  Widget build(BuildContext context) {
    final words = Column(
      crossAxisAlignment: stacked ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('SIWES360', style: Txt.sans(Txt.display, weight: FontWeight.w700).copyWith(letterSpacing: 1.5)),
        if (tagline != null) ...[
          const SizedBox(height: 2),
          Text(tagline!, style: Txt.sans(Txt.small, color: Palette.inkSoft)),
        ],
      ],
    );
    final mark = SiwesMark(size: markSize);
    return stacked
        ? Column(mainAxisSize: MainAxisSize.min, children: [mark, const SizedBox(height: Space.lg), words])
        : Row(mainAxisSize: MainAxisSize.min, children: [mark, const SizedBox(width: Space.md), words]);
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.color);

  final Color color;

  static const _stripes = 5;
  static const _gap = 0.32; // share of each band left empty

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = Offset(size.width / 2, size.height / 2);
    const k = 0.8660254; // cos 30°
    final top = c + Offset(0, -r);
    final upperRight = c + Offset(r * k, -r / 2);
    final lowerRight = c + Offset(r * k, r / 2);
    final bottom = c + Offset(0, r);
    final lowerLeft = c + Offset(-r * k, r / 2);
    final upperLeft = c + Offset(-r * k, -r / 2);

    final paint = Paint()..color = color;
    // Each face is a rhombus [a, b, c, d] in order around its edge. Stripes run
    // parallel to a->b and are stacked from a towards d. Moving each corner in a
    // little leaves a seam between the faces.
    final inset = r * 0.05;
    _face(canvas, paint, [lowerLeft, upperLeft, top, c], inset); // left face, vertical stripes
    _face(canvas, paint, [top, upperRight, lowerRight, c], inset); // right face, stripes down to the right
    _face(canvas, paint, [lowerLeft, c, lowerRight, bottom], inset); // bottom face, stripes up to the right
  }

  void _face(Canvas canvas, Paint paint, List<Offset> q, double inset) {
    final centre = (q[0] + q[1] + q[2] + q[3]) / 4;
    final p = q.map((v) => centre + (v - centre) * (1 - inset / (v - centre).distance)).toList();
    final a = p[0], b = p[1], c = p[2], d = p[3];
    for (var i = 0; i < _stripes; i++) {
      final t0 = (i + _gap / 2) / _stripes;
      final t1 = (i + 1 - _gap / 2) / _stripes;
      final corners = [_lerp(a, d, t0), _lerp(b, c, t0), _lerp(b, c, t1), _lerp(a, d, t1)];
      canvas.drawPath(Path()..addPolygon(corners, true), paint);
    }
  }

  Offset _lerp(Offset a, Offset b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(_MarkPainter old) => old.color != color;
}
