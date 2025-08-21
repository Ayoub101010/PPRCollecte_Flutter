// lib/point_form_screen.dart
import 'package:flutter/material.dart';
import 'category_selector_widget.dart';
import 'type_selector_widget.dart';
import 'point_form_widget.dart';

class PointFormScreen extends StatefulWidget {
  final Map<String, dynamic>? pointData;
  final String? agentName;
  const PointFormScreen({super.key, this.pointData, this.agentName});

  @override
  State<PointFormScreen> createState() => _PointFormScreenState();
}

class _PointFormScreenState extends State<PointFormScreen> {
  String? selectedCategory;
  String? selectedType;

  void _handleBack() {
    if (selectedType != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Abandonner la saisie ?"),
          content: const Text("Les données non sauvegardées seront perdues."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Annuler"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Abandonner"),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      selectedCategory = category;
      selectedType = null;
    });
  }

  void _onTypeSelected(String type) {
    setState(() {
      selectedType = type;
    });
  }

  void _onBackToCategories() {
    setState(() {
      selectedCategory = null;
      selectedType = null;
    });
  }

  void _onBackToTypes() {
    setState(() {
      selectedType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF), // Même couleur que React Native
      body: SafeArea(
        child: Column(
          children: [
            // Header - Style exactement comme React Native
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1976D2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _handleBack,
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    padding: const EdgeInsets.all(8),
                  ),
                  const Expanded(
                    child: Text(
                      "🎯 Point d'Intérêt",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 40), // Équilibrer avec le bouton back
                ],
              ),
            ),

            // Contenu dynamique
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (selectedCategory == null) {
      return CategorySelectorWidget(
        onCategorySelected: _onCategorySelected,
      );
    } else if (selectedType == null) {
      return TypeSelectorWidget(
        category: selectedCategory!,
        onTypeSelected: _onTypeSelected,
        onBack: _onBackToCategories,
      );
    } else {
      return PointFormWidget(
        category: selectedCategory!,
        type: selectedType!,
        pointData: widget.pointData,
        onBack: _onBackToTypes,
        onSaved: () {
          Navigator.of(context).pop();
        },
        agentName: widget.agentName,
      );
    }
  }
}
