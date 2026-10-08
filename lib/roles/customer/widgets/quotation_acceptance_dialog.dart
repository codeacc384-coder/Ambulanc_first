import 'package:flutter/material.dart';

import '../../../core/models/booking.dart';
import '../theme/ambulance_first_theme.dart';
import 'ambulance_first_button.dart';

/// Interactive Quotation Review & Authorization Dialog
class QuotationAcceptanceDialog extends StatefulWidget {
  const QuotationAcceptanceDialog({
    super.key,
    required this.booking,
    required this.onConfirmAcceptance,
    required this.onConfirmRejection,
  });

  final Booking booking;
  final Future<void> Function() onConfirmAcceptance;
  final Future<void> Function(String reason) onConfirmRejection;

  static void show(
    BuildContext context, {
    required Booking booking,
    required Future<void> Function() onConfirmAcceptance,
    required Future<void> Function(String reason) onConfirmRejection,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => QuotationAcceptanceDialog(
        booking: booking,
        onConfirmAcceptance: onConfirmAcceptance,
        onConfirmRejection: onConfirmRejection,
      ),
    );
  }

  @override
  State<QuotationAcceptanceDialog> createState() =>
      _QuotationAcceptanceDialogState();
}

class _QuotationAcceptanceDialogState extends State<QuotationAcceptanceDialog> {
  bool _isProcessing = false;
  bool _showDeclineInput = false;
  final TextEditingController _declineReasonCtrl = TextEditingController();

