import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class OgpPainter extends CustomPainter {
  OgpPainter(this.logoImage);

  final ui.Image logoImage;

  @override
  void paint(Canvas canvas, Size size) {
    const sideSpace = 150.0;

    // ====================================
    // 表示テキストの設定
    // ====================================
    final textSpan = TextSpan(
      text: 'Flutter✌️',
      style: TextStyle(
        color: Colors.black.withOpacity(0.5),
        fontSize: 160,
        fontWeight: FontWeight.w400,
      ),
    );

    // ====================================
    // painterの設定
    // ====================================
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr,
    );

    // ====================================
    // テキストを中心揃いにする
    // ====================================

    double centerTextPosY(double painterHeight) {
      return (size.height - painterHeight) / 2;
    }

    textPainter.layout();

    // ====================================
    // 描画処理
    // ====================================
    final backgroundPaint = Paint()
      ..color = Color(0xffffffff)
      ..blendMode = BlendMode.color;
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        size.width,
        size.height,
      ),
      backgroundPaint,
    );

    canvas.drawImage(
      logoImage,
      Offset(
        sideSpace,
        centerTextPosY(logoImage.height.toDouble()),
      ),
      Paint(),
    );

    textPainter.paint(
      canvas,
      Offset(
        sideSpace + logoImage.width + 24,
        centerTextPosY(textPainter.height),
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
