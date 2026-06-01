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
      backgroundColor: Colors.white,
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
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your appointment is confirmed',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 40),

              //  ملخص الفاتورة
              // 👈 استقبال البيانات من الـ arguments
              Builder(
                builder: (context) {
                  final args = Get.arguments as Map<String, dynamic>?;
                  final summary = args?['summary'];
                  final transId = args?['transaction_id'] ?? '#N/A';

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        InvoiceRow(
                          label: 'Date & Time',
                          value: summary?.dateTime ?? 'N/A',
                        ),
                        const SizedBox(height: 12),
                        InvoiceRow(
                          label: 'Doctor',
                          value: summary?.doctorName ?? 'N/A',
                        ),
                        const SizedBox(height: 12),
                        InvoiceRow(
                          label: 'Amount',
                          value:
                              '${summary?.price ?? 0} ${summary?.currency ?? ''}',
                        ),
                        const Divider(height: 30),
                        InvoiceRow(
                          label: 'Transaction ID',
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
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // 1. تحديث الكنترولر العام للمواعيد القادمة
                    if (Get.isRegistered<MyAppointmentsController>()) {
                      Get.find<MyAppointmentsController>().loadUpcoming();
                    }
                    // 2. تحديث قائمة الأطفال في الهوم بيج لتحديث الوجبات إن وجدت
                    if (Get.isRegistered<HomeController>()) {
                      Get.find<HomeController>().fetchChildren();
                    }
                    Get.offAllNamed('/home');
                  },
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // 1. تحديث الكنترولر العام فوراً قبل فتح الشاشة
                  if (Get.isRegistered<MyAppointmentsController>()) {
                    Get.find<MyAppointmentsController>().loadUpcoming();
                  }
                  // 2. تحديث كونتولر مواعيد الطفل (الخاص بشاشة ملف الطفل)
                  if (Get.isRegistered<AppointmentsController>()) {
                    Get.find<AppointmentsController>().fetchUpcoming();
                  }
                  Get.offAllNamed('/appointments');
                },
                child: Text(
                  'View My Appointments',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue.shade700,
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
