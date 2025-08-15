// lib/provisional_form_dialog.dart
import 'package:flutter/material.dart';
import 'collection_models.dart';

class ProvisionalFormDialog {
  static Future<Map<String, String>?> show({
    required BuildContext context,
    required CollectionType type,
  }) async {
    final typeLabel = type == CollectionType.ligne ? 'Piste' : 'Chaussée';
    final icon =
        type == CollectionType.ligne ? Icons.timeline : Icons.construction;
    final color = type == CollectionType.ligne
        ? const Color(0xFF1976D2)
        : const Color(0xFFFF9800);

    final idController = TextEditingController(
      text:
          '${typeLabel.toUpperCase()}_${DateTime.now().millisecondsSinceEpoch}',
    );
    final nameController = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Nouvelle $typeLabel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          titlePadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Champ ID (lecture seule)
              TextField(
                controller: idController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'ID ${typeLabel}',
                  prefixIcon: Icon(Icons.fingerprint, color: color),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),

              // Champ Nom (obligatoire)
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Nom de la ${typeLabel.toLowerCase()} *',
                  prefixIcon: Icon(Icons.edit, color: color),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Message d'information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'La collecte GPS démarrera après validation',
                        style: TextStyle(
                          fontSize: 12,
                          color: color.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Le nom est obligatoire'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop({
                  'id': idController.text,
                  'name': nameController.text.trim(),
                });
              },
              child: const Text('Commencer la collecte'),
            ),
          ],
        );
      },
    );
  }
}
