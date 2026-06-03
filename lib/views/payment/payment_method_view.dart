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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Finalize Appointment'.tr,
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

              trailingWidget: const Icon(
                Icons.credit_card_outlined,
                color: Color(0xFF1976D2),
                size: 32,
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: controller.proceedToCheckout,
                child: Text(
                  'Confirm & Proceed'.tr,
                  style: TextStyle(
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
      ),
    );
  }
}
