import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key, required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: const Color(0xFF121212),
      child: Column(
        children: [
          // Logo/Title area
          Container(
            height: 80,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF02569B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.flutter_dash,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'FlutterHub',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Menu items
          _buildMenuItem(
            icon: Icons.home,
            label: 'Home',
            index: 0,
            isSelected: selectedIndex == 0,
          ),
          _buildMenuItem(
            icon: Icons.install_desktop,
            label: 'Installs',
            index: 1,
            isSelected: selectedIndex == 1,
          ),
          _buildMenuItem(
            icon: Icons.settings,
            label: 'Settings',
            index: 2,
            isSelected: selectedIndex == 2,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF0078D4).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? const Color(0xFF0078D4) : const Color(0xFFBBBBBB),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isSelected ? Colors.white : const Color(0xFFBBBBBB),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF0078D4),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(2),
                    bottomRight: Radius.circular(2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
