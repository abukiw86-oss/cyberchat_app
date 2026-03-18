import 'package:flutter/material.dart';
import 'dart:math';
class MatrixSymbol {
  Offset position;
  String symbol;

  MatrixSymbol({required this.position, required this.symbol});
}

class MatrixRainPainter extends CustomPainter {
  final List<MatrixSymbol> symbols;

  MatrixRainPainter({required this.symbols});
  @override
  void paint(Canvas canvas, Size size) {
    const textStyle = TextStyle(
      color: Color.fromARGB(255, 255, 0, 0),
      fontSize: 16,
      fontWeight: .w900,
      fontFamily: 'monospace',
    );
    const textSpan = TextSpan(text: '0', style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    for (var symbol in symbols) {
      textPainter.text = TextSpan(
        text: symbol.symbol,
        style: textStyle.copyWith(
          color: const Color.fromARGB(255, 255, 0, 0).withOpacity(0.7 + Random().nextDouble() * 0.3),
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, symbol.position);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
