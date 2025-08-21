// lib/map_controls_widget.dart
import 'package:flutter/material.dart';
import 'home_controller.dart';

class MapControlsWidget extends StatelessWidget {
  final HomeController controller;
  final VoidCallback onAddPoint;
  final VoidCallback onStartLigne;
  final VoidCallback onStartChaussee;
  final VoidCallback onToggleLigne;
  final VoidCallback onToggleChaussee;
  final VoidCallback onFinishLigne;
  final VoidCallback onFinishChaussee;

  const MapControlsWidget({
    super.key,
    required this.controller,
    required this.onAddPoint,
    required this.onStartLigne,
    required this.onStartChaussee,
    required this.onToggleLigne,
    required this.onToggleChaussee,
    required this.onFinishLigne,
    required this.onFinishChaussee,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bouton Point (visible seulement si aucune collecte active)
          if (!controller.hasActiveCollection)
            FloatingActionButton.extended(
              heroTag: "pointBtn",
              backgroundColor: const Color(0xFFE53E3E),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.place),
              label: const Text("Point"),
              onPressed: onAddPoint,
              elevation: 6,
              highlightElevation: 12,
            ),

          if (!controller.hasActiveCollection) const SizedBox(height: 12),

          // Boutons Ligne/Piste
          _buildLigneControls(),

          const SizedBox(height: 12),

          // Boutons Chaussée
          _buildChausseeControls(),
        ],
      ),
    );
  }

  Widget _buildLigneControls() {
    final ligneCollection = controller.ligneCollection;

    if (ligneCollection == null || ligneCollection.isInactive) {
      // Bouton démarrer ligne/piste
      return FloatingActionButton.extended(
        heroTag: "ligneBtn",
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.timeline),
        label: const Text("Piste"),
        onPressed: onStartLigne,
        elevation: 6,
        highlightElevation: 12,
      );
    } else {
      // Contrôles ligne active/en pause
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton pause/reprendre
          FloatingActionButton(
            heroTag: "pauseLigneBtn",
            backgroundColor: ligneCollection.isPaused ? const Color(0xFF4CAF50) : const Color(0xFFD69E2E),
            foregroundColor: Colors.white,
            onPressed: onToggleLigne,
            mini: true,
            elevation: 4,
            child: Icon(
              ligneCollection.isPaused ? Icons.play_arrow : Icons.pause,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),

          // Bouton stop
          FloatingActionButton(
            heroTag: "stopLigneBtn",
            backgroundColor: const Color(0xFFE53E3E),
            foregroundColor: Colors.white,
            onPressed: onFinishLigne,
            mini: true,
            elevation: 4,
            child: const Icon(Icons.stop, size: 20),
          ),
        ],
      );
    }
  }

  Widget _buildChausseeControls() {
    final chausseeCollection = controller.chausseeCollection;

    if (chausseeCollection == null || chausseeCollection.isInactive) {
      // Bouton démarrer chaussée
      return FloatingActionButton.extended(
        heroTag: "chausseeBtn",
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.construction),
        label: const Text("Chaussée"),
        onPressed: onStartChaussee,
        elevation: 6,
        highlightElevation: 12,
      );
    } else {
      // Contrôles chaussée active/en pause
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton pause/reprendre
          FloatingActionButton(
            heroTag: "pauseChausseeBtn",
            backgroundColor: chausseeCollection.isPaused ? const Color(0xFF4CAF50) : const Color(0xFFD69E2E),
            foregroundColor: Colors.white,
            onPressed: onToggleChaussee,
            mini: true,
            elevation: 4,
            child: Icon(
              chausseeCollection.isPaused ? Icons.play_arrow : Icons.pause,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),

          // Bouton stop
          FloatingActionButton(
            heroTag: "stopChausseeBtn",
            backgroundColor: const Color(0xFFE53E3E),
            foregroundColor: Colors.white,
            onPressed: onFinishChaussee,
            mini: true,
            elevation: 4,
            child: const Icon(Icons.stop, size: 20),
          ),
        ],
      );
    }
  }
}
