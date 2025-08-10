import 'package:flutter/material.dart';

class BottomStatusBarWidget extends StatelessWidget {
  final bool gpsEnabled;

  const BottomStatusBarWidget({super.key, required this.gpsEnabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE3F2FD),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(6),
      child: Text(
        "📡 GPS: ${gpsEnabled ? 'Activé' : 'Désactivé'} | 🔄 Sync: 11h30 | 🌐 En ligne",
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}
