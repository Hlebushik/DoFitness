import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:online_trainer/pages/streaming/streaming_controller.dart';

class StreamingPage extends StatelessWidget {
  const StreamingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final StreamingController controller =
        Get.put(StreamingController(), permanent: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Трансляція'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Obx(() {
            switch (controller.connectionState.value) {
              case StreamConnectionState.idle:
                return Center(
                  child: ElevatedButton.icon(
                    onPressed: () => controller.startStreaming(),
                    icon: const Icon(Icons.videocam),
                    label: const Text('Розпочати трансляцію'),
                  ),
                );

              case StreamConnectionState.initializingCamera:
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Ініціалізація камери...'),
                    ],
                  ),
                );

              case StreamConnectionState.connectingServer:
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            const Text(
                              'Підключення до сервера...',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton(
                              onPressed: () => controller.cancelConnecting(),
                              child: const Text('Скасувати'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );

              case StreamConnectionState.error:
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cloud_off,
                              size: 48,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              controller.errorMessage.value,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => controller.startStreaming(),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Спробувати ще раз'),
                                ),
                                OutlinedButton(
                                  onPressed: () => controller.startStreaming(
                                    requireServer: false,
                                  ),
                                  child: const Text('Локальний предперегляд'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );

              case StreamConnectionState.streaming:
                final cam = controller.cameraController.value;
                if (cam == null || !controller.isInitialized.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: cam.value.aspectRatio,
                            child: CameraPreview(cam),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => controller.stopStreaming(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.stop),
                      label: const Text('Зупинити трансляцію'),
                    ),
                  ],
                );
            }
          }),
        ),
      ),
    );
  }
}