import 'package:flutter/material.dart';
import 'formulaire_ligne_controller.dart';

class ChausseeFormSection extends StatelessWidget {
  final FormulaireLigneController controller;
  const ChausseeFormSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Informations Chaussée", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Type de chaussée"),
              items: [
                "Asphalte",
                "Gravier",
                "Terre"
              ].map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (v) => controller.typeChaussee = v ?? '',
            ),
          ],
        ),
      ),
    );
  }
}
