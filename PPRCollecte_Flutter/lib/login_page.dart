import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'home_page.dart';
import 'db_helper.dart';
import 'api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF3b82f6),
              Color(0xFF10b981)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo Container
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFe0f7ff),
                        Color(0xFFccfbf1)
                      ],
                    ),
                  ),
                  child: const Stack(
                    alignment: Alignment.center,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.mapMarkerAlt,
                        color: Color(0xFF2196f3),
                        size: 32,
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Text(
                          "🛰",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4caf50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "PPRCollecte",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF1b1b1b),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Connexion à PPRCollecte",
                  style: TextStyle(
                    fontSize: 20,
                    color: Color(0xFF0f172a),
                  ),
                ),
                const SizedBox(height: 20),

                // Email Field
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Adresse e-mail",
                    style: TextStyle(color: Color(0xFF1e293b)),
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "exemple@domaine.com",
                    hintStyle: const TextStyle(color: Color(0xFFcbd5e1)),
                    filled: true,
                    fillColor: const Color(0xFF334155),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Password Field
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Mot de passe",
                    style: TextStyle(color: Color(0xFF1e293b)),
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "••••••••",
                    hintStyle: const TextStyle(color: Color(0xFFcbd5e1)),
                    filled: true,
                    fillColor: const Color(0xFF334155),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Switch + Forgot
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Switch(
                          value: rememberMe,
                          onChanged: (val) {
                            setState(() => rememberMe = val);
                          },
                        ),
                        const Text("Se souvenir"),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text("Mot de passe oublié ?"),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: const Color(0xFF0f172a),
                      backgroundColor: const Color(0xFF38bdf8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      final email = emailController.text.trim();
                      final password = passwordController.text;

                      if (email.isEmpty || password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Veuillez remplir tous les champs")),
                        );
                        return;
                      }

                      try {
                        print('Tentative connexion API...');
                        final userData = await ApiService.login(email, password);
                        print('Connexion API réussie: $userData');

                        final db = DBHelper();
                        await db.insertUser(email, password);
                        print('Utilisateur sauvegardé localement.');

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HomePage(
                              onLogout: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginPage()),
                                );
                              },
                            ),
                          ),
                        );
                      } catch (e) {
                        print('Connexion API échouée, essai base locale...');
                        bool isValidLocal = await DBHelper().validateUser(email, password);

                        if (isValidLocal) {
                          print('Connexion locale réussie.');
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HomePage(
                                onLogout: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => const LoginPage()),
                                  );
                                },
                              ),
                            ),
                          );
                        } else {
                          print('Échec connexion locale.');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      }
                    },
                    child: const Text(
                      "Se connecter",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
