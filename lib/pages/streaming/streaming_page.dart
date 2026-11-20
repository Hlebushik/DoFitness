import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:online_trainer/pages/streaming/streaming_controller.dart';

class StreamingPage extends StatelessWidget {
  const StreamingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final StreamingController controller = Get.put(StreamingController(), permanent: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Трансляція'), centerTitle: true),
      body: Center(
        child: Obx(() {
          if (!controller.isStreaming.value) {
            return ElevatedButton(
              onPressed: controller.isStreaming.value
                  ? null
                  : () => controller.startStreaming(),
              child: const Text('Розпочати трансляцію'),
            );
          }
          if (!controller.isInitialized.value) {
            return const CircularProgressIndicator();
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AspectRatio(
                aspectRatio:
                    controller.cameraController.value!.value.aspectRatio,
                child: CameraPreview(controller.cameraController.value!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: !controller.isStreaming.value
                    ? null
                    : () => controller.stopStreaming(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: const Text('Зупинити трансляцію'),
              ),
            ],
          );
        }),
      ),
    );
  }
}
