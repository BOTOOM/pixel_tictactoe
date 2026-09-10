enum Mark { x, o }

const List<List<int>> winLines = [
  [0, 1, 2],
  [3, 4, 5],
  [6, 7, 8],
  [0, 3, 6],
  [1, 4, 7],
  [2, 5, 8],
  [0, 4, 8],
  [2, 4, 6],
];

class GameState {
  GameState({
    List<Mark?>? board,
    this.current = Mark.x,
    this.starter = Mark.x,
    this.winner,
    this.winLine,
    this.scoreX = 0,
    this.scoreO = 0,
    this.draws = 0,
  }) : board = List<Mark?>.unmodifiable(board ?? List<Mark?>.filled(9, null));

  final List<Mark?> board;
  final Mark current;
  final Mark starter;
  final Mark? winner;
  final List<int>? winLine;
  final int scoreX;
  final int scoreO;
  final int draws;

  bool get isDraw => winner == null && board.every((c) => c != null);
  bool get isOver => winner != null || isDraw;

  GameState play(int index) {
    if (isOver || board[index] != null) return this;
    final next = List<Mark?>.of(board);
    next[index] = current;
    for (final line in winLines) {
      if (line.every((i) => next[i] == current)) {
        return GameState(
          board: next,
          current: current,
          winner: current,
          winLine: line,
          starter: starter,
          scoreX: scoreX + (current == Mark.x ? 1 : 0),
          scoreO: scoreO + (current == Mark.o ? 1 : 0),
          draws: draws,
        );
      }
    }
    final full = next.every((c) => c != null);
    return GameState(
      board: next,
      current: current == Mark.x ? Mark.o : Mark.x,
      starter: starter,
      scoreX: scoreX,
      scoreO: scoreO,
      draws: draws + (full ? 1 : 0),
    );
  }

  GameState nextRound() => GameState(
        current: starter == Mark.x ? Mark.o : Mark.x,
        starter: starter == Mark.x ? Mark.o : Mark.x,
        scoreX: scoreX,
        scoreO: scoreO,
        draws: draws,
      );

  GameState resetAll() => GameState();
}
