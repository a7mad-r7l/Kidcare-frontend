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
      backgroundColor: const Color(0xFFF4F6FA),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.selectedDate.value = '';
          Get.bottomSheet(const AddGrowthSheet(), isScrollControlled: true);
        },
        backgroundColor: const Color(0xFF3B9EFF),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),

      body: Obx(() {
        // 1. حالة التحميل
        if (controller.isLoading && controller.growthData.value == null) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blue),
          );
        }

        final data = controller.growthData.value;
        if (data == null) {
          return Center(
            child: Text(
              'Failed to load profile'.tr,
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.getGrowthDashboard(),
          color: Colors.blue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //  كروت القياسات العلوية السريعة
                _buildQuickStatsSection(
                  data.growthHistory,
                  data.currentAgeMonths,
                ),
                const SizedBox(height: 16),

                // المخطط البياني
                GrowthChartWidget(data: data),
                const SizedBox(height: 20),

                //   سجلات النمو السفلية
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Growth History'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2E5A),
                      ),
                    ),
                    Icon(
                      Icons.sort_rounded,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                //  قائمة القياسات التاريخية
                GrowthHistoryList(data: data),
                const SizedBox(height: 60),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// اللوحة العلوية  للقياسات
  Widget _buildQuickStatsSection(List<dynamic> history, double rawAge) {
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
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
          Container(width: 1, height: 40, color: Colors.grey.shade100),
          // كارت الطول
          Expanded(
            child: _QuickStatCard(
              icon: Icons.straighten_outlined,
              label: 'Current Height'.tr,
              value: displayHeight,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade100),
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
        Icon(icon, color: const Color(0xFF3B9EFF), size: 22),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2E5A),
          ),
        ),
      ],
    );
  }
}
