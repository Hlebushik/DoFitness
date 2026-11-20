import 'dart:isolate';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

void frameProcessingEntry(SendPort mainSendPort) {
  final port = ReceivePort();
  mainSendPort.send(port.sendPort);

  port.listen((dynamic message) {
    if (message is Map && message.containsKey('data')) {
      final int frameId = message['frameId'] as int;
      final TransferableTypedData transferable =
          message['data'] as TransferableTypedData;
      final int width = message['width'] as int;
      final int height = message['height'] as int;
      final int formatIndex = message['format'] as int;
      final List<int> planeLengths =
          (message['planeLengths'] as List).cast<int>();
      final List<int> rowStrides =
          (message['rowStrides'] as List).cast<int>();
      final int uvPixelStride = message['uvPixelStride'] as int;

      try {
        final Uint8List bytes = transferable.materialize().asUint8List();

        final img.Image rgbImage = _convertCameraImageToRGB(
          bytes: bytes,
          width: width,
          height: height,
          formatIndex: formatIndex,
          planeLengths: planeLengths,
          rowStrides: rowStrides,
          uvPixelStride: uvPixelStride,
        );

        final img.Image resized = img.copyResize(
          rgbImage,
          width: 640,
          height: 480,
          interpolation: img.Interpolation.nearest,
        );

        final Uint8List jpeg = Uint8List.fromList(
          img.encodeJpg(resized, quality: 75),
        );

        mainSendPort.send({
          'frameId': frameId,
          'jpeg': TransferableTypedData.fromList([jpeg]),
        });
      } catch (e) {
        mainSendPort.send({'error': e.toString()});
      }
    }
  });
}

img.Image _convertCameraImageToRGB({
  required Uint8List bytes,
  required int width,
  required int height,
  required int formatIndex,
  required List<int> planeLengths,
  required List<int> rowStrides,
  required int uvPixelStride,
}) {
  if (formatIndex == ImageFormatGroup.yuv420.index) {
    return _yuv420ToRgb(
      bytes: bytes,
      width: width,
      height: height,
      planeLengths: planeLengths,
      rowStrides: rowStrides,
      uvPixelStride: uvPixelStride,
    );
  } else if (formatIndex == ImageFormatGroup.bgra8888.index) {
    return _bgraToRgb(
      bytes: bytes,
      width: width,
      height: height,
      rowStride: rowStrides.isNotEmpty ? rowStrides[0] : width * 4,
    );
  } else {
    throw UnsupportedError('Unsupported image format: $formatIndex');
  }
}

img.Image _yuv420ToRgb({
  required Uint8List bytes,
  required int width,
  required int height,
  required List<int> planeLengths,
  required List<int> rowStrides,
  required int uvPixelStride,
}) {
  final int yLength = planeLengths[0];
  final int uLength = planeLengths[1];

  final Uint8List yBytes = Uint8List.sublistView(bytes, 0, yLength);
  final Uint8List uBytes =
      Uint8List.sublistView(bytes, yLength, yLength + uLength);
  final Uint8List vBytes =
      Uint8List.sublistView(bytes, yLength + uLength, yLength + uLength + planeLengths[2]);

  final int yRowStride = rowStrides[0];
  final int uvRowStride = rowStrides[1];

  final img.Image rgb = img.Image(width: width, height: height);

  for (int y = 0; y < height; y++) {
    final int yRowOffset = y * yRowStride;
    final int uvRowOffset = (y ~/ 2) * uvRowStride;

    for (int x = 0; x < width; x++) {
      final int yp = yBytes[yRowOffset + x];
      final int uvOffset = uvRowOffset + (x ~/ 2) * uvPixelStride;

      final int up = uBytes[uvOffset];
      final int vp = vBytes[uvOffset];

      final int r = (yp + vp * 1436 / 1024 - 179).clamp(0, 255).toInt();
      final int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
          .clamp(0, 255)
          .toInt();
      final int b = (yp + up * 1814 / 1024 - 227).clamp(0, 255).toInt();

      rgb.setPixelRgb(x, y, r, g, b);
    }
  }
  return rgb;
}

img.Image _bgraToRgb({
  required Uint8List bytes,
  required int width,
  required int height,
  required int rowStride,
}) {
  return img.Image.fromBytes(
    width: width,
    height: height,
    bytes: bytes.buffer,
    bytesOffset: bytes.offsetInBytes,
    rowStride: rowStride,
    numChannels: 4,
    order: img.ChannelOrder.bgra,
  );
}