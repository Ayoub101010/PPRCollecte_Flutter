// lib/provisional_form_dialog.dart - VERSION OPTIMISÉE
import 'package:flutter/material.dart';

class ProvisionalFormDialog {
  static Future<Map<String, String>?> show({
    required BuildContext context,
  }) async {
    final codeController = TextEditingController();

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
            decoration: const BoxDecoration(
              color: Color(0xFF1976D2), // ✅ Ajout de const
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: const Row(
              // ✅ Ajout de const
              children: [
                Icon(Icons.route, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(
                  // ✅ Ajout d'Expanded pour éviter l'overflow
                  child: Text(
                    'Nouvelle Piste',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          titlePadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                autofocus: true,
                textCapitalization:
                    TextCapitalization.characters, // ✅ Majuscules auto
                decoration: InputDecoration(
                  labelText: 'Code Piste *',
                  hintText: 'Ex: 1B-02CR03P01',
                  prefixIcon: const Icon(Icons.qr_code,
                      color: Color(0xFF1976D2)), // ✅ const
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: Color(0xFF1976D2), width: 2), // ✅ const
                  ),
                ),
                onSubmitted: (value) {
                  // ✅ Validation sur Enter
                  if (value.trim().isNotEmpty) {
                    Navigator.of(context).pop({
                      'code_piste': value.trim(),
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF1976D2).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Color(0xFF1976D2),
                    ), // ✅ const
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Format: [REGION][BTGR]-[PREFECTURE]CR[COMMUNE]P[NUMERO]',
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFF1976D2).withOpacity(0.8),
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
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white, // ✅ Couleur texte explicite
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                final code = codeController.text.trim();
                if (code.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Le code piste est obligatoire'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop({
                  'code_piste': code,
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
