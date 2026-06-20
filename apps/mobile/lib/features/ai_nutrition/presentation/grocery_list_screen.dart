import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/ai_nutrition_provider.dart';
import 'widgets/grocery_item_card.dart';

class GroceryListScreen extends ConsumerStatefulWidget {
  const GroceryListScreen({super.key});

  @override
  ConsumerState<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends ConsumerState<GroceryListScreen> {
  bool _isLoading = false;

  Future<void> _generateList() async {
    final mealPlan = ref.read(mealPlanNotifierProvider);
    if (mealPlan == null) return;
    setState(() => _isLoading = true);
    await ref.read(groceryListNotifierProvider.notifier).generateGroceryList(mealPlan);
    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> _parseGroceryList(String raw) {
    final categories = <Map<String, dynamic>>[];
    final lines = raw.split('\n');
    String? currentCategory;
    List<String> currentItems = [];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.endsWith(':') && !trimmed.startsWith('-')) {
        if (currentCategory != null && currentItems.isNotEmpty) {
          categories.add({'category': currentCategory, 'items': List<String>.from(currentItems)});
          currentItems = [];
        }
        currentCategory = trimmed.replaceAll(':', '');
      } else if (trimmed.startsWith('-') && currentCategory != null) {
        currentItems.add(trimmed.replaceFirst('- ', '').trim());
      }
    }

    if (currentCategory != null && currentItems.isNotEmpty) {
      categories.add({'category': currentCategory, 'items': List<String>.from(currentItems)});
    }

    return categories;
  }

  @override
  Widget build(BuildContext context) {
    final groceryList = ref.watch(groceryListNotifierProvider);
    final mealPlan = ref.watch(mealPlanNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Grocery List', style: TextStyle(color: AppColors.white)),
      ),
      body: mealPlan == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, color: AppColors.textTertiary, size: 64),
                  const SizedBox(height: 16),
                  const Text('No meal plan yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Generate a meal plan first', style: TextStyle(color: AppColors.textTertiary, fontSize: 14)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.push('/meal-plan'),
                    child: const Text('Create Meal Plan'),
                  ),
                ],
              ),
            )
          : groceryList == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_basket_outlined, color: AppColors.textTertiary, size: 64),
                      const SizedBox(height: 16),
                      const Text('Ready to generate your list', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _generateList,
                          child: _isLoading
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                    SizedBox(width: 12),
                                    Text('Generating...'),
                                  ],
                                )
                              : const Text('Generate Grocery List'),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Your Grocery List', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                        TextButton.icon(
                          onPressed: _isLoading ? null : _generateList,
                          icon: const Icon(Icons.refresh, color: AppColors.purple, size: 16),
                          label: const Text('Refresh', style: TextStyle(color: AppColors.purple, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._parseGroceryList(groceryList).map((category) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GroceryItemCard(
                        category: category['category'] as String,
                        items: List<String>.from(category['items'] as List),
                      ),
                    )),
                    const SizedBox(height: 32),
                  ],
                ),
    );
  }
}
