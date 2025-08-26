// lib/point_form_widget.dart
import 'package:flutter/material.dart';
import 'config.dart';

import 'database_helper.dart';

class PointFormWidget extends StatefulWidget {
  final String category;
  final String type;
  final Map<String, dynamic>? pointData;
  final VoidCallback onBack;
  final VoidCallback onSaved;
  final String? agentName; // ← nouveau

  const PointFormWidget({
    super.key,
    required this.category,
    required this.type,
    this.pointData,
    required this.onBack,
    required this.onSaved,
    this.agentName, // ← nouveau
  });

  @override
  State<PointFormWidget> createState() => _PointFormWidgetState();
}

class _PointFormWidgetState extends State<PointFormWidget> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _formData = {};
  bool _isLoading = false;
  late TextEditingController agentController;

  @override
  void initState() {
    super.initState();
    print('PointFormWidget.agentName = ${widget.agentName}');
    agentController = TextEditingController(text: widget.agentName ?? 'N/A');

    _initializeFormData();
  }

  @override
  void dispose() {
    agentController.dispose();
    super.dispose();
  }

  void _initializeFormData() {
    print('🔄 Début _initializeFormData()');
    print('   widget.pointData: ${widget.pointData}');

    // Réinitialiser _formData
    _formData = {};

    if (widget.pointData != null && widget.pointData!['id'] != null) {
      // ============ MODIFICATION ============
      print('📝 Mode MODIFICATION');

      final config = InfrastructureConfig.getEntityConfig(widget.category, widget.type);
      final tableName = config?['tableName'] ?? '';
      final coordinatePrefix = _getCoordinatePrefix(tableName);

      _formData = {
        'id': widget.pointData!['id'],
        'code_piste': widget.pointData!['code_piste'],
        'nom': widget.pointData!['nom'],
        'type': widget.pointData!['type'],
        'enqueteur': widget.pointData!['enqueteur'] ?? widget.agentName ?? 'N/A',
        'date_creation': widget.pointData!['date_creation'],
        'date_modification': widget.pointData!['date_modification'] ?? DateTime.now().toIso8601String(),
        'latitude': widget.pointData!['x_$coordinatePrefix'],
        'longitude': widget.pointData!['y_$coordinatePrefix'],
      };

      _addSpecificFormDataFromPointData(widget.pointData!, widget.type);
    } else {
      // ============ CRÉATION ============
      print('🆕 Mode CRÉATION');

      // COORDONNÉES GPS - CORRECTION DÉFINITIVE
      final double latitude = widget.pointData?['latitude']?.toDouble() ?? 0.0;
      final double longitude = widget.pointData?['longitude']?.toDouble() ?? 0.0;

      _formData = {
        'id': null,
        'code_piste': null,
        'nom': null,
        'type': null,
        'enqueteur': widget.agentName ?? 'N/A',
        'date_creation': null,
        'date_modification': null,
        'latitude': latitude,
        'longitude': longitude,
      };

      print('📍 Coordonnées extraites:');
      print('   latitude: $latitude');
      print('   longitude: $longitude');
      print('   widget.pointData[latitude]: ${widget.pointData?['latitude']}');
      print('   widget.pointData[longitude]: ${widget.pointData?['longitude']}');
    }

    print('✅ _initializeFormData() terminé:');
    print('   _formData: $_formData');
  }

  @override
  void didUpdateWidget(PointFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Re-initialiser si les données pointData changent
    if (oldWidget.pointData != widget.pointData) {
      print('🔄 didUpdateWidget - pointData changé');
      _initializeFormData();
    }

    // Mettre à jour le controller agent si besoin
    if (oldWidget.agentName != widget.agentName) {
      agentController.text = widget.agentName ?? 'N/A';
      _formData['enqueteur'] = widget.agentName ?? 'N/A';
    }
  }

  void _addSpecificFormDataFromPointData(Map<String, dynamic> pointData, String entityType) {
    // Champs communs pour plusieurs entités
    if (pointData.containsKey('nom_cours_eau')) {
      _formData['nom_cours_eau'] = pointData['nom_cours_eau'];
    }

    // Champs spécifiques par type d'entité
    switch (entityType) {
      case 'Pont':
        _formData['situation'] = pointData['situation_pont'];
        _formData['type_pont'] = pointData['type_pont'];
        break;

      case 'Bac':
        _formData['type_bac'] = pointData['type_bac'];
        _formData['nom_cours_eau'] = pointData['nom_cours_eau'];
        _formData['latitude_fin'] = pointData['x_fin_traversee_bac'];
        _formData['longitude_fin'] = pointData['y_fin_traversee_bac'];
        break;

      case 'Dalot':
        _formData['situation'] = pointData['situation_dalot'];
        break;

      case 'Passage Submersible':
        _formData['type'] = pointData['type_materiau'];
        _formData['latitude_fin'] = pointData['x_fin_passage_submersible'];
        _formData['longitude_fin'] = pointData['y_fin_passage_submersible'];
        break;

      case 'Point Critique':
        _formData['type_point_critique'] = pointData['type_point_critique'];
        break;

      case 'Point de Coupure':
        _formData['causes_coupures'] = pointData['causes_coupures'];
        break;

      // Pour les infrastructures rurales (écoles, marchés, etc.)
      default:
        // Les champs de base sont déjà mappés
        break;
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final config = InfrastructureConfig.getEntityConfig(widget.category, widget.type);
      final tableName = config?['tableName'];

      if (tableName == null) {
        throw Exception('Table non configurée pour ${widget.type}');
      }

      final coordinatePrefix = _getCoordinatePrefix(tableName);

      // Préparer les données de base avec le bon préfixe
      final entityData = {
        'x_$coordinatePrefix': _formData['latitude'] ?? 0.0,
        'y_$coordinatePrefix': _formData['longitude'] ?? 0.0,
        'nom': _formData['nom'] ?? 'Sans nom',
        'enqueteur': _formData['enqueteur'] ?? 'Anonyme',
        'code_piste': _formData['code_piste'],
      };

      // Si c'est une modification, ajouter l'ID
      if (widget.pointData != null && widget.pointData!['id'] != null) {
        entityData['id'] = widget.pointData!['id'];
        entityData['date_modification'] = _formData['date_modification'] ?? DateTime.now().toIso8601String();
        entityData['date_creation'] = _formData['date_creation'];
      } else {
        // Si c'est une création, ajouter la date de création
        entityData['date_creation'] = _formData['date_creation'] ?? DateTime.now().toIso8601String();
      }

      // Ajouter le type si présent dans le formulaire
      if (_formData['type'] != null) {
        entityData['type'] = _formData['type'];
      }

      // Ajouter les champs spécifiques selon le type d'entité
      _addSpecificFields(entityData, widget.type, config);

      // Insertion ou mise à jour dans la base
      final dbHelper = DatabaseHelper();
      int id;

      if (widget.pointData != null && widget.pointData!['id'] != null) {
        // MISE À JOUR de l'entité existante
        id = await dbHelper.updateEntity(tableName, widget.pointData!['id'], entityData);
        print('✅ Entité mise à jour avec ID: $id');
      } else {
        // INSERTION d'une nouvelle entité
        id = await dbHelper.insertEntity(tableName, entityData);
        print('✅ Nouvelle entité enregistrée avec ID: $id');
      }

      // ============ AJOUTER CE CODE POUR LA CONFIRMATION ============
      if (mounted) {
        // RÉINITIALISER L'ÉTAT DU FORMULAIRE APRÈS SUCCÈS
        _formKey.currentState?.reset();

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Succès'),
              ],
            ),
            content: Text('${widget.type} "${_formData['nom']}" enregistré avec succès\n'
                'Coordonnées: ${_formData['latitude']?.toStringAsFixed(6)}, '
                '${_formData['longitude']?.toStringAsFixed(6)}\n'
                'Code Piste: ${_formData['code_piste'] ?? 'Non spécifié'}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fermer la boîte de dialogue
                  widget.onSaved(); // ← CETTE LIGNE EST CRUCIALE
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      // ============ FIN DE L'AJOUT ============
    } catch (error) {
      print('❌ Erreur détaillée: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: ${error.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

// MÉTHODE COMPLÈTEMENT CORRIGÉE POUR LES PRÉFIXES :
  String _getCoordinatePrefix(String tableName) {
    // Mapping COMPLET de tous les cas spéciaux
    final Map<String, String> coordinatePrefixes = {
      // Infrastructures Rurales
      'localites': 'localite',
      'ecoles': 'ecole',
      'marches': 'marche',
      'services_santes': 'sante',
      'batiments_administratifs': 'batiment_administratif',
      'infrastructures_hydrauliques': 'infrastructure_hydraulique',
      'autres_infrastructures': 'autre_infrastructure',

      // Ouvrages
      'ponts': 'pont',
      'bacs': 'debut_traversee_bac', // Special case for bac
      'buses': 'buse',
      'dalots': 'dalot',
      'passages_submersibles': 'debut_passage_submersible', // Special case

      // Points Critiques
      'points_critiques': 'point_critique',
      'points_coupures': 'point_coupure',
    };

    // Retourne le préfixe spécifique ou le premier mot de la table
    return coordinatePrefixes[tableName] ?? tableName.split('_').first;
  }

// MÉTHODE POUR AJOUTER LES CHAMPS SPÉCIFIQUES :
  void _addSpecificFields(Map<String, dynamic> entityData, String entityType, Map<String, dynamic>? config) {
    // Champs communs basés sur la configuration
    if (config?['fields']?.contains('nom_cours_eau') == true && _formData['nom_cours_eau'] != null) {
      entityData['nom_cours_eau'] = _formData['nom_cours_eau'];
    }

    // Champs spécifiques par type d'entité
    switch (entityType) {
      case 'Pont':
        entityData['situation_pont'] = _formData['situation'] ?? 'Non spécifié';
        entityData['type_pont'] = _formData['type_pont'] ?? 'Non spécifié';
        break;

      case 'Bac':
        entityData['type_bac'] = _formData['type_bac'] ?? 'Non spécifié';
        entityData['nom_cours_eau'] = _formData['nom_cours_eau'] ?? 'Non spécifié';
        // Les coordonnées de début sont déjà dans entityData via le préfixe
        entityData['x_fin_traversee_bac'] = _formData['latitude_fin'] ?? _formData['latitude'] ?? 0.0;
        entityData['y_fin_traversee_bac'] = _formData['longitude_fin'] ?? _formData['longitude'] ?? 0.0;
        break;

      case 'Dalot':
        entityData['situation_dalot'] = _formData['situation'] ?? 'Non spécifié';
        break;

      case 'Passage Submersible':
        entityData['type_materiau'] = _formData['type'] ?? 'Non spécifié';
        // Les coordonnées de début sont déjà dans entityData via le préfixe
        entityData['x_fin_passage_submersible'] = _formData['latitude_fin'] ?? _formData['latitude'] ?? 0.0;
        entityData['y_fin_passage_submersible'] = _formData['longitude_fin'] ?? _formData['longitude'] ?? 0.0;
        break;

      case 'Point Critique':
        entityData['type_point_critique'] = _formData['type_point_critique'] ?? 'Non spécifié';
        break;

      case 'Point de Coupure':
        entityData['causes_coupures'] = _formData['causes_coupures'] ?? 'Non spécifié';
        break;

      // Pour TOUTES les autres entités (écoles, marchés, etc.)
      default:
        // Utilisent les champs de base déjà définis + nom_cours_eau si configuré
        break;
    }

    // Ajouter les champs optionnels supplémentaires
    _addOptionalFields(entityData, config);
  }

// MÉTHODE POUR LES CHAMPS OPTIONNELS :
  void _addOptionalFields(Map<String, dynamic> entityData, Map<String, dynamic>? config) {
    final optionalFields = {
      'description': _formData['description'],
      'etat': _formData['etat'],
      'capacite': _formData['capacite'],
      'materiau': _formData['materiau'],
      'hauteur': _formData['hauteur'],
      'largeur': _formData['largeur'],
    };

    optionalFields.forEach((key, value) {
      if (value != null && config?['fields']?.contains(key) == true) {
        entityData[key] = value;
      }
    });
  }

// MÉTHODE DE VALIDATION :
  void _validateRequiredFields(Map<String, dynamic> entityData, Map<String, dynamic>? config) {
    final requiredFields = config?['fields'] as List<String>? ?? [];
    final nullableFields = [
      'date_modification'
    ]; // Seulement ce champ
    for (var field in requiredFields) {
      if (nullableFields.contains(field)) continue;
      if (entityData[field] == null || entityData[field].toString().isEmpty) {
        throw Exception('Le champ $field est requis mais est vide');
      }
    }

    // Validation spécifique pour les entités avec coordonnées multiples
    if (widget.type == 'Bac' || widget.type == 'Passage Submersible') {
      final latDebut = entityData['x_debut_traversee_bac'] ?? entityData['x_debut_passage_submersible'];
      final lngDebut = entityData['y_debut_traversee_bac'] ?? entityData['y_debut_passage_submersible'];
      final latFin = entityData['x_fin_traversee_bac'] ?? entityData['x_fin_passage_submersible'];
      final lngFin = entityData['y_fin_traversee_bac'] ?? entityData['y_fin_passage_submersible'];

      if (latDebut == latFin && lngDebut == lngFin) {
        print('⚠️ Attention: Coordonnées identiques pour début et fin');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Afficher l'état des données
    print('🔄 PointFormWidget rebuild:');
    print('   category: ${widget.category}');
    print('   type: ${widget.type}');
    print('   pointData: ${widget.pointData}');
    print('   formData: $_formData');
    print('   agentName: ${widget.agentName}');
    final categoryColor = Color(InfrastructureConfig.getCategoryColor(widget.category));
    final config = InfrastructureConfig.getEntityConfig(widget.category, widget.type);
    final typeOptions = InfrastructureConfig.getTypeOptions(widget.category, widget.type);
    final bool isCreation = widget.pointData == null || widget.pointData!['id'] == null;
    print('🏗️ Build - Mode: ${isCreation ? "CRÉATION" : "MODIFICATION"}');
    print('   date_modification: ${_formData['date_modification']}');
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
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
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
                _buildCodePisteField(),
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
                    // Champ date de création
                    _buildDateField(
                      label: 'Date de création *',
                      key: 'date_creation',
                      required: true,
                    ),
                    _buildDateModificationField(),
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

  Widget _buildDateModificationField() {
    final bool isCreation = widget.pointData == null || widget.pointData!['id'] == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date de modification',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isCreation ? Colors.grey : const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: isCreation
                ? null
                : () async {
                    // DÉSACTIVÉ en création
                    DateTime initialDate = DateTime.now();
                    if (_formData['date_modification'] != null) {
                      initialDate = DateTime.tryParse(_formData['date_modification']) ?? DateTime.now();
                    }

                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _formData['date_modification'] = picked.toIso8601String();
                      });
                    }
                  },
            child: Container(
              decoration: BoxDecoration(
                color: isCreation ? const Color(0xFFF5F5F5) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCreation ? const Color(0xFFE0E0E0) : const Color(0xFFE5E7EB),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: isCreation ? Colors.grey : const Color(0xFF1976D2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isCreation
                          ? "Non modifié"
                          : (_formData['date_modification'] != null
                              ? (DateTime.tryParse(_formData['date_modification']) != null
                                  ? "${DateTime.parse(_formData['date_modification']).day.toString().padLeft(2, '0')}/"
                                      "${DateTime.parse(_formData['date_modification']).month.toString().padLeft(2, '0')}/"
                                      "${DateTime.parse(_formData['date_modification']).year}"
                                  : _formData['date_modification'].toString())
                              : "Sélectionner une date"),
                      style: TextStyle(
                        fontSize: 14,
                        color: isCreation ? const Color(0xFF9E9E9E) : (_formData['date_modification'] != null ? const Color(0xFF374151) : const Color(0xFF9CA3AF)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodePisteField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Code Piste *',
            style: TextStyle(
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.confirmation_number, size: 20, color: Color(0xFF1976D2)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: TextEditingController(
                      text: _formData['code_piste']?.toString() ?? '',
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Entrez le code de la piste',
                      hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF374151),
                    ),
                    onChanged: (value) {
                      _formData['code_piste'] = value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le code piste est obligatoire';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
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
          GestureDetector(
            onTap: () async {
              DateTime initialDate = DateTime.now();
              if (_formData[key] != null) {
                initialDate = DateTime.tryParse(_formData[key]) ?? DateTime.now();
              }

              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() {
                  _formData[key] = picked.toIso8601String();
                });
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formData[key] != null
                          ? DateTime.tryParse(_formData[key]) != null
                              ? "${DateTime.parse(_formData[key]).day.toString().padLeft(2, '0')}/"
                                  "${DateTime.parse(_formData[key]).month.toString().padLeft(2, '0')}/"
                                  "${DateTime.parse(_formData[key]).year}"
                              : _formData[key]
                          : "Sélectionner une date",
                      style: TextStyle(
                        fontSize: 14,
                        color: _formData[key] != null ? const Color(0xFF374151) : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                  const Icon(Icons.calendar_today, size: 20, color: Color(0xFF1976D2)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection({required String title, required List<Widget> children}) {
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
    // Créer un contrôleur avec la valeur pré-remplie
    final controller = TextEditingController(text: _formData[key]?.toString() ?? '');

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
            controller: controller, // Utiliser le contrôleur
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
    // Récupérer la valeur actuelle
    final currentValue = _formData[key];

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
                final isSelected = currentValue == option;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _formData[key] = option;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFD1D5DB), width: 2),
                          ),
                          child: isSelected
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
                            style: TextStyle(
                              fontSize: 15,
                              color: isSelected ? const Color(0xFF1976D2) : const Color(0xFF374151),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
    final dynamic lat = _formData['latitude'];
    final dynamic lng = _formData['longitude'];

    String latStr = 'N/A';
    String lngStr = 'N/A';

    if (lat != null) {
      latStr = lat is double ? lat.toStringAsFixed(6) : lat.toString();
    }

    if (lng != null) {
      lngStr = lng is double ? lng.toStringAsFixed(6) : lng.toString();
    }

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
          _buildGpsInfoRow('Latitude:', '$latStr°'),
          _buildGpsInfoRow('Longitude:', '$lngStr°'),
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
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.agentName ?? 'Non spécifié',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
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
    return config?.containsKey('situationOptions') == true || config?.containsKey('typePontOptions') == true || config?.containsKey('typeBacOptions') == true || config?.containsKey('causesOptions') == true;
  }

  List<Widget> _buildSpecificFields(Map<String, dynamic>? config, Color categoryColor) {
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
