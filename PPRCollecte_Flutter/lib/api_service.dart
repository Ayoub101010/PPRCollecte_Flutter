import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';
  static String? authToken;
  static int? userId;
  // Remplace par l'IP de ton PC ou le serveur API

  /// Fonction pour se connecter via API
  /// Retourne un Map<String, dynamic> contenant au minimum :
  /// { "nom": "...", "prenom": "...", "mail": "...", "role": "..." }
  static Future<Map<String, dynamic>> login(String mail, String mdp) async {
    final url = Uri.parse('$baseUrl/api/login/');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        'mail': mail,
        'mdp': mdp,
      }),
    );

    if (response.statusCode == 200) {
      print('Réponse API brute: ${response.body}');
      // L'API renvoie les données de l'utilisateur
      final data = jsonDecode(response.body);
      authToken = data['token'];
      userId = data['id'];
      // On vérifie que "nom" et "prenom" sont bien présents
      if (data.containsKey('nom') && data.containsKey('prenom')) {
        return data;
      } else {
        throw Exception("Réponse API invalide : nom ou prenom manquant");
      }
    } else {
      // En cas d’erreur, on décode le message envoyé par le serveur
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erreur inconnue');
    }
  }

// Méthode générique pour envoyer des données
  static Future<bool> postData(String endpoint, Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('$baseUrl/api/$endpoint/');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Données envoyées avec succès à $endpoint');
        return true;
      } else {
        print('❌ Erreur API ($endpoint): ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Exception lors de l\'envoi à $endpoint: $e');
      return false;
    }
  }

