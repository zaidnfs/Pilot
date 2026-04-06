import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/mode_provider.dart';

/// Animated pill toggle for switching between Requester and Traveler mode.
/// Touch target: 56dp height (exceeds 48dp minimum per mobile-design skill).
class ModeToggle extends StatelessWidget {
  final AppMode currentMode;
  final VoidCallback onToggle;

  const ModeToggle({
    super.key,
    required this.currentMode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isRequester = currentMode == AppMode.requester;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            // Animated sliding pill
            AnimatedAlign(
              alignment:
                  isRequester ? Alignment.centerLeft : Alignment.centerRight,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: Container(
                width: MediaQuery.of(context).size.width / 2 - 20,
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isRequester
                      ? AppColors.requesterMode
                      : AppColors.travelerMode,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: (isRequester
                              ? AppColors.requesterMode
                              : AppColors.travelerMode)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),

            // Labels
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 20,
                          color: isRequester ? Colors.white : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Requester',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isRequester
                                ? Colors.white
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delivery_dining_rounded,
                          size: 20,
                          color: !isRequester ? Colors.white : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Traveler',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: !isRequester
                                ? Colors.white
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
