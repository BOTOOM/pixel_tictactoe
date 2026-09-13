import 'dart:math' as math;

import 'game_logic.dart';

/// A move chosen by the CPU together with the name of the tactic used, so the
/// UI can show what the machine is "thinking".
class CpuMove {
  const CpuMove(this.index, this.tactic);

  final int index;
  final String tactic;
}

/// CPU opponent whose strength grows with [level] (1..maxLevel).
///
/// 1 ROOKIE  – random moves, sometimes misses even an open win.
/// 2 CASUAL  – takes wins and blocks threats, otherwise random.
/// 3 SMART   – adds classic opening book, fork creation and fork blocking.
/// 4 PRO     – perfect minimax play (cannot lose), still varied openings.
/// 5 MASTER  – perfect play that also prefers the fastest win / slowest loss.
class CpuPlayer {
  CpuPlayer({int level = 1, math.Random? random})
      : _level = level.clamp(minLevel, maxLevel),
        _rnd = random ?? math.Random();

  static const int minLevel = 1;
  static const int maxLevel = 5;
  static const List<String> levelNames = [
    'ROOKIE',
    'CASUAL',
    'SMART',
    'PRO',
    'MASTER',
  ];

  int _level;
  final math.Random _rnd;

  int get level => _level;
  set level(int v) => _level = v.clamp(minLevel, maxLevel);

  String get levelName => levelNames[level - 1];

  /// Human beat the CPU: get tougher.
  void onHumanWin() => level += 1;

  /// CPU beat the human: ease off a little so the game stays fun.
  void onCpuWin() => level -= 1;

  static const _corners = [0, 2, 6, 8];
  static const _edges = [1, 3, 5, 7];
  static const _center = 4;
  static const _opposite = {0: 8, 8: 0, 2: 6, 6: 2};

  CpuMove chooseMove(GameState s) {
    final me = s.current;
    final them = me == Mark.x ? Mark.o : Mark.x;
    final empty = _empty(s.board);
    if (empty.isEmpty) throw StateError('board is full');

    switch (level) {
      case 1:
        final win = _winningMove(s.board, me);
        if (win != null && _rnd.nextBool()) return CpuMove(win, 'WIN');
        return CpuMove(_pick(empty), 'RANDOM');
      case 2:
        return _winOrBlock(s.board, me, them) ??
            CpuMove(_pick(empty), 'RANDOM');
      case 3:
        return _winOrBlock(s.board, me, them) ??
            _fork(s.board, me, 'FORK') ??
            _blockFork(s.board, me, them) ??
            _openingBook(s.board, me, them) ??
            CpuMove(_pick(empty), 'RANDOM');
      default:
        return _winOrBlock(s.board, me, them) ??
            _fork(s.board, me, 'FORK') ??
            _openingBook(s.board, me, them) ??
            _minimaxMove(s.board, me, them, depthAware: level >= 5);
    }
  }

  // ---------------------------------------------------------------- helpers

  List<int> _empty(List<Mark?> b) =>
      [for (var i = 0; i < 9; i++) if (b[i] == null) i];

  int _pick(List<int> options) => options[_rnd.nextInt(options.length)];

  int? _winningMove(List<Mark?> b, Mark m) {
    final wins = _winningMoves(b, m);
    return wins.isEmpty ? null : _pick(wins);
  }

  List<int> _winningMoves(List<Mark?> b, Mark m) {
    final out = <int>{};
    for (final line in winLines) {
      final mine = line.where((i) => b[i] == m).length;
      final free = line.where((i) => b[i] == null).toList();
      if (mine == 2 && free.length == 1) out.add(free.single);
    }
    return out.toList();
  }

  CpuMove? _winOrBlock(List<Mark?> b, Mark me, Mark them) {
    final win = _winningMove(b, me);
    if (win != null) return CpuMove(win, 'WIN');
    final block = _winningMove(b, them);
    if (block != null) return CpuMove(block, 'BLOCK');
    return null;
  }

  /// A fork is a move that creates two simultaneous winning threats.
  List<int> _forkMoves(List<Mark?> b, Mark m) {
    final out = <int>[];
    for (final i in _empty(b)) {
      final next = List<Mark?>.of(b)..[i] = m;
      if (_winningMoves(next, m).length >= 2) out.add(i);
    }
    return out;
  }

