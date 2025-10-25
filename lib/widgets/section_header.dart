import 'package:e_library/design/colors.dart';
import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const SectionHeader({super.key, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: secondaryVariantColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: const Text(
              'See all',
              style: TextStyle(color: primaryColor, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
