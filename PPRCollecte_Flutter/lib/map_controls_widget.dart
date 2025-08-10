import 'package:flutter/material.dart';

class MapControlsWidget extends StatelessWidget {
  final bool lineActive;
  final bool linePaused;
  final VoidCallback addPointOfInterest;
  final VoidCallback startLineCollection;
  final VoidCallback toggleLineCollection;
  final VoidCallback finishLineCollection;

  const MapControlsWidget({
    super.key,
    required this.lineActive,
    required this.linePaused,
    required this.addPointOfInterest,
    required this.startLineCollection,
    required this.toggleLineCollection,
    required this.finishLineCollection,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: "pointBtn",
            backgroundColor: const Color(0xFFE53E3E),
            icon: const Icon(Icons.place),
            label: const Text("Point"),
            onPressed: addPointOfInterest,
          ),
          const SizedBox(height: 12),
          if (!lineActive)
            FloatingActionButton.extended(
              heroTag: "lineBtn",
              backgroundColor: const Color(0xFF1976D2),
              icon: const Icon(Icons.timeline),
              label: const Text("Piste"),
              onPressed: startLineCollection,
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: "pauseBtn",
                  backgroundColor: const Color(0xFFD69E2E),
                  onPressed: toggleLineCollection,
                  mini: true,
                  child: Icon(linePaused ? Icons.play_arrow : Icons.pause),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  heroTag: "stopBtn",
                  backgroundColor: const Color(0xFFE53E3E),
                  onPressed: finishLineCollection,
                  mini: true,
                  child: Icon(Icons.stop),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
