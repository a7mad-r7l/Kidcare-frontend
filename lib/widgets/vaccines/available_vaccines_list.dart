import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/vaccines/vaccines_controller.dart';
import '../../models/vaccines/vaccine_schedule_model.dart';
import 'vaccine_empty_state.dart';

class AvailableVaccinesList extends GetView<VaccinesController> {
  const AvailableVaccinesList({super.key});

  @override
  Widget build(BuildContext context) {
    if (controller.availableSchedules.isEmpty) {
      return VaccineEmptyState(
        icon: Icons.event_busy,
        text: 'No upcoming vaccines available for this age at the moment.'.tr,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: controller.availableSchedules.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _AvailableCard(item: controller.availableSchedules[index]);
      },
    );
  }
}

class _AvailableCard extends StatelessWidget {
  final VaccineScheduleModel item;

  const _AvailableCard({required this.item});

  @override
  Widget build(BuildContext context) {
    String formattedDate = item.date;
    try {
      formattedDate = DateFormat(
        'dd MMM, yyyy',
        Get.locale?.languageCode,
      ).format(DateTime.parse(item.date));
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? context.theme.cardColor
            : const Color(0xFFF3F7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.isDarkMode
              ? context.theme.dividerColor
              : Colors.blue.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Colors.blue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.vaccineName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.child_care,
                            size: 14,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.minAgeMonths} - ${item.maxAgeMonths} ${'Months'.tr}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(
              color: context.theme.dividerColor.withValues(alpha: 0.5),
              height: 1,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildIconText(
                Icons.calendar_month_outlined,
                'Available Date'.tr,
                formattedDate,
                context,
              ),
              Container(
                height: 30,
                width: 1,
                color: context.theme.dividerColor.withValues(alpha: 0.5),
              ),
              _buildIconText(
                Icons.access_time_outlined,
                'Available Time'.tr,
                '${item.startTime} - ${item.endTime}',
                context,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconText(
    IconData icon,
    String label,
    String value,
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: context.theme.hintColor),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: context.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
