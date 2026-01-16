import 'dart:math';
import 'package:flutter/material.dart';
import 'game_logic.dart';
import 'go_board.dart';
import 'go_ai.dart';

class GameScreen extends StatefulWidget {
  final int boardSize;

  const GameScreen({super.key, this.boardSize = 19});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GoGame game;
  late GoAI ai;
  bool isAiThinking = false;
  String statusMessage = "请执黑先行";

  @override
  void initState() {
    super.initState();
    game = GoGame(boardSize: widget.boardSize);
    ai = GoAI();
  }

  void _handleTap(int x, int y) async {
    if (isAiThinking || game.currentPlayer != Player.black) return;

    if (game.playMove(x, y)) {
      setState(() {
        statusMessage = "AI 思考中...";
        isAiThinking = true;
      });

      // AI Turn
      Point<int>? aiMove = await ai.getMove(game);
      
      if (mounted) {
        setState(() {
          isAiThinking = false;
          if (aiMove != null) {
            game.playMove(aiMove.x, aiMove.y);
            statusMessage = "轮到你了 (执黑)";
          } else {
            statusMessage = "AI 停了一手 (Pass)";
          }
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("无效的落子位置"), duration: Duration(milliseconds: 500)),
      );
    }
  }

  void _resetGame() {
    setState(() {
      game.reset();
      statusMessage = "请执黑先行";
      isAiThinking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('与 AI 对弈'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
            tooltip: '重新开始',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPlayerInfo(Player.black, "玩家", game.capturedWhite),
                Text(statusMessage, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                _buildPlayerInfo(Player.white, "AI", game.capturedBlack),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: GoBoard(
                    game: game,
                    onTap: _handleTap,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo(Player player, String name, int captured) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: player == Player.black ? Colors.black : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey),
              ),
            ),
            const SizedBox(width: 8),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Text("提子: $captured"),
      ],
    );
  }
}
