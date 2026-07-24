import 'package:flutter/material.dart';

/// Menampilkan pilihan jam ambil dalam bentuk chip yang bisa dipilih.
/// Dipakai di checkout_screen.dart
class TimePickerWidget extends StatelessWidget {
  final List<String> availableSlots;
  final String? selectedSlot;
  final ValueChanged<String> onSelected;

  const TimePickerWidget({
    super.key,
    required this.onSelected,
    this.selectedSlot,
    this.availableSlots = const ['09:00', '10:00', '11:00', '12:00'],
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: availableSlots.map((slot) {
        final isSelected = slot == selectedSlot;
        return ChoiceChip(
          label: Text(slot),
          selected: isSelected,
          onSelected: (_) => onSelected(slot),
          selectedColor: Theme.of(context).colorScheme.primary,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }
}
