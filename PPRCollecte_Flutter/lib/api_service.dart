import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';
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
}
