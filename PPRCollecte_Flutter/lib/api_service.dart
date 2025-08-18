import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';
  // Remplace par l'IP de ton PC

  // Fonction pour se connecter via API
  static Future<Map<String, dynamic>> login(String mail, String mdp) async {
    final url = Uri.parse('$baseUrl/api/login/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mail': mail, 'mdp': mdp}),
    );

    if (response.statusCode == 200) {
      // Retourne les données utilisateur
      return jsonDecode(response.body);
    } else {
      // En cas d’erreur, decode le message envoyé par le serveur
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erreur inconnue');
    }
  }
}