  @override
  void dispose() {
    _declineReasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleAccept() async {
    setState(() => _isProcessing = true);
    try {
      await widget.onConfirmAcceptance();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleDecline() async {
    final reason = _declineReasonCtrl.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please state a reason for declining this quotation.'),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      await widget.onConfirmRejection(reason);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.booking.quotation;
    if (q == null) {
      return AlertDialog(
        title: const Text('Quotation Unavailable'),
        content: const Text('No active quotation found for this booking.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      );
    }

    final media = MediaQuery.of(context);
    final dialogWidth = (media.size.width - 24).clamp(0.0, 520.0);
    final availableHeight =
        media.size.height -
        media.viewInsets.vertical -
        media.viewPadding.vertical -
        24;
    final dialogHeight = availableHeight.clamp(200.0, 680.0);

    return Dialog(
      backgroundColor: AmbulanceFirstColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusXl),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: SizedBox(
        width: dialogWidth,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: dialogHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Indicator
              Container(height: 4, color: AmbulanceFirstColors.clinicalCobalt),

              // Header
              LayoutBuilder(
                builder: (context, constraints) {
                  final heading = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OFFICIAL CLINICAL QUOTATION',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AmbulanceFirstTypography.codeSm(
                          color: AmbulanceFirstColors.clinicalCobalt,
                          weight: FontWeight.w700,
                        ).copyWith(letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        q.id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AmbulanceFirstTypography.codeLg(
                          color: AmbulanceFirstColors.onSurface,
                          weight: FontWeight.w700,
                        ).copyWith(fontSize: 18),
                      ),
                    ],
                  );
                  final validity = Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AmbulanceFirstColors.warningContainer,
                      borderRadius: BorderRadius.circular(
                        AmbulanceFirstSpacing.radiusPill,
                      ),
                      border: Border.all(color: AmbulanceFirstColors.warning),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 13,
                          color: AmbulanceFirstColors.onWarning,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            q.validUntil.isNotEmpty
                                ? q.validUntil
                                : 'Validity unavailable',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AmbulanceFirstTypography.codeSm(
                              color: AmbulanceFirstColors.onWarning,
                              weight: FontWeight.w700,
                            ).copyWith(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  );

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      constraints.maxWidth < 380 ? 12 : 20,
                      constraints.maxWidth < 380 ? 12 : 16,
                      constraints.maxWidth < 380 ? 12 : 20,
                      12,
                    ),
                    child: constraints.maxWidth < 380
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              heading,
                              const SizedBox(height: 8),
                              validity,
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: heading),
                              const SizedBox(width: 8),
                              Flexible(child: validity),
                            ],
                          ),
                  );
                },
              ),
              const Divider(height: 1),

              // Itemized Cost Ledger
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(media.size.width < 380 ? 12 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Patient & Mission Snapshot
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AmbulanceFirstColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(
                            AmbulanceFirstSpacing.radiusMd,
                          ),
                          border: Border.all(
                            color: AmbulanceFirstColors.borderSubtle,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.booking.patientName} (${widget.booking.patientAge}y / ${widget.booking.patientGender})',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AmbulanceFirstTypography.headlineSm(
                                color: AmbulanceFirstColors.onSurface,
                              ).copyWith(fontSize: 14),
                            ),
                            Text(
                              'REF #${widget.booking.id}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AmbulanceFirstTypography.codeSm(
                                color: AmbulanceFirstColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Route: ${widget.booking.pickup} → ${widget.booking.destination} (${widget.booking.distanceKm > 0 ? "${widget.booking.distanceKm} km" : "distance unavailable"})',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: AmbulanceFirstTypography.bodySm(
                                color: AmbulanceFirstColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Cost Breakdown & Line Items',
                        style: AmbulanceFirstTypography.labelMd(
                          color: AmbulanceFirstColors.onSurface,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),

                      _feeRow(
                        'Base Ambulance Charge (${widget.booking.ambulanceType})',
                        q.baseAmbulanceCharge,
                      ),
                      _feeRow(
                        'Distance Rate (${widget.booking.distanceKm} km transit)',
                        q.distanceCharge,
                      ),
                      if (q.doctorCharge > 0)
                        _feeRow('Attending Doctor / Physician', q.doctorCharge),
                      if (q.emtCharge > 0)
                        _feeRow('EMT / Paramedic Staff', q.emtCharge),
                      if (q.icuCharge > 0)
                        _feeRow(
                          'ICU Equipment & Life Support Pack',
                          q.icuCharge,
                        ),
                      if (q.ventilatorCharge > 0)
                        _feeRow(
                          'Transport Ventilator & Circuits',
                          q.ventilatorCharge,
                        ),
                      if (q.oxygenCharge > 0)
                        _feeRow('Medical Oxygen Cylinders', q.oxygenCharge),
                      if (q.pediatricIcuCharge > 0)
                        _feeRow(
                          'Specialized PICU / PALS Protocols',
                          q.pediatricIcuCharge,
                        ),
                      if (q.equipmentCharge > 0)
                        _feeRow(
                          'Ancillary Monitoring Equipment',
                          q.equipmentCharge,
                        ),
                      if (q.attendantCharge > 0)
                        _feeRow(
                          'Certified Medical Attendant',
                          q.attendantCharge,
                        ),
                      if (q.airAmbulanceCharges > 0)
                        _feeRow('Air ambulance charges', q.airAmbulanceCharges),
                      if (q.railwayCharges > 0)
                        _feeRow('Railway transfer charges', q.railwayCharges),
                      if (q.additionalCharges > 0)
                        _feeRow(
                          'Additional quotation adjustment',
                          q.additionalCharges,
                        ),
                      if (q.discount > 0)
                        _feeRow(
                          'Quotation discount',
                          -q.discount,
                          isDiscount: true,
                        ),

                      const Divider(height: 20),
                      _feeRow('Subtotal', q.subtotal, isBold: true),
                      _feeRow(
                        'Taxes (GST ${q.taxPercent.toInt()}%)',
                        q.taxAmount,
                      ),
                      const SizedBox(height: 8),

                      // Total Bar
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final totalAmount = Text(
                            '₹ ${q.finalAmount.toStringAsFixed(2)}',
                            maxLines: 1,
                            style: AmbulanceFirstTypography.telemetryNum(
                              color: AmbulanceFirstColors.onSurface,
                              size: constraints.maxWidth < 360 ? 18 : 22,
                            ),
                          );
                          final totalLabel = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL PAYABLE',
                                style: AmbulanceFirstTypography.codeSm(
                                  color: AmbulanceFirstColors.clinicalCobalt,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                q.paymentTerms,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AmbulanceFirstTypography.bodySm(
                                  color: AmbulanceFirstColors.onSurfaceVariant,
                                ).copyWith(fontSize: 11),
                              ),
                            ],
                          );

                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: constraints.maxWidth < 360 ? 10 : 14,
                              vertical: constraints.maxWidth < 360 ? 8 : 12,
                            ),
                            decoration: BoxDecoration(
                              color: AmbulanceFirstColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(
                                AmbulanceFirstSpacing.radiusMd,
                              ),
                              border: Border.all(
                                color: AmbulanceFirstColors.clinicalCobalt
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: constraints.maxWidth < 360
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      totalLabel,
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: totalAmount,
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: totalLabel),
                                      const SizedBox(width: 8),
                                      totalAmount,
                                    ],
                                  ),
                          );
                        },
                      ),

                      // Decline Form Field (if toggled)
                      if (_showDeclineInput) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _declineReasonCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Reason for Declining Quotation',
                            hintText: 'e.g. Disagree with pricing, alternate transport arranged, etc.',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Action Buttons
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 440;
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 12 : 20,
                      vertical: compact ? 10 : 14,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AmbulanceFirstColors.borderSubtle,
                        ),
                      ),
                    ),
                    child: compact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!_showDeclineInput) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: AmbulanceFirstButton(
                                        label: 'DECLINE',
                                        fullWidth: true,
                                        height: 40,
                                        onPressed: _isProcessing
                                            ? null
                                            : () => setState(
                                                () => _showDeclineInput = true,
                                              ),
                                        variant:
                                            AmbulanceFirstButtonVariant.ghost,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: AmbulanceFirstButton(
                                        label: 'CANCEL',
                                        fullWidth: true,
                                        height: 40,
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        variant:
                                            AmbulanceFirstButtonVariant.ghost,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                AmbulanceFirstButton(
                                  label: 'CONFIRM ACCEPTANCE',
                                  icon: Icons.verified_rounded,
                                  fullWidth: true,
                                  height: 42,
                                  isLoading: _isProcessing,
                                  onPressed: _handleAccept,
                                  variant: AmbulanceFirstButtonVariant.primary,
                                ),
                              ] else
                                Row(
                                  children: [
                                    AmbulanceFirstButton(
                                      label: 'BACK',
                                      height: 40,
                                      onPressed: () => setState(
                                        () => _showDeclineInput = false,
                                      ),
                                      variant:
                                          AmbulanceFirstButtonVariant.ghost,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: AmbulanceFirstButton(
                                        label: 'SUBMIT DECLINE',
                                        fullWidth: true,
                                        height: 40,
                                        isLoading: _isProcessing,
                                        onPressed: _handleDecline,
                                        variant: AmbulanceFirstButtonVariant
                                            .destructive,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          )
                        : Row(
                            children: [
                              if (!_showDeclineInput) ...[
                                AmbulanceFirstButton(
                                  label: 'DECLINE',
                                  onPressed: _isProcessing
                                      ? null
                                      : () => setState(
                                          () => _showDeclineInput = true,
                                        ),
                                  variant: AmbulanceFirstButtonVariant.ghost,
                                ),
                                const Spacer(),
                                AmbulanceFirstButton(
                                  label: 'CANCEL',
                                  onPressed: () => Navigator.of(context).pop(),
                                  variant: AmbulanceFirstButtonVariant.ghost,
                                ),
                                const SizedBox(width: 10),
                                AmbulanceFirstButton(
                                  label: 'CONFIRM ACCEPTANCE',
                                  icon: Icons.verified_rounded,
                                  isLoading: _isProcessing,
                                  onPressed: _handleAccept,
                                  variant: AmbulanceFirstButtonVariant.primary,
                                ),
                              ] else ...[
                                AmbulanceFirstButton(
                                  label: 'BACK',
                                  onPressed: () =>
                                      setState(() => _showDeclineInput = false),
                                  variant: AmbulanceFirstButtonVariant.ghost,
                                ),
                                const Spacer(),
                                AmbulanceFirstButton(
                                  label: 'SUBMIT DECLINE',
                                  isLoading: _isProcessing,
                                  onPressed: _handleDecline,
                                  variant:
                                      AmbulanceFirstButtonVariant.destructive,
                                ),
                              ],
                            ],
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feeRow(
    String label,
    double amount, {
    bool isBold = false,
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  AmbulanceFirstTypography.bodySm(
                    color: isDiscount
                        ? AmbulanceFirstColors.secondary
                        : AmbulanceFirstColors.onSurfaceVariant,
                  ).copyWith(
                    fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                  ),
            ),
          ),
          Flexible(
            child: Text(
              isDiscount
                  ? '- ₹ ${amount.abs().toStringAsFixed(2)}'
                  : '₹ ${amount.toStringAsFixed(2)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: AmbulanceFirstTypography.codeSm(
                color: isDiscount
                    ? AmbulanceFirstColors.secondary
                    : (isBold
                          ? AmbulanceFirstColors.onSurface
                          : AmbulanceFirstColors.onSurfaceVariant),
                weight: isBold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
