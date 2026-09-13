import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game_logic.dart';

class Palette {
  static const bg = Color(0xFF1A1033);
  static const bgDots = Color(0xFF24184A);
  static const panel = Color(0xFF2E2157);
  static const panelLight = Color(0xFF4A3A85);
  static const panelDark = Color(0xFF120B26);
  static const ink = Color(0xFFF8F1E7);
  static const inkDim = Color(0xFF9E93C4);
  static const xColor = Color(0xFFFF5D73);
  static const xShade = Color(0xFFA8203A);
  static const oColor = Color(0xFF4FE3C1);
  static const oShade = Color(0xFF1B8C79);
  static const gold = Color(0xFFFFD447);
  static const goldShade = Color(0xFFC98A12);
  static const grid = Color(0xFF6C5CB0);

  static const confetti = [
    Color(0xFFFF5D73),
    Color(0xFF4FE3C1),
    Color(0xFFFFD447),
    Color(0xFF7CFF6B),
    Color(0xFF6BA8FF),
    Color(0xFFFF8BEA),
    Color(0xFFF8F1E7),
  ];

  static Color of(Mark m) => m == Mark.x ? xColor : oColor;
  static Color shadeOf(Mark m) => m == Mark.x ? xShade : oShade;
}

const pixelFont = 'PressStart2P';

class PixelText extends StatelessWidget {
  const PixelText(
    this.text, {
    super.key,
    this.size = 12,
    this.color = Palette.ink,
    this.shadow = Palette.panelDark,
    this.align = TextAlign.center,
  });

  final String text;
  final double size;
  final Color color;
  final Color? shadow;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: TextStyle(
        fontFamily: pixelFont,
        fontSize: size,
        color: color,
        height: 1.4,
        shadows: shadow == null
            ? null
            : [Shadow(color: shadow!, offset: Offset(size / 6, size / 6))],
      ),
    );
  }
}

/// Chunky bevelled box that mimics an 8-bit menu panel.
class PixelPanel extends StatelessWidget {
  const PixelPanel({
    super.key,
    required this.child,
    this.fill = Palette.panel,
    this.light = Palette.panelLight,
    this.dark = Palette.panelDark,
    this.border = 4,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final Color fill;
  final Color light;
  final Color dark;
  final double border;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BevelPainter(fill: fill, light: light, dark: dark, b: border),
      child: Padding(padding: padding + EdgeInsets.all(border), child: child),
    );
  }
}

class _BevelPainter extends CustomPainter {
  _BevelPainter({
    required this.fill,
    required this.light,
    required this.dark,
    required this.b,
  });

  final Color fill;
  final Color light;
  final Color dark;
  final double b;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    final w = size.width;
    final h = size.height;
    // Outer dark outline with notched (rounded-pixel) corners.
    p.color = dark;
    canvas.drawRect(Rect.fromLTWH(b, 0, w - 2 * b, h), p);
    canvas.drawRect(Rect.fromLTWH(0, b, w, h - 2 * b), p);
    // Highlight (top/left).
    p.color = light;
    canvas.drawRect(Rect.fromLTWH(b, b, w - 2 * b, b), p);
    canvas.drawRect(Rect.fromLTWH(b, b, b, h - 2 * b), p);
    // Fill.
    p.color = fill;
    canvas.drawRect(Rect.fromLTWH(2 * b, 2 * b, w - 4 * b, h - 4 * b), p);
    // Shadow (bottom/right) drawn inside the fill.
    p.color = Color.lerp(fill, dark, 0.5)!;
    canvas.drawRect(Rect.fromLTWH(2 * b, h - 2 * b, w - 3 * b, b), p);
    canvas.drawRect(Rect.fromLTWH(w - 2 * b, 2 * b, b, h - 3 * b), p);
  }

  @override
  bool shouldRepaint(covariant _BevelPainter old) =>
      old.fill != fill || old.light != light || old.dark != dark || old.b != b;
}

class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = Palette.gold,
    this.shade = Palette.goldShade,
    this.textColor = Palette.panelDark,
    this.size = 10,
  });

  final String label;
  final VoidCallback onPressed;
  final Color color;
  final Color shade;
  final Color textColor;
  final double size;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onPressed();
      },
      child: Transform.translate(
        offset: Offset(0, _down ? 4 : 0),
        child: PixelPanel(
          fill: widget.color,
          light: Color.lerp(widget.color, Colors.white, 0.45)!,
          dark: widget.shade,
          border: 3,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: PixelText(
            widget.label,
            size: widget.size,
            color: widget.textColor,
            shadow: null,
          ),
        ),
      ),
    );
  }
}

