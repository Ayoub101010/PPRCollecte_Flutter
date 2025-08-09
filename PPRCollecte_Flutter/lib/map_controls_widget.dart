import 'package:flutter/material.dart';

class MapControlsWidget extends StatelessWidget {
  final bool lineActive;
  final bool linePaused;
  final VoidCallback addPointOfInterest;
  final VoidCallback startLineCollection;
  final VoidCallback toggleLineCollection;
  final VoidCallback finishLineCollection;

  const MapControlsWidget({
    Key? key,
    required this.lineActive,
    required this.linePaused,
    required this.addPointOfInterest,
    required this.startLineCollection,
    required this.toggleLineCollection,
    required this.finishLineCollection,
  }) : super(key: key);

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
            backgroundColor: Color(0xFFE53E3E),
            icon: Icon(Icons.place),
            label: Text("Point"),
            onPressed: addPointOfInterest,
          ),
          SizedBox(height: 12),
          if (!lineActive)
            FloatingActionButton.extended(
              heroTag: "lineBtn",
              backgroundColor: Color(0xFF1976D2),
              icon: Icon(Icons.timeline),
              label: Text("Piste"),
              onPressed: startLineCollection,
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: "pauseBtn",
                  backgroundColor: Color(0xFFD69E2E),
                  onPressed: toggleLineCollection,
                  child: Icon(linePaused ? Icons.play_arrow : Icons.pause),
                  mini: true,
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  heroTag: "stopBtn",
                  backgroundColor: Color(0xFFE53E3E),
                  onPressed: finishLineCollection,
                  child: Icon(Icons.stop),
                  mini: true,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
