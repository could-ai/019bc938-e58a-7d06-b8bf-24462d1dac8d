import 'dart:math';
import 'game_logic.dart';

class GoAI {
  final Random _random = Random();
  // 模拟次数，次数越多棋力越强，但思考时间越长
  final int _simulationCount = 1000; 

  Future<Point<int>?> getMove(GoGame game) async {
    // 简单的开局库：如果是空棋盘或前几手，优先占角或星位
    if (game.history.length < 4) {
      Point<int>? openingMove = _getOpeningMove(game);
      if (openingMove != null) return openingMove;
    }

    // 使用蒙特卡洛树搜索 (MCTS) 获取最佳落子
    // 由于Dart单线程限制，这里做一个简化的MCTS或纯蒙特卡洛模拟(Pure Monte Carlo)
    // 对于手机端，纯蒙特卡洛模拟配合一些启发式剪枝通常比纯随机强很多
    
    return await _runMonteCarloSearch(game);
  }

  Point<int>? _getOpeningMove(GoGame game) {
    int size = game.boardSize;
    List<Point<int>> stars = [];
    
    if (size == 19) {
      stars = [
        const Point(3, 3), const Point(15, 3), const Point(3, 15), const Point(15, 15), // 星位
        const Point(9, 9), // 天元
        const Point(3, 9), const Point(9, 3), const Point(15, 9), const Point(9, 15) // 边星
      ];
    } else if (size == 9) {
      stars = [
        const Point(2, 2), const Point(6, 2), const Point(2, 6), const Point(6, 6),
        const Point(4, 4)
      ];
    }

    // 过滤已被占用的点
    List<Point<int>> availableStars = stars.where((p) => game.board[p.y][p.x] == null).toList();
    
    if (availableStars.isNotEmpty) {
      return availableStars[_random.nextInt(availableStars.length)];
    }
    return null;
  }

  Future<Point<int>?> _runMonteCarloSearch(GoGame originalGame) async {
    List<Point<int>> validMoves = [];
    for (int y = 0; y < originalGame.boardSize; y++) {
      for (int x = 0; x < originalGame.boardSize; x++) {
        if (originalGame.isValidMove(x, y)) {
          validMoves.add(Point(x, y));
        }
      }
    }

    if (validMoves.isEmpty) return null;

    // 如果合法步数太多，随机采样一部分以减少计算量 (例如最多分析20个候选点)
    // 优先保留更有价值的点（如靠近已有棋子的点）
    if (validMoves.length > 20) {
      validMoves.shuffle(_random);
      // 这里可以加入启发式排序，目前简化为随机截取
      validMoves = validMoves.sublist(0, 20);
    }

    int bestScore = -999999;
    Point<int>? bestMove;

    // 对每个候选点进行模拟
    for (var move in validMoves) {
      int wins = 0;
      // 每个点模拟 N 次
      int simulationsPerMove = (_simulationCount / validMoves.length).ceil();
      
      for (int i = 0; i < simulationsPerMove; i++) {
        // 复制游戏状态
        GoGame simulationGame = _cloneGame(originalGame);
        
        // 落下当前候选子
        simulationGame.playMove(move.x, move.y);
        
        // 快速模拟直到终局（或达到最大步数）
        bool won = _simulateRandomGame(simulationGame, originalGame.currentPlayer);
        if (won) wins++;
      }

      if (wins > bestScore) {
        bestScore = wins;
        bestMove = move;
      }
      
      // 让UI线程有机会刷新，避免卡顿
      await Future.delayed(Duration.zero);
    }

    return bestMove ?? validMoves[_random.nextInt(validMoves.length)];
  }

  // 深度克隆游戏状态
  GoGame _cloneGame(GoGame source) {
    GoGame clone = GoGame(boardSize: source.boardSize);
    clone.board = List.generate(
      source.boardSize, 
      (y) => List.from(source.board[y])
    );
    clone.currentPlayer = source.currentPlayer;
    clone.capturedBlack = source.capturedBlack;
    clone.capturedWhite = source.capturedWhite;
    // History is heavy, we might skip it for simulation if Ko rule isn't strictly enforced in sim
    return clone;
  }

  // 快速模拟一局，返回 originalPlayer 是否获胜
  bool _simulateRandomGame(GoGame game, Player originalPlayer) {
    int maxMoves = 60; // 模拟最大步数，防止死循环，9路盘60步足够，19路可能需要更多
    if (game.boardSize == 19) maxMoves = 150;

    Player myColor = originalPlayer;

    for (int i = 0; i < maxMoves; i++) {
      // 随机找一个合法落子点
      // 为了性能，不遍历所有点，而是随机尝试直到找到合法点或尝试次数耗尽
      List<Point<int>> candidates = [];
      
      // 优化：只在已有棋子周围寻找落子点 (3x3 范围内)
      // 这样模拟更像人类，而不是全盘瞎下
      for (int y = 0; y < game.boardSize; y++) {
        for (int x = 0; x < game.boardSize; x++) {
          if (game.board[y][x] != null) {
             // Check neighbors
             List<Point<int>> neighbors = [
               Point(x+1, y), Point(x-1, y), Point(x, y+1), Point(x, y-1),
               Point(x+1, y+1), Point(x-1, y-1), Point(x-1, y+1), Point(x+1, y-1)
             ];
             for(var n in neighbors) {
               if(n.x >=0 && n.x < game.boardSize && n.y >=0 && n.y < game.boardSize && game.board[n.y][n.x] == null) {
                 candidates.add(n);
               }
             }
          }
        }
      }
      
      // 去重
      Set<String> seen = {};
      List<Point<int>> uniqueCandidates = [];
      for (var p in candidates) {
        String key = "${p.x},${p.y}";
        if (!seen.contains(key)) {
          seen.add(key);
          uniqueCandidates.add(p);
        }
      }

      if (uniqueCandidates.isEmpty) {
        // 全盘随机尝试
        for(int k=0; k<10; k++) {
           int rx = _random.nextInt(game.boardSize);
           int ry = _random.nextInt(game.boardSize);
           if (game.isValidMove(rx, ry)) {
             uniqueCandidates.add(Point(rx, ry));
             break;
           }
        }
      }

      if (uniqueCandidates.isEmpty) break; // 无处可下，终局

      Point<int> move = uniqueCandidates[_random.nextInt(uniqueCandidates.length)];
      if (game.isValidMove(move.x, move.y)) {
        game.playMove(move.x, move.y);
      } else {
        break; 
      }
    }

    // 简单的胜负判定：数子 (简化版：只看提子数 + 棋盘上留存子数)
    // 准确的数目需要复杂的算法，这里用简单的启发式代替
    int blackScore = game.capturedWhite + _countStones(game, Player.black);
    int whiteScore = game.capturedBlack + _countStones(game, Player.white) + 6; // 贴目 6.5 (取整6)

    if (myColor == Player.black) {
      return blackScore > whiteScore;
    } else {
      return whiteScore > blackScore;
    }
  }

  int _countStones(GoGame game, Player player) {
    int count = 0;
    for (var row in game.board) {
      for (var p in row) {
        if (p == player) count++;
      }
    }
    return count;
  }
}
