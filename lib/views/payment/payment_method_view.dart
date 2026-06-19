import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/payment_controller.dart';
import '../../widgets/payment_widgets.dart';

class PaymentMethodView extends GetView<PaymentController> {
  const PaymentMethodView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(PaymentController());

    controller.selectedPaymentMethod.value = 2;

    return Scaffold(
      // ❌ تم إزالة backgroundColor ليقرأ خلفية النظام تلقائياً
      appBar: AppBar(
        title: Text(
          'Finalize Appointment'.tr,
          style: TextStyle(
            color: context.textTheme.bodyLarge?.color, // ─── نص متكيف ───
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: context.iconColor), // ─── أيقونة متكيفة ───
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Image.asset(
                'assets/images/wallet_lock_icon.png',
                height: 250,
              ),
            ),
            const SizedBox(height: 40),

            // Pay Online
            PaymentMethodCard(
              title: 'Pay Online Now'.tr,
              subtitle: 'Pay online to confirm booking'.tr,
              value: 2,
              groupValue: 2,
              onTap: () {},
              trailingWidget: Icon(
                Icons.credit_card_outlined,
                color: context.theme.primaryColor, // ─── لون الأيقونة متكيف ───
                size: 32,
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.theme.primaryColor, // ─── اللون الأساسي للزر متكيف ───
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: controller.proceedToCheckout,
                child: Text(
                  'Confirm & Proceed'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white, // يبقى أبيض ليكون بارزاً داخل الزر الأساسي
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}