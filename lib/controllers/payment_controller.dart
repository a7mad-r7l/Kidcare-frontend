import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../core/repos/payment_repo.dart';
import '../../models/appointment_details_model.dart';

class PaymentController extends GetxController {
  final PaymentRepo repo = PaymentRepo();

  var isLoading = false.obs;
  var isDetailsLoading = false.obs;
  var appointmentSummary = Rxn<AppointmentDetailsModel>();
  var transactionId = ''.obs;

  var selectedPaymentMethod = 2.obs;
  var selectedCardMethod = 1.obs;

  void setPaymentMethod(int value) => selectedPaymentMethod.value = value;
  void setCardMethod(int value) => selectedCardMethod.value = value;
  String currentAppointmentId = '';

  @override
  void onInit() {
    super.onInit();
    currentAppointmentId = Get.arguments?.toString() ?? '1';


    loadAppointmentDetails(currentAppointmentId);
  }

  // 1. استدعاء تفاصيل الموعد الـ GET
  Future<void> loadAppointmentDetails(String appointmentId) async {
    isDetailsLoading.value = true;
    try {
      final summary = await repo.fetchAppointmentSummary(appointmentId);
      appointmentSummary.value = summary;
    } catch (e) {
      Get.snackbar('Error Loading Details'.tr, e.toString().replaceAll('Exception:', '').trim());
    } finally {
      isDetailsLoading.value = false;
    }
  }

  void proceedToCheckout() {
    Get.toNamed('/checkout-summary');
  }

  // 2. إرسال طلب   الـ POST والربط مع Stripe
  Future<void> processPayment() async {
    final summary = appointmentSummary.value;
    if (summary == null) {
      Get.snackbar('Error'.tr, 'No appointment data found to process'.tr);
      return;
    }

    isLoading.value = true;
    try {
      // تمرير البيانات  للسيرفر
      final intentModel = await repo.fetchPaymentIntent(currentAppointmentId,  summary.currency);
      final clientSecret = intentModel.clientSecret;
      transactionId.value = intentModel.transactionId;

      // تهيئة نافذة الدفع
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'KidCare Clinic'.tr,
          style: ThemeMode.light,
          billingDetailsCollectionConfiguration: const BillingDetailsCollectionConfiguration(
            address: AddressCollectionMode.never, // إخفاء الرمز البريدي
          ),
        ),
      );
      isLoading.value = false;

      displayPaymentSheet();

    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Payment Error'.tr,
        e.toString().replaceAll('Exception:', '').trim(),
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      isLoading.value = false;
      Get.offAllNamed('/payment-success', arguments:{ 'summary': appointmentSummary.value,
        'transaction_id': transactionId.value,});
    } on StripeException catch (e) {
      isLoading.value = false;
      Get.snackbar('Payment Cancelled'.tr, e.error.message ?? 'User cancelled the payment'.tr);
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('Error'.tr, 'An unexpected error occurred'.tr);
    }
  }
}