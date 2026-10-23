import 'package:flutter/material.dart';

class FloatTile extends StatelessWidget {
  final IconData icon;
  const FloatTile(this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFFFC266),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: const Color(0xFF5A3A1A), size: 26),
    );
  }
}
