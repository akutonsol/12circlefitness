import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class GroceryItemCard extends StatefulWidget {
  final String category;
  final List<String> items;

  const GroceryItemCard({
    super.key,
    required this.category,
    required this.items,
  });

  @override
  State<GroceryItemCard> createState() => _GroceryItemCardState();
}

class _GroceryItemCardState extends State<GroceryItemCard> {
  final Set<int> _checkedItems = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceDarkElevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shopping_basket_outlined, color: AppColors.purple, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                widget.category,
                style: const TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${_checkedItems.length}/${widget.items.length}',
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.items.asMap().entries.map((entry) {
            final isChecked = _checkedItems.contains(entry.key);
            return GestureDetector(
              onTap: () => setState(() {
                if (isChecked) {
                  _checkedItems.remove(entry.key);
                } else {
                  _checkedItems.add(entry.key);
                }
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isChecked ? AppColors.success : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isChecked ? AppColors.success : AppColors.textTertiary,
                        ),
                      ),
                      child: isChecked
                          ? const Icon(Icons.check, color: AppColors.white, size: 14)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          color: isChecked ? AppColors.textTertiary : AppColors.white,
                          fontSize: 14,
                          decoration: isChecked ? TextDecoration.lineThrough : null,
                          decorationColor: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
