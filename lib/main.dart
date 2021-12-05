import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ogp_sample/painter/ogp_painter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ByteData? byteData;
  Uri? uri;

  @override
  Widget build(BuildContext context) {
    final isGenerated = byteData != null && uri != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: isGenerated
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width - 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                    ),
                    child: Image.memory(
                      Uint8List.view(byteData!.buffer),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () async {
                      final data = ClipboardData(text: uri.toString());
                      await Clipboard.setData(data);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied to clipboard.'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                    child: Text(uri.toString()),
                  ),
                ],
              )
            : Text(
                'Tap the button to generate the image.',
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isGenerated
            ? () {
                setState(() {
                  byteData = null;
                });
              }
            : () async {
                final imageData = await _createOgpImage();
                if (imageData == null) return;
                final imageUrl = await _uploadImage(imageData);
                print('imageUrl => $imageUrl');
                if (imageUrl == null) return null;
                final dynamicLinkUrl = await _buildDynamicUrl(imageUrl);
                print('dynamicLinkUrl => $dynamicLinkUrl');
                setState(() {
                  byteData = imageData;
                  uri = dynamicLinkUrl;
                });
              },
        child: isGenerated ? Icon(Icons.delete) : Icon(Icons.add),
      ),
    );
  }

  String _formattedDate() {
    final dateTime = DateTime.now();
    return '${DateFormat('yyyyMMddHHmmss').format(dateTime)}_${dateTime.microsecondsSinceEpoch}';
  }

  ///
  /// OGP画像を生成
  ///
  Future<ByteData?> _createOgpImage() async {
    // OGP画像の基本サイズ
    const imageWidth = 1200;
    const imageHeight = 630;
    ui.PictureRecorder recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final logoImage = await _assetImageToUiImage('assets/flutter_logo.png');
    OgpPainter(logoImage).paint(
      canvas,
      Size(
        imageWidth.toDouble(),
        imageHeight.toDouble(),
      ),
    );

    final image = await recorder.endRecording().toImage(
          imageWidth,
          imageHeight,
        );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);

    return data;
  }

  ///
  /// FirebaseStorageへ画像をアップロード
  ///
  Future<Uri?> _uploadImage(ByteData data) async {
    final bytes = data.buffer.asUint8List();
    final dateString = _formattedDate();
    final ref = FirebaseStorage.instance.ref('ogp_images/$dateString.png');
    try {
      await ref.putData(
        bytes,
        SettableMetadata(
          contentType: 'image/png',
        ),
      );
      return Uri.parse(
          'https://storage.googleapis.com/${ref.bucket}/ogp_images/$dateString.png');
    } on FirebaseException catch (e) {
      print('OGP Image Upload Error = $e');
    }
  }

  ///
  /// DynamicLinksを生成
  ///
  Future<Uri> _buildDynamicUrl(Uri imageUrl) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://hoge.page.link', // Dynamic Linksで作成したURL接頭辞
      link: Uri.parse('https://flutter.dev/'), // 遷移先URL
      socialMetaTagParameters: SocialMetaTagParameters(
        title: 'Flutter - Build apps for any screen',
        description:
            'Flutter transforms the app development process. Build, test, and deploy beautiful mobile, web, desktop, and embedded apps from a single codebase.',
        imageUrl: imageUrl,
      ),
    );

    final dynamicUrl = await parameters.buildShortLink();

    print('Dynamic Link Short Url = ${dynamicUrl.shortUrl}');
    return dynamicUrl.shortUrl;
  }

  ///
  /// AssetImage -> ui.Imageに変換
  ///
  Future<ui.Image> _assetImageToUiImage(String imageAssetPath) async {
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
}
