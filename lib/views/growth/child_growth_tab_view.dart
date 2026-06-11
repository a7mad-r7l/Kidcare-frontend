import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/growth/child_growth_controller.dart';
import '../../../core/repos/growth/child_growth_repo.dart';
import '../../widgets/growth/add_growth_sheet.dart';
import '../../widgets/growth/growth_chart_widget.dart';
import '../../widgets/growth/growth_history_list.dart';

class ChildGrowthTabView extends StatelessWidget {
  final int childId;

  const ChildGrowthTabView({super.key, required this.childId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChildGrowthController(repo: ChildGrowthRepo()));

    controller.childId = childId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getGrowthDashboard();
    });

    return Scaffold(
      // ❌ تم إزالة backgroundColor ليقرأ خلفية النظام تلقائياً

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.selectedDate.value = '';
          Get.bottomSheet(const AddGrowthSheet(), isScrollControlled: true);
        },
        // ─── لون الزر العائم متكيف مع السمة ───
        backgroundColor: context.theme.primaryColor,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),

      body: Obx(() {
        // 1. حالة التحميل
        if (controller.isLoading && controller.growthData.value == null) {
          return Center(
            // ─── مؤشر التحميل متكيف ───
            child: CircularProgressIndicator(color: context.theme.primaryColor),
          );
        }

        final data = controller.growthData.value;
        if (data == null) {
          return Center(
            child: Text(
              'Failed to load profile'.tr,
              // ─── نص متكيف ───
              style: TextStyle(color: context.textTheme.bodyMedium?.color),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.getGrowthDashboard(),
          // ─── لون مؤشر التحديث متكيف ───
          color: context.theme.primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //  كروت القياسات العلوية السريعة
                _buildQuickStatsSection(
                  context, // ─── نمرر الـ context لاستخدامه في تكييف الألوان ───
                  data.growthHistory,
                  data.currentAgeMonths,
                ),
                const SizedBox(height: 16),

                // المخطط البياني (قد يحتاج لتعديل داخلي إذا كانت ألوانه ثابتة)
                GrowthChartWidget(data: data),
                const SizedBox(height: 20),

                //   سجلات النمو السفلية
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Growth History'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        // ─── نص متكيف ───
                        color: context.textTheme.bodyLarge?.color,
                      ),
                    ),
                    Icon(
                      Icons.sort_rounded,
                      // ─── أيقونة متكيفة ───
                      color: context.textTheme.bodyMedium?.color,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                //  قائمة القياسات التاريخية (قد تحتاج لتعديل داخلي إذا كانت ألوانها ثابتة)
                GrowthHistoryList(data: data),
                const SizedBox(height: 60),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// اللوحة العلوية للقياسات
  Widget _buildQuickStatsSection(BuildContext context, List<dynamic> history, double rawAge) {
    final latestRecord = history.isNotEmpty ? history.first : null;
    final displayWeight = latestRecord != null
        ? '${latestRecord.weight} ${'kg'.tr}'
        : '--';
    final displayHeight = latestRecord != null
        ? '${latestRecord.height} ${'cm'.tr}'
        : '--';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // ─── لون خلفية البطاقة متكيف ───
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        // ─── إطار البطاقة متكيف ───
        border: Border.all(color: context.theme.dividerColor),
      ),
      child: Row(
        children: [
          // كارت الوزن
          Expanded(
            child: _QuickStatCard(
              icon: Icons.scale_outlined,
              label: 'Current Weight'.tr,
              value: displayWeight,
            ),
          ),
          // ─── خط فاصل متكيف ───
          Container(width: 1, height: 40, color: context.theme.dividerColor),
          // كارت الطول
          Expanded(
            child: _QuickStatCard(
              icon: Icons.straighten_outlined,
              label: 'Current Height'.tr,
              value: displayHeight,
            ),
          ),
          // ─── خط فاصل متكيف ───
          Container(width: 1, height: 40, color: context.theme.dividerColor),
          // كارت العمر
          Expanded(
            child: _QuickStatCard(
              icon: Icons.calendar_month_outlined,
              label: 'Age'.tr,
              value: '${rawAge.toInt()} ${'Months'.tr}',
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _QuickStatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ─── لون الأيقونة متكيف ───
        Icon(icon, color: context.theme.primaryColor, size: 22),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            // ─── نص ثانوي متكيف ───
            color: context.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            // ─── نص أساسي متكيف ───
            color: context.textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }
}