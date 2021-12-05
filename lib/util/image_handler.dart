import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

Future<ui.Image> assetImageToUiImage(String imageAssetPath) async {
  Completer<ImageInfo> completer = Completer();
  final img = AssetImage(imageAssetPath);
  img
      .resolve(ImageConfiguration())
      .addListener(ImageStreamListener((ImageInfo info, bool _) {
    completer.complete(info);
  }));
  ImageInfo imageInfo = await completer.future;
  return imageInfo.image;
}
