import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/vaccines/vaccines_controller.dart';
import '../../models/vaccines/vaccine_history_model.dart';
import 'vaccine_empty_state.dart';

class HistoryVaccinesList extends GetView<VaccinesController> {
  const HistoryVaccinesList({super.key});

  @override
  Widget build(BuildContext context) {
    if (controller.historyRecords.isEmpty) {
      return VaccineEmptyState(
        icon: Icons.history_toggle_off,
        text: 'No vaccination records found.'.tr,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: controller.historyRecords.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _HistoryCard(item: controller.historyRecords[index]);
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final VaccineHistoryModel item;

  const _HistoryCard({required this.item});

  bool _hasValidNotes(String? notes) {
    if (notes == null) return false;
    final clean = notes.trim().toLowerCase();

    if (clean.isEmpty || clean == 'null' || clean == '...') return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = item.givenDate;
    try {
      formattedDate = DateFormat(
        'dd MMM, yyyy',
        Get.locale?.languageCode,
      ).format(DateTime.parse(item.givenDate));
    } catch (_) {}

    String vaccineName = item.vaccineName.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        boxShadow: [
          if (!context.isDarkMode)
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vaccineName.tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          size: 14,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${'Given on'.tr}: $formattedDate',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (_hasValidNotes(item.notes)) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? context.theme.scaffoldBackgroundColor
                    : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.sticky_note_2_outlined,
                    size: 16,
                    color: context.theme.hintColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.notes!.trim(),
                      style: TextStyle(
                        fontSize: 13,
                        color: context.theme.hintColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
