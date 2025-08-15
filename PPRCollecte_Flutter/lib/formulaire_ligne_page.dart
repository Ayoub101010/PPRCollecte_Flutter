import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

class FormulaireLignePage extends StatefulWidget {
  final List<LatLng> linePoints;
  final String? provisionalId;
  final String? provisionalName;

  const FormulaireLignePage({
    super.key,
    required this.linePoints,
    this.provisionalId,
    this.provisionalName,
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

  String? _communeRurale;
  String? _typeOccupation;
  DateTime? _debutOccupation;
  DateTime? _finOccupation;
  double? _largeurEmprise; // Largeur de l'emprise de la piste
  String? _frequenceTrafic;
  String? _typeTrafic;
  String? _etatPiste;
  DateTime? _dateDebutTravaux;
  bool _travauxRealises = false;

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
    "rural",
    "semi urbain",
    "urbain",
    "rizipiscicole",
    "forestier",
    "autre"
  ];

  final List<String> _typeTraficOptions = [
    "piétons",
    "véhicules légers",
    "motos",
    "poids lourds",
    "mixte",
    "autre"
  ];

  final List<String> _frequenceTraficOptions = [
    "quotidien",
    "hebdomadaire",
    "mensuel",
    "saisonnier"
  ];

  final List<String> _etatOptions = [
    "Très bon",
    "Bon",
    "Passable",
    "Mauvais",
    "Très mauvais",
    "Impraticable"
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.provisionalId != null) {
      _codeController.text = widget.provisionalId!;
    }
    if (widget.provisionalName != null) {
      _nomOrigineController.text = widget.provisionalName!;
    }

    // Récupérer automatiquement l'utilisateur connecté et l'heure actuelle
    _userLoginController.text =
        _getCurrentUser(); // À implémenter selon votre système d'auth
    final now = TimeOfDay.now();
    _heureDebutController.text =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

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

  // Méthode pour récupérer l'utilisateur actuel (à adapter selon votre système)
  String _getCurrentUser() {
    // TODO: Remplacer par votre logique d'authentification
    // Exemples possibles :
    // return SharedPreferences.getString('user_login') ?? '';
    // return Provider.of<AuthProvider>(context, listen: false).currentUser?.login ?? '';
    // return FirebaseAuth.instance.currentUser?.email ?? '';
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

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(point1.latitude * p) *
            cos(point2.latitude * p) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return 6371000 * c; // Rayon de la Terre en mètres
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

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        final timeString =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
        if (isStartTime) {
          _heureDebutController.text = timeString;
        } else {
          _heureFinController.text = timeString;
        }
      });
    }
  }

  Future<void> _selectOccupationDate(
      BuildContext context, bool isStartDate) async {
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
        'id': _codeController.text,
        'code_piste': _codeController.text,
        'commune_rurale_id': _communeRurale, // À mapper avec l'ID réel
        'user_login': _userLoginController.text,
        'heure_debut': _heureDebutController.text,
        'heure_fin': _heureFinController.text,
        'nom_origine_piste': _nomOrigineController.text,
        'x_origine': double.tryParse(_xOrigineController.text),
        'y_origine': double.tryParse(_yOrigineController.text),
        'nom_destination_piste': _nomDestinationController.text,
        'x_destination': double.tryParse(_xDestinationController.text),
        'y_destination': double.tryParse(_yDestinationController.text),
        'type_occupation': _typeOccupation,
        'debut_occupation': _debutOccupation?.toIso8601String(),
        'fin_occupation': _finOccupation?.toIso8601String(),
        'longueur_emergee':
            _largeurEmprise, // Correction: c'est largeur emprise
        'frequence_trafic': _frequenceTrafic,
        'type_trafic': _typeTrafic,
        'etat_piste': _etatPiste,
        'travaux_realises': _travauxRealises,
        'date_travaux': _dateDebutTravaux?.toIso8601String(),
        'entreprise': _travauxRealises
            ? _entrepriseController.text
            : null, // Seulement si travaux réalisés
        'points': widget.linePoints
            .map((p) => {
                  'latitude': p.latitude,
                  'longitude': p.longitude,
                })
            .toList(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': 'pending',
      };

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 28),
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
                          onChanged: (value) =>
                              setState(() => _communeRurale = value),
                          required: true,
                        ),
                        _buildTextField(
                          controller: _userLoginController,
                          label: 'Utilisateur *',
                          hint: 'Utilisateur connecté',
                          required: true,
                          enabled: false, // Champ en lecture seule
                        ),
                        //  la section des heures - les deux en lecture seule
                        Row(
                          children: [
                            Expanded(
                              child: _buildTimeField(
                                label: 'Heure Début',
                                controller: _heureDebutController,
                                onTap: () => _selectTime(context, true),
                                enabled: false, // Lecture seule
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTimeField(
                                label: 'Heure Fin',
                                controller: _heureFinController,
                                onTap: () => _selectTime(context, false),
                                enabled:
                                    false, // CORRECTION : Lecture seule aussi
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
                        _buildDropdownField(
                          label: 'Type d\'Occupation',
                          value: _typeOccupation,
                          options: _typeOccupationOptions,
                          onChanged: (value) =>
                              setState(() => _typeOccupation = value),
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
                              onTap: () =>
                                  _selectOccupationDate(context, false),
                            ),
                          ],
                        ),
                        _buildTextFieldWithCallback(
                          controller: TextEditingController(
                              text: _largeurEmprise?.toString() ?? ''),
                          label: 'Largeur Emprise (m)',
                          hint: 'Largeur de l\'emprise en mètres',
                          keyboardType: TextInputType.number,
                          onChanged: (value) =>
                              _largeurEmprise = double.tryParse(value),
                        ),
                      ],
                    ),

                    // Section Caractéristiques du Trafic
                    _buildFormSection(
                      title: '🚗 Caractéristiques du Trafic',
                      children: [
                        _buildDropdownField(
                          label: 'État de la Piste *',
                          value: _etatPiste,
                          options: _etatOptions,
                          onChanged: (value) =>
                              setState(() => _etatPiste = value),
                          required: true,
                        ),
                        _buildDropdownField(
                          label: 'Fréquence du Trafic',
                          value: _frequenceTrafic,
                          options: _frequenceTraficOptions,
                          onChanged: (value) =>
                              setState(() => _frequenceTrafic = value),
                        ),
                        _buildDropdownField(
                          label: 'Type de Trafic',
                          value: _typeTrafic,
                          options: _typeTraficOptions,
                          onChanged: (value) =>
                              setState(() => _typeTrafic = value),
                        ),
                      ],
                    ),

                    // Section Travaux
                    _buildFormSection(
                      title: '🔧 Travaux',
                      children: [
                        _buildSwitchField(
                          label: 'Travaux réalisés',
                          value: _travauxRealises,
                          onChanged: (value) =>
                              setState(() => _travauxRealises = value),
                        ),
                        if (_travauxRealises) ...[
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
              fillColor:
                  enabled ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6),
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
                  const Icon(Icons.calendar_today,
                      size: 20, color: Color(0xFF666666)),
                  const SizedBox(width: 12),
                  Text(
                    value != null
                        ? "${value.day}/${value.month}/${value.year}"
                        : "Sélectionner une date",
                    style: TextStyle(
                      fontSize: 14,
                      color: value != null
                          ? const Color(0xFF374151)
                          : const Color(0xFF9CA3AF),
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
    required VoidCallback onTap,
    bool enabled = true, // Nouveau paramètre
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
          onTap: enabled ? onTap : null,
          child: Container(
            decoration: BoxDecoration(
              color:
                  enabled ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 20,
                  color: enabled
                      ? const Color(0xFF666666)
                      : const Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.text.isEmpty
                        ? "Sélectionner l'heure"
                        : controller.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: controller.text.isEmpty
                          ? const Color(0xFF9CA3AF)
                          : (enabled
                              ? const Color(0xFF374151)
                              : const Color(0xFF6B7280)),
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

  Widget _buildSwitchField({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF1976D2),
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
          _buildGpsInfoRow('Distance totale:',
              '${(_calculateTotalDistance(widget.linePoints) / 1000).toStringAsFixed(2)} km'),
          if (widget.linePoints.isNotEmpty) ...[
            _buildGpsInfoRow('Premier point:',
                '${widget.linePoints.first.latitude.toStringAsFixed(6)}°, ${widget.linePoints.first.longitude.toStringAsFixed(6)}°'),
            _buildGpsInfoRow('Dernier point:',
                '${widget.linePoints.last.latitude.toStringAsFixed(6)}°, ${widget.linePoints.last.longitude.toStringAsFixed(6)}°'),
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
}
