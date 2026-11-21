import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/exercise_model.dart';
import 'streaming_controller.dart';

class StreamingPage extends StatelessWidget {
  const StreamingPage({super.key, required this.exercise});

  final ExerciseModel exercise;

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return GetX<StreamingController>(
      init: StreamingController(exercise: exercise),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: Text(exercise.name),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildBody(context, controller),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, StreamingController controller) {
    switch (controller.connectionState.value) {
      case StreamConnectionState.idle:
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      exercise.category == 'weighted'
                          ? Icons.fitness_center
                          : Icons.accessibility_new,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      exercise.name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      exercise.description,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => controller.startStreaming(),
                      icon: const Icon(Icons.videocam),
                      label: Text('start_streaming'.tr),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

      case StreamConnectionState.initializingCamera:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('initializing_camera'.tr),
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
                    Text(
                      'connecting_server'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () => controller.cancelConnecting(),
                      child: Text('cancel'.tr),
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
                          label: Text('try_again'.tr),
                        ),
                        OutlinedButton(
                          onPressed: () => controller.startStreaming(
                            requireServer: false,
                          ),
                          child: Text('local_preview'.tr),
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

        final isPlank = exercise.slug == 'plank';
        final counterLabel = isPlank
            ? 'hold_seconds'.trParams({'count': '${controller.repsCount.value}'})
            : 'reps_count'.trParams({'count': '${controller.repsCount.value}'});

        return Column(
          children: [
            // Top Telemetry Bar (Timer + Reps)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Chip(
                    avatar: const Icon(Icons.timer_outlined, size: 18),
                    label: Text(
                      _formatDuration(controller.elapsedSeconds.value),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Chip(
                    avatar: const Icon(Icons.repeat, size: 18),
                    label: Text(
                      counterLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Bounded Camera Preview (prevents desktop overflow)
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
            const SizedBox(height: 12),

            // Live Coach Feedback Box
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: _FeedbackBanner(
                status: controller.feedbackStatus.value,
                message: controller.feedbackMessage.value,
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: () => controller.stopStreaming(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.stop),
              label: Text('stop_streaming'.tr),
            ),
          ],
        );
    }
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.status,
    required this.message,
  });

  final String status;
  final String message;

  @override
  Widget build(BuildContext context) {
    final Color accentColor;
    final IconData icon;

    switch (status) {
      case 'good':
        accentColor = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case 'correction':
        accentColor = Colors.amber;
        icon = Icons.info_outline;
        break;
      default:
        accentColor = Theme.of(context).colorScheme.primary;
        icon = Icons.sports_gymnastics;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}