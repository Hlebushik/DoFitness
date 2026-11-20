import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' as getx;
// ignore: unused_import
import 'package:image/image.dart' as img;
import 'package:rxdart/rxdart.dart' as rx;
import '../../isolates/frame_processor.dart';
import 'dart:typed_data';
import 'dart:isolate';

class StreamingController extends getx.GetxController with WidgetsBindingObserver {
  getx.Rx<CameraController?> cameraController = getx.Rx<CameraController?>(
    null,
  );
  getx.RxBool isInitialized = false.obs;
  getx.RxBool isStreaming = false.obs;

  late rx.PublishSubject<CameraImage> _frameSubject;
  Isolate? _processingIsolate;
  SendPort? _isolateSendPort;
  ReceivePort? _mainReceivePort;

  WebSocket? _webSocket;
  final String _wsUrl = 'ws://10.0.2.2:8000/ws';

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final camera = cameraController.value;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (isStreaming.value) {
        stopStreaming();
      }

      if (camera != null && camera.value.isInitialized) {
        camera.dispose();
        cameraController.value = null;
        isInitialized.value = false;
      }
    }

    else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }


  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    stopStreaming();
    cameraController.value?.dispose();
    super.onClose();
  }
  
  Future<void> _initCamera() async {
    if (cameraController.value != null) return; // Already initialized
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    final camera = CameraController(
      cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    cameraController.value = camera;
    try {
      await camera.initialize();
      isInitialized.value = true;
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _connectWebSocket() async {
    try {
      _webSocket = await WebSocket.connect(_wsUrl);
      print('WebSocket connected to $_wsUrl');
    } catch (e) {
      print('WebSocket connection error: $e');
    }
  }

  Future<void> _startIsolate() async {
    _mainReceivePort = ReceivePort();
    _processingIsolate = await Isolate.spawn(
      frameProcessingEntry,
      _mainReceivePort!.sendPort,
    );

    _mainReceivePort!.listen((dynamic message) {
      if (message is SendPort) {
        _isolateSendPort = message;
        // print('Isolate SendPort received');
      } else if (message is Uint8List) {

        if (_webSocket != null && _webSocket!.readyState == WebSocket.open) {
          _webSocket!.add(message);
        }


        // HEAVY DEBUG BLOCK TO CHECK IF FRAMES ARE RECIEVED CORRECTLY

        // final processedImage = img.decodeJpg(message);
        // if (processedImage != null) {

        //   print(
        //     'Processed frame JPEG dimensions: ${processedImage.width}x${processedImage.height}',
        //   );
        // }
        // print(
        //   'Processed frame received from isolate, JPEG size: ${message.length}',
        // );


      } else if (message is Map && message['error'] != null) {
        print('Frame processing error: ${message['error']}');
      } else {
        print('Unknown message from isolate: $message');
      }
    });
  }

  Future<void> startStreaming() async {
    if (isStreaming.value) return;

    await _initCamera();
    await _startIsolate();
    await _connectWebSocket();

    if (cameraController.value == null || !cameraController.value!.value.isInitialized) {
      print("Streaming aborted: Camera was disposed during startup sequence.");
      return;
    }

    // Recreate frame subject every start
    _frameSubject = rx.PublishSubject<CameraImage>();

    // Start camera image stream
    if (cameraController.value != null &&
        cameraController.value!.value.isInitialized) {
      await cameraController.value!.startImageStream((CameraImage image) {
        _frameSubject.add(image);
      });

      _frameSubject.throttleTime(const Duration(milliseconds: 66)).listen((
        CameraImage image,
      ) {
        print('Throttled frame: ${image.width}x${image.height}');
        if (_isolateSendPort != null) {
          final bytes = Uint8List.fromList(
            image.planes.expand((p) => p.bytes).toList(),
          );
          _isolateSendPort!.send({
            'bytes': bytes,
            'width': image.width,
            'height': image.height,
            'format': image.format.group.index,
          });
          // print('Frame sent to isolate');
        } else {
          print('Isolate SendPort is null, frame not sent');
        }
      });

      isStreaming.value = true;
      print('Streaming started');
    }
  }

  Future<void> stopStreaming() async {
    if (cameraController.value != null &&
        cameraController.value!.value.isStreamingImages) {
      try {
        await cameraController.value!.stopImageStream();
        print('Streaming stopped');
      } catch (e) {
        print('Error stopping image stream: $e');
      }
    }

    // Close frame subject safely
    try {
      if (!_frameSubject.isClosed) {
        await _frameSubject.close();
      }
    } catch (e) {
      print('Error closing frame subject: $e');
    }

    // Close the WebSocket safely 

    try {
      await _webSocket?.close();
      _webSocket = null;
      print('WebSocket closed');
    } catch (e) {
      print('Error closing WebSocket: $e');
    }

    // Kill processing isolate
    try {
      _processingIsolate?.kill(priority: Isolate.immediate);
    } catch (e) {
      print('Error killing isolate: $e');
    } finally {
      _processingIsolate = null;
      _isolateSendPort = null;
      try {
        _mainReceivePort?.close();
      } catch (e) {
        print('Error closing receive port: $e');
      } finally {
        _mainReceivePort = null;
      }
    }

    isStreaming.value = false;
  }

}