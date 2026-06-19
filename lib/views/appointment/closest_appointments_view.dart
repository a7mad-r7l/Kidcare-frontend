import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../controllers/appointment/appointment_controller.dart';
import '../../controllers/appointment/closest_appointments_controller.dart';
import '../../models/appointment/closest_appointment_model.dart';
import '../../models/appointment/doctor_model.dart';
import '../../widgets/booking_app_bar.dart';

class ClosestAppointmentsView extends GetView<ClosestAppointmentsController> {
  const ClosestAppointmentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: bookingAppBar(subtitle: 'Closest Appointments'.tr),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildDepartmentsSlider(context),
          const SizedBox(height: 16),
          Expanded(child: _buildAppointmentsList()),
        ],
      ),
    );
  }

  Widget _buildDepartmentsSlider(BuildContext context) {
    return Obx(() {
      if (controller.departments.isEmpty && controller.isLoading) {
        return const SizedBox(height: 45, child: Center(child: CircularProgressIndicator()));
      }

      return SizedBox(
        height: 45,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: controller.departments.length,
          itemBuilder: (context, index) {
            final dept = controller.departments[index];
            final isSelected = controller.selectedDepartmentId.value == dept.id;

            return GestureDetector(
              onTap: () => controller.fetchClosestAppointments(dept.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? context.theme.primaryColor : context.theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? context.theme.primaryColor : context.theme.dividerColor,
                  ),
                ),
                child: Text(
                  dept.name.tr,
                  style: TextStyle(
                    color: isSelected ? Colors.white : context.textTheme.bodyLarge?.color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildAppointmentsList() {
    return Obx(() {
      if (controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.closestAppointments.isEmpty) {
        return Center(
          child: Text(
            'No upcoming appointments available for this department.'.tr,
            style: TextStyle(color: Get.context!.textTheme.bodyMedium?.color),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: controller.closestAppointments.length,
        itemBuilder: (context, index) {
          final item = controller.closestAppointments[index];
          return _ClosestAppointmentCard(item: item);
        },
      );
    });
  }
}

class _ClosestAppointmentCard extends StatelessWidget {
  final ClosestAppointmentModel item;

  const _ClosestAppointmentCard({required this.item});

  void _onCardTapped() {
    final aptCtrl = Get.find<AppointmentController>();

    // 1. تمرير مودل وهمي للطبيب يحتوي على الـ ID والاسم الأساسي فقط لأننا لا نحتاج الباقي هنا
    aptCtrl.selectDoctor(DoctorModel(
      id: item.doctorId,
      firstName: item.doctorName,
      lastName: '',
      email: '',
      address: '',
      isFavorite: false,
    ));

    // 2. تحديد التاريخ والوقت تلقائياً
    aptCtrl.selectDate(DateTime.parse(item.date));
    aptCtrl.selectTime(item.time);

    // 3. الانتقال لاختيار الطفل مع تمرير Flag ليخبر الواجهة أن هذا "حجز سريع"
    Get.toNamed('/choose-child', arguments: {'is_quick_book': true});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onCardTapped,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.theme.dividerColor),
          boxShadow: [
            if (!context.isDarkMode)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: context.isDarkMode ? Colors.blue.withValues(alpha: 0.15) : Colors.blue.shade50,
              backgroundImage: item.profilePictureUrl != null ? NetworkImage(item.profilePictureUrl!) : null,
              child: item.profilePictureUrl == null ? Icon(Icons.person, color: context.theme.primaryColor) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.doctorName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 16, color: context.theme.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        '${item.date} (${item.dayName.tr})',
                        style: TextStyle(fontSize: 13, color: context.textTheme.bodyMedium?.color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 16, color: Colors.orange.shade600),
                      const SizedBox(width: 6),
                      Text(
                        item.time,
                        style: TextStyle(fontSize: 13, color: context.textTheme.bodyMedium?.color, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.theme.dividerColor),
          ],
        ),
      ),
    );
  }
}