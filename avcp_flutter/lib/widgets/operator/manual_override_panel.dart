/// Manual override panel — allows operators to manually set zone status.
library;

import 'package:flutter/material.dart';

import '../../accessibility/wcag_tokens.dart';
import '../../models/congestion_level.dart';

class ManualOverridePanel extends StatefulWidget {
  const ManualOverridePanel({super.key});

  @override
  State<ManualOverridePanel> createState() => _ManualOverridePanelState();
}

class _ManualOverridePanelState extends State<ManualOverridePanel> {
  String? _selectedZoneId;
  CongestionLevel? _overrideLevel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Manual Override',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AvenuColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Zone selector
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedZoneId,
                  hint: const Text('Select zone'),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AvenuColors.surfaceCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'gate_a', child: Text('Gate A')),
                    DropdownMenuItem(value: 'gate_b', child: Text('Gate B')),
                    DropdownMenuItem(value: 'gate_c', child: Text('Gate C')),
                    DropdownMenuItem(
                      value: 'concourse_main',
                      child: Text('Concourse'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedZoneId = v),
                ),
              ),
              const SizedBox(width: 8),

              // Level selector
              Expanded(
                child: DropdownButtonFormField<CongestionLevel>(
                  value: _overrideLevel,
                  hint: const Text('Level'),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AvenuColors.surfaceCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: CongestionLevel.values
                      .map(
                        (level) => DropdownMenuItem(
                          value: level,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(level.icon, size: 16, color: level.color),
                              const SizedBox(width: 6),
                              Text(level.label),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _overrideLevel = v),
                ),
              ),
              const SizedBox(width: 8),

              // Apply button
              SizedBox(
                height: AvenuTouchTargets.minimum,
                width: AvenuTouchTargets.minimum,
                child: Semantics(
                  button: true,
                  label: 'Apply manual override',
                  child: IconButton.filled(
                    onPressed:
                        _selectedZoneId != null && _overrideLevel != null
                            ? _applyOverride
                            : null,
                    icon: const Icon(Icons.check),
                    tooltip: 'Apply override',
                    style: IconButton.styleFrom(
                      backgroundColor: AvenuColors.accentBlue,
                      disabledBackgroundColor: AvenuColors.surfaceCard,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _applyOverride() {
    // TODO: push override to Firebase via provider
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Override applied: $_selectedZoneId → ${_overrideLevel?.label}',
        ),
      ),
    );
  }
}
