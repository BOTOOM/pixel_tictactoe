import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_tictactoe/ai.dart';
import 'package:pixel_tictactoe/game_logic.dart';

GameState boardOf(String cells, Mark current) {
  final board = <Mark?>[
    for (final c in cells.split(''))
      c == 'X'
          ? Mark.x
          : c == 'O'
              ? Mark.o
              : null,
  ];
  return GameState(board: board, current: current);
}

/// Enumerates every possible human line of play against the CPU and fails if
/// the human ever wins.
void assertNeverLoses(CpuPlayer cpu, GameState s, Mark cpuMark) {
  if (s.isOver) {
    expect(s.winner, isNot(cpuMark == Mark.x ? Mark.o : Mark.x),
        reason: 'human won with board ${s.board}');
    return;
  }
  if (s.current == cpuMark) {
    // CPU has randomness among equal moves; try a few seeds.
    for (var seed = 0; seed < 3; seed++) {
      final c = CpuPlayer(level: cpu.level, random: math.Random(seed));
      assertNeverLoses(cpu, s.play(c.chooseMove(s).index), cpuMark);
    }
  } else {
    for (var i = 0; i < 9; i++) {
      if (s.board[i] == null) assertNeverLoses(cpu, s.play(i), cpuMark);
    }
  }
}

void main() {
  test('level 2+ takes an immediate win', () {
    final s = boardOf('XX.OO....', Mark.o);
    for (final lvl in [2, 3, 4, 5]) {
      final m = CpuPlayer(level: lvl, random: math.Random(1)).chooseMove(s);
      expect(m.index, 5, reason: 'level $lvl');
      expect(m.tactic, 'WIN');
    }
  });

  test('level 2+ blocks an immediate threat', () {
    final s = boardOf('XX..O....', Mark.o);
    for (final lvl in [2, 3, 4, 5]) {
      final m = CpuPlayer(level: lvl, random: math.Random(1)).chooseMove(s);
      expect(m.index, 2, reason: 'level $lvl');
      expect(m.tactic, 'BLOCK');
    }
  });

  test('level 3 creates a fork when available', () {
    // O at 0 and 2, X at 1 and 5: O in the centre threatens 6 and 8 at once.
    final s = boardOf('OXO..X...', Mark.o);
    final m = CpuPlayer(level: 3, random: math.Random(1)).chooseMove(s);
    expect(m.tactic, 'FORK');
    expect(m.index, 4);
  });

  test('opening book: answers a corner with the centre', () {
    final s = boardOf('X........', Mark.o);
    final m = CpuPlayer(level: 3, random: math.Random(1)).chooseMove(s);
    expect(m.index, 4);
    expect(m.tactic, 'TAKE CENTER');
  });

  test('opening book: answers the centre with a corner', () {
    final s = boardOf('....X....', Mark.o);
    final m = CpuPlayer(level: 4, random: math.Random(1)).chooseMove(s);
    expect([0, 2, 6, 8], contains(m.index));
    expect(m.tactic, 'CORNER REPLY');
  });

  test('opening book: corner trap against an edge reply', () {
    final s = boardOf('O..X.....', Mark.o);
    final m = CpuPlayer(level: 3, random: math.Random(1)).chooseMove(s);
    expect(m.index, 4);
    expect(m.tactic, 'CORNER TRAP');
  });

  test('level 4 and 5 never lose, whether moving first or second', () {
    for (final lvl in [4, 5]) {
      final cpu = CpuPlayer(level: lvl);
      assertNeverLoses(cpu, GameState(), Mark.x);
      assertNeverLoses(cpu, GameState(), Mark.o);
    }
  });

  test('level 5 prefers the fastest win', () {
    // O can win immediately at 2 or set up a slower win; must pick 2.
    final s = boardOf('OO.XX....', Mark.o);
    final m = CpuPlayer(level: 5, random: math.Random(1)).chooseMove(s);
    expect(m.index, 2);
  });

  test('difficulty adapts to results and stays within bounds', () {
    final cpu = CpuPlayer();
    expect(cpu.level, 1);
    expect(cpu.levelName, 'ROOKIE');
    cpu.onCpuWin();
    expect(cpu.level, 1);
    for (var i = 0; i < 10; i++) {
      cpu.onHumanWin();
    }
    expect(cpu.level, CpuPlayer.maxLevel);
    expect(cpu.levelName, 'MASTER');
    cpu.onCpuWin();
    expect(cpu.level, 4);
  });
}
