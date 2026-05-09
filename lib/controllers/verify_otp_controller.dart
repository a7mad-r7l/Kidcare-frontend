import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/base/base_controller.dart';
import '../core/repos/verify_otp_repo.dart';

class VerifyOtpController extends BaseController {
  final VerifyOtpRepo verifyOtpRepo;

  VerifyOtpController({required this.verifyOtpRepo});

  late final String phoneNumber;

  final otp1 = TextEditingController();
  final otp2 = TextEditingController();
  final otp3 = TextEditingController();
  final otp4 = TextEditingController();

  final f1 = FocusNode();
  final f2 = FocusNode();
  final f3 = FocusNode();
  final f4 = FocusNode();

  // 5-minute validity countdown
  final RxInt validitySeconds = 300.obs;
  // 60-second resend cooldown
  final RxInt resendSeconds = 60.obs;
  final RxBool canResend = false.obs;

  Timer? _validityTimer;
  Timer? _resendTimer;

  @override
  void onInit() {
    super.onInit();
    phoneNumber = Get.arguments as String? ?? '';
    _startValidityTimer();
    _startResendTimer();
  }

  void _startValidityTimer() {
    _validityTimer?.cancel();
    _validityTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (validitySeconds.value > 0) {
        validitySeconds.value--;
      } else {
        t.cancel();
      }
    });
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    canResend.value = false;
    resendSeconds.value = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (resendSeconds.value > 0) {
        resendSeconds.value--;
      } else {
        canResend.value = true;
        t.cancel();
      }
    });
  }

  String get maskedPhone {
    if (phoneNumber.length <= 4) return phoneNumber;
    return '${phoneNumber.substring(0, 4)}${'*' * (phoneNumber.length - 4)}';
  }

  String get validityFormatted => _fmt(validitySeconds.value);
  String get resendFormatted => _fmt(resendSeconds.value);

  String _fmt(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  void onOtpChanged(String val, FocusNode? next, FocusNode? prev) {
    if (val.isNotEmpty && next != null) {
      next.requestFocus();
    } else if (val.isEmpty && prev != null) {
      prev.requestFocus();
    }
  }

  String get _fullOtp =>
      otp1.text + otp2.text + otp3.text + otp4.text;

  Future<void> verifyOtp() async {
    if (_fullOtp.length < 4) {
      handleError('Please enter the 4-digit code');
      return;
    }

    isLoading.value = true;
    try {
      final result = await verifyOtpRepo.verify(
        phone: phoneNumber,
        otp: _fullOtp,
      );

      Get.snackbar(
        'Success',
        result['message'] ?? 'Phone verified successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.offAllNamed('/login');
    } catch (e, s) {
      debugPrint('VerifyOtp Error: $e\n$s');
      handleError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendOtp() async {
    if (!canResend.value) return;

    isLoading.value = true;
    try {
      final result = await verifyOtpRepo.resend(phone: phoneNumber);

      Get.snackbar(
        'Success',
        result['message'] ?? 'Code resent successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      _startResendTimer();
    } catch (e, s) {
      debugPrint('ResendOtp Error: $e\n$s');
      handleError(e);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _validityTimer?.cancel();
    _resendTimer?.cancel();
    otp1.dispose();
    otp2.dispose();
    otp3.dispose();
    otp4.dispose();
    f1.dispose();
    f2.dispose();
    f3.dispose();
    f4.dispose();
    super.onClose();
  }
}
