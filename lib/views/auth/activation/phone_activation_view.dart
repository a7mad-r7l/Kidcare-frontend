import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth/activation_controller.dart';
import '../../../widgets/activation_helpers.dart';
import '../../../widgets/custom_text_field.dart';

class PhoneActivationView extends GetView<ActivationController> {
  const PhoneActivationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const StepProgressIndicator(currentStep: 1),
               ActivationHeader(
                imagePath: 'assets/images/shield_blue_logo.png',
                title: 'Activate Account'.tr,
                subtitle: 'Enter your phone number registered at the clinic'.tr,
              ),

              CustomTextField(
                controller: controller.phoneController,
                hintText: 'phone number'.tr,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 12),
               Align(
                 alignment:AlignmentDirectional.topStart,
                child: Text(
                  " ${'Please enter your registered phone number'.tr}",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 40),
              Obx(
                () => controller.isLoading
                    ? const CircularProgressIndicator()
                    : PrimaryButton(
                        text: 'Send Verification Code'.tr,
                        onPressed: controller.startActivation,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
