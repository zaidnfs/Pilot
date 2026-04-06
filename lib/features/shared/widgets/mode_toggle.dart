import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/mode_provider.dart';

/// Animated pill toggle for switching between Buyer and Traveler mode.
/// Follows Stitch design references (Home Dashboard).
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
        height: 64,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Stack(
          children: [
            // Animated sliding pill
            AnimatedAlign(
              alignment:
                  isRequester ? Alignment.centerLeft : Alignment.centerRight,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: LayoutBuilder(builder: (context, constraints) {
                return Container(
                  width: constraints.maxWidth / 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isRequester
                          ? [AppColors.primary, AppColors.primaryLight]
                          : [AppColors.primaryLight, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                );
              }),
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
                          Icons.shopping_bag_rounded,
                          size: 20,
                          color: isRequester
                              ? Colors.white
                              : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Buyer',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
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
                          Icons.directions_car_rounded,
                          size: 20,
                          color: !isRequester
                              ? Colors.white
                              : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Traveler',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
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