// Dans votre api_service.dart

  /// Méthodes spécifiques pour chaque type de données
  static Future<bool> syncLocalite(Map<String, dynamic> data) async {
    return await postData('localites', _mapLocaliteToApi(data));
  }

  static Future<bool> syncEcole(Map<String, dynamic> data) async {
    return await postData('ecoles', _mapEcoleToApi(data));
  }

  static Future<bool> syncMarche(Map<String, dynamic> data) async {
    return await postData('marches', _mapMarcheToApi(data));
  }

  static Future<bool> syncServiceSante(Map<String, dynamic> data) async {
    return await postData('services_santes', _mapServiceSanteToApi(data));
  }

  static Future<bool> syncBatimentAdministratif(Map<String, dynamic> data) async {
    return await postData('batiments_administratifs', _mapBatimentAdministratifToApi(data));
  }

  static Future<bool> syncInfrastructureHydraulique(Map<String, dynamic> data) async {
    return await postData('infrastructures_hydrauliques', _mapInfrastructureHydrauliqueToApi(data));
  }

  static Future<bool> syncAutreInfrastructure(Map<String, dynamic> data) async {
    return await postData('autres_infrastructures', _mapAutreInfrastructureToApi(data));
  }

  static Future<bool> syncPont(Map<String, dynamic> data) async {
    return await postData('ponts', _mapPontToApi(data));
  }

  static Future<bool> syncBac(Map<String, dynamic> data) async {
    return await postData('bacs', _mapBacToApi(data));
  }

  static Future<bool> syncBuse(Map<String, dynamic> data) async {
    return await postData('buses', _mapBuseToApi(data));
  }

  static Future<bool> syncDalot(Map<String, dynamic> data) async {
    return await postData('dalots', _mapDalotToApi(data));
  }

  static Future<bool> syncPassageSubmersible(Map<String, dynamic> data) async {
    return await postData('passages_submersibles', _mapPassageSubmersibleToApi(data));
  }

  static Future<bool> syncPointCritique(Map<String, dynamic> data) async {
    return await postData('points_critiques', _mapPointCritiqueToApi(data));
  }

  static Future<bool> syncPointCoupure(Map<String, dynamic> data) async {
    return await postData('points_coupures', _mapPointCoupureToApi(data));
  }

  /// Mapping des données locales vers le format API
  static Map<String, dynamic> _mapLocaliteToApi(Map<String, dynamic> localData) {
    return {
      'sqlite_id': localData['id'],
      'x_localite': localData['x_localite'],
      'y_localite': localData['y_localite'],
      'nom': localData['nom'],
      'type': localData['type'],
      'enqueteur': localData['enqueteur'],
      'date_creation': localData['date_creation'],
      'code_piste': localData['code_piste'],
      'login_id': userId,
    };
  }

  static Map<String, dynamic> _mapEcoleToApi(Map<String, dynamic> localData) {
    return {
      'sqlite_id': localData['id'],
      'x_ecole': localData['x_ecole'],
      'y_ecole': localData['y_ecole'],
      'nom': localData['nom'],
      'type': localData['type'],
      'enqueteur': localData['enqueteur'],
      'date_creation': localData['date_creation'],
      'code_piste': localData['code_piste'],
      'login_id': userId,
    };
  }

  static Map<String, dynamic> _mapMarcheToApi(Map<String, dynamic> localData) {
    return {
      'sqlite_id': localData['id'],
      'x_marche': localData['x_marche'],
      'y_marche': localData['y_marche'],
      'nom': localData['nom'],
      'type': localData['type'],
      'enqueteur': localData['enqueteur'],
      'date_creation': localData['date_creation'],
      'code_piste': localData['code_piste'],
      'login_id': userId,
    };
  }

  static Map<String, dynamic> _mapServiceSanteToApi(Map<String, dynamic> localData) {
    return {
      'sqlite_id': localData['id'],
      'x_sante': localData['x_sante'],
      'y_sante': localData['y_sante'],
      'nom': localData['nom'],
      'type': localData['type'],
      'enqueteur': localData['enqueteur'],
      'date_creation': localData['date_creation'],
      'code_piste': localData['code_piste'],
      'login_id': userId,
    };
  }

  static Map<String, dynamic> _mapBatimentAdministratifToApi(Map<String, dynamic> localData) {
    return {
      'sqlite_id': localData['id'],
      'x_batiment_administratif': localData['x_batiment_administratif'],
      'y_batiment_administratif': localData['y_batiment_administratif'],
      'nom': localData['nom'],
      'type': localData['type'],
      'enqueteur': localData['enqueteur'],
      'date_creation': localData['date_creation'],
      'code_piste': localData['code_piste'],
      'login_id': userId,
    };
  }

  static Map<String, dynamic> _mapInfrastructureHydrauliqueToApi(Map<String, dynamic> localData) {
    return {
      'sqlite_id': localData['id'],
      'x_infrastructure_hydraulique': localData['x_infrastructure_hydraulique'],
      'y_infrastructure_hydraulique': localData['y_infrastructure_hydraulique'],
      'nom': localData['nom'],
      'type': localData['type'],
      'enqueteur': localData['enqueteur'],
      'date_creation': localData['date_creation'],
      'code_piste': localData['code_piste'],
      'login_id': userId,
    };
  }

  static Map<String, dynamic> _mapAutreInfrastructureToApi(Map<String, dynamic> localData) {
    return {
      'sqlite_id': localData['id'],
      'x_autre_infrastructure': localData['x_autre_infrastructure'],
      'y_autre_infrastructure': localData['y_autre_infrastructure'],
      'nom': localData['nom'],
      'type': localData['type'],
      'enqueteur': localData['enqueteur'],
      'date_creation': localData['date_creation'],
      'code_piste': localData['code_piste'],
      'login_id': userId,
    };
  }

  static Map<String, dynamic> _mapPontToApi(Map<String, dynamic> localData) {
    return {
      'sqlite_id': localData['id'],
      'x_pont': localData['x_pont'],
      'y_pont': localData['y_pont'],
      'nom': localData['nom'],
      'situation_pont': localData['situation_pont'],
      'type_pont': localData['type_pont'],
      'nom_cours_eau': localData['nom_cours_eau'],
      'enqueteur': localData['enqueteur'],
      'date_creation': localData['date_creation'],
      'code_piste': localData['code_piste'],
      'login_id': userId,
    };
  }

  static Map<String, dynamic> _mapBacToApi(Map<String, dynamic> localData) {
    return {
      'sqlite_id': localData['id'],
      'x_debut_traversee_bac': localData['x_debut_traversee_bac'],
      'y_debut_traversee_bac': localData['y_debut_traversee_bac'],
      'x_fin_traversee_bac': localData['x_fin_traversee_bac'],
      'y_fin_traversee_bac': localData['y_fin_traversee_bac'],
      'nom': localData['nom'],
      'type_bac': localData['type_bac'],
      'nom_cours_eau': localData['nom_cours_eau'],
      'enqueteur': localData['enqueteur'],
      'date_creation': localData['date_creation'],
      'code_piste': localData['code_piste'],
      'login_id': userId,
    };
  }

  static Map<String, dynamic> _mapBuseToApi(Map<String, dynamic> localData) {
    return {
      'sqlite_id': localData['id'],
      'x_buse': localData['x_buse'],
      'y_buse': localData['y_buse'],
      'nom': localData['nom'],
      'enqueteur': localData['enqueteur'],
      'date_creation': localData['date_creation'],
      'code_piste': localData['code_piste'],
      'login_id': userId,
    };
  }

  static Map<String, dynamic> _mapDalotToApi(Map<String, dynamic> localData) {
    return {
      'sqlite_id': localData['id'],
      'x_dalot': localData['x_dalot'],
      'y_dalot': localData['y_dalot'],
      'nom': localData['nom'],
      'situation_dalot': localData['situation_dalot'],
      'enqueteur': localData['enqueteur'],
      'date_creation': localData['date_creation'],
      'code_piste': localData['code_piste'],
      'login_id': userId,
    };
  }

  static Map<String, dynamic> _mapPassageSubmersibleToApi(Map<String, dynamic> localData) {
    return {
      'sqlite_id': localData['id'],
      'x_debut_passage_submersible': localData['x_debut_passage_submersible'],
      'y_debut_passage_submersible': localData['y_debut_passage_submersible'],
      'x_fin_passage_submersible': localData['x_fin_passage_submersible'],
      'y_fin_passage_submersible': localData['y_fin_passage_submersible'],
      'nom': localData['nom'],
      'type_materiau': localData['type_materiau'],
      'enqueteur': localData['enqueteur'],
      'date_creation': localData['date_creation'],
      'code_piste': localData['code_piste'],
      'login_id': userId,
    };
  }

  static Map<String, dynamic> _mapPointCritiqueToApi(Map<String, dynamic> localData) {
    return {
      'sqlite_id': localData['id'],
      'x_point_critique': localData['x_point_critique'],
      'y_point_critique': localData['y_point_critique'],
      'type_point_critique': localData['type_point_critique'],
      'enqueteur': localData['enqueteur'],
      'date_creation': localData['date_creation'],
      'code_piste': localData['code_piste'],
      'login_id': userId,
    };
  }

  static Map<String, dynamic> _mapPointCoupureToApi(Map<String, dynamic> localData) {
    return {
      'sqlite_id': localData['local_id'],
      'x_point_coupure': localData['x_point_coupure'],
      'y_point_coupure': localData['y_point_coupure'],
      'causes_coupures': localData['causes_coupures'],
      'enqueteur': localData['enqueteur'],
      'date_creation': localData['date_creation'],
      'code_piste': localData['code_piste'],
      'login_id': userId,
    };
  }

  // ============ MÉTHODES GET POUR TÉLÉCHARGER LES DONNÉES ============

  /// Méthode générique pour récupérer des données
  static Future<List<dynamic>> fetchData(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl/api/$endpoint/');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['features']; // Extraire les features du GeoJSON
      } else {
        print('❌ Erreur GET ($endpoint): ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Exception lors de la récupération de $endpoint: $e');
      return [];
    }
  }

  /// Méthodes spécifiques pour chaque type de données
  static Future<List<dynamic>> fetchLocalites() async {
    return await fetchData('localites');
  }

  static Future<List<dynamic>> fetchEcoles() async {
    return await fetchData('ecoles');
  }

  static Future<List<dynamic>> fetchMarches() async {
    return await fetchData('marches');
  }

  static Future<List<dynamic>> fetchServicesSantes() async {
    return await fetchData('services_santes');
  }

  static Future<List<dynamic>> fetchBatimentsAdministratifs() async {
    return await fetchData('batiments_administratifs');
  }

  static Future<List<dynamic>> fetchInfrastructuresHydrauliques() async {
    return await fetchData('infrastructures_hydrauliques');
  }

  static Future<List<dynamic>> fetchAutresInfrastructures() async {
    return await fetchData('autres_infrastructures');
  }

  static Future<List<dynamic>> fetchPonts() async {
    return await fetchData('ponts');
  }

  static Future<List<dynamic>> fetchBacs() async {
    return await fetchData('bacs');
  }

  static Future<List<dynamic>> fetchBuses() async {
    return await fetchData('buses');
  }

  static Future<List<dynamic>> fetchDalots() async {
    return await fetchData('dalots');
  }

  static Future<List<dynamic>> fetchPassagesSubmersibles() async {
    return await fetchData('passages_submersibles');
  }

  static Future<List<dynamic>> fetchPointsCritiques() async {
    return await fetchData('points_critiques');
  }

  static Future<List<dynamic>> fetchPointsCoupures() async {
    return await fetchData('points_coupures');
  }

  /// Méthode pour extraire les données du GeoJSON
  static Map<String, dynamic> extractFromGeoJson(Map<String, dynamic> geoJson) {
    return {
      'properties': geoJson['properties'],
      'geometry': geoJson['geometry'],
      'id': geoJson['id'],
    };
  }
}
