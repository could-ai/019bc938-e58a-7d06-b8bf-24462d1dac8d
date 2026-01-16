import 'dart:math';
import 'game_logic.dart';

class GoAI {
  final Random _random = Random();

  Future<Point<int>?> getMove(GoGame game) async {
    // Simulate thinking time
    await Future.delayed(const Duration(milliseconds: 500));

    List<Point<int>> validMoves = [];

    // Simple heuristic: find all valid empty spots
    // For a 19x19 board, checking all spots is fast enough for this level
    for (int y = 0; y < game.boardSize; y++) {
      for (int x = 0; x < game.boardSize; x++) {
        if (game.isValidMove(x, y)) {
          validMoves.add(Point(x, y));
        }
      }
    }

    if (validMoves.isEmpty) {
      return null; // Pass
    }

    // Slightly smarter than random: prefer moves near existing stones (local play)
    // or near star points in opening.
    // For MVP, random is sufficient to demonstrate functionality.
    return validMoves[_random.nextInt(validMoves.length)];
  }
}
