import 'package:flutter/material.dart';

import '../../../../core/models/driver_models.dart';
import '../../theme/driver_colors.dart';
import '../../theme/driver_text_styles.dart';
import '../widgets/emergency_sos_modal.dart';

class DriverTopBar extends StatelessWidget implements PreferredSizeWidget {
  const DriverTopBar({
    super.key,
    required this.driver,
    this.activeBooking,
    required this.onSosTriggered,
    this.onProfileTap,
  });

  final DriverProfile driver;
  final DriverBooking? activeBooking;
  final VoidCallback onSosTriggered;
  final VoidCallback? onProfileTap;

  @override
  Size get preferredSize => const Size.fromHeight(120);

  Color get _dutyColor {
    switch (driver.status) {
      case 'AVAILABLE':
        return DriverColors.secondary;
      case 'ON_TRIP':
        return DriverColors.primaryContainer;
      case 'OFF_DUTY':
        return DriverColors.outline;
      case 'LEAVE':
        return DriverColors.warning;
      default:
        return DriverColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DriverColors.surfaceContainerLowest,
        border: const Border(
          bottom: BorderSide(
            color: DriverColors.surfaceContainerHigh,
            width: 1.2,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;
            final veryCompact = constraints.maxWidth < 360;
            final identity = Row(
              children: [
                if (!veryCompact) ...[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: DriverColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: DriverColors.primaryContainer.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              compact ? driver.name : 'Ambulance First',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DriverTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          if (!veryCompact) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: DriverColors.primaryContainer.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'DRIVER',
                                style: DriverTextStyles.telemetryMicro.copyWith(
                                  color: DriverColors.primaryContainer,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 8.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (!compact)
                        Text(
                          [
                            if (driver.assignedAmbulanceNumber.isNotEmpty)
                              driver.assignedAmbulanceNumber,
                            driver.name.toUpperCase(),
                          ].join(' • '),
                          style: DriverTextStyles.telemetryMicro.copyWith(
                            color: DriverColors.onSurfaceVariant,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            );

            final status = Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: _dutyColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _dutyColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _dutyColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    driver.status.replaceAll('_', ' '),
                    style: DriverTextStyles.telemetryMicro.copyWith(
                      color: _dutyColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            );

            void triggerSos() {
              showDialog(
                context: context,
                builder: (ctx) => EmergencySosModal(
                  driverId: driver.id,
                  driverName: driver.name,
                  bookingId: activeBooking?.id,
                  ambulanceUnit: driver.assignedAmbulanceNumber,
                  latitude: driver.latitude,
                  longitude: driver.longitude,
                  onSosTriggered: onSosTriggered,
                ),
              );
            }

            final sosButton = veryCompact
                ? SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton.filled(
                      onPressed: triggerSos,
                      tooltip: 'SOS',
                      style: IconButton.styleFrom(
                        backgroundColor: DriverColors.tertiary,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.warning_rounded, size: 18),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: triggerSos,
                    icon: const Icon(
                      Icons.warning_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text('SOS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DriverColors.tertiary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );

            final profileButton = InkWell(
              onTap: onProfileTap,
              borderRadius: BorderRadius.circular(20),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: DriverColors.surfaceContainerHighest,
                child: Text(
                  driver.name.isNotEmpty ? driver.name[0].toUpperCase() : 'D',
                  style: DriverTextStyles.titleSmall.copyWith(
                    color: DriverColors.primaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            );

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 16,
                vertical: 8,
              ),
              child: compact
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(child: identity),
                            const SizedBox(width: 8),
                            profileButton,
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            status,
                            const SizedBox(width: 8),
                            sosButton,
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: identity),
                        const SizedBox(width: 12),
                        status,
                        const SizedBox(width: 10),
                        sosButton,
                        const SizedBox(width: 10),
                        profileButton,
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}
