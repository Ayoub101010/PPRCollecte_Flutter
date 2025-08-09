import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BottomButtonsWidget extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onSync;
  final VoidCallback onMenu;

  const BottomButtonsWidget({
    Key? key,
    required this.onSave,
    required this.onSync,
    required this.onMenu,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4CAF50),
                padding: EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: FaIcon(FontAwesomeIcons.save, size: 14),
              label: Text("Sauvegarder", style: TextStyle(fontWeight: FontWeight.w500)),
              onPressed: onSave,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2196F3),
                padding: EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: FaIcon(FontAwesomeIcons.sync, size: 14),
              label: Text("Synchroniser", style: TextStyle(fontWeight: FontWeight.w500)),
              onPressed: onSync,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF757575),
                padding: EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: Icon(Icons.menu, size: 18),
              label: Text("Menu", style: TextStyle(fontWeight: FontWeight.w500)),
              onPressed: onMenu,
            ),
          ),
        ],
      ),
    );
  }
}
