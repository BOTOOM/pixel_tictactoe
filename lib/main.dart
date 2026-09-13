import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ai.dart';
import 'audio.dart';
import 'game_logic.dart';
import 'pixel_widgets.dart';
import 'win_animation.dart';

void main() {
  runApp(const PixelTicTacToeApp());
}

class PixelTicTacToeApp extends StatelessWidget {
  const PixelTicTacToeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixel Tic-Tac-Toe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Palette.bg,
        fontFamily: pixelFont,
        useMaterial3: true,
      ),
      home: const ModeScreen(),
    );
  }
}

enum GameMode { twoPlayers, vsCpu }

class ModeScreen extends StatefulWidget {
  const ModeScreen({super.key});

  @override
  State<ModeScreen> createState() => _ModeScreenState();
}

class _ModeScreenState extends State<ModeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bg;

  @override
  void initState() {
    super.initState();
    _bg = AnimationController(vsync: this, duration: const Duration(seconds: 60))
      ..repeat();
  }

  @override
  void dispose() {
    _bg.dispose();
    super.dispose();
  }

  void _start(GameMode mode) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GameScreen(mode: mode)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _bg,
            builder: (_, __) =>
                CustomPaint(painter: BackgroundPainter(_bg.value * 60)),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _Title(),
                  const SizedBox(height: 36),
                  PixelPanel(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 26, vertical: 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PixelText('SELECT MODE', size: 12),
                        const SizedBox(height: 22),
                        PixelButton(
                            label: '2 PLAYERS',
                            onPressed: () => _start(GameMode.twoPlayers)),
                        const SizedBox(height: 14),
                        PixelButton(
                          label: 'VS CPU',
                          color: Palette.oColor,
                          shade: Palette.oShade,
                          onPressed: () => _start(GameMode.vsCpu),
                        ),
                        const SizedBox(height: 18),
                        const PixelText(
                          'CPU GETS SMARTER EVERY TIME YOU WIN',
                          size: 8,
                          color: Palette.inkDim,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          IgnorePointer(child: CustomPaint(painter: ScanlinePainter())),
        ],
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.mode});

  final GameMode mode;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  GameState _state = GameState();
  late final AnimationController _bg;
  late final AnimationController _win;
  bool _showOverlay = false;
  Timer? _drawTimer;
  Timer? _cpuTimer;
  final _cpu = CpuPlayer();
  String? _cpuTactic;
  final _audio = GameAudio();
  final GlobalKey _boardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _audio.startBgm();
    _scheduleCpu();
    _bg = AnimationController(vsync: this, duration: const Duration(seconds: 60))
      ..repeat();
    _win = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _showOverlay = true);
        }
      });
  }

  @override
  void dispose() {
    _drawTimer?.cancel();
    _cpuTimer?.cancel();
    _audio.dispose();
    _bg.dispose();
    _win.dispose();
    super.dispose();
  }

  void _tap(int i) {
    if (_state.isOver || _state.board[i] != null) return;
    // In VS CPU mode it's the machine's turn when O is up.
    if (widget.mode == GameMode.vsCpu && _state.current == Mark.o) return;
    _applyMove(i);
  }

  void _applyMove(int i) {
    HapticFeedback.lightImpact();
    final placed = _state.current;
    final next = _state.play(i);
    if (identical(next, _state)) return;
    if (widget.mode == GameMode.vsCpu && next.winner != null) {
      if (next.winner == Mark.x) {
        _cpu.onHumanWin();
      } else {
        _cpu.onCpuWin();
      }
    }
    _audio.startBgm(); // web autoplay: retry on first gesture
    if (placed == Mark.x) {
      _audio.placeX();
    } else {
      _audio.placeO();
    }
    setState(() => _state = next);
    if (next.winner != null) {
      HapticFeedback.heavyImpact();
      _audio.win();
      _win.forward(from: 0);
    } else if (next.isDraw) {
      _audio.draw();
      _drawTimer?.cancel();
      _drawTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted && _state.isDraw) setState(() => _showOverlay = true);
      });
    }
    _scheduleCpu();
  }

  void _scheduleCpu() {
    _cpuTimer?.cancel();
    if (widget.mode != GameMode.vsCpu ||
        _state.isOver ||
        _state.current != Mark.o) {
      return;
    }
    _cpuTimer = Timer(const Duration(milliseconds: 550), () {
      if (!mounted ||
          widget.mode != GameMode.vsCpu ||
          _state.isOver ||
          _state.current != Mark.o) {
        return;
      }
      final m = _cpu.chooseMove(_state);
      _cpuTactic = m.tactic;
      _applyMove(m.index);
    });
  }

  void _nextRound() {
    _drawTimer?.cancel();
    _cpuTimer?.cancel();
    _cpuTactic = null;
    _win.reset();
    setState(() {
      _showOverlay = false;
      _state = _state.nextRound();
    });
    _scheduleCpu();
  }

  void _resetAll() {
    _drawTimer?.cancel();
    _cpuTimer?.cancel();
    _cpuTactic = null;
    _cpu.level = CpuPlayer.minLevel;
    _win.reset();
    setState(() {
      _showOverlay = false;
      _state = _state.resetAll();
    });
  }

  Offset _boardCenter(BuildContext context) {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return MediaQuery.sizeOf(context).center(Offset.zero);
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _bg,
            builder: (_, __) =>
                CustomPaint(painter: BackgroundPainter(_bg.value * 60)),
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: _win,
              builder: (context, child) {
                // Screen shake during the first 0.6s of the win animation.
                final t = _win.value * 2.4;
                final shake = _win.isAnimating && t < 0.6 ? (0.6 - t) / 0.6 : 0.0;
                final dx = math.sin(t * 90) * 10 * shake;
                final dy = math.cos(t * 70) * 6 * shake;
                return Transform.translate(offset: Offset(dx, dy), child: child);
              },
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _Title(),
                        const SizedBox(height: 18),
                        _ScoreBoard(state: _state, mode: widget.mode),
                        if (widget.mode == GameMode.vsCpu) ...[
                          const SizedBox(height: 10),
                          PixelPanel(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PixelText(
                                  'CPU LVL ${_cpu.level} ${_cpu.levelName}',
                                  size: 9,
                                  color: Palette.oColor,
                                ),
                                if (_cpuTactic != null) ...[
                                  const SizedBox(height: 4),
                                  PixelText(
                                    _cpuTactic!,
                                    size: 8,
                                    color: Palette.inkDim,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        _TurnBanner(state: _state, mode: widget.mode),
                        const SizedBox(height: 16),
                        KeyedSubtree(
                          key: _boardKey,
                          child: _Board(
                            state: _state,
                            winAnim: _win,
                            onTap: _tap,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 14,
                          runSpacing: 12,
                          children: [
                            PixelButton(label: 'NEW ROUND', onPressed: _nextRound),
                            PixelButton(
                              label: 'RESET',
                              color: Palette.panelLight,
                              shade: Palette.panelDark,
                              textColor: Palette.ink,
                              onPressed: _resetAll,
                            ),
                            PixelButton(
                              label: _audio.muted ? 'SFX OFF' : 'SFX ON',
                              color: Palette.panelLight,
                              shade: Palette.panelDark,
                              textColor: Palette.ink,
                              onPressed: () => setState(() {
                                _audio.setMuted(!_audio.muted);
                              }),
                            ),
                            PixelButton(
                              label: 'MENU',
                              color: Palette.panelLight,
                              shade: Palette.panelDark,
                              textColor: Palette.ink,
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          IgnorePointer(child: CustomPaint(painter: ScanlinePainter())),
          if (_showOverlay)
            WinOverlay(
              winner: _state.winner,
              origin: _boardCenter(context),
              onContinue: _nextRound,
              label: widget.mode == GameMode.vsCpu && _state.winner != null
                  ? (_state.winner == Mark.x ? 'YOU WIN!' : 'CPU WINS!')
                  : null,
            ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PixelText('TIC', size: 26, color: Palette.xColor, shadow: Palette.xShade),
            SizedBox(width: 14),
            PixelText('TAC', size: 26, color: Palette.gold, shadow: Palette.goldShade),
            SizedBox(width: 14),
            PixelText('TOE', size: 26, color: Palette.oColor, shadow: Palette.oShade),
          ],
        ),
        SizedBox(height: 8),
        PixelText('* PIXEL EDITION *', size: 9, color: Palette.inkDim),
      ],
    );
  }
}

class _ScoreBoard extends StatelessWidget {
  const _ScoreBoard({required this.state, required this.mode});

  final GameState state;
  final GameMode mode;

  @override
  Widget build(BuildContext context) {
    Widget score(String label, int v, Color c, Color s) => Column(
          children: [
            PixelText(label, size: 10, color: c, shadow: s),
            const SizedBox(height: 6),
            PixelText('$v', size: 18),
          ],
        );
    return PixelPanel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          score(mode == GameMode.vsCpu ? 'YOU' : 'X', state.scoreX,
              Palette.xColor, Palette.xShade),
          score('DRAW', state.draws, Palette.inkDim, Palette.panelDark),
          score(mode == GameMode.vsCpu ? 'CPU' : 'O', state.scoreO,
              Palette.oColor, Palette.oShade),
        ],
      ),
    );
  }
}

class _TurnBanner extends StatelessWidget {
  const _TurnBanner({required this.state, required this.mode});

  final GameState state;
  final GameMode mode;

  @override
  Widget build(BuildContext context) {
    final String text;
    final Color color;
    final vsCpu = mode == GameMode.vsCpu;
    if (state.winner != null) {
      text = vsCpu
          ? (state.winner == Mark.x ? 'YOU WIN' : 'CPU WINS')
          : 'PLAYER ${state.winner == Mark.x ? 'X' : 'O'} WINS';
      color = Palette.of(state.winner!);
    } else if (state.isDraw) {
      text = 'IT\'S A DRAW';
      color = Palette.inkDim;
    } else {
      text = vsCpu
          ? (state.current == Mark.x ? 'YOUR TURN' : 'CPU THINKING...')
          : 'PLAYER ${state.current == Mark.x ? 'X' : 'O'} TURN';
      color = Palette.of(state.current);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _BlinkingCursor(color: color),
        const SizedBox(width: 10),
        PixelText(text, size: 11, color: color),
      ],
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor({required this.color});

  final Color color;

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Opacity(
        opacity: _c.value < 0.5 ? 1 : 0,
        child: Container(width: 10, height: 14, color: widget.color),
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({
    required this.state,
    required this.winAnim,
    required this.onTap,
  });

  final GameState state;
  final Animation<double> winAnim;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return PixelPanel(
      border: 5,
      padding: const EdgeInsets.all(8),
      child: AspectRatio(
        aspectRatio: 1,
        child: AnimatedBuilder(
          animation: winAnim,
          builder: (context, _) {
            final t = winAnim.value * 2.4; // seconds
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _GridPainter()),
                ),
                Positioned.fill(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                    ),
                    itemCount: 9,
                    itemBuilder: (context, i) {
                      final inLine = state.winLine?.contains(i) ?? false;
                      // Winning cells pulse white after the line is drawn.
                      final glow = inLine && t > 0.7
                          ? 0.5 + 0.5 * math.sin((t - 0.7) * 14)
                          : 0.0;
                      final bounce = inLine && t > 0.7
                          ? (math.sin((t - 0.7) * 14).abs() * 6)
                          : 0.0;
                      return _Cell(
                        mark: state.board[i],
                        glow: glow,
                        lift: bounce,
                        dimmed: state.winner != null && !inLine,
                        onTap: () => onTap(i),
                      );
                    },
                  ),
                ),
                if (state.winLine != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _WinLinePainter(
                          line: state.winLine!,
                          progress: (t / 0.7).clamp(0.0, 1.0),
                          color: Palette.gold,
                          shade: Palette.goldShade,
                          pulse: t,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Palette.grid
      ..isAntiAlias = false;
    final shade = Paint()
      ..color = Palette.panelDark
      ..isAntiAlias = false;
    const w = 6.0;
    for (var i = 1; i < 3; i++) {
      final x = (size.width * i / 3 - w / 2).floorToDouble();
      final y = (size.height * i / 3 - w / 2).floorToDouble();
      canvas.drawRect(Rect.fromLTWH(x + 3, 0, w, size.height), shade);
      canvas.drawRect(Rect.fromLTWH(0, y + 3, size.width, w), shade);
      canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), paint);
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, w), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _WinLinePainter extends CustomPainter {
  _WinLinePainter({
    required this.line,
    required this.progress,
    required this.color,
    required this.shade,
    required this.pulse,
  });

  final List<int> line;
  final double progress;
  final Color color;
  final Color shade;
  final double pulse;

  Offset _center(Size s, int i) =>
      Offset((i % 3 + 0.5) * s.width / 3, (i ~/ 3 + 0.5) * s.height / 3);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final a = _center(size, line[0]);
    final b = _center(size, line[2]);
    final dir = b - a;
    final len = dir.distance;
    final unit = dir / len;
    // Extend a bit past the outer cell centres so the line spans the board.
    final start = a - unit * (size.width / 6 * 0.7);
    final end = start + unit * ((len + size.width / 3 * 0.7) * progress);

    // Draw the line as a run of chunky squares (pixels), not a smooth stroke.
    const step = 8.0;
    final count = ((end - start).distance / step).floor();
    final paint = Paint()..isAntiAlias = false;
    final thickness = 14.0 + (progress >= 1 ? 3 * math.sin(pulse * 12) : 0);
    for (var i = 0; i <= count; i++) {
      final p = start + unit * (i * step);
      final r = Rect.fromCenter(
        center: Offset(p.dx.roundToDouble(), p.dy.roundToDouble()),
        width: thickness,
        height: thickness,
      );
      paint.color = shade;
      canvas.drawRect(r.shift(const Offset(4, 4)), paint);
    }
    for (var i = 0; i <= count; i++) {
      final p = start + unit * (i * step);
      final r = Rect.fromCenter(
        center: Offset(p.dx.roundToDouble(), p.dy.roundToDouble()),
        width: thickness,
        height: thickness,
      );
      paint.color = i == count && progress < 1 ? Colors.white : color;
      canvas.drawRect(r, paint);
    }
    // Sparks at the tip while the line is still sweeping.
    if (progress < 1) {
      final rnd = math.Random((progress * 1000).toInt());
      for (var i = 0; i < 6; i++) {
        final o = Offset((rnd.nextDouble() - 0.5) * 40, (rnd.nextDouble() - 0.5) * 40);
        paint.color = i.isEven ? Colors.white : color;
        canvas.drawRect(Rect.fromCenter(center: end + o, width: 5, height: 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WinLinePainter old) =>
      old.progress != progress || old.line != line || old.pulse != pulse;
}

class _Cell extends StatefulWidget {
  const _Cell({
    required this.mark,
    required this.glow,
    required this.lift,
    required this.dimmed,
    required this.onTap,
  });

  final Mark? mark;
  final double glow;
  final double lift;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  State<_Cell> createState() => _CellState();
}

class _CellState extends State<_Cell> with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: widget.mark == null ? 0 : 1,
  );
  bool _hover = false;

  @override
  void didUpdateWidget(covariant _Cell old) {
    super.didUpdateWidget(old);
    if (old.mark == null && widget.mark != null) {
      _pop.forward(from: 0);
    } else if (widget.mark == null) {
      _pop.value = 0;
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Transform.translate(
            offset: Offset(0, -widget.lift),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: widget.dimmed ? 0.35 : 1,
              child: Container(
                color: _hover && widget.mark == null
                    ? Palette.panelLight.withValues(alpha: 0.35)
                    : Colors.transparent,
                child: widget.mark == null
                    ? null
                    : AnimatedBuilder(
                        animation: _pop,
                        builder: (_, __) => CustomPaint(
                          painter: MarkPainter(
                            widget.mark!,
                            progress: Curves.easeOut.transform(_pop.value),
                            glow: widget.glow,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
