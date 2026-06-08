import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home/child_profile_controller.dart';
import '../../models/appointment/child_model.dart';
import '../growth/child_growth_tab_view.dart';

class ChildProfileView extends GetView<ChildProfileController> {
  const ChildProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final RxBool isGrowthTab = true.obs;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Child Profile'.tr,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2E5A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF1A2E5A),
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blue),
          );
        }

        final child = controller.child.value;
        if (child == null) {
          return Center(child: Text('Failed to load profile'.tr));
        }

        return Column(
          children: [
            //  كارت معلومات الطفل الأساسية
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _InfoCard(child: child),
            ),
            const SizedBox(height: 16),

            // Custom Tabs Switcher
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF2F8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    //  منحنى النمو والوزن
                    Expanded(
                      child: GestureDetector(
                        onTap: () => isGrowthTab.value = true,
                        child: Obx(
                          () => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isGrowthTab.value
                                  ? const Color(0xFF2ecc71)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.show_chart_rounded,
                                  color: isGrowthTab.value
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Growth Chart & Weight'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isGrowthTab.value
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    //  المواعيد والبيانات الطبية
                    Expanded(
                      child: GestureDetector(
                        onTap: () => isGrowthTab.value = false,
                        child: Obx(
                          () => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !isGrowthTab.value
                                  ? const Color(0xFF3B9EFF)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  color: !isGrowthTab.value
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Appointments & Files'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: !isGrowthTab.value
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: Obx(() {
                if (isGrowthTab.value) {
                  return ChildGrowthTabView(childId: controller.childId);
                } else {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    child: Column(
                      children: [
                        _StatsCard(child: child),
                        const SizedBox(height: 16),

                        if (child.medicalHistory != null &&
                            child.medicalHistory!.isNotEmpty) ...[
                          _DataCard(
                            title: 'Medical History'.tr,
                            content: child.medicalHistory!,
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (child.allergies != null &&
                            child.allergies!.isNotEmpty) ...[
                          _DataCard(
                            title: 'Allergies'.tr,
                            content: child.allergies!,
                          ),
                          const SizedBox(height: 16),
                        ],

                        _ActionButton(
                          icon: Icons.vaccines_outlined,
                          label: 'Vaccination Record'.tr,
                          color: Colors.blue,
                          onTap: () =>
                              Get.toNamed('/vaccinations', arguments: child.id),
                        ),
                        const SizedBox(height: 10),
                        _ActionButton(
                          icon: Icons.calendar_today_outlined,
                          label: 'Appointments'.tr,
                          color: Colors.blue,
                          onTap: () =>
                              Get.toNamed('/appointments', arguments: child.id),
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Get.dialog(
                                AlertDialog(
                                  title: Text('Delete Child'.tr),
                                  content: Text(
                                    'Are you sure you want to delete this child profile? This action cannot be undone.'
                                        .tr,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Get.back(),
                                      child: Text('Cancel'.tr),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Get.back();
                                        controller.deleteCurrentChild();
                                      },
                                      child: Text(
                                        'Delete'.tr,
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                            label: Text(
                              'Delete Child Profile'.tr,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade400,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  );
                }
              }),
            ),
          ],
        );
      }),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final ChildModel child;

  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: Colors.white,
            backgroundImage: (child.image != null && child.image!.isNotEmpty)
                ? NetworkImage(child.image!)
                : null,
            child: (child.image == null || child.image!.isEmpty)
                ? Icon(Icons.person, color: Colors.grey.shade300, size: 55)
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.fullName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2E5A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '${child.ageYears} ${' years'.tr}',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      child.gender.toLowerCase() == 'female'
                          ? Icons.female
                          : Icons.male,
                      color: const Color(0xFF4CAF50),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      child.gender.capitalizeFirst ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final ChildModel child;

  const _StatsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.water_drop_outlined,
              value: child.bloodType ?? 'N/A',
              label: 'Blood Type'.tr,
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.calendar_month_outlined,
              value: '${child.ageYears}',
              label: 'Age'.tr,
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _StatItem(
              icon: child.gender.toLowerCase() == 'female'
                  ? Icons.female
                  : Icons.male,
              value: child.gender.capitalizeFirst ?? '',
              label: 'Gender'.tr,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF4CAF50), size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2E5A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 60, color: Colors.grey.shade200);
  }
}

class _DataCard extends StatelessWidget {
  final String title;
  final String content;

  const _DataCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2E5A),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2E5A),
                  ),
                ),
              ],
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF1A2E5A), size: 22),
          ],
        ),
      ),
    );
  }
}
