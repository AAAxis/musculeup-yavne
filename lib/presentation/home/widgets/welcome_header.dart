import 'package:flutter/material.dart';

class WelcomeHeader extends StatelessWidget {
  final String displayName;

  const WelcomeHeader({
    super.key,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: isDark
                  ? [
                      Colors.white, // white
                    ]
                  : [
                      const Color(0xFF059669), // emerald-600
                      const Color(0xFF14B8A6), // teal-500
                      const Color(0xFF059669), // emerald-600
                    ],
            ).createShader(bounds),
            child: Text(
              'שלום, $displayName',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ברוך הבא לפלטפורמת האימונים המתקדמת שלך',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
