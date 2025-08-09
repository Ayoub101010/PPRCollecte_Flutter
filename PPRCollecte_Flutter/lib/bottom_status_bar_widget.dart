import 'package:flutter/material.dart';

class BottomStatusBarWidget extends StatelessWidget {
  final bool gpsEnabled;

  const BottomStatusBarWidget({Key? key, required this.gpsEnabled}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFE3F2FD),
      alignment: Alignment.center,
      padding: EdgeInsets.all(6),
      child: Text(
        "📡 GPS: ${gpsEnabled ? 'Activé' : 'Désactivé'} | 🔄 Sync: 11h30 | 🌐 En ligne",
        style: TextStyle(fontSize: 14),
      ),
    );
  }
}
