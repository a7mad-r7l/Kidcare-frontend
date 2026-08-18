import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/payment_controller.dart';
import '../../widgets/payment_widgets.dart';

class CheckoutSummaryView extends GetView<PaymentController> {
  const CheckoutSummaryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Review & Pay'.tr,
          style: TextStyle(
            color: context.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        iconTheme: IconThemeData(color: context.iconColor),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isDetailsLoading.value) {
          return Center(child: CircularProgressIndicator(color: context.theme.primaryColor));
        }

        final summary = controller.appointmentSummary.value;
        if (summary == null) {
          return Center(
            child: Text(
              "Failed to load appointment data.".tr,
              style: TextStyle(color: context.textTheme.bodyMedium?.color),
            ),
          );
        }

        // ─── تم إعادة الهيكلة هنا لحل مشكلة الـ Overflow ───
        return Column(
          children: [
            // 1. الجزء القابل للتمرير (المحتوى)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // كارت تفاصيل الموعد
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? context.theme.cardColor : const Color(0xFFEDF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: context.isDarkMode ? Border.all(color: context.theme.dividerColor) : null,
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: context.isDarkMode ? Colors.purple.withOpacity(0.15) : Colors.purple.shade100,
                                backgroundImage: summary.patientImageUrl.isNotEmpty
                                    ? NetworkImage(summary.patientImageUrl)
                                    : null,
                                child: summary.patientImageUrl.isEmpty
                                    ? Icon(
                                  Icons.person,
                                  color: context.isDarkMode ? Colors.purpleAccent : Colors.purple.shade700,
                                  size: 30,
                                )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      summary.patientName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: context.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${summary.patientAge} ${summary.ageType.tr}',
                                      style: TextStyle(
                                        color: context.textTheme.bodyMedium?.color,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: context.isDarkMode ? Colors.blue.withOpacity(0.15) : Colors.blue.shade100,
                                          child: Icon(
                                            Icons.medical_services,
                                            size: 14,
                                            color: context.isDarkMode ? Colors.blueAccent : Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${summary.doctorName} - ${summary.departmentName}',
                                            style: TextStyle(
                                              color: context.textTheme.bodyLarge?.color,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF4CAF50),
                                size: 28,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(
                            height: 30,
                            color: context.theme.dividerColor,
                            thickness: 1,
                          ),
                          PaymentSummaryRow(
                            label: 'Date & Time'.tr,
                            value: summary.dateTime,
                          ),
                          const SizedBox(height: 12),
                          PaymentSummaryRow(
                            label: 'Consultation Fee'.tr,
                            value: '${summary.price} ${summary.currency}',
                          ),
                          Divider(
                            height: 30,
                            color: context.theme.dividerColor,
                            thickness: 1,
                          ),
                          PaymentSummaryRow(
                            label: 'Total'.tr,
                            value: '${summary.price} ${summary.currency}',
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                    Text(
                      'Choose how to pay'.tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // طرق الدفع
                    Column(
                      children: [
                        PaymentOptionCard(
                          title: 'Mada'.tr,
                          value: 1,
                          groupValue: controller.selectedCardMethod.value,
                          onTap: () => controller.setCardMethod(1),
                          trailingWidget: Image.asset(
                            'assets/images/mada_logo.png',
                            height: 22,
                          ),
                        ),
                        const SizedBox(height: 12),
                        PaymentOptionCard(
                          title: 'Credit Card (Visa/Mastercard)'.tr,
                          value: 2,
                          groupValue: controller.selectedCardMethod.value,
                          onTap: () => controller.setCardMethod(2),
                          trailingWidget: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/mastercard_logo.png',
                                height: 24,
                              ),
                              const SizedBox(width: 8),
                              Image.asset('assets/images/visa_logo.png', height: 18),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        PaymentOptionCard(
                          title: 'Apple Pay'.tr,
                          value: 3,
                          groupValue: controller.selectedCardMethod.value,
                          onTap: () => controller.setCardMethod(3),
                          trailingWidget: Image.asset(
                            'assets/images/apple_pay_logo.png',
                            height: 24,
                          ),
                        ),
                        const SizedBox(height: 12),
                        PaymentOptionCard(
                          title: 'STC Pay'.tr,
                          value: 4,
                          groupValue: controller.selectedCardMethod.value,
                          onTap: () => controller.setCardMethod(4),
                          trailingWidget: Image.asset(
                            'assets/images/stc-pay-logo.png',
                            height: 24,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 2. الجزء السفلي الثابت (زر الدفع)
            SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                decoration: BoxDecoration(
                  color: context.theme.scaffoldBackgroundColor,
                  boxShadow: [
                    if (!context.isDarkMode)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      )
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.theme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.processPayment(),
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      'Pay'.tr + ' ${summary.price} ${summary.currency}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}