import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home/appointments_controller.dart';
import '../../models/home/appointments_model.dart';

class AppointmentsView extends GetView<AppointmentsController> {
  const AppointmentsView({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isSingleChild =
        controller.childId != null && controller.childId != 0;

    // ─── إحاطة الواجهة بـ PopScope للتحكم بزر الرجوع في النظام ───
    return PopScope(
      canPop: false, // نمنع الرجوع الافتراضي
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        // ─── توجيه المستخدم للرئيسية عند ضغط زر الهاتف ───
        Get.offAllNamed('/home');
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title: Text(
            isSingleChild ? 'Child Appointments'.tr : 'My Appointments'.tr,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.textTheme.bodyLarge?.color,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: context.iconColor,
              size: 20,
            ),
            onPressed: () {
              // ─── العودة إلى الرئيسية مباشرة من زر الواجهة ───
              Get.offAllNamed('/home');
            },
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 16),

            // ─── Tabs (Slider) ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Obx(
                () => Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.theme.cardColor,
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
                              color: controller.showUpcoming.value
                                  ? context.theme.primaryColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_month_outlined,
                                  color: controller.showUpcoming.value
                                      ? Colors.white
                                      : context.textTheme.bodyMedium?.color,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Upcoming'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: controller.showUpcoming.value
                                        ? Colors.white
                                        : context.textTheme.bodyMedium?.color,
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
                              color: !controller.showUpcoming.value
                                  ? context.theme.primaryColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history_outlined,
                                  color: !controller.showUpcoming.value
                                      ? Colors.white
                                      : context.textTheme.bodyMedium?.color,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Past'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: !controller.showUpcoming.value
                                        ? Colors.white
                                        : context.textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── List مع ميزة التحديث بالسحب ───
            Expanded(
              child: Obx(() {
                final list = controller.showUpcoming.value
                    ? controller.upcoming
                    : controller.past;

                // نظهر دائرة التحميل فقط إذا كانت القائمة فارغة (لتجنب اختفاء المواعيد عند التحديث اليدوي)
                if (controller.isLoading && list.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  );
                }

                return RefreshIndicator(
                  color: context.theme.primaryColor,
                  onRefresh: () async {
                    if (controller.showUpcoming.value) {
                      await controller.fetchUpcoming();
                    } else {
                      await controller.fetchPast();
                    }
                  },
                  child: list.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.6,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 60,
                                  color: context.theme.dividerColor,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No appointments found'.tr,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: context.textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          // ضروري لعمل السحب
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          itemCount: list.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, index) => _AppointmentCard(
                            appointment: list[index],
                            isSingleChild: isSingleChild,
                            isUpcoming: controller
                                .showUpcoming
                                .value, // 👈 إرسال حالة التبويب للبطاقة
                          ),
                        ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Appointment Card ───
class _AppointmentCard extends StatelessWidget {
  final AppointmentsModel appointment;
  final bool isSingleChild;
  final bool isUpcoming; // 👈 متغير لتحديد ظهور زر الإلغاء

  const _AppointmentCard({
    required this.appointment,
    required this.isSingleChild,
    required this.isUpcoming,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.transparent
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isSingleChild
          ? _buildSingleChildLayout(context)
          : _buildAllAppointmentsLayout(context),
    );
  }

  // ─── زر الإلغاء المخصص ───
  Widget _buildCancelButton() {
    final AppointmentsController controller =
        Get.find<AppointmentsController>();
    return IconButton(
      icon: const Icon(Icons.cancel_outlined, color: Colors.red),
      tooltip: 'Cancel Appointment'.tr,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      // لتقليل المساحة المحيطة بالزر
      onPressed: () {
        Get.defaultDialog(
          title: 'Cancel Appointment'.tr,
          middleText:
              'Are you sure you want to cancel this appointment? A refund will be initiated.'
                  .tr,
          titleStyle: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
          textConfirm: 'Yes, Cancel'.tr,
          textCancel: 'No'.tr,
          confirmTextColor: Colors.white,
          buttonColor: Colors.red,
          cancelTextColor: Colors.red,
          onConfirm: () {
            Get.back(); // إغلاق نافذة التأكيد
            controller.cancelAppointment(
              appointment.id,
            ); // استدعاء دالة الحذف من الكنترولر
          },
        );
      },
    );
  }

  Widget _buildAllAppointmentsLayout(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: context.isDarkMode
                  ? Colors.blue.withValues(alpha: 0.15)
                  : Colors.blue.shade50,
              backgroundImage:
                  appointment.childImage != null &&
                      appointment.childImage!.isNotEmpty
                  ? NetworkImage(appointment.childImage!)
                  : null,
              child:
                  appointment.childImage == null ||
                      appointment.childImage!.isEmpty
                  ? Icon(
                      Icons.child_care,
                      color: Colors.blue.shade300,
                      size: 24,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.childName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Patient'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
            _StatusPill(status: appointment.status),
            // إظهار زر الإلغاء إذا كان الموعد قادماً وغير ملغي
            if (isUpcoming &&
                appointment.status.toLowerCase() != 'cancelled' &&
                appointment.status.toLowerCase() != 'canceled') ...[
              const SizedBox(width: 8),
              _buildCancelButton(),
            ],
          ],
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Divider(
            height: 1,
            thickness: 1,
            color: context.theme.dividerColor,
          ),
        ),

        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? context.theme.scaffoldBackgroundColor
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                image:
                    appointment.doctorImage != null &&
                        appointment.doctorImage!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(appointment.doctorImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child:
                  appointment.doctorImage == null ||
                      appointment.doctorImage!.isEmpty
                  ? Icon(Icons.person, color: context.theme.dividerColor)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.doctorName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: context.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    appointment.specialty,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        _buildDateTimeSection(context),

        // 👈 هذا هو التعديل الجديد: زر عرض التقييم الطبي للمواعيد المكتملة
        if (appointment.status.toLowerCase() == 'completed') ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                foregroundColor: context.theme.primaryColor,
                side: BorderSide(color: context.theme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () =>
                  Get.toNamed('/prescription', arguments: appointment.id),
              icon: const Icon(Icons.medical_information_outlined, size: 20),
              label: Text(
                'View Medical Assessment'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSingleChildLayout(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? context.theme.scaffoldBackgroundColor
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
                image:
                    appointment.doctorImage != null &&
                        appointment.doctorImage!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(appointment.doctorImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child:
                  appointment.doctorImage == null ||
                      appointment.doctorImage!.isEmpty
                  ? Icon(
                      Icons.medical_services_outlined,
                      color: Colors.blue.shade400,
                      size: 26,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.textTheme.bodyLarge?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _StatusPill(status: appointment.status),
                          // إظهار زر الإلغاء إذا كان الموعد قادماً وغير ملغي
                          if (isUpcoming &&
                              appointment.status.toLowerCase() != 'cancelled' &&
                              appointment.status.toLowerCase() !=
                                  'canceled') ...[
                            const SizedBox(width: 8),
                            _buildCancelButton(),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    appointment.specialty,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDateTimeSection(context),

        // 👈 هذا هو التعديل الجديد: زر عرض التقييم الطبي للمواعيد المكتملة
        if (appointment.status.toLowerCase() == 'completed') ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                foregroundColor: context.theme.primaryColor,
                side: BorderSide(color: context.theme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () =>
                  Get.toNamed('/prescription', arguments: appointment.id),
              icon: const Icon(Icons.medical_information_outlined, size: 20),
              label: Text(
                'View Medical Assessment'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateTimeSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? context.theme.scaffoldBackgroundColor
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 16,
            color: context.isDarkMode
                ? Colors.blue.shade300
                : Colors.blue.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            appointment.date,
            style: TextStyle(
              fontSize: 13,
              color: context.isDarkMode
                  ? Colors.blue.shade300
                  : Colors.blue.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '|',
              style: TextStyle(color: context.theme.dividerColor),
            ),
          ),
          Icon(
            Icons.access_time_outlined,
            size: 16,
            color: context.isDarkMode
                ? Colors.blue.shade300
                : Colors.blue.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            appointment.time,
            style: TextStyle(
              fontSize: 13,
              color: context.isDarkMode
                  ? Colors.blue.shade300
                  : Colors.blue.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

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
        bg = context.isDarkMode
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.green.shade50;
        fg = context.isDarkMode ? Colors.greenAccent : Colors.green.shade600;
        break;
      case 'cancelled':
      case 'canceled':
        bg = context.isDarkMode
            ? Colors.red.withValues(alpha: 0.2)
            : Colors.red.shade50;
        fg = context.isDarkMode ? Colors.redAccent : Colors.red.shade600;
        break;
      case 'pending':
      default:
        bg = context.isDarkMode
            ? Colors.orange.withValues(alpha: 0.2)
            : Colors.orange.shade50;
        fg = context.isDarkMode ? Colors.orangeAccent : Colors.orange.shade700;
        break;
    }

    final label = status.isEmpty
        ? 'Pending'
        : status[0].toUpperCase() + status.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.tr,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
