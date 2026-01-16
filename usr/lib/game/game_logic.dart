import 'dart:math';

enum Player { black, white }

class GoGame {
  final int boardSize;
  late List<List<Player?>> board;
  Player currentPlayer = Player.black;
  List<List<List<Player?>>> history = []; // For Ko rule and undo
  int capturedBlack = 0;
  int capturedWhite = 0;

  GoGame({this.boardSize = 19}) {
    reset();
  }

  void reset() {
    board = List.generate(boardSize, (_) => List.filled(boardSize, null));
    currentPlayer = Player.black;
    history.clear();
    capturedBlack = 0;
    capturedWhite = 0;
  }

  bool isValidMove(int x, int y) {
    // 1. Check bounds
    if (x < 0 || x >= boardSize || y < 0 || y >= boardSize) return false;
    
    // 2. Check if empty
    if (board[y][x] != null) return false;

    // 3. Check suicide rule (simplified: if placing stone results in 0 liberties and no captures, it's invalid)
    // We need to simulate the move to check this properly
    bool valid = true;
    
    // Create a temporary board to simulate
    List<List<Player?>> tempBoard = List.generate(
      boardSize, 
      (i) => List.from(board[i])
    );
    tempBoard[y][x] = currentPlayer;

    // Check if this move captures any opponent stones
    Player opponent = currentPlayer == Player.black ? Player.white : Player.black;
    bool captures = _checkCapturesOnBoard(tempBoard, x, y, opponent);
    
    // If it doesn't capture, check if the placed stone has liberties
    if (!captures) {
      if (!_hasLibertiesOnBoard(tempBoard, x, y)) {
        valid = false; // Suicide move
      }
    }

    // 4. Check Ko rule (cannot repeat previous board state)
    // For MVP, we might skip complex Ko checks or just check immediate previous state
    if (valid && history.isNotEmpty) {
      // If simulating the move (including captures) results in the same board as history.last, it's Ko.
      // This requires full simulation. For MVP, we'll skip strict Ko enforcement to keep it responsive,
      // or implement a basic check if needed.
    }

    return valid;
  }

  bool playMove(int x, int y) {
    if (!isValidMove(x, y)) return false;

    // Save state for history
    history.add(List.generate(boardSize, (i) => List.from(board[i])));

    // Place stone
    board[y][x] = currentPlayer;

    // Handle captures
    Player opponent = currentPlayer == Player.black ? Player.white : Player.black;
    _handleCaptures(x, y, opponent);

    // Switch turn
    currentPlayer = opponent;
    return true;
  }

  void _handleCaptures(int x, int y, Player opponent) {
    // Check neighbors of the placed stone for opponent groups that might be captured
    List<Point<int>> neighbors = [
      Point(x + 1, y),
      Point(x - 1, y),
      Point(x, y + 1),
      Point(x, y - 1)
    ];

    for (var p in neighbors) {
      if (p.x >= 0 && p.x < boardSize && p.y >= 0 && p.y < boardSize) {
        if (board[p.y.toInt()][p.x.toInt()] == opponent) {
          if (!_hasLibertiesOnBoard(board, p.x.toInt(), p.y.toInt())) {
            _removeGroup(p.x.toInt(), p.y.toInt());
          }
        }
      }
    }
  }

  // Helper for validation (simulation)
  bool _checkCapturesOnBoard(List<List<Player?>> b, int x, int y, Player opponent) {
    List<Point<int>> neighbors = [
      Point(x + 1, y),
      Point(x - 1, y),
      Point(x, y + 1),
      Point(x, y - 1)
    ];

    for (var p in neighbors) {
      if (p.x >= 0 && p.x < boardSize && p.y >= 0 && p.y < boardSize) {
        if (b[p.y.toInt()][p.x.toInt()] == opponent) {
          if (!_hasLibertiesOnBoard(b, p.x.toInt(), p.y.toInt())) {
            return true; // Would capture something
          }
        }
      }
    }
    return false;
  }

  bool _hasLibertiesOnBoard(List<List<Player?>> b, int x, int y) {
    Player? color = b[y][x];
    if (color == null) return true;

    Set<String> visited = {};
    List<Point<int>> stack = [Point(x, y)];
    visited.add('$x,$y');

    while (stack.isNotEmpty) {
      Point<int> current = stack.removeLast();
      
      List<Point<int>> neighbors = [
        Point(current.x + 1, current.y),
        Point(current.x - 1, current.y),
        Point(current.x, current.y + 1),
        Point(current.x, current.y - 1)
      ];

      for (var n in neighbors) {
        if (n.x < 0 || n.x >= boardSize || n.y < 0 || n.y >= boardSize) continue;
        
        if (b[n.y.toInt()][n.x.toInt()] == null) {
          return true; // Found a liberty
        }

        if (b[n.y.toInt()][n.x.toInt()] == color) {
          String key = '${n.x},${n.y}';
          if (!visited.contains(key)) {
            visited.add(key);
            stack.add(n);
          }
        }
      }
    }
    return false;
  }

  void _removeGroup(int x, int y) {
    Player? color = board[y][x];
    if (color == null) return;

    List<Point<int>> stack = [Point(x, y)];
    board[y][x] = null; // Remove first
    _incrementCapture(color);

    while (stack.isNotEmpty) {
      Point<int> current = stack.removeLast();
      
      List<Point<int>> neighbors = [
        Point(current.x + 1, current.y),
        Point(current.x - 1, current.y),
        Point(current.x, current.y + 1),
        Point(current.x, current.y - 1)
      ];

      for (var n in neighbors) {
        if (n.x < 0 || n.x >= boardSize || n.y < 0 || n.y >= boardSize) continue;
        
        if (board[n.y.toInt()][n.x.toInt()] == color) {
          board[n.y.toInt()][n.x.toInt()] = null;
          _incrementCapture(color);
          stack.add(n);
        }
      }
    }
  }

  void _incrementCapture(Player capturedColor) {
    if (capturedColor == Player.black) {
      capturedBlack++;
    } else {
      capturedWhite++;
    }
  }
}
