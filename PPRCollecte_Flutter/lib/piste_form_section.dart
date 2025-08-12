import 'package:flutter/material.dart';
import 'formulaire_ligne_controller.dart';

class PisteFormSection extends StatelessWidget {
  final FormulaireLigneController controller;
  const PisteFormSection({super.key, required this.controller});

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
            const Text("Informations Piste", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextFormField(
              decoration: const InputDecoration(labelText: "Nom de la piste"),
              validator: (v) => v == null || v.isEmpty ? "Champ requis" : null,
              onSaved: (v) => controller.nomPiste = v ?? '',
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: "Longueur estimée (m)"),
              keyboardType: TextInputType.number,
              onSaved: (v) => controller.longueurPiste = double.tryParse(v ?? '0') ?? 0,
            ),
          ],
        ),
      ),
    );
  }
}
