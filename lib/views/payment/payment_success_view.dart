import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/appointment/my_appointments_controller.dart';
import '../../controllers/home/appointments_controller.dart';
import '../../controllers/home/home_controller.dart';
import '../../widgets/payment_widgets.dart';

class PaymentSuccessView extends StatelessWidget {
  const PaymentSuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ❌ تم إزالة backgroundColor ليقرأ خلفية النظام تلقائياً
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              Image.asset(
                'assets/images/success_celebration_icon.png',
                height: 200,
              ),
              const SizedBox(height: 24),
              Text(
                'Payment Successful!'.tr,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.textTheme.bodyLarge?.color, // ─── نص أساسي متكيف ───
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your appointment is confirmed'.tr,
                style: TextStyle(
                  fontSize: 16,
                  color: context.textTheme.bodyMedium?.color, // ─── نص ثانوي متكيف ───
                ),
              ),

              const SizedBox(height: 40),

              // ملخص الفاتورة
              Builder(
                builder: (context) {
                  final args = Get.arguments as Map<String, dynamic>?;
                  final summary = args?['summary'];
                  final transId = args?['transaction_id'] ?? '#N/A';

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      // ─── لون إطار البطاقة متكيف ───
                      border: Border.all(color: context.theme.dividerColor),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        InvoiceRow(
                          label: 'Date & Time'.tr,
                          value: summary?.dateTime ?? 'N/A',
                        ),
                        const SizedBox(height: 12),
                        InvoiceRow(
                          label: 'Doctor'.tr,
                          value: summary?.doctorName ?? 'N/A',
                        ),
                        const SizedBox(height: 12),
                        InvoiceRow(
                          label: 'Amount'.tr,
                          value: '${summary?.price ?? 0} ${summary?.currency ?? ''}',
                        ),
                        Divider(
                          height: 30,
                          color: context.theme.dividerColor, // ─── خط فاصل متكيف ───
                        ),
                        InvoiceRow(
                          label: 'Transaction ID'.tr,
                          value: '#$transId',
                          isBold: true,
                        ),
                      ],
                    ),
                  );
                },
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.theme.primaryColor, // ─── لون الزر الأساسي متكيف ───
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (Get.isRegistered<MyAppointmentsController>()) {
                      Get.find<MyAppointmentsController>().loadUpcoming();
                    }

                    if (Get.isRegistered<HomeController>()) {
                      Get.find<HomeController>().fetchChildren();
                    }
                    Get.offAllNamed('/home');
                  },
                  child: Text(
                    'Back to Home'.tr,
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  if (Get.isRegistered<MyAppointmentsController>()) {
                    Get.find<MyAppointmentsController>().loadUpcoming();
                  }

                  if (Get.isRegistered<AppointmentsController>()) {
                    Get.find<AppointmentsController>().fetchUpcoming();
                  }
                  Get.offAllNamed('/appointments');
                },
                child: Text(
                  'View My Appointments'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    color: context.theme.primaryColor, // ─── لون النص متكيف ───
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}