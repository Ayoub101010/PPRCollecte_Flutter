// lib/point_form_widget.dart
import 'package:flutter/material.dart';
import 'config.dart';

class PointFormWidget extends StatefulWidget {
  final String category;
  final String type;
  final Map<String, dynamic>? pointData;
  final VoidCallback onBack;
  final VoidCallback onSaved;

  const PointFormWidget({
    Key? key,
    required this.category,
    required this.type,
    this.pointData,
    required this.onBack,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<PointFormWidget> createState() => _PointFormWidgetState();
}

class _PointFormWidgetState extends State<PointFormWidget> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _formData = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    if (widget.pointData != null) {
      _formData = {
        'latitude': widget.pointData!['latitude'],
        'longitude': widget.pointData!['longitude'],
        'accuracy': widget.pointData!['accuracy'],
        'timestamp': widget.pointData!['timestamp'],
        'enqueteur': 'Agent PPR', // À récupérer depuis les prefs
      };
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Simuler sauvegarde
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Infrastructure sauvegardée'),
              ],
            ),
            content: Text(
              '${widget.type} enregistré.\n\n'
              'Coordonnées: ${_formData['latitude']?.toStringAsFixed(6)}, ${_formData['longitude']?.toStringAsFixed(6)}',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onSaved();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor =
        Color(InfrastructureConfig.getCategoryColor(widget.category));
    final config =
        InfrastructureConfig.getEntityConfig(widget.category, widget.type);
    final typeOptions =
        InfrastructureConfig.getTypeOptions(widget.category, widget.type);

    return Column(
      children: [
        // Header du formulaire - Style React Native
        Container(
          decoration: BoxDecoration(
            color: categoryColor,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      widget.type,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Table: ${config?['tableName'] ?? ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withAlpha((0.9 * 255).round()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),

        // Contenu du formulaire
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Section Association
                _buildFormSection(
                  title: '🔗 Association',
                  children: [
                    _buildInfoBox(
                      'Ce point sera associé à une piste lors de la synchronisation.',
                      Colors.blue,
                    ),
                  ],
                ),

                // Section Identification
                _buildFormSection(
                  title: '🏷️ Identification',
                  children: [
                    _buildTextField(
                      label: 'Nom *',
                      hint: 'Nom de ${widget.type.toLowerCase()}',
                      key: 'nom',
                      required: true,
                    ),
                    if (typeOptions.isNotEmpty)
                      _buildDropdownField(
                        label: 'Type *',
                        hint: 'Sélectionner un type',
                        options: typeOptions,
                        key: 'type',
                        required: true,
                      ),
                    if (config?['fields']?.contains('nom_cours_eau') == true)
                      _buildTextField(
                        label: 'Nom du cours d\'eau *',
                        hint: 'Nom du cours d\'eau traversé',
                        key: 'nom_cours_eau',
                        required: true,
                      ),
                  ],
                ),

                // Section Caractéristiques spécifiques
                if (_hasSpecificFields(config))
                  _buildFormSection(
                    title: '⚙️ Caractéristiques',
                    children: _buildSpecificFields(config, categoryColor),
                  ),

                // Section GPS et Métadonnées
                _buildFormSection(
                  title: '📍 Géolocalisation',
                  children: [
                    _buildGpsInfo(),
                    _buildReadOnlyField(
                      label: 'Agent enquêteur',
                      value: _formData['enqueteur'] ?? 'Non connecté',
                      icon: Icons.person,
                    ),
                  ],
                ),

                const SizedBox(height: 120), // Espace pour le bouton flottant
              ],
            ),
          ),
        ),

        // Bouton Sauvegarder - Style React Native
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: categoryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Enregistrer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection(
      {required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE3F2FD))),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1976D2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required String key,
    bool required = false,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF1976D2)),
              ),
            ),
            maxLines: maxLines,
            textAlignVertical: maxLines > 1 ? TextAlignVertical.top : null,
            validator: required
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '$label est obligatoire';
                    }
                    return null;
                  }
                : null,
            onChanged: (value) {
              _formData[key] = value;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required List<String> options,
    required String key,
    bool required = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: options.map((option) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _formData[key] = option;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFFD1D5DB), width: 2),
                          ),
                          child: _formData[key] == option
                              ? const Center(
                                  child: Icon(
                                    Icons.circle,
                                    size: 12,
                                    color: Color(0xFF1976D2),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsInfo() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3F2FD)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.gps_fixed, size: 20, color: Color(0xFF1976D2)),
              SizedBox(width: 8),
              Text(
                'Position GPS collectée',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1976D2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildGpsInfoRow('Latitude:',
              '${_formData['latitude']?.toStringAsFixed(6) ?? 'N/A'}°'),
          _buildGpsInfoRow('Longitude:',
              '${_formData['longitude']?.toStringAsFixed(6) ?? 'N/A'}°'),
          if (_formData['accuracy'] != null)
            _buildGpsInfoRow(
                'Précision:', '±${_formData['accuracy']?.round()}m'),
        ],
      ),
    );
  }

  Widget _buildGpsInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFF666666)),
                const SizedBox(width: 12),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: color.withOpacity(0.8),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasSpecificFields(Map<String, dynamic>? config) {
    return config?.containsKey('situationOptions') == true ||
        config?.containsKey('typePontOptions') == true ||
        config?.containsKey('typeBacOptions') == true ||
        config?.containsKey('causesOptions') == true;
  }

  List<Widget> _buildSpecificFields(
      Map<String, dynamic>? config, Color categoryColor) {
    List<Widget> fields = [];

    // Champs spécifiques selon l'entité
    if (config?.containsKey('situationOptions') == true) {
      fields.add(_buildDropdownField(
        label: 'Situation *',
        hint: 'Sélectionner une situation',
        options: List<String>.from(config!['situationOptions']),
        key: 'situation',
        required: true,
      ));
    }

    if (config?.containsKey('typePontOptions') == true) {
      fields.add(_buildDropdownField(
        label: 'Type du pont *',
        hint: 'Sélectionner un type',
        options: List<String>.from(config!['typePontOptions']),
        key: 'type_pont',
        required: true,
      ));
    }

    if (config?.containsKey('typeBacOptions') == true) {
      fields.add(_buildDropdownField(
        label: 'Type du bac *',
        hint: 'Sélectionner un type',
        options: List<String>.from(config!['typeBacOptions']),
        key: 'type_bac',
        required: true,
      ));
    }

    if (config?.containsKey('causesOptions') == true) {
      fields.add(_buildDropdownField(
        label: 'Cause de la coupure *',
        hint: 'Sélectionner une cause',
        options: List<String>.from(config!['causesOptions']),
        key: 'causes_coupures',
        required: true,
      ));
    }

    return fields;
  }
}