const List<String> _xSprite = [
  '11000011',
  '11100111',
  '01111110',
  '00111100',
  '00111100',
  '01111110',
  '11100111',
  '11000011',
];

const List<String> _oSprite = [
  '00111100',
  '01111110',
  '11000011',
  '11000011',
  '11000011',
  '11000011',
  '01111110',
  '00111100',
];

const List<String> crownSprite = [
  '1000001000001',
  '1100011100011',
  '1110111110111',
  '1111111111111',
  '1111111111111',
  '0111111111110',
  '0111111111110',
];

/// Draws an 8x8 sprite crisply (no anti-aliasing) scaled to fit [size].
void drawSprite(
  Canvas canvas,
  List<String> sprite,
  Rect area, {
  required Color color,
  Color? shade,
}) {
  final rows = sprite.length;
  final cols = sprite[0].length;
  final px = (math.min(area.width / cols, area.height / rows)).floorToDouble();
  if (px <= 0) return;
  final ox = area.left + ((area.width - px * cols) / 2).floorToDouble();
  final oy = area.top + ((area.height - px * rows) / 2).floorToDouble();
  final paint = Paint()..isAntiAlias = false;
  if (shade != null) {
    paint.color = shade;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (sprite[r][c] == '1') {
          canvas.drawRect(
            Rect.fromLTWH(ox + c * px + px / 2, oy + r * px + px / 2, px, px),
            paint,
          );
        }
      }
    }
  }
  paint.color = color;
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      if (sprite[r][c] == '1') {
        canvas.drawRect(Rect.fromLTWH(ox + c * px, oy + r * px, px, px), paint);
      }
    }
  }
}

class MarkPainter extends CustomPainter {
  MarkPainter(this.mark, {this.progress = 1, this.glow = 0});

  final Mark mark;
  final double progress; // 0..1 pop-in
  final double glow; // 0..1 win highlight

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    // Quantized pop-in: sprite grows in chunky steps for a retro feel.
    final steps = (progress * 4).ceil() / 4;
    final overshoot = progress < 1 ? 1 + 0.25 * math.sin(progress * math.pi) : 1;
    final s = size.shortestSide * 0.72 * steps * overshoot;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: s,
      height: s,
    );
    final base = Palette.of(mark);
    final color = Color.lerp(base, Colors.white, glow * 0.8)!;
    drawSprite(canvas, mark == Mark.x ? _xSprite : _oSprite, rect,
        color: color, shade: Palette.shadeOf(mark));
  }

  @override
  bool shouldRepaint(covariant MarkPainter old) =>
      old.mark != mark || old.progress != progress || old.glow != glow;
}

/// Dithered starfield background that slowly scrolls.
class BackgroundPainter extends CustomPainter {
  BackgroundPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()..isAntiAlias = false;
    paint.color = Palette.bg;
    canvas.drawRect(Offset.zero & size, paint);

    const cell = 24.0;
    paint.color = Palette.bgDots;
    final offset = (t * 20) % cell;
    for (var y = -cell; y < size.height + cell; y += cell) {
      for (var x = -cell; x < size.width + cell; x += cell) {
        final odd = ((x / cell).round() + (y / cell).round()).isOdd;
        if (odd) {
          canvas.drawRect(
              Rect.fromLTWH(x + offset, y + offset, 4, 4), paint);
        }
      }
    }

    final rnd = math.Random(7);
    for (var i = 0; i < 40; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = (rnd.nextDouble() * size.height + t * 12 * (1 + i % 3)) %
          size.height;
      final tw = 0.5 + 0.5 * math.sin(t * 3 + i);
      paint.color = Palette.inkDim.withValues(alpha: 0.25 + 0.5 * tw);
      final s = 2.0 + (i % 3) * 2;
      canvas.drawRect(Rect.fromLTWH(x.floorToDouble(), y.floorToDouble(), s, s),
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter old) => old.t != t;
}

/// CRT scanline overlay.
class ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..isAntiAlias = false;
    for (var y = 0.0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
