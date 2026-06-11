import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/growth/child_growth_controller.dart';
import '../../../models/growth/child_growth_response_model.dart';
import '../../../models/growth/growth_record_model.dart';

class GrowthHistoryList extends StatelessWidget {
  final ChildGrowthResponseModel data;

  const GrowthHistoryList({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChildGrowthController>();

    // 1. ترتيب السجلات تنازلياً (الأحدث أولاً)
    final List<GrowthRecordModel> sortedHistory = List.from(data.growthHistory)
      ..sort((a, b) => b.ageInMonths.compareTo(a.ageInMonths));

    if (sortedHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(
            'No appointments found'.tr,
            // ─── نص ثانوي متكيف ───
            style: TextStyle(color: context.textTheme.bodyMedium?.color, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedHistory.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final record = sortedHistory[index];
        return _HistoryCard(record: record, controller: controller);
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final GrowthRecordModel record;
  final ChildGrowthController controller;

  const _HistoryCard({required this.record, required this.controller});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    try {
      badgeColor = Color(int.parse(record.statusColor.replaceAll('#', '0xFF')));
    } catch (_) {
      badgeColor = const Color(0xFF4CAF50);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // ─── لون البطاقة متكيف ───
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // ─── إخفاء الظل في الوضع الليلي ───
            color: context.isDarkMode ? Colors.transparent : Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        // ─── إطار البطاقة متكيف ───
        border: Border.all(color: context.theme.dividerColor),
      ),
      child: Row(
        children: [
          // 1. أيقونة الميزان الجانبية
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              // ─── خلفية الأيقونة متكيفة للوضع الليلي والنهاري ───
              color: context.isDarkMode ? Colors.blue.withOpacity(0.15) : const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.assignment_outlined,
              // ─── أيقونة متكيفة ───
              color: context.isDarkMode ? Colors.blue.shade300 : Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),

          // 2. عمود تفاصيل الوزن والطول
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                        '${'Weight'.tr}: ${record.weight} ${'kg'.tr}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          // ─── نص أساسي متكيف ───
                          color: context.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '|  ${'Height'.tr}: ${record.height} ${'cm'.tr}',
                        style: TextStyle(
                          fontSize: 12,
                          // ─── نص ثانوي متكيف ───
                          color: context.textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      record.date,
                      style: TextStyle(
                        fontSize: 10,
                        // ─── نص ثانوي متكيف ───
                        color: context.textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // ─── لون النقطة الفاصلة متكيف ───
                        color: context.theme.dividerColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${'Age'.tr} ${record.ageInMonths.toInt()} ${'months_old'.tr}',
                        style: TextStyle(
                          fontSize: 10,
                          // ─── نص ثانوي متكيف ───
                          color: context.textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // 3. قسم الشارة التفاعلية وزر الحذف
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showStatusDetailsDialog(context, badgeColor),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        // ─── جعل الشارة أكثر شفافية لتناسب الوضعين ───
                        color: badgeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              record.statusText.contains('ينصح')
                                  ? 'Needs Review'.tr
                                  : record.statusText.tr,
                              style: TextStyle(
                                color: badgeColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.info_outline_rounded,
                            color: badgeColor,
                            size: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _confirmDelete(context, record.id),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    // ─── لون أيقونة الحذف متكيف ───
                    color: context.isDarkMode ? Colors.redAccent : Colors.red.shade400,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusDetailsDialog(BuildContext context, Color color) {
    Get.dialog(
      AlertDialog(
        // ─── خلفية نافذة الحوار متكيفة ───
        backgroundColor: context.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.analytics_outlined, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              'Medical Assessment'.tr,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                // ─── نص العنوان متكيف ───
                color: context.textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Text(
                record.statusText,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  // ─── نص التفاصيل متكيف ───
                  color: context.textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Close'.tr,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                // ─── لون الزر متكيف ───
                color: context.theme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int growthId) {
    Get.dialog(
      AlertDialog(
        // ─── خلفية نافذة التأكيد متكيفة ───
        backgroundColor: context.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete'.tr,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            // ─── نص العنوان متكيف ───
            color: context.textTheme.bodyLarge?.color,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this record?'.tr,
          // ─── نص المحتوى متكيف ───
          style: TextStyle(color: context.textTheme.bodyLarge?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel'.tr,
              // ─── لون زر الإلغاء متكيف ───
              style: TextStyle(color: context.textTheme.bodyMedium?.color),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteMeasurement(growthId);
            },
            child: Text(
              'Delete'.tr,
              style: TextStyle(
                // ─── لون زر الحذف متكيف ───
                color: context.isDarkMode ? Colors.redAccent : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
