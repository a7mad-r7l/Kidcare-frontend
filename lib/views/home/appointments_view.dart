import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home/appointments_controller.dart';
import '../../models/home/appointments_model.dart';

class AppointmentsView extends GetView<AppointmentsController> {
  const AppointmentsView({super.key});

  @override
  Widget build(BuildContext context) {
    // تحديد السياق: هل نحن في مواعيد طفل محدد أم كل مواعيد المستخدم؟
    final bool isSingleChild = controller.childId != null && controller.childId != 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F4FF),
        elevation: 0,
        centerTitle: true,
        title: Text(
          // ─── إضافة الترجمة لعنوان الشاشة ───
          isSingleChild ? 'Child Appointments'.tr : 'My Appointments'.tr,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2E5A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A2E5A), size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // ─── Tabs (Slider) ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Obx(() => Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.switchTab(true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: controller.showUpcoming.value ? const Color(0xFF3B9EFF) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_month_outlined,
                              color: controller.showUpcoming.value ? Colors.white : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              // ─── الترجمة هنا ───
                              'Upcoming'.tr,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: controller.showUpcoming.value ? Colors.white : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.switchTab(false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !controller.showUpcoming.value ? const Color(0xFF3B9EFF) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_outlined,
                              color: !controller.showUpcoming.value ? Colors.white : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              // ─── الترجمة هنا ───
                              'Past'.tr,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: !controller.showUpcoming.value ? Colors.white : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ),
          const SizedBox(height: 16),

          // ─── List ───
          Expanded(
            child: Obx(() {
              if (controller.isLoading) {
                return const Center(child: CircularProgressIndicator(color: Colors.blue));
              }

              final list = controller.showUpcoming.value ? controller.upcoming : controller.past;

              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        // ─── الترجمة هنا ───
                        'No appointments found'.tr,
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, index) => _AppointmentCard(
                  appointment: list[index],
                  isSingleChild: isSingleChild, // نمرر السياق للبطاقة
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Appointment Card ───
class _AppointmentCard extends StatelessWidget {
  final AppointmentsModel appointment;
  final bool isSingleChild;

  const _AppointmentCard({
    required this.appointment,
    required this.isSingleChild,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      // تبديل ذكي بين التصميمين بناءً على السياق
      child: isSingleChild ? _buildSingleChildLayout() : _buildAllAppointmentsLayout(),
    );
  }

  // 1. تصميم (جميع المواعيد للمستخدم) - يظهر فيه الطفل والطبيب معاً
  Widget _buildAllAppointmentsLayout() {
    return Column(
      children: [
        // الصف الأول: معلومات الطفل وحالة الموعد
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.blue.shade50,
              backgroundImage: appointment.childImage != null && appointment.childImage!.isNotEmpty
                  ? NetworkImage(appointment.childImage!)
                  : null,
              child: appointment.childImage == null || appointment.childImage!.isEmpty
                  ? Icon(Icons.child_care, color: Colors.blue.shade300, size: 24)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // ملاحظة: يُفضل استخدام .tr داخل المودل كما فعلنا سابقاً، لذلك لا نحتاج لإضافتها هنا للاسم
                    appointment.childName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2E5A)),
                  ),
                  const SizedBox(height: 2),
                  // ─── الترجمة هنا ───
                  Text('Patient'.tr, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            _StatusPill(status: appointment.status),
          ],
        ),

        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFF0F4FF)),
        ),

        // الصف الثاني: معلومات الطبيب والاختصاص
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                image: appointment.doctorImage != null && appointment.doctorImage!.isNotEmpty
                    ? DecorationImage(image: NetworkImage(appointment.doctorImage!), fit: BoxFit.cover)
                    : null,
              ),
              child: appointment.doctorImage == null || appointment.doctorImage!.isEmpty
                  ? Icon(Icons.person, color: Colors.grey.shade400)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.doctorName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A2E5A)),
                  ),
                  const SizedBox(height: 2),
                  Text(appointment.specialty, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // الصف الثالث: التاريخ والوقت
        _buildDateTimeSection(),
      ],
    );
  }

  // 2. تصميم (مواعيد طفل محدد) - يظهر فيه الطبيب والقسم فقط
  Widget _buildSingleChildLayout() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة الطبيب
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
                image: appointment.doctorImage != null && appointment.doctorImage!.isNotEmpty
                    ? DecorationImage(image: NetworkImage(appointment.doctorImage!), fit: BoxFit.cover)
                    : null,
              ),
              child: appointment.doctorImage == null || appointment.doctorImage!.isEmpty
                  ? Icon(Icons.medical_services_outlined, color: Colors.blue.shade400, size: 26)
                  : null,
            ),
            const SizedBox(width: 14),

            // معلومات الطبيب والحالة
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          appointment.doctorName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2E5A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _StatusPill(status: appointment.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    appointment.specialty,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // شريط التاريخ والوقت
        _buildDateTimeSection(),
      ],
    );
  }

  // ويدجت مشتركة لعرض الوقت والتاريخ بشكل منسق
  Widget _buildDateTimeSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 16, color: Colors.blue.shade600),
          const SizedBox(width: 6),
          Text(
            appointment.date,
            style: TextStyle(fontSize: 13, color: Colors.blue.shade700, fontWeight: FontWeight.w600),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('|', style: TextStyle(color: Colors.grey)),
          ),
          Icon(Icons.access_time_outlined, size: 16, color: Colors.blue.shade600),
          const SizedBox(width: 6),
          Text(
            appointment.time,
            style: TextStyle(fontSize: 13, color: Colors.blue.shade700, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── Status Pill (مساعد لتلوين حالة الموعد) ───
class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    late final Color bg;
    late final Color fg;

    switch (normalized) {
      case 'confirmed':
      case 'success':
        bg = Colors.green.shade50;
        fg = Colors.green.shade600;
        break;
      case 'cancelled':
      case 'canceled':
        bg = Colors.red.shade50;
        fg = Colors.red.shade600;
        break;
      case 'pending':
      default:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
        break;
    }

    // تجهيز الكلمة (حرف كبير في البداية) لتتطابق مع مفاتيح ملف الترجمة
    final label = status.isEmpty ? 'Pending' : status[0].toUpperCase() + status.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      // ─── تطبيق الترجمة على حالة الموعد هنا ───
      child: Text(label.tr, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}