import 'package:flutter/material.dart';

class DataCountWidget extends StatelessWidget {
  final int count;

  const DataCountWidget({Key? key, required this.count}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 80,
      right: 16,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(0xFF1976D2).withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          "📊 : $count éléments",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ),
    );
  }
}