  CpuMove? _fork(List<Mark?> b, Mark me, String tactic) {
    final forks = _forkMoves(b, me);
    return forks.isEmpty ? null : CpuMove(_pick(forks), tactic);
  }

  /// Stop the opponent's fork: preferably by making a threat they must answer
  /// (that doesn't hand them the fork square), otherwise by occupying it.
  CpuMove? _blockFork(List<Mark?> b, Mark me, Mark them) {
    final forks = _forkMoves(b, them);
    if (forks.isEmpty) return null;
    for (final i in _empty(b)) {
      final next = List<Mark?>.of(b)..[i] = me;
      final threats = _winningMoves(next, me);
      if (threats.length == 1 && !forks.contains(threats.single)) {
        return CpuMove(i, 'COUNTER');
      }
    }
    return CpuMove(_pick(forks), 'BLOCK FORK');
  }

  /// Classic openings and textbook replies for the first two moves.
  CpuMove? _openingBook(List<Mark?> b, Mark me, Mark them) {
    final filled = b.where((c) => c != null).length;
    if (filled == 0) {
      // Strongest first moves: a corner (sets up forks) or the centre.
      return _rnd.nextInt(3) == 0
          ? const CpuMove(_center, 'CENTER OPENING')
          : CpuMove(_pick(_corners), 'CORNER OPENING');
    }
    if (filled == 1) {
      final theirs = b.indexWhere((c) => c == them);
      if (theirs == _center) {
        // Only a corner reply holds the draw against a centre opening.
        return CpuMove(_pick(_corners), 'CORNER REPLY');
      }
      if (_corners.contains(theirs)) {
        // Anything but the centre loses to a corner opening.
        return const CpuMove(_center, 'TAKE CENTER');
      }
      // Edge opening: centre is the strongest answer.
      return const CpuMove(_center, 'TAKE CENTER');
    }
    if (filled == 2 && b[_center] == me) {
      final theirs = b.indexWhere((c) => c == them);
      if (_corners.contains(theirs)) {
        // Centre vs corner: the opposite corner keeps all options open.
        final opp = _opposite[theirs]!;
        if (b[opp] == null) return CpuMove(opp, 'OPPOSITE CORNER');
      }
    }
    if (filled == 2 && _corners.contains(b.indexWhere((c) => c == me))) {
      final mine = b.indexWhere((c) => c == me);
      final theirs = b.indexWhere((c) => c == them);
      if (theirs == _center) {
        // Corner + centre taken: the opposite corner invites the edge trap.
        final opp = _opposite[mine]!;
        return CpuMove(opp, 'OPPOSITE CORNER');
      }
      if (_edges.contains(theirs)) {
        // The famous corner trap: X takes centre, threatening a fork the
        // edge reply cannot stop.
        return const CpuMove(_center, 'CORNER TRAP');
      }
    }
    return null;
  }

  // ---------------------------------------------------------------- minimax

  CpuMove _minimaxMove(
    List<Mark?> b,
    Mark me,
    Mark them, {
    required bool depthAware,
  }) {
    var best = -1000;
    final bestMoves = <int>[];
    for (final i in _empty(b)) {
      final next = List<Mark?>.of(b)..[i] = me;
      final score = -_negamax(next, them, me, 1, depthAware);
      if (score > best) {
        best = score;
        bestMoves
          ..clear()
          ..add(i);
      } else if (score == best) {
        bestMoves.add(i);
      }
    }
    final tactic = best > 0
        ? 'FORCED WIN'
        : best == 0
            ? 'SOLID'
            : 'DEFEND';
    return CpuMove(_pick(bestMoves), tactic);
  }

  /// Score from the point of view of [player], who is about to move.
  int _negamax(List<Mark?> b, Mark player, Mark other, int depth, bool depthAware) {
    if (_hasWon(b, other)) return depthAware ? -(10 - depth) : -1;
    final empty = _empty(b);
    if (empty.isEmpty) return 0;
    var best = -1000;
    for (final i in empty) {
      final next = List<Mark?>.of(b)..[i] = player;
      final score = -_negamax(next, other, player, depth + 1, depthAware);
      if (score > best) best = score;
    }
    return best;
  }

  bool _hasWon(List<Mark?> b, Mark m) =>
      winLines.any((line) => line.every((i) => b[i] == m));
}
