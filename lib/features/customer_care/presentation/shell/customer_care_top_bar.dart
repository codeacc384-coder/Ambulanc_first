import 'package:flutter/material.dart';
import '../../theme/customer_care_colors.dart';
import '../../theme/customer_care_text_styles.dart';

class CustomerCareTopBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomerCareTopBar({
    super.key,
    required this.onOpenDrawer,
    this.onCallHotline,
    this.onNotificationsTap,
    this.agentName = 'Customer Care',
  });

  final VoidCallback onOpenDrawer;
  final VoidCallback? onCallHotline;
  final VoidCallback? onNotificationsTap;
  final String agentName;

  @override
  Size get preferredSize => const Size.fromHeight(102);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CustomerCareColors.surfaceContainerLowest,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Primary Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu, size: 22),
                        color: CustomerCareColors.onSurface,
                        onPressed: onOpenDrawer,
                        tooltip: 'Open Operations Hub',
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: CustomerCareColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.medical_services_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ambulance First',
                            style: CustomerCareTextStyles.headlineSm.copyWith(
                              color: CustomerCareColors.primaryContainer,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'Agent: $agentName',
                            style: CustomerCareTextStyles.labelSm.copyWith(
                              color: CustomerCareColors.onSurfaceVariant,
                              fontSize: 9.5,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // On-duty badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: CustomerCareColors.secondaryContainer.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: CustomerCareColors.secondary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ON-DUTY',
                              style: CustomerCareTextStyles.labelSm.copyWith(
                                color: CustomerCareColors.onSecondaryFixedVariant,
                                fontWeight: FontWeight.w800,
                                fontSize: 9.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Notifications
                      IconButton(
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.notifications_outlined, size: 21),
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: CustomerCareColors.error,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '3',
                                  style: CustomerCareTextStyles.labelSm.copyWith(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        onPressed: onNotificationsTap,
                        tooltip: 'Notifications',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Emergency Dispatch Hotline Strip
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: CustomerCareColors.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.emergency_rounded,
                        size: 16,
                        color: CustomerCareColors.errorContainer,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Dispatch: 1800-AMBULANCE (Priority 1)',
                        style: CustomerCareTextStyles.labelSm.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: onCallHotline,
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: CustomerCareColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'CALL',
                        style: CustomerCareTextStyles.labelSm.copyWith(
                          color: CustomerCareColors.primaryContainer,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
