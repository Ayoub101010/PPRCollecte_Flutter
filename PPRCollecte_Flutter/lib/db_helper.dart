import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DBHelper {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  Future<Database> initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'users.db');

    return await openDatabase(
      path,
      version: 2, // Version incrémentée pour la migration
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nom TEXT,
            prenom TEXT,
            email TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL
          )
        ''');

        // Insertion de l'utilisateur test
        await db.insert(
            'users',
            {
              'nom': 'Agent',
              'prenom': 'Test',
              'email': 'test@ppr.com',
              'password': '12345678'
            },
            conflictAlgorithm: ConflictAlgorithm.replace);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Migration pour les versions antérieures
          try {
            await db.execute('ALTER TABLE users ADD COLUMN nom TEXT');
            await db.execute('ALTER TABLE users ADD COLUMN prenom TEXT');

            // Mettre à jour l'utilisateur existant si nécessaire
            await db.update(
              'users',
              {
                'nom': 'Agent',
                'prenom': 'Test'
              },
              where: 'email = ?',
              whereArgs: [
                'test@ppr.com'
              ],
            );
          } catch (e) {
            print("Erreur lors de la migration: $e");
          }
        }
      },
    );
  }

  Future<String?> getAgentFullName(String email) async {
    try {
      final db = await database;
      final result = await db.query(
        'users',
        columns: [
          'prenom',
          'nom'
        ],
        where: 'email = ?',
        whereArgs: [
          email
        ],
        limit: 1,
      );

      if (result.isNotEmpty) {
        final prenom = result.first['prenom'] as String? ?? '';
        final nom = result.first['nom'] as String? ?? '';
        return '$prenom $nom'.trim();
      }
      return null;
    } catch (e) {
      print("Erreur getAgentFullName: $e");
      return null;
    }
  }

  Future<bool> validateUser(String email, String password) async {
    try {
      final db = await database;
      final result = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [
          email,
          password
        ],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      print("Erreur validateUser: $e");
      return false;
    }
  }

  Future<int> insertUser(String prenom, String nom, String email, String password) async {
    try {
      final db = await database;
      return await db.insert(
        'users',
        {
          'prenom': prenom,
          'nom': nom,
          'email': email,
          'password': password
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print("Erreur insertUser: $e");
      return -1;
    }
  }

  Future<int> deleteAllUsers() async {
    try {
      final db = await database;
      return await db.delete('users');
    } catch (e) {
      print("Erreur deleteAllUsers: $e");
      return -1;
    }
  }

  // Méthode pour réinitialiser complètement la base de données
  Future<void> resetDatabase() async {
    try {
      final db = await database;
      await db.close();
      _db = null;
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, 'users.db');
      await deleteDatabase(path);
    } catch (e) {
      print("Erreur resetDatabase: $e");
    }
  }
}
