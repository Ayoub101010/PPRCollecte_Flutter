// lib/provisional_form_dialog.dart - VERSION CORRIGÉE
import 'package:flutter/material.dart'; // ✅ IMPORT AJOUTÉ

class ProvisionalFormDialog {
  static Future<Map<String, String>?> show({
    required BuildContext context,
  }) async {
    final codeController = TextEditingController(); // ✅ Vide par défaut

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
              color: const Color(0xFF1976D2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.route, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Nouvelle Piste',
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
              // ✅ UN SEUL CHAMP : Code Piste
              TextField(
                controller: codeController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Code Piste *',
                  hintText: 'Ex: 1B-02CR03P01', // ✅ Exemple du format
                  prefixIcon:
                      Icon(Icons.qr_code, color: const Color(0xFF1976D2)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: const Color(0xFF1976D2), width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Message d'information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF1976D2).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: const Color(0xFF1976D2)),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                if (codeController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Le code piste est obligatoire'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop({
                  'code_piste': codeController.text.trim(),
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
