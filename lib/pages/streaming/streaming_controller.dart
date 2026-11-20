import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:rxdart/rxdart.dart' as rx;
import '../../isolates/frame_processor.dart';

enum StreamConnectionState {
  idle,
  initializingCamera,
  connectingServer,
  streaming,
  error,
}

class StreamingController extends GetxController with WidgetsBindingObserver {
  final Rx<CameraController?> cameraController = Rx<CameraController?>(null);
  final RxBool isInitialized = false.obs;
  final RxBool isStreaming = false.obs;

  final Rx<StreamConnectionState> connectionState =
      StreamConnectionState.idle.obs;
  final RxString errorMessage = ''.obs;

  // Configurable from Settings page later
  final RxString serverUrl = _defaultServerUrl().obs;
  final RxInt connectionTimeoutSeconds = 5.obs;

  rx.PublishSubject<CameraImage>? _frameSubject;
  StreamSubscription<CameraImage>? _throttledSub;
  Isolate? _processingIsolate;
  SendPort? _isolateSendPort;
  ReceivePort? _mainReceivePort;
  WebSocket? _webSocket;

  bool _isStarting = false;
  bool _cancelRequested = false;
  int _nextFrameId = 0;
  int _lastSentFrameId = -1;

  static String _defaultServerUrl() {
    if (Platform.isAndroid) {
      return 'ws://10.0.2.2:8000/ws';
    }
    return 'ws://127.0.0.1:8000/ws';
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((Platform.isAndroid || Platform.isIOS) &&
        (state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive)) {
      _teardownAll();
    }
  }

