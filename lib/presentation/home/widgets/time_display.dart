import 'package:flutter/material.dart';

class TimeDisplay extends StatelessWidget {
  final String currentTime;
  final String currentDate;

  const TimeDisplay({
    super.key,
    required this.currentTime,
    required this.currentDate,
  });

  String _translateDayToHebrew(String date) {
    // Translate English day names to Hebrew
    return date
        .replaceAll('Monday', 'יום שני')
        .replaceAll('Tuesday', 'יום שלישי')
        .replaceAll('Wednesday', 'יום רביעי')
        .replaceAll('Thursday', 'יום חמישי')
        .replaceAll('Friday', 'יום שישי')
        .replaceAll('Saturday', 'שבת')
        .replaceAll('Sunday', 'יום ראשון');
  }

  @override
  Widget build(BuildContext context) {
    final timeParts = currentTime.split(':');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hebrewDate = _translateDayToHebrew(currentDate);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.ltr, // Keep clock LTR (HH:MM format)
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: isDark
                      ? [
                          Colors.white,
                        ]
                      : [
                          const Color(0xFF059669), // emerald-600
                          const Color(0xFF14B8A6), // teal-500
                          const Color(0xFF059669), // emerald-600
                        ],
                ).createShader(bounds),
                child: Text(
                  timeParts[0],
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: isDark
                      ? [
                          Colors.white,
                        ]
                      : [
                          const Color(0xFF059669), // emerald-600
                          const Color(0xFF14B8A6), // teal-500
                          const Color(0xFF059669), // emerald-600
                        ],
                ).createShader(bounds),
                child: const Text(
                  ':',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: isDark
                      ? [
                          Colors.white,
                        ]
                      : [
                          const Color(0xFF059669), // emerald-600
                          const Color(0xFF14B8A6), // teal-500
                          const Color(0xFF059669), // emerald-600
                        ],
                ).createShader(bounds),
                child: Text(
                  timeParts[1],
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        Colors.green[900]!.withAlpha(128),
                        Colors.blue[900]!.withAlpha(128),
                      ]
                    : [
                        Colors.green[100]!.withAlpha(128),
                        Colors.blue[100]!.withAlpha(128),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              hebrewDate,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
