import 'dart:isolate';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

void frameProcessingEntry(SendPort mainSendPort) {
  final port = ReceivePort();
  mainSendPort.send(port.sendPort);
  print('SendPort sent back to main thread');

  port.listen((dynamic message) {
    // print('Frame received in isolate: ${message['width']}x${message['height']}');
    if (message is Map && message.containsKey('bytes')) {
      final Uint8List bytes = message['bytes'];
      final int width = message['width'];
      final int height = message['height'];
      final int formatIndex = message['format'];
      try {
        final img.Image rgbImage = _convertCameraImageToRGB(
          bytes,
          width,
          height,
          formatIndex,
        );

        final resized = img.copyResize(rgbImage, width: 640, height: 480);

        final jpeg = img.encodeJpg(resized);

        mainSendPort.send(Uint8List.fromList(jpeg));
      } catch (e) {
        mainSendPort.send({'error': e.toString()});
      }
    }
  });
}

img.Image _convertCameraImageToRGB(
  Uint8List bytes,
  int width,
  int height,
  int formatIndex,
) {
  if (formatIndex == ImageFormatGroup.yuv420.index) {
    return _yuv420ToRgb(bytes, width, height);
  } else if (formatIndex == ImageFormatGroup.bgra8888.index) {
    return _bgraToRgb(bytes, width, height);
  } else {
    throw UnsupportedError('Unsupported image format: $formatIndex');
  }
}

img.Image _yuv420ToRgb(Uint8List bytes, int width, int height) {
  final int frameSize = width * height;
  final int uvSize = frameSize ~/ 4;
  final Uint8List yBytes = bytes.sublist(0, frameSize);
  final Uint8List uBytes = bytes.sublist(frameSize, frameSize + uvSize);
  final Uint8List vBytes = bytes.sublist(frameSize + uvSize);

  final img.Image rgb = img.Image(width: width, height: height);

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final int yIndex = y * width + x;
      final yp = yBytes[yIndex];

      final uvX = x ~/ 2;
      final uvY = y ~/ 2;
      final uvIndex = uvY * (width ~/ 2) + uvX;

      final up = uBytes[uvIndex];
      final vp = vBytes[uvIndex];

      final r = (yp + vp * 1436 / 1024 - 179).clamp(0, 255).toInt();
      final g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
          .clamp(0, 255)
          .toInt();
      final b = (yp + up * 1814 / 1024 - 227).clamp(0, 255).toInt();

      rgb.setPixelRgb(x, y, r, g, b);
    }
  }
  return rgb;
}

img.Image _bgraToRgb(Uint8List bytes, int width, int height) {
  final rgb = img.Image(width: width, height: height);
  int offset = 0;

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final b = bytes[offset++];
      final g = bytes[offset++];
      final r = bytes[offset++];
      offset++;
      rgb.setPixelRgb(x, y, r, g, b);
    }
  }
  return rgb;
}
