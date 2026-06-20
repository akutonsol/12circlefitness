import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class MotivationalQuoteCard extends StatelessWidget {
  final String quote;
  final String author;

  const MotivationalQuoteCard({
    super.key,
    required this.quote,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceDarkElevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💬', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 12),
          Text(
            '"$quote"',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 15,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '— $author',
            style: const TextStyle(
              color: AppColors.purple,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
