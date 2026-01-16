import 'dart:math';
import 'package:flutter/material.dart';
import 'game_logic.dart';

class GoBoard extends StatelessWidget {
  final GoGame game;
  final Function(int, int) onTap;

  const GoBoard({super.key, required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double size = min(constraints.maxWidth, constraints.maxHeight);
        double cellSize = size / (game.boardSize + 1); // Add padding margin

        return GestureDetector(
          onTapUp: (details) {
            // Calculate grid coordinates
            double touchX = details.localPosition.dx;
            double touchY = details.localPosition.dy;

            // Offset for margin
            double margin = cellSize;
            
            // Convert to grid index
            // The grid starts at margin, ends at size - margin
            // x = (touchX - margin + half_cell) / cellSize
            
            int gridX = ((touchX - margin + cellSize / 2) / cellSize).floor();
            int gridY = ((touchY - margin + cellSize / 2) / cellSize).floor();

            if (gridX >= 0 && gridX < game.boardSize && gridY >= 0 && gridY < game.boardSize) {
              onTap(gridX, gridY);
            }
          },
          child: CustomPaint(
            size: Size(size, size),
            painter: BoardPainter(game: game, cellSize: cellSize),
          ),
        );
      },
    );
  }
}

class BoardPainter extends CustomPainter {
  final GoGame game;
  final double cellSize;

  BoardPainter({required this.game, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    Paint bgPaint = Paint()..color = const Color(0xFFDCB35C); // Traditional wood color
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    Paint linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0;

    double margin = cellSize;
    double boardWidth = cellSize * (game.boardSize - 1);

    // Draw Grid Lines
    for (int i = 0; i < game.boardSize; i++) {
      double offset = margin + i * cellSize;
      
      // Vertical lines
      canvas.drawLine(
        Offset(offset, margin),
        Offset(offset, margin + boardWidth),
        linePaint,
      );

      // Horizontal lines
      canvas.drawLine(
        Offset(margin, offset),
        Offset(margin + boardWidth, offset),
        linePaint,
      );
    }

    // Draw Star Points (Hoshi)
    if (game.boardSize == 19) {
      List<int> stars = [3, 9, 15];
      for (int x in stars) {
        for (int y in stars) {
          canvas.drawCircle(
            Offset(margin + x * cellSize, margin + y * cellSize),
            3.0,
            Paint()..color = Colors.black..style = PaintingStyle.fill,
          );
        }
      }
    } else if (game.boardSize == 9) {
       List<int> stars = [2, 6]; // 3-3 point and 7-7 point (index 2 and 6) + center 4,4
       // Center
       canvas.drawCircle(
          Offset(margin + 4 * cellSize, margin + 4 * cellSize),
          3.0,
          Paint()..color = Colors.black..style = PaintingStyle.fill,
        );
       for (int x in stars) {
        for (int y in stars) {
          canvas.drawCircle(
            Offset(margin + x * cellSize, margin + y * cellSize),
            3.0,
            Paint()..color = Colors.black..style = PaintingStyle.fill,
          );
        }
      }
    }

    // Draw Stones
    for (int y = 0; y < game.boardSize; y++) {
      for (int x = 0; x < game.boardSize; x++) {
        Player? p = game.board[y][x];
        if (p != null) {
          double cx = margin + x * cellSize;
          double cy = margin + y * cellSize;
          double radius = cellSize * 0.45;

          // Shadow
          canvas.drawCircle(
            Offset(cx + 2, cy + 2),
            radius,
            Paint()..color = Colors.black.withOpacity(0.3),
          );

          // Stone
          Paint stonePaint = Paint()
            ..color = p == Player.black ? Colors.black : Colors.white;
          canvas.drawCircle(Offset(cx, cy), radius, stonePaint);
          
          // Slight shine for 3D effect on white stones or both
          if (p == Player.white) {
             canvas.drawCircle(
              Offset(cx - radius * 0.3, cy - radius * 0.3),
              radius * 0.2,
              Paint()..color = Colors.white.withOpacity(0.8)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
            );
          } else {
             canvas.drawCircle(
              Offset(cx - radius * 0.3, cy - radius * 0.3),
              radius * 0.3,
              Paint()..color = Colors.white.withOpacity(0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
            );
          }
        }
      }
    }
    
    // Highlight last move if exists
    if (game.history.isNotEmpty) {
      // We need to track the last move coordinate in GameLogic ideally, 
      // but for now we can infer or just skip. 
      // Let's skip for MVP to keep logic simple, or add a marker if we tracked it.
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
