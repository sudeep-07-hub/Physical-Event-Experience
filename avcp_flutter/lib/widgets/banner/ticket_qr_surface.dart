/// Ticket QR surface — auto-shows within 30m of assigned gate.
///
/// Displays the user's ticket QR code with gate and distance info.
/// Uses [qr_flutter] for QR code rendering.
library;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../accessibility/wcag_tokens.dart';

class TicketQRSurface extends StatelessWidget {
  const TicketQRSurface({
    super.key,
    required this.gateId,
    required this.distanceMetres,
  });

  final String gateId;
  final double distanceMetres;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Ticket QR code for $gateId. '
          'You are ${distanceMetres.round()} metres away.',
      child: Row(
        children: [
          // QR code
          QrImageView(
            data: 'avcp://ticket/$gateId',
            version: QrVersions.auto,
            size: 56,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.black,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 12),
          // Gate info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Gate $gateId',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AvenuColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${distanceMetres.round()}m away — Show this at entry',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AvenuColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
