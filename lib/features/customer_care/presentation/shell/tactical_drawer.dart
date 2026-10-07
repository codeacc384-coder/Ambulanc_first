import 'package:flutter/material.dart';
import '../../../../core/models/auth_user.dart';
import '../../theme/customer_care_colors.dart';
import '../../theme/customer_care_text_styles.dart';

class TacticalDrawer extends StatelessWidget {
  const TacticalDrawer({
    super.key,
    required this.currentTab,
    required this.onSelectTab,
    required this.onOpenArchive,
    required this.onOpenProfile,
    required this.newInboundCount,
    required this.pendingCallsCount,
    required this.hasLoaded,
    this.user,
    this.onLogout,
  });

  final int currentTab;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onOpenArchive;
  final VoidCallback onOpenProfile;
  final int newInboundCount;
  final int pendingCallsCount;
  final bool hasLoaded;
  final AuthUser? user;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: CustomerCareColors.surfaceContainerLowest,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: CustomerCareColors.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.medical_services_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ambulance First',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: CustomerCareTextStyles.headlineSm.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: CustomerCareColors.primaryContainer,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'Customer Care Ops v4.2',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: CustomerCareTextStyles.labelSm.copyWith(
                                  color: CustomerCareColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: CustomerCareColors.outlineVariant),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'OPERATIONS HUB',
                style: CustomerCareTextStyles.labelSm.copyWith(
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                  color: CustomerCareColors.onSurfaceVariant,
                ),
              ),
            ),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.grid_view_rounded,
                    title: 'Triage Dashboard',
                    isSelected: currentTab == 0,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelectTab(0);
                    },
                  ),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.move_to_inbox_rounded,
                    title: 'New Inbound Queue',
                    isSelected: currentTab == 1,
                    badge: hasLoaded ? '$newInboundCount' : null,
                    badgeColor: CustomerCareColors.error,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelectTab(1);
                    },
                  ),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.phone_in_talk_rounded,
                    title: 'Pending Calls / Triage',
                    isSelected: currentTab == 2,
                    badge: hasLoaded ? '$pendingCallsCount' : null,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelectTab(2);
                    },
                  ),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.assignment_ind_rounded,
                    title: 'Team Lead Handovers',
                    isSelected: currentTab == 3,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelectTab(3);
                    },
                  ),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.flight_takeoff_rounded,
                    title: 'Active Trips & Telemetry',
                    isSelected: currentTab == 4,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelectTab(4);
                    },
                  ),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.inventory_2_rounded,
                    title: 'All Bookings Archive',
                    isSelected: false,
                    onTap: () {
                      Navigator.of(context).pop();
                      onOpenArchive();
                    },
                  ),
                ],
              ),
            ),

            // Dispatcher Profile Strip in Drawer Footer
            Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CustomerCareColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  onTap: onOpenProfile,
                  leading: const Icon(
                    Icons.person_outline_rounded,
                    color: CustomerCareColors.primaryContainer,
                  ),
                  title: Text(
                    user?.name.isNotEmpty == true ? user!.name : 'Profile',
                    style: CustomerCareTextStyles.labelMd.copyWith(
                      fontWeight: FontWeight.w700,
                      color: CustomerCareColors.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'View profile',
                    style: CustomerCareTextStyles.labelSm.copyWith(
                      color: CustomerCareColors.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                  trailing: onLogout == null
                      ? null
                      : IconButton(
                          icon: const Icon(
                            Icons.logout,
                            size: 18,
                            color: CustomerCareColors.outline,
                          ),
                          onPressed: onLogout,
                          tooltip: 'Sign Out',
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    String? badge,
    Color? badgeColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? CustomerCareColors.surfaceContainerHigh : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          dense: true,
          leading: Icon(
          icon,
          size: 20,
          color: isSelected
              ? CustomerCareColors.primaryContainer
              : CustomerCareColors.onSurfaceVariant,
          ),
          title: Text(
          title,
          style: CustomerCareTextStyles.bodyMd.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? CustomerCareColors.primaryContainer
                : CustomerCareColors.onSurface,
          ),
          ),
          trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor ?? CustomerCareColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: CustomerCareTextStyles.labelSm.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              )
              : null,
            ),
      ),
    );
  }
}
