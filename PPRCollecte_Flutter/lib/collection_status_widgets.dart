import 'package:flutter/material.dart';
import 'collection_models.dart';

class LigneStatusWidget extends StatelessWidget {
  final LigneCollection collection;
  final double? topOffset;

  const LigneStatusWidget({
    super.key,
    required this.collection,
    this.topOffset,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: topOffset ?? 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: collection.isActive ? const Color(0xFF1976D2) : Colors.orange,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 2),
              blurRadius: 4,
            )
          ],
        ),
        child: Row(
          children: [
            Icon(
              collection.isActive ? Icons.radio_button_checked : Icons.pause_circle_filled,
              color: collection.isActive ? const Color(0xFF1976D2) : Colors.orange,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                collection.isActive ? "Collecte piste active" : "Piste en pause",
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
              ),
            ),
            Text(
              "${collection.points.length} pts • ${collection.totalDistance.round()}m",
              style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}

class ChausseeStatusWidget extends StatelessWidget {
  final ChausseeCollection collection;
  final double? topOffset;

  const ChausseeStatusWidget({
    super.key,
    required this.collection,
    this.topOffset,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: topOffset ?? 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: collection.isActive ? const Color(0xFFFF9800) : Colors.deepOrange,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 2),
              blurRadius: 4,
            )
          ],
        ),
        child: Row(
          children: [
            Icon(
              collection.isActive ? Icons.radio_button_checked : Icons.pause_circle_filled,
              color: collection.isActive ? const Color(0xFFFF9800) : Colors.deepOrange,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                collection.isActive ? "Collecte chaussée active" : "Chaussée en pause",
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
              ),
            ),
            Text(
              "${collection.points.length} pts • ${collection.totalDistance.round()}m",
              style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}

// Ajouter après ChausseeStatusWidget
class SpecialStatusWidget extends StatelessWidget {
  final SpecialCollection collection;
  final double? topOffset;

  const SpecialStatusWidget({
    super.key,
    required this.collection,
    this.topOffset,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: topOffset ?? 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF9C27B0), // Violet pour spécial
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 2),
              blurRadius: 4,
            )
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.radio_button_checked,
              color: const Color(0xFF9C27B0),
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Collecte ${collection.specialType} active",
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
              ),
            ),
            Text(
              "${collection.points.length} pts • ${collection.totalDistance.round()}m",
              style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
