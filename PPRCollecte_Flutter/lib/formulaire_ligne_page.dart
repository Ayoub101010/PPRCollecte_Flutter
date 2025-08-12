import 'package:flutter/material.dart';
import 'piste_form_section.dart';
import 'chaussee_form_section.dart';
import 'formulaire_ligne_controller.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FormulaireLignePage extends StatefulWidget {
  final List<LatLng> linePoints; // Tu peux passer les coordonnées collectées
  const FormulaireLignePage({super.key, required this.linePoints});

  @override
  State<FormulaireLignePage> createState() => _FormulaireLignePageState();
}

class _FormulaireLignePageState extends State<FormulaireLignePage> {
  final _formKey = GlobalKey<FormState>();
  final controller = FormulaireLigneController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Formulaire Ligne"),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Section Piste
            PisteFormSection(controller: controller),

            const SizedBox(height: 20),

            // Section Chaussée
            ChausseeFormSection(controller: controller),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text("Enregistrer"),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();

                  final result = controller.buildResult(widget.linePoints);

                  Navigator.pop(context, result);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
