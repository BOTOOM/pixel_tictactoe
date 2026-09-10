import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_tictactoe/game_logic.dart';

void main() {
  test('X wins on the top row', () {
    var s = GameState();
    for (final i in [0, 3, 1, 4, 2]) {
      s = s.play(i);
    }
    expect(s.winner, Mark.x);
    expect(s.winLine, [0, 1, 2]);
    expect(s.scoreX, 1);
    expect(s.isOver, isTrue);
  });

  test('draw is detected and counted', () {
    var s = GameState();
    for (final i in [0, 1, 2, 4, 3, 5, 7, 6, 8]) {
      s = s.play(i);
    }
    expect(s.winner, isNull);
    expect(s.isDraw, isTrue);
    expect(s.draws, 1);
  });

  test('occupied cells and finished games ignore moves', () {
    var s = GameState().play(4);
    expect(s.play(4), same(s));
    for (final i in [0, 1, 3, 7]) {
      s = s.play(i);
    }
    expect(s.winner, Mark.x);
    expect(s.play(6), same(s));
  });

  test('next round keeps scores and alternates the starter', () {
    var s = GameState();
    for (final i in [0, 3, 1, 4, 2]) {
      s = s.play(i);
    }
    final n = s.nextRound();
    expect(n.board.every((c) => c == null), isTrue);
    expect(n.scoreX, 1);
    expect(n.current, Mark.o);

    var o = GameState();
    for (final i in [0, 3, 1, 4, 8, 5]) {
      o = o.play(i);
    }
    expect(o.winner, Mark.o);
    expect(o.winLine, [3, 4, 5]);
    expect(o.scoreO, 1);
    expect(o.nextRound().current, Mark.o);
  });

  test('board is unmodifiable', () {
    final s = GameState();
    expect(() => s.board[0] = Mark.x, throwsUnsupportedError);
  });
}
