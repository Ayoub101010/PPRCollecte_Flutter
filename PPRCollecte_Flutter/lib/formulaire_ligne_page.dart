import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'piste_chaussee_db_helper.dart';
import 'api_service.dart';

class FormulaireLignePage extends StatefulWidget {
  final List<LatLng> linePoints;
  final String? provisionalCode;
  final DateTime? startTime; // 🆕 Heure de début de collecte
  final DateTime? endTime; // 🆕 Heure de fin de collecte
  final String? agentName;

  const FormulaireLignePage({
    super.key,
    required this.linePoints,
    this.provisionalCode, // AJOUTER cette ligne
    this.startTime, // 🆕 Passé depuis la page de collecte GPS
    this.endTime, // 🆕 Passé depuis la page de collecte GPS
    this.agentName,
  });

  @override
  State<FormulaireLignePage> createState() => _FormulairePageState();
}

class _FormulairePageState extends State<FormulaireLignePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Champs du formulaire selon le MCD
  final _codeController = TextEditingController();
  final _nomOrigineController = TextEditingController();
  final _nomDestinationController = TextEditingController();
  final _xOrigineController = TextEditingController();
  final _yOrigineController = TextEditingController();
  final _xDestinationController = TextEditingController();
  final _yDestinationController = TextEditingController();
  final _userLoginController = TextEditingController();
  final _heureDebutController = TextEditingController();
  final _heureFinController = TextEditingController();
  final _entrepriseController = TextEditingController();
  final _travauxRealisesController = TextEditingController();

  String? _communeRurale;
  String? _typeOccupation;
  DateTime? _debutOccupation;
  DateTime? _finOccupation;
  double? _largeurEmprise; // Largeur de l'emprise de la piste
  String? _frequenceTrafic;
  String? _typeTrafic;
  DateTime? _dateDebutTravaux;
  DateTime? _dateCreation; // ← NOUVEAU
  DateTime? _dateModification;
  // Options pour les dropdowns
  final List<String> _communesRuralesOptions = [
    "Beyla",
    "Lola",
    "Nzérékoré",
    "Yomou",
    "Macenta",
    "Gueckédou",
    "Kissidougou",
    "Faranah",
    "Dabola"
  ];

  final List<String> _typeOccupationOptions = [
    "Urbain",
    "Semi Urbain",
    "Rural",
    "Rizipiscicole",
    "Autre"
  ];

  final List<String> _typeTraficOptions = [
    "Véhicules Légers",
    "Poids Lourds",
    "Motos",
    "Piétons",
    "Autre"
  ];

  final List<String> _frequenceTraficOptions = [
    "Quotidien",
    "Hebdomadaire",
    "Mensuel",
    "Saisonnier"
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.provisionalCode != null) {
      _codeController.text = widget.provisionalCode!;
    }
    // Récupérer automatiquement l'utilisateur connecté et l'heure actuelle
    _userLoginController.text = widget.agentName ?? _getCurrentUser(); // À implémenter selon votre système d'auth
    // Date de création = maintenant par défaut
    _dateCreation = DateTime.now();

    // Date de modification = maintenant (automatique)
    _dateModification = null;
    if (widget.startTime != null) {
      final startTime = TimeOfDay.fromDateTime(widget.startTime!);
      _heureDebutController.text = "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}";
    } else {
      // Fallback : heure actuelle
      final now = TimeOfDay.now();
      _heureDebutController.text = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    }

    // 🚀 NOUVEAU : Heure de fin automatique
    if (widget.endTime != null) {
      final endTime = TimeOfDay.fromDateTime(widget.endTime!);
      _heureFinController.text = "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";
    } else {
      // Cas exceptionnel : utiliser l'heure actuelle comme fallback
      final now = TimeOfDay.now();
      _heureFinController.text = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    }

    // Calculer et remplir automatiquement les coordonnées d'origine et destination
    if (widget.linePoints.isNotEmpty) {
      final firstPoint = widget.linePoints.first;
      final lastPoint = widget.linePoints.last;

      _xOrigineController.text = firstPoint.longitude.toStringAsFixed(6);
      _yOrigineController.text = firstPoint.latitude.toStringAsFixed(6);
      _xDestinationController.text = lastPoint.longitude.toStringAsFixed(6);
      _yDestinationController.text = lastPoint.latitude.toStringAsFixed(6);
    }
  }

  // Méthode pour récupérer l'utilisateur actuel
  String _getCurrentUser() {
    // je vais complèter ça après

    return 'user_demo'; // Valeur temporaire pour test
  }

  double _calculateTotalDistance(List<LatLng> points) {
    if (points.length < 2) return 0.0;

    double total = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      total += _distanceBetween(points[i], points[i + 1]);
    }
    return total;
  }

  double _distanceBetween(LatLng point1, LatLng point2) {
    // Formule de Haversine
    const double p = 0.017453292519943295; // pi/180

    final dLat = (point2.latitude - point1.latitude) * p;
    final dLon = (point2.longitude - point1.longitude) * p;

    final a = sin(dLat / 2) * sin(dLat / 2) + cos(point1.latitude * p) * cos(point2.latitude * p) * sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return 6371000 * c; // Rayon de la Terre en mètres
  }

  Future<void> _selectDateCreation(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateCreation ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _dateCreation = picked;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _dateDebutTravaux = picked;
      });
    }
  }

  Future<void> _selectOccupationDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _debutOccupation = picked;
        } else {
          _finOccupation = picked;
        }
      });
    }
  }

  Future<void> _savePiste() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));

      final pisteData = {
        // ✅ L'ID sera auto-généré par la BDD, ne pas l'inclure ici
        'code_piste': _codeController.text,
        'commune_rurale_id': _communeRurale,
        'user_login': widget.agentName,
        'heure_debut': _heureDebutController.text,
        'heure_fin': _heureFinController.text,
        'nom_origine_piste': _nomOrigineController.text,
        'nom_destination_piste': _nomDestinationController.text,
        'type_occupation': _typeOccupation,
        'debut_occupation': _debutOccupation?.toIso8601String(),
        'fin_occupation': _finOccupation?.toIso8601String(),
        'largeur_emprise': _largeurEmprise,
        'frequence_trafic': _frequenceTrafic,
        'type_trafic': _typeTrafic,
        'travaux_realises': _travauxRealisesController.text.isNotEmpty ? _travauxRealisesController.text : null,
        'date_travaux': _dateDebutTravaux?.toIso8601String(),
        'entreprise': _entrepriseController.text.isNotEmpty ? _entrepriseController.text : null,

        // ✅ TOUS les points de la piste (MultiLineString)
        'points': widget.linePoints
            .map((p) => {
                  'latitude': p.latitude,
                  'longitude': p.longitude,
                })
            .toList(),

        // ✅ Coordonnées EXTRACTIVES (depuis les points, pas les TextFields)
        'x_origine': widget.linePoints.first.latitude, // ← Premier point
        'y_origine': widget.linePoints.first.longitude, // ← Premier point
        'x_destination': widget.linePoints.last.latitude, // ← Dernier point
        'y_destination': widget.linePoints.last.longitude, // ← Dernier point

        // ✅ Dates
        'created_at': _dateCreation?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'updated_at': null,

        'sync_status': 'pending',
        'login_id': ApiService.userId,
      };
      final storageHelper = SimpleStorageHelper();
      final savedId = await storageHelper.savePiste(pisteData);
      if (savedId != null) {
        print('✅ Piste sauvegardée en local avec ID: $savedId');
        await storageHelper.debugPrintAllPistes();
      }

      if (mounted) {
        Navigator.of(context).pop(pisteData);
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

  void _confirmExit() {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      body: SafeArea(
        child: Column(
          children: [
            // Remplacer tout le header actuel par ceci :
// Header du formulaire - Style React Native
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
                    onPressed: () => _confirmExit(), // ← On va créer cette méthode
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    padding: const EdgeInsets.all(8),
                  ),
                  const Expanded(
                    child: Text(
                      "🛤️ Formulaire Piste",
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

            // Contenu du formulaire
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Section Identification
                    _buildFormSection(
                      title: '🏷️ Identification',
                      children: [
                        _buildTextField(
                          controller: _codeController,
                          label: 'Code Piste *',
                          hint: 'Code unique de la piste',
                          required: true,
                        ),
                        _buildDropdownField(
                          label: 'Commune Rurale *',
                          value: _communeRurale,
                          options: _communesRuralesOptions,
                          onChanged: (value) => setState(() => _communeRurale = value),
                          required: true,
                        ),
                        _buildDateCreationField(),
                        _buildDateModificationField(),
                        // Remplacer le TextField "Utilisateur" par :
                        _buildReadOnlyField(
                          label: 'Agent enquêteur',
                          icon: Icons.person,
                          value: _userLoginController.text,
                        ),
                        //  la section des heures - les deux en lecture seule
                        Row(
                          children: [
                            Expanded(
                              child: _buildTimeField(
                                label: 'Heure Début',
                                controller: _heureDebutController,
                                enabled: false, // 🔒 Lecture seule
                                // onTap supprimé car non nécessaire
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTimeField(
                                label: 'Heure Fin',
                                controller: _heureFinController,
                                enabled: false, // 🔒 Lecture seule
                                // onTap supprimé car non nécessaire
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Section Points
                    _buildFormSection(
                      title: '🎯 Points de la Piste',
                      children: [
                        _buildTextField(
                          controller: _nomOrigineController,
                          label: 'Nom Origine *',
                          hint: 'Point de départ de la piste',
                          required: true,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _xOrigineController,
                                label: 'X Origine',
                                hint: 'Longitude origine',
                                keyboardType: TextInputType.number,
                                enabled: false, // CORRECTION : Lecture seule
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _yOrigineController,
                                label: 'Y Origine',
                                hint: 'Latitude origine',
                                keyboardType: TextInputType.number,
                                enabled: false, // CORRECTION : Lecture seule
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _nomDestinationController,
                          label: 'Nom Destination *',
                          hint: 'Point d\'arrivée de la piste',
                          required: true,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _xDestinationController,
                                label: 'X Destination',
                                hint: 'Longitude destination',
                                keyboardType: TextInputType.number,
                                enabled: false, // CORRECTION : Lecture seule
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _yDestinationController,
                                label: 'Y Destination',
                                hint: 'Latitude destination',
                                keyboardType: TextInputType.number,
                                enabled: false, // CORRECTION : Lecture seule
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Section Occupation
                    _buildFormSection(
                      title: '🏘️ Occupation du Sol',
                      children: [
                        _buildRadioGroupField(
                          label: 'Type d\'Occupation',
                          value: _typeOccupation,
                          options: _typeOccupationOptions,
                          onChanged: (value) => setState(() => _typeOccupation = value),
                        ),
                        Column(
                          children: [
                            _buildDateField(
                              label: 'Début Occupation',
                              value: _debutOccupation,
                              onTap: () => _selectOccupationDate(context, true),
                            ),
                            _buildDateField(
                              label: 'Fin Occupation',
                              value: _finOccupation,
                              onTap: () => _selectOccupationDate(context, false),
                            ),
                          ],
                        ),
                        _buildTextFieldWithCallback(
                          controller: TextEditingController(text: _largeurEmprise?.toString() ?? ''),
                          label: 'Largeur Emprise (m)',
                          hint: 'Largeur de l\'emprise en mètres',
                          keyboardType: TextInputType.number,
                          onChanged: (value) => _largeurEmprise = double.tryParse(value),
                        ),
                      ],
                    ),

                    // REMPLACER TOUTE LA SECTION PAR :
                    _buildFormSection(
                      title: '🚗 Caractéristiques du Trafic',
                      children: [
                        _buildRadioGroupField(
                          label: 'Fréquence du Trafic',
                          value: _frequenceTrafic,
                          options: _frequenceTraficOptions,
                          onChanged: (value) => setState(() => _frequenceTrafic = value),
                        ),
                        _buildRadioGroupField(
                          label: 'Type de Trafic',
                          value: _typeTrafic,
                          options: _typeTraficOptions,
                          onChanged: (value) => setState(() => _typeTrafic = value),
                        ),
                      ],
                    ),

                    // Section Travaux
                    _buildFormSection(
                      title: '🔧 Travaux',
                      children: [
                        _buildTextField(
                          controller: _travauxRealisesController,
                          label: 'Travaux réalisés',
                          hint: 'Description des travaux réalisés',
                          maxLines: 3,
                        ),
                        _buildDateField(
                          label: 'Date des Travaux',
                          value: _dateDebutTravaux,
                          onTap: () => _selectDate(context, true),
                        ),
                        _buildTextField(
                          controller: _entrepriseController,
                          label: 'Entreprise',
                          hint: 'Nom de l\'entreprise',
                        ),
                      ],
                    ),

                    // Section GPS
                    _buildFormSection(
                      title: '📍 Géolocalisation',
                      children: [
                        _buildGpsInfo(),
                      ],
                    ),

                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),

            // Bouton Sauvegarder
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
                  onPressed: _isLoading ? null : _savePiste,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
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
                              'Enregistrer la Piste',
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
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required IconData icon,
    required String value,
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
                  value,
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

  Widget _buildDateCreationField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Date de création *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _selectDateCreation(context),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20, color: Color(0xFF1976D2)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _dateCreation != null ? "${_dateCreation!.day.toString().padLeft(2, '0')}/${_dateCreation!.month.toString().padLeft(2, '0')}/${_dateCreation!.year}" : "Sélectionner une date",
                      style: TextStyle(
                        fontSize: 14,
                        color: _dateCreation != null ? const Color(0xFF374151) : const Color(0xFF9CA3AF),
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

  Widget _buildDateModificationField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Date de modification',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: null,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _dateModification != null ? "${_dateModification!.day.toString().padLeft(2, '0')}/${_dateModification!.month.toString().padLeft(2, '0')}/${_dateModification!.year}" : (_dateModification?.toString().substring(0, 10) ?? DateTime.now().toString().substring(0, 10)), // ← CORRECTION ICI
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
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
    required TextEditingController controller,
    required String label,
    required String hint,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool enabled = true, // Nouveau paramètre pour champs en lecture seule
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
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            enabled: enabled,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              filled: true,
              fillColor: enabled ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF1976D2)),
              ),
            ),
            textAlignVertical: maxLines > 1 ? TextAlignVertical.top : null,
            validator: required
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '$label est obligatoire';
                    }
                    return null;
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldWithCallback({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    Function(String)? onChanged,
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
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            onChanged: onChanged,
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
            textAlignVertical: maxLines > 1 ? TextAlignVertical.top : null,
            validator: required
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '$label est obligatoire';
                    }
                    return null;
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> options,
    required Function(String?) onChanged,
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
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
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
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: onChanged,
            validator: required
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return '$label est obligatoire';
                    }
                    return null;
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
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
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20, color: Color(0xFF666666)),
                  const SizedBox(width: 12),
                  Text(
                    value != null ? "${value.day}/${value.month}/${value.year}" : "Sélectionner une date",
                    style: TextStyle(
                      fontSize: 14,
                      color: value != null ? const Color(0xFF374151) : const Color(0xFF9CA3AF),
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

  Widget _buildTimeField({
    required String label,
    required TextEditingController controller,
    VoidCallback? onTap, // 🚀 RENDRE OPTIONNEL (ajout du ?)
    bool enabled = true,
  }) {
    return Column(
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
          onTap: enabled && onTap != null ? onTap : null, // 🚀 CONDITIONNEL
          child: Container(
            decoration: BoxDecoration(
              color: enabled ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 20,
                  color: enabled ? const Color(0xFF666666) : const Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.text.isEmpty
                        ? "Heure automatique" // 🚀 MESSAGE PLUS CLAIR
                        : controller.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: controller.text.isEmpty ? const Color(0xFF9CA3AF) : (enabled ? const Color(0xFF374151) : const Color(0xFF6B7280)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
                'Tracé GPS collecté',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1976D2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildGpsInfoRow('Points collectés:', '${widget.linePoints.length}'),
          _buildGpsInfoRow('Distance totale:', '${(_calculateTotalDistance(widget.linePoints) / 1000).toStringAsFixed(2)} km'),
          if (widget.linePoints.isNotEmpty) ...[
            _buildGpsInfoRow('Premier point:', '${widget.linePoints.first.latitude.toStringAsFixed(6)}°, ${widget.linePoints.first.longitude.toStringAsFixed(6)}°'),
            _buildGpsInfoRow('Dernier point:', '${widget.linePoints.last.latitude.toStringAsFixed(6)}°, ${widget.linePoints.last.longitude.toStringAsFixed(6)}°'),
          ],
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

  Widget _buildRadioGroupField({
    required String label,
    required String? value,
    required List<String> options,
    required Function(String?) onChanged,
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
                return RadioListTile<String>(
                  title: Text(
                    option,
                    style: const TextStyle(fontSize: 14),
                  ),
                  value: option,
                  groupValue: value,
                  onChanged: onChanged,
                  activeColor: const Color(0xFF1976D2),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              }).toList(),
            ),
          ),
          if (required && (value == null || value.isEmpty))
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12),
              child: Text(
                '$label est obligatoire',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
