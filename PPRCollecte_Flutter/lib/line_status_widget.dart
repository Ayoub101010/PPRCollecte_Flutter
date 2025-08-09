import 'package:flutter/material.dart';

class LineStatusWidget extends StatelessWidget {
  final bool linePaused;
  final int linePointsCount;
  final double distance;

  const LineStatusWidget({
    Key? key,
    required this.linePaused,
    required this.linePointsCount,
    required this.distance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: Offset(0, 2),
              blurRadius: 4,
            )
          ],
        ),
        child: Row(
          children: [
            Icon(
              linePaused ? Icons.pause_circle_filled : Icons.radio_button_checked,
              color: linePaused ? Color(0xFFFF9800) : Color(0xFF4CAF50),
              size: 16,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                linePaused ? "En pause" : "Collecte piste",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
              ),
            ),
            Text(
              "$linePointsCount pts • ${distance.round()}m",
              style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