  Future<void> _initCamera() async {
    if (cameraController.value != null &&
        cameraController.value!.value.isInitialized) {
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('Камеру не знайдено на цьому пристрої');
    }

    final camera = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    cameraController.value = camera;
    try {
      await camera.initialize();
      isInitialized.value = true;
    } catch (e) {
      await camera.dispose();
      cameraController.value = null;
      isInitialized.value = false;
      rethrow;
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
      } else if (message is Map && message.containsKey('jpeg')) {
        final int frameId = message['frameId'] as int;
        if (frameId < _lastSentFrameId) return;
        _lastSentFrameId = frameId;

        final Uint8List jpegBytes = (message['jpeg'] as TransferableTypedData)
            .materialize()
            .asUint8List();

        if (_webSocket != null && _webSocket!.readyState == WebSocket.open) {
          _webSocket!.add(jpegBytes);
        }
      } else if (message is Map && message['error'] != null) {
        debugPrint('Frame processing error: ${message['error']}');
      }
    });
  }

  Future<void> _connectWebSocket() async {
    final timeout = Duration(seconds: connectionTimeoutSeconds.value);
    _webSocket = await WebSocket.connect(serverUrl.value).timeout(timeout);

    _webSocket!.listen(
      (dynamic serverMessage) {
        debugPrint('Server feedback: $serverMessage');
      },
      onError: (error) => debugPrint('WebSocket stream error: $error'),
      onDone: () => debugPrint('WebSocket closed by server'),
    );
  }

  Future<void> startStreaming({bool requireServer = true}) async {
      if (isStreaming.value || _isStarting) return;
      _isStarting = true;
      _cancelRequested = false;
      _nextFrameId = 0;
      _lastSentFrameId = -1;
      errorMessage.value = '';

      try {
        connectionState.value = StreamConnectionState.initializingCamera;
        try {
          await _initCamera();
        } catch (e) {
          debugPrint('Camera initialization error: $e');
          if (!_cancelRequested) {
            errorMessage.value =
                'Не вдалося запустити камеру. Перевірте пристрій та дозволи.';
            connectionState.value = StreamConnectionState.error;
          }
          return;
        }
        if (_aborted) return;

        await _startIsolate();
        if (_aborted) return;

        if (requireServer) {
          connectionState.value = StreamConnectionState.connectingServer;
          await _connectWebSocket();
          if (_aborted) return;
        }

        _frameSubject = rx.PublishSubject<CameraImage>();
        _throttledSub = _frameSubject!
            .throttleTime(const Duration(milliseconds: 66))
            .listen(_dispatchFrameToIsolate);

        await cameraController.value!.startImageStream((CameraImage image) {
          if (_frameSubject != null && !_frameSubject!.isClosed) {
            _frameSubject!.add(image);
          }
        });

        isStreaming.value = true;
        connectionState.value = StreamConnectionState.streaming;
      } on TimeoutException catch (e) {
        debugPrint('WebSocket connection timeout: $e');
        await stopStreaming(resetState: false);
        errorMessage.value =
            'Час очікування відповіді від сервера вичерпано. Перевірте з\'єднання.';
        connectionState.value = StreamConnectionState.error;
      } catch (e) {
        debugPrint('WebSocket connection error: $e');
        await stopStreaming(resetState: false);
        if (!_cancelRequested) {
          errorMessage.value =
              'Помилка підключення до сервера. Перевірте з\'єднання.';
          connectionState.value = StreamConnectionState.error;
        }
      } finally {
        _isStarting = false;
      }
    }

  bool get _aborted =>
      _cancelRequested ||
      isClosed ||
      cameraController.value == null ||
      !cameraController.value!.value.isInitialized;

  Future<void> cancelConnecting() async {
    _cancelRequested = true;
    await stopStreaming();
  }

  void _dispatchFrameToIsolate(CameraImage image) {
    final sendPort = _isolateSendPort;
    if (sendPort == null) return;

    final int planeCount = image.planes.length;
    int totalBytes = 0;
    final List<int> planeLengths = List<int>.filled(planeCount, 0);
    final List<int> rowStrides = List<int>.filled(planeCount, 0);

    for (int i = 0; i < planeCount; i++) {
      final plane = image.planes[i];
      planeLengths[i] = plane.bytes.length;
      rowStrides[i] = plane.bytesPerRow;
      totalBytes += plane.bytes.length;
    }

    final Uint8List packedBytes = Uint8List(totalBytes);
    int offset = 0;
    for (int i = 0; i < planeCount; i++) {
      final Uint8List src = image.planes[i].bytes;
      packedBytes.setRange(offset, offset + src.length, src);
      offset += src.length;
    }

    final int uvPixelStride =
        planeCount > 1 ? (image.planes[1].bytesPerPixel ?? 1) : 1;

    sendPort.send({
      'frameId': _nextFrameId++,
      'data': TransferableTypedData.fromList([packedBytes]),
      'width': image.width,
      'height': image.height,
      'format': image.format.group.index,
      'formatRaw': image.format.raw?.toString() ?? '',
      'planeLengths': planeLengths,
      'rowStrides': rowStrides,
      'uvPixelStride': uvPixelStride,
    });
  }

  Future<void> stopStreaming({bool resetState = true}) async {
    final controller = cameraController.value;
    if (controller != null &&
        controller.value.isInitialized &&
        controller.value.isStreamingImages) {
      try {
        await controller.stopImageStream();
      } catch (e) {
        debugPrint('Error stopping image stream: $e');
      }
    }

    await _throttledSub?.cancel();
    _throttledSub = null;

    if (_frameSubject != null && !_frameSubject!.isClosed) {
      await _frameSubject!.close();
    }
    _frameSubject = null;

    try {
      await _webSocket?.close();
    } catch (e) {
      debugPrint('Error closing WebSocket: $e');
    } finally {
      _webSocket = null;
    }

    _processingIsolate?.kill(priority: Isolate.immediate);
    _processingIsolate = null;
    _isolateSendPort = null;

    _mainReceivePort?.close();
    _mainReceivePort = null;

    isStreaming.value = false;
    if (resetState) {
      connectionState.value = StreamConnectionState.idle;
      errorMessage.value = '';
    }
  }

  Future<void> _teardownAll() async {
    await stopStreaming();
    final controller = cameraController.value;
    cameraController.value = null;
    isInitialized.value = false;
    await controller?.dispose();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _teardownAll();
    super.onClose();
  }
}