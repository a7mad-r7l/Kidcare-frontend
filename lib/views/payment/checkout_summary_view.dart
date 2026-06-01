import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/payment_controller.dart';
import '../../widgets/payment_widgets.dart';

class CheckoutSummaryView extends GetView<PaymentController> {
  const CheckoutSummaryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Review & Pay',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: Obx(() {
        // 1.  انتطار بيانات الموعد من  الـ GET  مؤشر تحميل
        if (controller.isDetailsLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final summary = controller.appointmentSummary.value;
        if (summary == null) {
          return const Center(child: Text("Failed to load appointment data."));
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // كارت تفاصيل الموعد
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF6FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //  بروفايل صورة الطفل
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.purple.shade100,
                          backgroundImage: summary.patientImageUrl.isNotEmpty
                              ? NetworkImage(
                                  summary.patientImageUrl,
                                ) //  من الباك إند
                              : null,
                          // Fallback في حال عدم توفر صورة
                          child: summary.patientImageUrl.isEmpty
                              ? Icon(
                                  Icons.person,
                                  color: Colors.purple.shade700,
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
                                summary.patientName, // اسم الطفل
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                summary.patientAge, // عمر الطفل
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.blue.shade100,
                                    child: const Icon(
                                      Icons.medical_services,
                                      size: 14,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      // اسم الطبيب و العيادة
                                      '${summary.doctorName} - ${summary.departmentName}',

                                      style: TextStyle(
                                        color: Colors.grey.shade800,
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
                    const Divider(
                      height: 30,
                      color: Colors.black12,
                      thickness: 1,
                    ),
                    PaymentSummaryRow(
                      label: 'Date & Time',
                      value: summary.dateTime, // التاريخ و الوقت
                    ),
                    const SizedBox(height: 12),
                    PaymentSummaryRow(
                      label: 'Consultation Fee',
                      value:
                          '${summary.price} ${summary.currency}', // السعر و العملة
                    ),
                    const Divider(
                      height: 30,
                      color: Colors.black12,
                      thickness: 1,
                    ),
                    PaymentSummaryRow(
                      label: 'Total',
                      value: '${summary.price} ${summary.currency}', // الإجمالي

                      isTotal: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              const Text(
                'Choose how to pay',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              //  طرق الدفع الثابتة
              Column(
                children: [
                  PaymentOptionCard(
                    title: 'Mada',
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
                    title: 'Credit Card (Visa/Mastercard)',
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
                    title: 'Apple Pay',
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
                    title: 'STC Pay',
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

              const Spacer(),

              // زر الدفع
              SizedBox(
                width: double.infinity,
                height: 30,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
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
                          'Pay ${summary.price} ${summary.currency}',
                          // النص مع الفاتورة القادمة من السيرفر
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      }),
    );
  }
}
