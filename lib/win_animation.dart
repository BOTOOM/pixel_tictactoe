import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game_logic.dart';
import 'pixel_widgets.dart';

class _Particle {
  _Particle({
    required this.pos,
    required this.vel,
    required this.color,
    required this.size,
    required this.spin,
    required this.delay,
  });

  Offset pos;
  Offset vel;
  final Color color;
  final double size;
  final double spin;
  final double delay;
}

/// Full-screen celebration: flash, pixel fireworks/confetti, bouncing banner.
class WinOverlay extends StatefulWidget {
  const WinOverlay({
    super.key,
    required this.winner,
    required this.origin,
    required this.onContinue,
  });

  final Mark? winner; // null => draw
  final Offset origin; // where the fireworks burst from (board centre)
  final VoidCallback onContinue;

  @override
  State<WinOverlay> createState() => _WinOverlayState();
}

class _WinOverlayState extends State<WinOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<_Particle> _particles = [];
  final _rnd = math.Random();
  Duration _last = Duration.zero;
  double _time = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_tick)
      ..forward();
    if (widget.winner != null) _spawnBurst(widget.origin, 140, 0);
    for (var i = 1; i <= 4; i++) {
      _spawnBurst(
        widget.origin +
            Offset((_rnd.nextDouble() - 0.5) * 320, (_rnd.nextDouble() - 0.6) * 300),
        50,
        0.45 * i,
      );
    }
  }

  void _spawnBurst(Offset at, int count, double delay) {
    for (var i = 0; i < count; i++) {
      final a = _rnd.nextDouble() * math.pi * 2;
      final sp = 180 + _rnd.nextDouble() * 420;
      _particles.add(_Particle(
        pos: at,
        vel: Offset(math.cos(a) * sp, math.sin(a) * sp - 120),
        color: Palette.confetti[_rnd.nextInt(Palette.confetti.length)],
        size: 4.0 + _rnd.nextInt(3) * 4,
        spin: _rnd.nextDouble() * 6,
        delay: delay,
      ));
    }
  }

  void _tick() {
    final now = _ctrl.lastElapsedDuration ?? Duration.zero;
    var dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    if (dt > 0.05) dt = 0.05;
    _time += dt;
    for (final p in _particles) {
      if (_time < p.delay) continue;
      p.vel = Offset(p.vel.dx * 0.985, p.vel.dy + 900 * dt);
      p.pos += p.vel * dt;
    }
    // Keep the party going: light drizzle of confetti from the top.
    if (_time > 1.2 && _rnd.nextDouble() < 0.35) {
      final w = MediaQuery.sizeOf(context).width;
      _particles.add(_Particle(
        pos: Offset(_rnd.nextDouble() * w, -10),
        vel: Offset((_rnd.nextDouble() - 0.5) * 60, 60 + _rnd.nextDouble() * 80),
        color: Palette.confetti[_rnd.nextInt(Palette.confetti.length)],
        size: 4.0 + _rnd.nextInt(2) * 4,
        spin: _rnd.nextDouble() * 6,
        delay: 0,
      ));
    }
    final h = MediaQuery.sizeOf(context).height;
    _particles.removeWhere((p) => p.pos.dy > h + 40);
    setState(() {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _time;
    final flash = (1 - t / 0.35).clamp(0.0, 1.0);
    // Banner drops in from the top with a bounce, starting at 0.3s.
    final bannerT = ((t - 0.3) / 0.9).clamp(0.0, 1.0);
    final bannerY = -400 * (1 - Curves.bounceOut.transform(bannerT));
    final wobble = math.sin(t * 6) * 3;
    final blink = (t * 2).floor().isEven;
    final hue = (t * 120) % 360;
    final rainbow = HSVColor.fromAHSV(1, hue, 0.55, 1).toColor();

    final winner = widget.winner;
    final title = winner == null
        ? 'DRAW!'
        : winner == Mark.x
            ? 'X WINS!'
            : 'O WINS!';
    final accent = winner == null ? Palette.inkDim : Palette.of(winner);
    final accentShade = winner == null ? Palette.panelDark : Palette.shadeOf(winner);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: t > 1.0 ? widget.onContinue : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: CustomPaint(painter: _ConfettiPainter(_particles, t)),
          ),
          if (flash > 0)
            IgnorePointer(
              child: Container(color: Colors.white.withValues(alpha: flash * 0.9)),
            ),
          Align(
            alignment: const Alignment(0, -0.35),
            child: Transform.translate(
              offset: Offset(0, bannerY + wobble),
              child: Transform.rotate(
                angle: math.sin(t * 4) * 0.03,
                child: PixelPanel(
                  fill: Palette.panelDark,
                  light: accent,
                  dark: accentShade,
                  border: 5,
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (winner != null)
                        SizedBox(
                          width: 78,
                          height: 42,
                          child: Transform.translate(
                            offset: Offset(0, math.sin(t * 8) * 4),
                            child: CustomPaint(
                              painter: _SpritePainter(
                                crownSprite,
                                color: Palette.gold,
                                shade: Palette.goldShade,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      _ShakyText(
                        title,
                        size: 30,
                        color: winner == null ? Palette.ink : rainbow,
                        shadow: accentShade,
                        t: t,
                      ),
                      const SizedBox(height: 16),
                      PixelText(
                        winner == null ? 'NOBODY WINS...' : 'FLAWLESS VICTORY',
                        size: 9,
                        color: Palette.inkDim,
                      ),
                      const SizedBox(height: 18),
                      Opacity(
                        opacity: t > 1.0 && blink ? 1 : 0,
                        child: const PixelText('TAP TO CONTINUE',
                            size: 9, color: Palette.gold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Each letter bobs on its own phase like an arcade high-score screen.
class _ShakyText extends StatelessWidget {
  const _ShakyText(
    this.text, {
    required this.size,
    required this.color,
    required this.shadow,
    required this.t,
  });

  final String text;
  final double size;
  final Color color;
  final Color shadow;
  final double t;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < text.length; i++)
          Transform.translate(
            offset: Offset(0, (math.sin(t * 7 + i * 0.7) * 6).roundToDouble()),
            child: PixelText(text[i], size: size, color: color, shadow: shadow),
          ),
      ],
    );
  }
}

class _SpritePainter extends CustomPainter {
  _SpritePainter(this.sprite, {required this.color, this.shade});

  final List<String> sprite;
  final Color color;
  final Color? shade;

  @override
  void paint(Canvas canvas, Size size) {
    drawSprite(canvas, sprite, Offset.zero & size, color: color, shade: shade);
  }

  @override
  bool shouldRepaint(covariant _SpritePainter old) =>
      old.sprite != sprite || old.color != color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.t);

  final List<_Particle> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    for (final p in particles) {
      if (t < p.delay) continue;
      // Snap to a 4px grid so the confetti reads as pixels, not smooth dots.
      final x = (p.pos.dx / 4).floorToDouble() * 4;
      final y = (p.pos.dy / 4).floorToDouble() * 4;
      // Fake tumbling by squashing width.
      final w = (p.size * math.cos(t * 5 + p.spin).abs()).clamp(2.0, p.size);
      paint.color = p.color;
      canvas.drawRect(Rect.fromLTWH(x, y, w, p.size), paint);
      paint.color = Colors.black.withValues(alpha: 0.35);
      canvas.drawRect(Rect.fromLTWH(x, y + p.size - 2, w, 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => true;
}
