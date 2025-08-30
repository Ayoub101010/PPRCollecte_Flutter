import 'package:flutter/material.dart';
import 'login_page.dart';
import 'database_helper.dart';

void main() async {
  // 1. Initialisation obligatoire pour Flutter
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper().resetDatabase();
  // 2. Initialisation de la base de données
  await DatabaseHelper().database;

  // 3. Lancement de l'application
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PPRCollecte',
      home: LoginPage(),
    );
  }
}
