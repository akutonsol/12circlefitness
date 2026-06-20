import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/animations/app_animations.dart';
import '../../data/models/class_model.dart';
import '../../domain/class_provider.dart';

class ClassCard extends ConsumerWidget {
  final FitnessClass fitnessClass;
  final int index;

  const ClassCard({super.key, required this.fitnessClass, required this.index});

  Color get _categoryColor {
    switch (fitnessClass.category) {
      case ClassCategory.hiit: return const Color(0xFFFF6B35);
      case ClassCategory.strength: return AppColors.purple;
      case ClassCategory.yoga: return const Color(0xFF34D399);
      case ClassCategory.cardio: return const Color(0xFF60A5FA);
      case ClassCategory.pilates: return const Color(0xFFA78BFA);
      case ClassCategory.dance: return const Color(0xFFF472B6);
      case ClassCategory.boxing: return const Color(0xFFFBBF24);
      case ClassCategory.meditation: return const Color(0xFF34D399);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(classServiceProvider);
    final emoji = service.getCategoryEmoji(fitnessClass.category);

    return GestureDetector(
      onTap: () {
        ref.read(selectedClassProvider.notifier).state = fitnessClass;
        context.push('/class-detail');
        AppAnimations.hapticLight();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: fitnessClass.isLive ? _categoryColor.withValues(alpha: 0.1) : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: fitnessClass.isLive ? _categoryColor.withValues(alpha: 0.4) : AppColors.surfaceDarkElevated,
          ),
          boxShadow: fitnessClass.isLive
              ? [BoxShadow(color: _categoryColor.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: _categoryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (fitnessClass.isLive)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.circle, color: Colors.white, size: 6),
                                  SizedBox(width: 4),
                                  Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 800.ms),
                          Expanded(
                            child: Text(fitnessClass.title,
                                style: const TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(fitnessClass.instructor.name,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                if (fitnessClass.isVirtual)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF60A5FA).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.videocam_outlined, color: Color(0xFF60A5FA), size: 14),
                        SizedBox(width: 4),
                        Text('Virtual', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 11)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, color: AppColors.textTertiary, size: 14),
                const SizedBox(width: 4),
                Text(_formatTime(fitnessClass.startTime),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(width: 12),
                const Icon(Icons.timer_outlined, color: AppColors.textTertiary, size: 14),
                const SizedBox(width: 4),
                Text('${fitnessClass.durationMinutes} min',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(width: 12),
                const Icon(Icons.location_on_outlined, color: AppColors.textTertiary, size: 14),
                const SizedBox(width: 4),
                Text(fitnessClass.location,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Online group calls are unlimited → no spots/capacity bar.
                Expanded(
                  child: fitnessClass.isVirtual
                      ? Row(children: const [
                          Icon(Icons.videocam_outlined, color: Color(0xFF60A5FA), size: 14),
                          SizedBox(width: 6),
                          Text('Online group call · open to all',
                              style: TextStyle(color: Color(0xFF60A5FA), fontSize: 12, fontWeight: FontWeight.w500)),
                        ])
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  fitnessClass.isFull ? 'Full — ${fitnessClass.waitlistCount} waitlisted' : '${fitnessClass.spotsLeft} spots left',
                                  style: TextStyle(
                                    color: fitnessClass.isFull ? AppColors.error : AppColors.success,
                                    fontSize: 12, fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text('${fitnessClass.bookedCount}/${fitnessClass.capacity}',
                                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: fitnessClass.fillPercent,
                                backgroundColor: AppColors.surfaceDarkElevated,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  fitnessClass.isFull ? AppColors.error : _categoryColor,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(width: 12),
                _buildActionButton(context, ref),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 80))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref) {
    if (fitnessClass.isBooked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            Icon(Icons.check, color: AppColors.success, size: 14),
            SizedBox(width: 4),
            Text('Booked', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    if (fitnessClass.isWaitlisted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            Icon(Icons.schedule, color: AppColors.warning, size: 14),
            SizedBox(width: 4),
            Text('Waitlisted', style: TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    // Virtual classes are unlimited → always "Register"; in-person waitlists when full.
    final waitlist = !fitnessClass.isVirtual && fitnessClass.isFull;
    return GestureDetector(
      onTap: () async {
        await ref.read(liveClassServiceProvider).bookClass(fitnessClass.id);
        AppAnimations.hapticSuccess();
        ref.read(refreshClassesProvider.notifier).state++;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: waitlist ? AppColors.warning : AppColors.purple,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          waitlist ? 'Waitlist' : (fitnessClass.isVirtual ? 'Register' : 'Book'),
          style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final isToday = time.day == now.day && time.month == now.month;
    final isTomorrow = time.day == now.day + 1 && time.month == now.month;
    final prefix = isToday ? 'Today' : isTomorrow ? 'Tomorrow' : '${time.day}/${time.month}';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$prefix $hour:$minute';
  }
}
