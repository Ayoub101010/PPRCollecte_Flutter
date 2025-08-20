import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:permission_handler/permission_handler.dart';

import 'database_helper.dart';

void main() async {
  // 1. Initialisation obligatoire pour Flutter
  WidgetsFlutterBinding.ensureInitialized();
  // Demandez les permissions de stockage
  await Permission.storage.request();
  await Permission.manageExternalStorage.request();
  await DatabaseHelper().database;
  // 2. Réinitialisation de la base de données (uniquement en développement)
  //await DBHelper().resetDatabase();

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
