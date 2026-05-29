# KidCare Project Code

### File: lib\controllers\appointment\appointment_controller.dart
```dart
import 'package:get/get.dart';

import '../../core/repos/appointment/appointment_repo.dart';
import 'my_appointments_controller.dart';
import '../../core/repos/appointment/doctor_repo.dart';
import '../../models/appointment/appointment_model.dart';
import '../../models/appointment/child_model.dart';
import '../../models/appointment/doctor_model.dart';
import '../base_controller.dart';

/// Cross-screen state for the booking wizard.
///
/// Lives across the 3 booking screens via `Get.put(permanent: true)`
/// on flow entry, and is freed via `Get.delete(force: true)` on exit.
class AppointmentController extends BaseController {
  final AppointmentRepo repo;
  final DoctorRepo doctorRepo;

  AppointmentController({required this.repo, required this.doctorRepo});

  // ---- wizard selection state ----
  final selectedDoctor = Rxn<DoctorModel>();
  final selectedChild = Rxn<ChildModel>();
  final selectedDate = Rxn<DateTime>();
  final selectedTime = RxnString();

  // ---- slots for the picked date ----
  final availableTimes = <String>[].obs;
  final isLoadingSlots = false.obs;

  // ---- doctor's weekly schedule (Dart weekdays: Mon=1..Sun=7) ----
  // Empty = unknown / not loaded yet — calendar shows no red marks.
  final workingWeekdays = <int>{}.obs;

  // ---- result ----
  final bookedAppointment = Rxn<AppointmentModel>();

  // ---- selection setters ----
  void selectDoctor(DoctorModel doctor) => selectedDoctor.value = doctor;
  void selectChild(ChildModel child) => selectedChild.value = child;

  void selectDate(DateTime date) {
    selectedDate.value = date;
    selectedTime.value = null;
    availableTimes.clear();
  }

  void selectTime(String time) => selectedTime.value = time;

  // ---- actions ----

  Future<void> loadDoctorAvailability() async {
    final doctor = selectedDoctor.value;
    workingWeekdays.clear();
    if (doctor == null) return;
    try {
      final availabilities = await doctorRepo.fetchWeeklyAvailability(
        doctor.id,
      );
      final weekdays = availabilities
          .map((a) => _weekdayFromString(a.dayOfWeek))
          .whereType<int>()
          .toSet();
      workingWeekdays.assignAll(weekdays);
    } catch (_) {
      // Silent fail — calendar simply shows no red marks if the call fails.
    }
  }

  Future<void> loadSlots() async {
    final doctor = selectedDoctor.value;
    final date = selectedDate.value;
    if (doctor == null || date == null) return;

    isLoadingSlots.value = true;
    try {
      availableTimes.value = await doctorRepo.fetchSlots(
        doctor.id,
        _formatDate(date),
      );
    } catch (e) {
      handleError(e);
    } finally {
      isLoadingSlots.value = false;
    }
  }

  Future<bool> bookAppointment() async {
    final doctor = selectedDoctor.value;
    final child = selectedChild.value;
    final date = selectedDate.value;
    final time = selectedTime.value;

    if (doctor == null || child == null || date == null || time == null) {
      showInfo('Please complete doctor, child, date, and time selection');
      return false;
    }

    showLoading();
    bool success = false;
    try {
      bookedAppointment.value = await repo.book(
        doctorId: doctor.id,
        childId: child.id,
        date: _formatDate(date),
        time: time,
      );
      success = true;
    } catch (e) {
      handleError(e);
      // The slot is likely stale — drop selection and re-fetch so the
      // now-invalid slot disappears from the grid.
      selectedTime.value = null;
      loadSlots();
    } finally {
      hideLoading();
    }

    return success;
  }

  Future<void> reschedule(int id, {DateTime? date, String? time}) async {
    showLoading();
    try {
      await repo.reschedule(
        id,
        date: date != null ? _formatDate(date) : null,
        time: time,
      );
      Get.back();
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> cancel(int id) async {
    showLoading();
    try {
      await repo.cancel(id);
      // Refresh the listing so the cancelled item disappears immediately.
      if (Get.isRegistered<MyAppointmentsController>()) {
        Get.find<MyAppointmentsController>().loadUpcoming();
      }
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  void resetSelection() {
    selectedDoctor.value = null;
    selectedChild.value = null;
    selectedDate.value = null;
    selectedTime.value = null;
    availableTimes.clear();
    bookedAppointment.value = null;
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  int? _weekdayFromString(String dayOfWeek) {
    switch (dayOfWeek.toLowerCase()) {
      case 'monday':
        return DateTime.monday;
      case 'tuesday':
        return DateTime.tuesday;
      case 'wednesday':
        return DateTime.wednesday;
      case 'thursday':
        return DateTime.thursday;
      case 'friday':
        return DateTime.friday;
      case 'saturday':
        return DateTime.saturday;
      case 'sunday':
        return DateTime.sunday;
      default:
        return null;
    }
  }
}

```

### File: lib\controllers\appointment\child_controller.dart
```dart
import 'package:get/get.dart';
import '../../core/repos/appointment/child_repo.dart';
import '../../models/appointment/child_model.dart';
import '../base_controller.dart';

class ChildController extends BaseController {
  final ChildRepo repo;

  ChildController({required this.repo});

  final children = <ChildModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadChildren();
  }

  Future<void> loadChildren() async {
    showLoading();
    try {
      children.value = await repo.fetchMyChildren();
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }
}

```

### File: lib\controllers\appointment\department_controller.dart
```dart
import 'package:get/get.dart';
import '../../core/repos/appointment/department_repo.dart';
import '../../models/appointment/department_model.dart';
import '../base_controller.dart';

class DepartmentController extends BaseController {
  final DepartmentRepo repo;

  DepartmentController({required this.repo});

  final departments = <DepartmentModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDepartments();
  }

  Future<void> loadDepartments() async {
    showLoading();
    try {
      departments.value = await repo.fetchAll();
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }
}

```

### File: lib\controllers\appointment\doctor_controller.dart
```dart
import 'package:get/get.dart';
import '../../core/repos/appointment/doctor_repo.dart';
import '../../models/appointment/doctor_model.dart';
import '../../models/appointment/doctor_availability_model.dart';
import '../base_controller.dart';

class DoctorController extends BaseController {
  final DoctorRepo repo;

  DoctorController({required this.repo});

  final doctors = <DoctorModel>[].obs;
  final weeklyAvailability = <DoctorAvailabilityModel>[].obs;

  Future<void> loadDoctors(int departmentId) async {
    showLoading();
    try {
      doctors.value = await repo.fetchByDepartment(departmentId);
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> loadWeeklyAvailability(int doctorId) async {
    try {
      weeklyAvailability.value = await repo.fetchWeeklyAvailability(doctorId);
    } catch (e) {
      handleError(e);
    }
  }
}

```

### File: lib\controllers\appointment\my_appointments_controller.dart
```dart
import 'package:get/get.dart';
import '../../core/repos/appointment/appointment_repo.dart';
import '../../core/repos/appointment/child_repo.dart';
import '../../core/repos/appointment/doctor_repo.dart';
import '../../models/appointment/appointment_model.dart';
import '../base_controller.dart';

class MyAppointmentsController extends BaseController {
  final AppointmentRepo repo;
  final DoctorRepo doctorRepo;
  final ChildRepo childRepo;

  MyAppointmentsController({
    required this.repo,
    required this.doctorRepo,
    required this.childRepo,
  });

  final all = <AppointmentModel>[].obs;
  final upcoming = <AppointmentModel>[].obs;
  final past = <AppointmentModel>[].obs;
  final selected = Rxn<AppointmentModel>();

  // id → name caches — populated lazily, reused across tab switches.
  final _doctorNameCache = <int, String>{};
  final _childNameCache = <int, String>{};

  Future<void> loadAll() async {
    showLoading();
    try {
      all.value = await _enrich(await repo.listAll());
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> loadUpcoming() async {
    showLoading();
    try {
      upcoming.value = await _enrich(await repo.listUpcoming());
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> loadPast() async {
    showLoading();
    try {
      past.value = await _enrich(await repo.listPast());
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> loadUpcomingForChild(int childId) async {
    showLoading();
    try {
      upcoming.value = await _enrich(await repo.listUpcomingForChild(childId));
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> loadPastForChild(int childId) async {
    showLoading();
    try {
      past.value = await _enrich(await repo.listPastForChild(childId));
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> loadOne(int id) async {
    showLoading();
    try {
      final list = await _enrich([await repo.fetchOne(id)]);
      selected.value = list.first;
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  // Resolves doctor + child names for a list of appointments.
  // Fetches only doctor IDs not already in the cache; child names come from
  // ChildController which is always alive alongside this controller.
  Future<List<AppointmentModel>> _enrich(List<AppointmentModel> items) async {
    if (items.isEmpty) return items;

    final missingDoctorIds = items
        .map((a) => a.doctorId)
        .toSet()
        .where((id) => !_doctorNameCache.containsKey(id))
        .toList();

    await Future.wait(
      missingDoctorIds.map((id) async {
        try {
          final doctor = await doctorRepo.fetchById(id);
          _doctorNameCache[id] = doctor.fullName;
        } catch (_) {
          _doctorNameCache[id] = 'Doctor #$id';
        }
      }),
    );

    final missingChildIds = items
        .map((a) => a.childId)
        .toSet()
        .where((id) => !_childNameCache.containsKey(id))
        .toList();

    if (missingChildIds.isNotEmpty) {
      try {
        final children = await childRepo.fetchMyChildren();
        for (final c in children) {
          _childNameCache[c.id] = c.fullName;
        }
      } catch (_) {}
      // Any ID still missing after the fetch gets a fallback below.
    }

    return items.map((a) {
      return a.withNames(
        doctorName: _doctorNameCache[a.doctorId],
        childName: _childNameCache[a.childId] ?? 'Child #${a.childId}',
      );
    }).toList();
  }
}

```

### File: lib\controllers\auth\activation_controller.dart
```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/repos/auth/activation_repo.dart';
import '../base_controller.dart';

class ActivationController extends BaseController {
  final ActivationRepo repo = ActivationRepo();

  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  var isPasswordHidden = true.obs;


  var secondsRemaining = 45.obs;
  Timer? _timer;

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }


  void startTimer() {
    secondsRemaining.value = 45;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining.value > 0) {
        secondsRemaining.value--;
      } else {
        timer.cancel();
      }
    });
  }

  // 1. طلب OTP والانتقال للواجهة الثانية
  Future<void> startActivation() async {
    String phone = phoneController.text.trim();
    if (phone.isEmpty || phone.length != 12) {
      Get.snackbar(
        "Notice",
        phone.isEmpty
            ? "Please enter phone number"
            : "Phone number must be 12 numbers (e.g., 9639XXXXXXXX)",
        backgroundColor: Colors.grey.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 2),
      );
      return;
    }
    showLoading();
    try {
      await repo.requestOtp(phoneController.text.trim());
      startTimer();
      Get.toNamed('/activation-otp');
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }


  Future<void> resendOtp() async {
    showLoading();
    try {
      await repo.requestOtp(phoneController.text.trim());
      startTimer();
      Get.snackbar(
        "Success",
        "Verification code resent successfully",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  // 2. التحقق من الرمز عبر السيرفر والانتقال للواجهة الثالثة
  Future<void> verifyOtp() async {
    String otp = otpController.text.trim();
    if (otp.isEmpty || otp.length != 4) {
      Get.snackbar(
        "Check Code",
        otp.isEmpty
            ? "Please enter OTP"
            : "Please enter the 4-digit code correctly",
        backgroundColor: Colors.grey.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 2),
      );
      return;
    }
    showLoading();
    try {
      await repo.verifyOtp(
        phoneController.text.trim(),
        otpController.text.trim(),
      );
      _timer?.cancel();
      Get.toNamed('/set-password');
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  // 3. إرسال كلمة المرور للتفعيل والدخول
  Future<void> completeActivation() async {
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;

    // 1. التحقق من الحقول الفارغة
    if (password.isEmpty || confirmPassword.isEmpty) {
      Get.snackbar(
        "Required Fields",
        "Please fill in all fields",
        backgroundColor: Colors.grey.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
      );
      return;
    }

    // 2. التحقق من تطابق كلمتي المرور
    if (password != confirmPassword) {
      Get.snackbar(
        "Error",
        "Passwords do not match",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    // 3. التحقق من طول كلمة المرور
    if (password.length < 8) {
      Get.snackbar(
        "Weak Password",
        "Password must be at least 8 characters long",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        icon: const Icon(Icons.lock_outline, color: Colors.white),
      );
      return;
    }
    showLoading();
    try {
      await repo.activateAndLogin(
        phoneController.text.trim(),
        passwordController.text,
      );

      Get.snackbar(
        "Success",
        "Account activated successfully",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // التوجه للصفحة الرئيسية بعد التفعيل
      // Get.offAllNamed('/home');
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }
}
```

### File: lib\controllers\auth\forgot_password_controller.dart
```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/repos/auth/activation_repo.dart';
import '../base_controller.dart';

class ForgotPasswordController extends BaseController {
  final ActivationRepo repo = ActivationRepo();

  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  var isPasswordVisible = false.obs;
  var isConfirmVisible = false.obs;

  var secondsRemaining = 45.obs;
  Timer? _timer;

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void startTimer() {
    secondsRemaining.value = 45;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining.value > 0) {
        secondsRemaining.value--;
      } else {
        timer.cancel();
      }
    });
  }

  // 1. إرسال رمز التحقق
  Future<void> sendCode() async {
    String phone = phoneController.text.trim();
    if (phone.isEmpty || phone.length < 9) {
      Get.snackbar(
        "Notice",
        "Please enter a valid phone number",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    showLoading();
    try {
      await repo.requestOtp(phone);
      startTimer();
      Get.toNamed('/forgot-otp');
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  // 2. التحقق من رمز OTP
  Future<void> verifyCode() async {
    String otp = otpController.text.trim();
    if (otp.length != 4) {
      Get.snackbar(
        "Notice",
        "Please enter the 4-digit code",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    showLoading();
    try {
      await repo.verifyOtp(phoneController.text.trim(), otp);
      _timer?.cancel();
      Get.toNamed('/reset-password');
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  // 3. تحديث كلمة المرور
  Future<void> updatePassword() async {
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;

    if (password.length < 8) {
      Get.snackbar(
        "Weak Password",
        "Password must be at least 8 characters long",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    if (password != confirmPassword) {
      Get.snackbar(
        "Error",
        "Passwords do not match",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    showLoading();
    try {
      await repo.activateAndLogin(phoneController.text.trim(), password);

      Get.offAllNamed('/success-reset');
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }
}

```

### File: lib\controllers\auth\login_controller.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/repos/auth/login_repo.dart';
import '../base_controller.dart';

class LoginController extends BaseController {
  final LoginRepo loginRepo;

  // تمرير الـ Repo عبر الـ Constructor
  LoginController({required this.loginRepo});

  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  final isPasswordHidden = true.obs;

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  Future<void> login() async {
    String phone = phoneController.text.trim();
    if (phoneController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar(
        "Required Fields",
        "Please fill in all fields",
        backgroundColor: Colors.grey.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    // 2. التحقق من طول رقم الهاتف
    if (phone.length != 12) {
      Get.snackbar(
        "Invalid Phone Number",
        "Phone number must be exactly 12 numbers (e.g., 9639XXXXXXXX)",
        backgroundColor: Colors.grey.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    showLoading();
    try {
      final user = await loginRepo.loginUser(
        phoneController.text.trim(),
        passwordController.text.trim(),
      );

      Get.snackbar(
        "Success",
        "Welcome Back, ${user.firstName}!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.offAllNamed('/home');
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  @override
  void onClose() {
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}

```

### File: lib\controllers\auth\sign_up_controller.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/repos/auth/sign_up_repo.dart';
import '../base_controller.dart';

class SignUpController extends BaseController {
  final SignUpRepo signUpRepo;

  SignUpController({required this.signUpRepo});

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final RxBool isPasswordHidden = true.obs;
  final RxBool isConfirmPasswordHidden = true.obs;

  void togglePassword() => isPasswordHidden.value = !isPasswordHidden.value;

  void toggleConfirmPassword() =>
      isConfirmPasswordHidden.value = !isConfirmPasswordHidden.value;

  Future<void> signUp() async {
    String phone = phoneController.text.trim();

    // 1. التحقق من الحقول الفارغة
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phone.isEmpty ||
        addressController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      Get.snackbar(
        'Required Fields',
        'Please fill in all fields',
        backgroundColor: Colors.grey.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // 2. التحقق من طول رقم الهاتف
    if (phone.length != 12) {
      Get.snackbar(
        'Invalid Phone Number',
        'Phone number must be exactly 12 numbers (e.g., 9639XXXXXXXX)',
        backgroundColor: Colors.grey.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // 3. التحقق من تطابق كلمتي المرور
    if (passwordController.text != confirmPasswordController.text) {
      Get.snackbar(
        'Error',
        'Passwords do not match',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // 4. التحقق من طول كلمة المرور
    if (passwordController.text.length < 8) {
      Get.snackbar(
        'Weak Password',
        'Password must be at least 8 characters long',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
        icon: const Icon(Icons.lock_outline, color: Colors.white),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    showLoading();
    try {
      final result = await signUpRepo.registerUser(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        phone: phone,
        address: addressController.text.trim(),
        password: passwordController.text.trim(),
      );

      Get.snackbar(
        'Success',
        result.message,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
      );

      Get.toNamed('/verify-otp', arguments: result.phoneNumber);
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}

```

### File: lib\controllers\auth\verify_otp_controller.dart
```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../base_controller.dart';
import '../../core/repos/auth/verify_otp_repo.dart';

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

  final RxInt validitySeconds = 300.obs;
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

  String get _fullOtp => otp1.text + otp2.text + otp3.text + otp4.text;

  Future<void> verifyOtp() async {
    // Client-Side Validation
    if (_fullOtp.isEmpty) {
      Get.snackbar(
        'Required',
        'Please enter the verification code',
        backgroundColor: Colors.grey.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (_fullOtp.length < 4) {
      Get.snackbar(
        'Invalid Code',
        'Please enter the complete 4-digit code',
        backgroundColor: Colors.grey.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    showLoading();
    try {
      await verifyOtpRepo.verify(phone: phoneNumber, otp: _fullOtp);

      Get.snackbar(
        'Success',
        'Phone verified successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
      );

      Get.offAllNamed('/home');
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> resendOtp() async {
    if (!canResend.value) return;

    showLoading();
    try {
      await verifyOtpRepo.resend(phone: phoneNumber);

      Get.snackbar(
        'Success',
        'Code resent successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
      );

      _startResendTimer();
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
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
```

### File: lib\controllers\base_controller.dart
```dart
import 'dart:convert';

import 'package:get/get.dart';
import 'package:flutter/material.dart';

class BaseController extends GetxController {
  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  void showLoading() => _isLoading.value = true;
  void hideLoading() => _isLoading.value = false;

  void handleError(dynamic e) {
    hideLoading();

    final errorString = e.toString();
    String message = "Something went wrong. Please try again.";

    try {
      if (errorString.contains("401")) {
        // 401 means either wrong login credentials OR an expired session token.
        // The screen that triggered the request knows which it is — here we
        // just show a generic message and let the caller decide whether to
        // navigate. (Navigating from inside handleError disposes the current
        // screen's TextEditingControllers mid-frame and crashes the build.)
        message = "Incorrect phone number or password.";
      } else if (errorString.contains('{') && errorString.contains('}')) {
        final startIndex = errorString.indexOf('{');
        final endIndex = errorString.lastIndexOf('}') + 1;
        final jsonPart = errorString.substring(startIndex, endIndex);
        final decoded = jsonDecode(jsonPart);
        if (decoded['message'] != null) {
          message = decoded['message'];
        }
      } else if (errorString.contains("Exception:")) {
        message = errorString.split("Exception:").last.trim();
      } else if (errorString.contains("SocketException")) {
        message = "No Internet connection. Please check your network.";
      } else if (errorString.contains("TimeoutException")) {
        message = "Request timed out. Please try again.";
      }
    } catch (_) {
      // JSON parse failed — fall through to the generic message above.
    }

    Get.snackbar(
      "Error",
      message,
      backgroundColor: Colors.red.shade800,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(15),
      icon: const Icon(Icons.error_outline, color: Colors.white),
      duration: const Duration(seconds: 4),
    );
  }

  void showSuccess(String message) {
    Get.snackbar(
      "Success",
      message,
      backgroundColor: Colors.green.shade700,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(15),
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }

  void showInfo(String message) {
    Get.snackbar(
      "Info",
      message,
      backgroundColor: Colors.grey.shade700,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(15),
      duration: const Duration(seconds: 3),
    );
  }
}
```

### File: lib\controllers\home\add_child_controller.dart
```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/repos/home/add_child_repo.dart';
import '../base_controller.dart';


class AddChildController extends BaseController {
  final AddChildRepo addChildRepo;

  AddChildController({required this.addChildRepo});

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final medicalHistoryController = TextEditingController();
  final allergiesController = TextEditingController();

  final RxString selectedGender = 'male'.obs;
  final RxString selectedBloodType = ''.obs;
  final RxString selectedBirthDate = ''.obs;

  // ✅ الصورة المختارة
  final Rx<File?> selectedImage = Rx<File?>(null);

  final List<String> bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  void selectGender(String gender) => selectedGender.value = gender;
  Future<void> deleteChild(int childId) async {
    showLoading();
    try {
      await addChildRepo.deleteChild(childId);

      Get.snackbar(
        'Success',
        'Child deleted successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
      );

      await Future.delayed(const Duration(seconds: 1));
      Get.offAllNamed('/home'); // ✅ العودة للـ home بعد الحذف
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  // ✅ فتح الـ Gallery
  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      selectedImage.value = File(image.path);
    }
  }

  Future<void> pickBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2020),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      selectedBirthDate.value =
      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> addChild() async {
    if (firstNameController.text.isEmpty || lastNameController.text.isEmpty) {
      Get.snackbar(
        'Required Fields',
        'Please enter first and last name',
        backgroundColor: Colors.grey.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (selectedBirthDate.value.isEmpty) {
      Get.snackbar(
        'Required Fields',
        'Please select birth date',
        backgroundColor: Colors.grey.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (selectedBloodType.value.isEmpty) {
      Get.snackbar(
        'Required Fields',
        'Please select blood type',
        backgroundColor: Colors.grey.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    showLoading();
    try {
      await addChildRepo.addChild(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        gender: selectedGender.value,
        birthDate: selectedBirthDate.value,
        bloodType: selectedBloodType.value,
        medicalHistory: medicalHistoryController.text.trim(),
        allergies: allergiesController.text.trim(),
        image: selectedImage.value, // ✅
      );

      Get.snackbar(
        'Success',
        'Child added successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
      );
      await Future.delayed(const Duration(seconds: 1));
      Get.back();
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    medicalHistoryController.dispose();
    allergiesController.dispose();
    super.onClose();
  }
}
```

### File: lib\controllers\home\appointments_controller.dart
```dart
import 'package:get/get.dart';
import '../../core/repos/home/appointments_repo.dart';
import '../../models/appointment/appointment_model.dart';
import '../base_controller.dart';


class AppointmentsController extends BaseController {
  final AppointmentsRepo appointmentsRepo;

  AppointmentsController({required this.appointmentsRepo});

  late final int childId;

  final RxList<AppointmentModel> upcoming = <AppointmentModel>[].obs;
  final RxList<AppointmentModel> past = <AppointmentModel>[].obs;
  final RxBool showUpcoming = true.obs;

  @override
  void onInit() {
    super.onInit();
    childId = Get.arguments as int;
    fetchUpcoming();
  }

  void switchTab(bool isUpcoming) {
    showUpcoming.value = isUpcoming;
    if (isUpcoming && upcoming.isEmpty) {
      fetchUpcoming();
    } else if (!isUpcoming && past.isEmpty) {
      fetchPast();
    }
  }

  Future<void> fetchUpcoming() async {
    showLoading();
    try {
      final result = await appointmentsRepo.getUpcoming(childId);
      upcoming.assignAll(result);
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> fetchPast() async {
    showLoading();
    try {
      final result = await appointmentsRepo.getPast(childId);
      past.assignAll(result);
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }
}
```

### File: lib\controllers\home\home_controller.dart
```dart
import 'package:get/get.dart';
import '../../core/repos/home/home_children_repo.dart';
import '../../core/repos/home/parent_name_repo.dart';
import '../../models/home/home_child_model.dart';
import '../base_controller.dart';


class HomeController extends BaseController {
  final HomeChildrenRepo homeChildrenRepo;
  final ParentNameRepo parentNameRepo;

  HomeController({
    required this.homeChildrenRepo,
    required this.parentNameRepo,
  });

  final RxList<HomeChildModel> children = <HomeChildModel>[].obs;

  // ✅ اسم المستخدم
  final RxString parentName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchChildren();
    fetchParentName();
  }

  Future<void> fetchChildren() async {
    showLoading();
    try {
      final result = await homeChildrenRepo.getChildren();
      children.assignAll(result);
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> fetchParentName() async {
    try {
      final name = await parentNameRepo.getParentName();
      parentName.value = name;
    } catch (e) {
      handleError(e);
    }
  }
}
```

### File: lib\controllers\home\profile_controller.dart
```dart
import 'package:get/get.dart';

import '../../core/helper/secure_storage_service.dart';
import '../../core/repos/home/profile_repo.dart';
import '../../models/home/profile_model.dart';
import '../base_controller.dart';


class ProfileController extends BaseController {
  final ProfileRepo profileRepo;

  ProfileController({required this.profileRepo});

  final Rx<ProfileModel?> profile = Rx<ProfileModel?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    showLoading();
    try {
      final result = await profileRepo.getProfile();
      profile.value = result;
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> logout() async {
    await SecureStorage.removeToken();
    Get.offAllNamed('/login');
  }
}
```

### File: lib\controllers\payment_controller.dart
```dart
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

  var selectedPaymentMethod = 2.obs;
  var selectedCardMethod = 1.obs;

  void setPaymentMethod(int value) => selectedPaymentMethod.value = value;
  void setCardMethod(int value) => selectedCardMethod.value = value;

  @override
  void onInit() {
    super.onInit();


    loadAppointmentDetails('1');
  }

  // 1. استدعاء تفاصيل الموعد الـ GET
  Future<void> loadAppointmentDetails(String appointmentId) async {
    isDetailsLoading.value = true;
    try {
      final summary = await repo.fetchAppointmentSummary(appointmentId);
      appointmentSummary.value = summary;
    } catch (e) {
      Get.snackbar('Error Loading Details', e.toString().replaceAll('Exception:', '').trim());
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
      Get.snackbar('Error', 'No appointment data found to process');
      return;
    }

    isLoading.value = true;
    try {
      // تمرير البيانات  للسيرفر
      final intentModel = await repo.fetchPaymentIntent('1',  summary.currency);
      final clientSecret = intentModel.clientSecret;

      // تهيئة نافذة الدفع
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'KidCare Clinic',
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
        'Payment Error',
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
      Get.offAllNamed('/payment-success');
    } on StripeException catch (e) {
      isLoading.value = false;
      Get.snackbar('Payment Cancelled', e.error.message ?? 'User cancelled the payment');
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('Error', 'An unexpected error occurred');
    }
  }
}
```

### File: lib\controllers\settings_controller.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/helper/secure_storage_service.dart';

class SettingsController extends GetxController {
  var currentLanguage = 'en'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    String? savedLang = await SecureStorage.getLanguage();
    if (savedLang != null) {
      currentLanguage.value = savedLang;
    }
  }

  Future<void> changeLanguage(String langCode) async {
    if (currentLanguage.value == langCode) return;

    currentLanguage.value = langCode;
    await SecureStorage.storeLanguage(langCode);

    Locale newLocale = langCode == 'ar'
        ? const Locale('ar', 'SA')
        : const Locale('en', 'US');
    Get.updateLocale(newLocale);
  }
}

```

### File: lib\core\apis\appointment\appointment_api.dart
```dart
import 'package:http/http.dart' as http;
import '../../constants.dart';

class AppointmentApi {
  final http.Client client = http.Client();

  Future<String> create(String token, Map<String, dynamic> body) async {
    final response = await client.post(
      Uri.parse('$baseUrl/appointment'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body.map((k, v) => MapEntry(k, v.toString())),
    );
    return response.body;
  }

  Future<String> listAll(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/appointments'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.body;
  }

  Future<String> listUpcoming(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/appointments/upcoming'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.body;
  }

  Future<String> listPast(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/appointments/past'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.body;
  }

  Future<String> listUpcomingForChild(String token, int childId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/appointments/upcoming/$childId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.body;
  }

  Future<String> listPastForChild(String token, int childId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/appointments/past/$childId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.body;
  }

  Future<String> getById(String token, int appointmentId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/appointments/$appointmentId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.body;
  }

  Future<String> update(
    String token,
    int appointmentId,
    Map<String, dynamic> body,
  ) async {
    final response = await client.put(
      Uri.parse('$baseUrl/appointments/$appointmentId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body.map((k, v) => MapEntry(k, v.toString())),
    );
    return response.body;
  }

  Future<String> delete(String token, int appointmentId) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/appointments/$appointmentId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.body;
  }
}

```

### File: lib\core\apis\appointment\child_api.dart
```dart
import 'package:http/http.dart' as http;
import '../../constants.dart';

class ChildApi {
  final http.Client client = http.Client();

  Future<String> getMine(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/children'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.body;
  }
}

```

### File: lib\core\apis\appointment\department_api.dart
```dart
import 'package:http/http.dart' as http;
import '../../constants.dart';

class DepartmentApi {
  final http.Client client = http.Client();

  Future<String> getAll(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/departments'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.body;
  }
}

```

### File: lib\core\apis\appointment\doctor_api.dart
```dart
import 'package:http/http.dart' as http;
import '../../constants.dart';

class DoctorApi {
  final http.Client client = http.Client();

  Future<String> getByDepartment(String token, int departmentId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/departments/$departmentId/doctors'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.body;
  }

  Future<String> getById(String token, int doctorId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/doctors/$doctorId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.body;
  }

  Future<String> getAvailabilities(String token, int doctorId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/doctors/$doctorId/availabilities'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.body;
  }

  Future<String> getAvailableTimes(
    String token,
    int doctorId,
    String date,
  ) async {
    final response = await client.post(
      Uri.parse('$baseUrl/doctors/$doctorId/available-times'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {'date': date},
    );
    return response.body;
  }
}

```

### File: lib\core\apis\auth\activation_api.dart
```dart
import 'package:http/http.dart' as http;
import '../../constants.dart';


class ActivationApi {
  final http.Client client = http.Client();

  // 1. طلب إرسال رمز OTP
  Future<String> sendOtp(String phoneNumber) async {
    final response = await client.post(
      Uri.parse("$baseUrl/sendOtp"),
      headers: {"Accept": "application/json"},
      body: {"phone_number": phoneNumber},
    );
    return response.body;
  }

  // 2. التحقق من الرمز
  Future<String> verifyOtp(String phoneNumber, String otp) async {
    final response = await client.post(
      Uri.parse("$baseUrl/verifyOtp"),
      headers: {"Accept": "application/json"},
      body: {
        "phone_number": phoneNumber,
        "otp": otp
      },
    );
    return response.body;
  }

  // 3. تعيين كلمة المرور
  Future<String> setPassword(String phoneNumber, String password) async {
    final response = await client.post(
      Uri.parse("$baseUrl/SetPassword"),
      headers: {"Accept": "application/json"},
      body: {
        "phone_number": phoneNumber,
        "password": password,
        "password_confirmation": password
      },
    );
    return response.body;
  }
}
```

### File: lib\core\apis\auth\login_api.dart
```dart
import 'dart:async';
import 'package:http/http.dart' as http;

import '../../constants.dart';

class LoginApi {
  Future<String> login(String phoneNumber, String password) async {
    try {
      var response = await http.post(
            Uri.parse("$baseUrl/login"),
            headers: {"Accept": "application/json"},
            body: {"phone_number": phoneNumber, "password": password},
          ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception("Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      rethrow;
    }
  }
}

```

### File: lib\core\apis\auth\sign_up_api.dart
```dart
import 'package:http/http.dart' as http;
import '../../constants.dart';

class SignUpApi {
  final http.Client client = http.Client();

  Future<String> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String address,
    required String password,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Accept': 'application/json',
      },
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone_number': phone,
        'address': address,
        'password': password,
        'password_confirmation': password,
      },
    );

    // ✅ API مسؤولة فقط عن إرجاع الرد كـ String
    return response.body;
  }
}
```

### File: lib\core\apis\auth\verify_otp_api.dart
```dart

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../constants.dart';

class VerifyOtpApi {
  final http.Client client = http.Client();

  // مهمة الدالة فقط إرسال البيانات وإرجاع الرد كـ String
  Future<String> verify({
    required String phone,
    required String otp,
  }) async {
    debugPrint('── VerifyOtpApi.verify ─────────────────');
    debugPrint('phone=$phone | otp=$otp');

    final response = await client.post(
      Uri.parse('$baseUrl/verifyOtp'),
      headers: {'Accept': 'application/json'},
      body: {'phone_number': phone, 'otp': otp},
    );

    debugPrint('Status: ${response.statusCode} | Body: ${response.body}');
    return response.body;
  }

  Future<String> resend({required String phone}) async {
    debugPrint('── VerifyOtpApi.resend ─────────────────');

    final response = await client.post(
      Uri.parse('$baseUrl/sendOtp'),
      headers: {'Accept': 'application/json'},
      body: {'phone_number': phone},
    );

    debugPrint('Status: ${response.statusCode} | Body: ${response.body}');
    return response.body;
  }
}
```

### File: lib\core\apis\home\add_child_api.dart
```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../constants.dart';
import '../../helper/secure_storage_service.dart';


class AddChildApi {

  Future<String> deleteChild(int childId) async {
    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Session expired. Please login again.');
    }

    // ✅ استخدام http.delete مباشرة بدل client.delete
    final response = await http.delete(
      Uri.parse('$baseUrl/children/$childId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('── Delete Status: ${response.statusCode}');
    debugPrint('── Delete Body: ${response.body}');

    return response.body;
  }

  Future<String> addChild({
    required String firstName,
    required String lastName,
    required String gender,
    required String birthDate,
    required String bloodType,
    required String medicalHistory,
    required String allergies,
    File? image,
  }) async {
    final token = await SecureStorage.getToken();
    debugPrint('── Token: $token');

    if (token == null || token.isEmpty) {
      throw Exception('Session expired. Please login again.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/children?token=$token'),
    );

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    request.fields['first_name'] = firstName;
    request.fields['last_name'] = lastName;
    request.fields['gender'] = gender;
    request.fields['birth_date'] = birthDate;
    request.fields['blood_type'] = bloodType;
    request.fields['medical_history'] = medicalHistory;
    request.fields['allergies'] = allergies;

    if (image != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', image.path),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('── Status: ${response.statusCode}');
    debugPrint('── Body: ${response.body}');

    return response.body;
  }
}

```

### File: lib\core\apis\home\appoimtments_api.dart
```dart
import 'package:http/http.dart' as http;
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';



class AppointmentsApi {
  final http.Client client = http.Client();

  Future<String> getUpcoming(int childId) async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) throw Exception('Session expired. Please login again.');

    final response = await client.get(
      Uri.parse('$baseUrl/appointments/upcoming/$childId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.body;
  }

  Future<String> getPast(int childId) async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) throw Exception('Session expired. Please login again.');

    final response = await client.get(
      Uri.parse('$baseUrl/appointments/past/$childId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.body;
  }
}

```

### File: lib\core\apis\home\home_children_api.dart
```dart
import 'package:http/http.dart' as http;

import '../../constants.dart';
import '../../helper/secure_storage_service.dart';


class HomeChildrenApi {
  final http.Client client = http.Client();

  Future<String> getChildren() async {
    final token = await SecureStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Session expired. Please login again.');
    }

    final response = await client.get(
      Uri.parse('$baseUrl/home-children'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return response.body;
  }
}

```

### File: lib\core\apis\home\parent_name_api.dart
```dart
import 'package:http/http.dart' as http;

import '../../constants.dart';
import '../../helper/secure_storage_service.dart';


class ParentNameApi {
  final http.Client client = http.Client();

  Future<String> getParentName() async {
    final token = await SecureStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Session expired. Please login again.');
    }

    final response = await client.get(
      Uri.parse('$baseUrl/parentName'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return response.body;
  }
}

```

### File: lib\core\apis\home\profile_api.dart
```dart
import 'package:http/http.dart' as http;

import '../../constants.dart';
import '../../helper/secure_storage_service.dart';


class ProfileApi {
  final http.Client client = http.Client();

  Future<String> getProfile() async {
    final token = await SecureStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Session expired. Please login again.');
    }

    final response = await client.get(
      Uri.parse('$baseUrl/parentProfile'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return response.body;
  }
}

```

### File: lib\core\apis\payment_api.dart
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants.dart';

class PaymentApi {
  // 1.   تفاصيل الموعد
  Future<String> getAppointmentSummary(
    String token,
    String appointmentId,
  ) async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/appointments/$appointmentId/summary'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return response.body;
      } else {
        var errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to load appointment details',
        );
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 2.  طلب الدفع
  Future<String> createPaymentIntent(
    String token,
    String appointmentId,
    String currency,
  ) async {
    try {
      Map<String, dynamic> body = {
        'appointment_id': appointmentId,
        'currency': currency.toLowerCase(),
      };

      var response = await http.post(
        Uri.parse('$baseUrl/payment/checkout'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.body;
      } else {
        var errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to initialize payment from server',
        );
      }
    } catch (err) {
      throw Exception(err.toString());
    }
  }
}

```

### File: lib\core\booking_theme.dart
```dart
import 'package:flutter/material.dart';

const kBookingPrimary = Color(0xFF3B82F6);
const kBookingBackground = Color(0xFFF5F7FB);
const kBookingTextPrimary = Color(0xFF1F2937);
const kBookingTextSecondary = Color(0xFF6B7280);
const kBookingBorder = Color(0xFFE5E7EB);
const kBookingAvatarTint = Color(0xFFEFF6FF);

```

### File: lib\core\constants.dart
```dart
const String baseUrl = 'http://10.49.66.70:8000/api';

String token = '';
```

### File: lib\core\helper\json_utils.dart
```dart
/// Defensive JSON value converters.
///
/// Laravel can serialize integers and decimals as strings depending on column
/// type and Resource setup. These helpers tolerate either form so model
/// parsing never throws a TypeError just because `id` came back as `"17"`
/// instead of `17`.
int toIntSafe(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

num toNumSafe(dynamic v, [num fallback = 0]) {
  if (v is num) return v;
  if (v is String) return num.tryParse(v) ?? fallback;
  return fallback;
}

double? toDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

bool toBoolSafe(dynamic v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final lower = v.toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
  }
  return fallback;
}

```

### File: lib\core\helper\secure_storage_service.dart
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';

const secureStorage = FlutterSecureStorage();

class SecureStorage {
  static Future<void> removeAll() async {
    await secureStorage.delete(key: 'token');
    token = '';
    await secureStorage.delete(key: 'refreshToken');
    await secureStorage.delete(key: 'email');
  }

  static Future<void> storeToken(String token) async {
    await secureStorage.write(key: 'token', value: token);
  }

  static Future<String> getToken() async {
    return await secureStorage.read(key: 'token') ?? '';
  }

  static Future<void> removeToken() async {
    await secureStorage.delete(key: 'token');
  }

  static Future<void> storeRefreshToken(String token) async {
    await secureStorage.write(key: 'refreshToken', value: token);
  }

  static Future<String> getRefreshToken() async {
    return await secureStorage.read(key: 'refreshToken') ?? '';
  }

  static Future<void> removeRefreshToken() async {
    await secureStorage.delete(key: 'refreshToken');
  }

  // حفظ كود اللغة ('en' أو 'ar')
  static Future<void> storeLanguage(String langCode) async {
    await secureStorage.write(key: 'language', value: langCode);
  }

  // استرجاع كود اللغة
  static Future<String?> getLanguage() async {
    return await secureStorage.read(key: 'language');
  }
}

```

### File: lib\core\localization\app_translations.dart
```dart
import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    // ==========================================================
    // 1. ENGLISH LOCALE (en_US)
    // ==========================================================
    'en_US': {
      // --- General ---
      'app_name': 'KidCare',
      'back': 'Back',
      'next': 'Next',
      'or': 'Or',
      'verify': 'Verify',

      // --- Login View ---
      'welcome_back': 'Welcome Back',
      'phone_number': 'Phone Number',
      'password': 'Password',
      'forgot_password_link': 'Forgot Password?',
      'login_btn': 'Login',
      'create_new_account': 'Create New Account',
      'have_clinic_file': 'Have a clinic file? ',
      'activate_account': 'Activate account',

      // --- Sign Up View ---
      'create_account_title': 'Create New Account',
      'create_account_subtitle': 'Create your account to benefit from our services',
      'enter_name': 'Enter your name',
      'name': 'Name',
      'enter_last_name': 'Enter your last name',
      'last_name': 'Last Name',
      'enter_email': 'Enter your email',
      'email': 'Email',
      'enter_phone': 'Enter your phone number',
      'phone': 'Phone',
      'enter_address': 'Enter your address in detail',
      'address': 'Address',
      'enter_password': 'Enter your password',
      'password_condition': 'At least 8 characters with uppercase, lowercase and a number',
      'enter_password_again': 'Enter your password again',
      'confirm_password': 'Confirm Password',
      'create_account_btn': 'Create Account',
      'already_have_account': 'Already have an account?',

      // --- Forgot Password & OTP ---
      'forgot_password_title': 'Forgot Password?',
      'forgot_password_desc': 'Don\'t worry, enter your phone number associated with your account and we will send you a verification code.',
      'send_verification_code': 'Send Verification Code',
      'verify_phone_title': 'Verify Phone Number',
      'code_sent_to': 'We have sent a 4-digit verification code to',
      'didnt_receive_code': 'Didn\'t receive the code?',
      'resend_code': 'Resend Code',
      'resend_in': 'Resend in',
      'create_new_password_title': 'Create New Password',
      'new_password_unique': 'Your new password must be new and unique',
      'new_password': 'New Password',
      'update_password': 'Update Password',
      'password_updated': 'Password Updated Successfully!',
      'login_with_new_password': 'You can now log in with your new password.',
      'go_to_login': 'Go to Login',
      'code_valid_for': 'The code is valid for ',
      'minutes': ' minutes',
      'resend_after_countdown': 'You can resend the code after the countdown ends',
      'change_phone_number': 'Change Phone Number',

      // --- Activation ---
      'activate_account_title': 'Activate Account',
      'enter_registered_phone': 'Enter your phone number registered at the clinic',
      'please_enter_registered_phone': 'Please enter your registered phone number',
      'verify_and_activate': 'Verify and Activate Account',
      'create_strong_password': 'Create a strong password to protect your account',
      'password_must_contain': 'Password must contain:',
      'at_least_8_chars': 'At least 8 characters',
      'set_password_and_login': 'Set Password and Login',

      // --- Home & Navigation ---
      'home_tab': 'Home',
      'appointments_tab': 'Appointments',
      'records_tab': 'Records',
      'more_tab': 'More',
      'welcome_user': 'Welcome back!',
      'book_new_appointment': 'Book New Appointment',
      'upcoming_appointments': 'Upcoming Appointments',
      'status_confirmed': 'Confirmed',
      'quick_services': 'Quick Services',
      'follow_up': 'Follow-up',
      'prescriptions': 'Prescriptions',
      'vaccinations': 'Vaccinations',

      // --- Payment & Checkout ---
      'review_and_pay': 'Review & Pay',
      'date_and_time': 'Date & Time',
      'consultation_fee': 'Consultation Fee',
      'total': 'Total',
      'choose_how_to_pay': 'Choose how to pay',
      'pay': 'Pay',
      'finalize_appointment': 'Finalize Appointment',
      'pay_online_now': 'Pay Online Now',
      'pay_online_desc': 'Pay online to confirm booking',
      'confirm_and_proceed': 'Confirm & Proceed',
      'payment_successful': 'Payment Successful!',
      'appointment_confirmed': 'Your appointment is confirmed',
      'date': 'Date',
      'time': 'Time',
      'doctor': 'Doctor',
      'amount': 'Amount',
      'transaction_id': 'Transaction ID',
      'back_to_home': 'Back to Home',
      'view_appointment_details': 'View Appointment Details',

      // --- Settings ---
      'settings': 'Settings',
      'account': 'Account',
      'profile': 'Profile Card',
      'edit_personal_info': 'Edit your personal information',
      'your_children': 'Your Children',
      'manage_children_info': 'Manage children\'s profiles',
      'payment_data': 'Payment Data',
      'manage_payment_methods': 'Manage payment methods and invoices',
      'preferences': 'Preferences',
      'language': 'Language',
      'change_language': 'Change Language',
      'theme': 'Theme',
      'light_mode': 'Light Mode',
      'font_size': 'Font Size',
      'medium': 'Medium',
      'notifications': 'Notifications',
      'manage_notifications': 'Manage notification preferences',
      'support_and_more': 'Support & More',
      'help_center': 'Help Center',
      'faq_and_support': 'FAQs and Support',
      'app_rating': 'Rate App',
      'share_your_opinion': 'Share your opinion with us',
      'about_app': 'About App',
      'version': 'Version',
      'logout': 'Log Out',
      'logout_from_account': 'Log out from your account',
      'view_profile': 'View Profile',
    },

    // ==========================================================
    // 2. ARABIC LOCALE (ar_SA)
    // ==========================================================
    'ar_SA': {
      // --- عام ---
      'app_name': 'كيد كير',
      'back': 'رجوع',
      'next': 'التالي',
      'or': 'أو',
      'verify': 'تحقق',

      // --- تسجيل الدخول ---
      'welcome_back': 'مرحباً بك مجدداً',
      'phone_number': 'رقم الهاتف',
      'password': 'كلمة المرور',
      'forgot_password_link': 'نسيت كلمة المرور؟',
      'login_btn': 'تسجيل الدخول',
      'create_new_account': 'إنشاء حساب جديد',
      'have_clinic_file': 'لديك ملف بالعيادة؟ ',
      'activate_account': 'تفعيل الحساب',

      // --- إنشاء حساب ---
      'create_account_title': 'إنشاء حساب جديد',
      'create_account_subtitle': 'أنشئ حسابك للاستفادة من خدماتنا',
      'enter_name': 'أدخل اسمك',
      'name': 'الاسم',
      'enter_last_name': 'أدخل اسم العائلة',
      'last_name': 'اسم العائلة',
      'enter_email': 'أدخل بريدك الإلكتروني',
      'email': 'البريد الإلكتروني',
      'enter_phone': 'أدخل رقم هاتفك',
      'phone': 'الهاتف',
      'enter_address': 'أدخل عنوانك بالتفصيل',
      'address': 'العنوان',
      'enter_password': 'أدخل كلمة المرور',
      'password_condition': '8 أحرف على الأقل، تتضمن أحرف كبيرة وصغيرة ورقم',
      'enter_password_again': 'أدخل كلمة المرور مرة أخرى',
      'confirm_password': 'تأكيد كلمة المرور',
      'create_account_btn': 'إنشاء الحساب',
      'already_have_account': 'لديك حساب بالفعل؟',

      // --- نسيان كلمة المرور و OTP ---
      'forgot_password_title': 'نسيت كلمة المرور؟',
      'forgot_password_desc': 'لا تقلق، أدخل رقم الهاتف المرتبط بحسابك وسيرسل لك رمز التحقق.',
      'send_verification_code': 'إرسال رمز التحقق',
      'verify_phone_title': 'تحقق من رقم الهاتف',
      'code_sent_to': 'تم إرسال رمز التحقق إلى',
      'didnt_receive_code': 'لم يصلك الرمز؟',
      'resend_code': 'إعادة إرسال الرمز',
      'resend_in': 'إعادة الإرسال خلال',
      'create_new_password_title': 'إنشاء كلمة مرور جديدة',
      'new_password_unique': 'يجب أن تكون كلمة المرور جديدة وفريدة من نوعها',
      'new_password': 'كلمة المرور الجديدة',
      'update_password': 'تحديث كلمة المرور',
      'password_updated': 'تم تحديث كلمة المرور بنجاح!',
      'login_with_new_password': 'يمكنك الآن تسجيل الدخول باستخدام كلمة المرور الجديدة',
      'go_to_login': 'الذهاب إلى تسجيل الدخول',
      'code_valid_for': 'الرمز صالح لمدة ',
      'minutes': ' دقائق',
      'resend_after_countdown': 'يمكنك إعادة إرسال الرمز بعد انتهاء العداد',
      'change_phone_number': 'تغيير رقم الهاتف',

      // --- التفعيل ---
      'activate_account_title': 'تفعيل الحساب',
      'enter_registered_phone': 'أدخل رقم هاتفك المسجل في العيادة',
      'please_enter_registered_phone': 'يرجى إدخال رقم هاتفك المسجل',
      'verify_and_activate': 'تحقق وفعل الحساب',
      'create_strong_password': 'أنشئ كلمة مرور قوية لحماية حسابك',
      'password_must_contain': 'يجب أن تحتوي كلمة المرور على:',
      'at_least_8_chars': '8 أحرف على الأقل',
      'set_password_and_login': 'تعيين كلمة المرور وتسجيل الدخول',

      // --- الرئيسية والتنقل ---
      'home_tab': 'الرئيسية',
      'appointments_tab': 'المواعيد',
      'records_tab': 'الملفات',
      'more_tab': 'المزيد',
      'welcome_user': 'مرحباً بك!',
      'book_new_appointment': 'حجز موعد جديد',
      'upcoming_appointments': 'المواعيد القادمة',
      'status_confirmed': 'مؤكد',
      'quick_services': 'خدمات سريعة',
      'follow_up': 'الاستشارات',
      'prescriptions': 'الوصفات',
      'vaccinations': 'اللقاحات',

      // --- الدفع وملخص الموعد ---
      'review_and_pay': 'ملخص الموعد',
      'date_and_time': 'التاريخ والوقت',
      'consultation_fee': 'رسوم الكشف',
      'total': 'الإجمالي',
      'choose_how_to_pay': 'اختر طريقة الدفع',
      'pay': 'ادفع',
      'finalize_appointment': 'طريقة الدفع',
      'pay_online_now': 'الدفع الآن إلكترونياً',
      'pay_online_desc': 'ادفع أونلاين لتأكيد الحجز',
      'confirm_and_proceed': 'تأكيد ومتابعة',
      'payment_successful': 'تمت عملية الدفع بنجاح!',
      'appointment_confirmed': 'تم تأكيد موعدك',
      'date': 'التاريخ',
      'time': 'الوقت',
      'doctor': 'الطبيب',
      'amount': 'المبلغ',
      'transaction_id': 'رقم العملية',
      'back_to_home': 'العودة للرئيسية',
      'view_appointment_details': 'عرض تفاصيل الموعد',

      // --- الإعدادات ---
      'settings': 'الإعدادات',
      'account': 'الحساب',
      'profile': 'ملف البروفايل',
      'edit_personal_info': 'تعديل معلوماتك الشخصية',
      'your_children': 'أطفالك',
      'manage_children_info': 'إدارة معلومات الأطفال',
      'payment_data': 'بيانات الدفع',
      'manage_payment_methods': 'إدارة وسائل الدفع والفواتير',
      'preferences': 'التفضيلات',
      'language': 'اللغة',
      'change_language': 'تغيير اللغة',
      'theme': 'المظهر',
      'light_mode': 'الوضع الفاتح',
      'font_size': 'حجم الخط',
      'medium': 'متوسط',
      'notifications': 'الإشعارات',
      'manage_notifications': 'إدارة تفضيلات الإشعارات',
      'support_and_more': 'الدعم والمزيد',
      'help_center': 'مركز المساعدة',
      'faq_and_support': 'الأسئلة الشائعة والدعم',
      'app_rating': 'تقييم التطبيق',
      'share_your_opinion': 'شاركنا رأيك',
      'about_app': 'عن التطبيق',
      'version': 'الإصدار',
      'logout': 'تسجيل الخروج',
      'logout_from_account': 'تسجيل الخروج من حسابك',
      'view_profile': 'عرض الملف الشخصي',
    }
  };
}
```

### File: lib\core\repos\appointment\appointment_repo.dart
```dart
import 'dart:convert';
import '../../apis/appointment/appointment_api.dart';
import '../../helper/secure_storage_service.dart';
import '../../../models/appointment/appointment_model.dart';

class AppointmentRepo {
  final AppointmentApi _api;

  AppointmentRepo({AppointmentApi? api}) : _api = api ?? AppointmentApi();

  Future<AppointmentModel> book({
    required int doctorId,
    required int childId,
    required String date,
    required String time,
  }) async {
    final token = await SecureStorage.getToken();
    final response = await _api.create(token, {
      'doctor_id': doctorId,
      'child_id': childId,
      'date': date,
      'time': time,
    });
    final decoded = jsonDecode(response);

    if (decoded is Map && decoded['appointment'] is Map<String, dynamic>) {
      return AppointmentModel.fromJson(
        decoded['appointment'] as Map<String, dynamic>,
      );
    }

    throw Exception(_errorMessage(decoded, 'Failed to book appointment'));
  }

  Future<List<AppointmentModel>> listAll() => _fetchList(_api.listAll);
  Future<List<AppointmentModel>> listUpcoming() =>
      _fetchList(_api.listUpcoming);
  Future<List<AppointmentModel>> listPast() => _fetchList(_api.listPast);

  Future<List<AppointmentModel>> listUpcomingForChild(int childId) async {
    final token = await SecureStorage.getToken();
    return _parseList(
      await _api.listUpcomingForChild(token, childId),
      'Failed to load upcoming appointments',
    );
  }

  Future<List<AppointmentModel>> listPastForChild(int childId) async {
    final token = await SecureStorage.getToken();
    return _parseList(
      await _api.listPastForChild(token, childId),
      'Failed to load past appointments',
    );
  }

  Future<AppointmentModel> fetchOne(int id) async {
    final token = await SecureStorage.getToken();
    final response = await _api.getById(token, id);
    final decoded = jsonDecode(response);

    if (decoded is Map<String, dynamic>) {
      final raw = decoded['appointment'] is Map<String, dynamic>
          ? decoded['appointment'] as Map<String, dynamic>
          : (decoded['data'] is Map<String, dynamic>
                ? decoded['data'] as Map<String, dynamic>
                : decoded);
      if (raw['id'] != null) return AppointmentModel.fromJson(raw);
    }

    throw Exception(_errorMessage(decoded, 'Failed to load appointment'));
  }

  Future<AppointmentModel> reschedule(
    int id, {
    String? date,
    String? time,
  }) async {
    final token = await SecureStorage.getToken();
    final body = <String, dynamic>{};
    if (date != null) body['date'] = date;
    if (time != null) body['time'] = time;

    final response = await _api.update(token, id, body);
    final decoded = jsonDecode(response);

    if (decoded is Map && decoded['appointment'] is Map<String, dynamic>) {
      return AppointmentModel.fromJson(
        decoded['appointment'] as Map<String, dynamic>,
      );
    }

    throw Exception(_errorMessage(decoded, 'Failed to reschedule appointment'));
  }

  Future<void> cancel(int id) async {
    final token = await SecureStorage.getToken();
    final response = await _api.delete(token, id);
    if (response.isEmpty) return;

    final decoded = jsonDecode(response);
    if (decoded is Map && decoded['errors'] != null) {
      throw Exception(_errorMessage(decoded, 'Failed to cancel appointment'));
    }
  }

  // ---- helpers ----

  Future<List<AppointmentModel>> _fetchList(
    Future<String> Function(String token) call,
  ) async {
    final token = await SecureStorage.getToken();
    return _parseList(await call(token), 'Failed to load appointments');
  }

  List<AppointmentModel> _parseList(String response, String fallbackMsg) {
    final decoded = jsonDecode(response);

    List? items;
    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map) {
      if (decoded['appointments'] is List) {
        items = decoded['appointments'] as List;
      } else if (decoded['data'] is List) {
        items = decoded['data'] as List;
      }
    }

    if (items != null) {
      return items
          .map((j) => AppointmentModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }

    throw Exception(_errorMessage(decoded, fallbackMsg));
  }

  String _errorMessage(dynamic decoded, String fallback) {
    if (decoded is Map && decoded['message'] != null) {
      return decoded['message'].toString();
    }
    return fallback;
  }
}

```

### File: lib\core\repos\appointment\child_repo.dart
```dart
import 'dart:convert';
import '../../apis/appointment/child_api.dart';
import '../../helper/secure_storage_service.dart';
import '../../../models/appointment/child_model.dart';

class ChildRepo {
  final ChildApi _api;

  ChildRepo({ChildApi? api}) : _api = api ?? ChildApi();

  Future<List<ChildModel>> fetchMyChildren() async {
    final token = await SecureStorage.getToken();
    final response = await _api.getMine(token);
    final decoded = jsonDecode(response);

    if (decoded is Map && decoded['children'] is List) {
      return (decoded['children'] as List)
          .map((j) => ChildModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }

    final msg = (decoded is Map && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Failed to load children';
    throw Exception(msg);
  }
}

```

### File: lib\core\repos\appointment\department_repo.dart
```dart
import 'dart:convert';
import '../../apis/appointment/department_api.dart';
import '../../helper/secure_storage_service.dart';
import '../../../models/appointment/department_model.dart';

class DepartmentRepo {
  final DepartmentApi _api;

  DepartmentRepo({DepartmentApi? api}) : _api = api ?? DepartmentApi();

  Future<List<DepartmentModel>> fetchAll() async {
    final token = await SecureStorage.getToken();
    final response = await _api.getAll(token);
    final decoded = jsonDecode(response);

    if (decoded is List) {
      return decoded
          .map((j) => DepartmentModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }

    final msg = (decoded is Map && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Failed to load departments';
    throw Exception(msg);
  }
}

```

### File: lib\core\repos\appointment\doctor_repo.dart
```dart
import 'dart:convert';
import '../../apis/appointment/doctor_api.dart';
import '../../helper/secure_storage_service.dart';
import '../../../models/appointment/doctor_model.dart';
import '../../../models/appointment/doctor_availability_model.dart';

class DoctorRepo {
  final DoctorApi _api;

  DoctorRepo({DoctorApi? api}) : _api = api ?? DoctorApi();

  Future<List<DoctorModel>> fetchByDepartment(int departmentId) async {
    final token = await SecureStorage.getToken();
    final response = await _api.getByDepartment(token, departmentId);
    final decoded = jsonDecode(response);

    if (decoded is List) {
      return decoded
          .map((j) => DoctorModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }

    final msg = (decoded is Map && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Failed to load doctors';
    throw Exception(msg);
  }

  Future<DoctorModel> fetchById(int doctorId) async {
    final token = await SecureStorage.getToken();
    final response = await _api.getById(token, doctorId);
    final decoded = jsonDecode(response);

    if (decoded is Map<String, dynamic>) {
      final raw = decoded['data'] is Map<String, dynamic>
          ? decoded['data'] as Map<String, dynamic>
          : decoded;
      if (raw['id'] != null) return DoctorModel.fromJson(raw);
    }

    final msg = (decoded is Map && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Failed to load doctor';
    throw Exception(msg);
  }

  Future<List<DoctorAvailabilityModel>> fetchWeeklyAvailability(
    int doctorId,
  ) async {
    final token = await SecureStorage.getToken();
    final response = await _api.getAvailabilities(token, doctorId);
    final decoded = jsonDecode(response);

    if (decoded is List) {
      return decoded
          .map(
            (j) =>
                DoctorAvailabilityModel.fromJson(j as Map<String, dynamic>),
          )
          .toList();
    }

    final msg = (decoded is Map && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Failed to load availability';
    throw Exception(msg);
  }

  /// Returns the list of available time slots for a doctor on a given date.
  /// An empty list is a valid result (backend returns `times: []`) — not an error.
  Future<List<String>> fetchSlots(int doctorId, String date) async {
    final token = await SecureStorage.getToken();
    final response = await _api.getAvailableTimes(token, doctorId, date);
    final decoded = jsonDecode(response);

    if (decoded is Map && decoded['times'] is List) {
      return List<String>.from(
        (decoded['times'] as List).map((e) => e.toString()),
      );
    }

    final msg = (decoded is Map && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Failed to load available times';
    throw Exception(msg);
  }
}

```

### File: lib\core\repos\auth\activation_repo.dart
```dart
import 'dart:convert';
import '../../apis/auth/activation_api.dart';
import '../../helper/secure_storage_service.dart';


class ActivationRepo {
  final ActivationApi api = ActivationApi();

  Future<bool> requestOtp(String phone) async {
    var response = await api.sendOtp(phone);
    var body = json.decode(response);

    if (body['status'] == 'success') return true;
    throw Exception(body['message'] ?? "Error sending OTP");
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    var response = await api.verifyOtp(phone, otp);
    var body = json.decode(response);

    if (body['status'] == 'success') return true;
    throw Exception(body['message'] ?? "Invalid OTP");
  }

  Future<bool> activateAndLogin(String phone, String password) async {
    var response = await api.setPassword(phone, password);
    var body = json.decode(response);

    if (body['status'] == 'success') {
      String token = body['token'];
      await SecureStorage.storeToken(token);
      return true;
    }
    throw Exception(body['message'] ?? "Activation failed");
  }
}
```

### File: lib\core\repos\auth\login_repo.dart
```dart
import 'dart:convert';
import '../../../models/auth/user_model.dart';
import '../../apis/auth/login_api.dart';
import '../../helper/secure_storage_service.dart';


class LoginRepo {
  final LoginApi loginApi = LoginApi();

  Future<UserModel> loginUser(String phone, String password) async {
    var response = await loginApi.login(phone, password);
    var responseBody = json.decode(response);

    if (responseBody['status'] == 'success') {
      if (responseBody['user'] == null) {
        throw Exception(
          "Login successful, but 'user' data is missing from server!",
        );
      }

      String token = responseBody['Token'];
      Map<String, dynamic> userData = responseBody['user'];

      UserModel user = UserModel.fromJson(userData, token);

      await SecureStorage.storeToken(token);

      return user;
    } else {
      throw Exception(responseBody['message'] ?? 'Invalid login details');
    }
  }
}

```

### File: lib\core\repos\auth\sign_up_repo.dart
```dart
import 'dart:convert';
import '../../apis/auth/sign_up_api.dart';
import '../../helper/secure_storage_service.dart';
import '../../../models/auth/sign_up_response_model.dart';

class SignUpRepo {
  final SignUpApi _api = SignUpApi();

  Future<SignUpResponseModel> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String address,
    required String password,
  }) async {
    var response = await _api.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      address: address,
      password: password,
    );

    var body = json.decode(response);

    // ✅ إذا رجع errors أو لم يرجع phone_number = فشل
    if (body['errors'] != null || body['phone_number'] == null) {
      throw Exception(body['message'] ?? 'Registration failed');
    }

    final result = SignUpResponseModel.fromJson(body);

    if (result.accessToken.isNotEmpty) {
      await SecureStorage.storeToken(result.accessToken);
    }

    return result;
  }
}
```

### File: lib\core\repos\auth\verify_otp_repo.dart
```dart
import 'dart:convert';
import '../../apis/auth/verify_otp_api.dart';

class VerifyOtpRepo {
  final VerifyOtpApi _api = VerifyOtpApi();

  Future<void> verify({
    required String phone,
    required String otp,
  }) async {
    final response = await _api.verify(phone: phone, otp: otp);
    final body = json.decode(response);

    if (body['status'] == 'success') return;

    throw Exception(body['message'] ?? 'Error verifying OTP');
  }

  Future<void> resend({required String phone}) async {
    final response = await _api.resend(phone: phone);
    final body = json.decode(response);

    if (body['status'] == 'success') return;

    throw Exception(body['message'] ?? 'Error resending OTP');
  }
}
```

### File: lib\core\repos\home\add_child_repo.dart
```dart
import 'dart:convert';
import 'dart:io';

import '../../apis/home/add_child_api.dart';


class AddChildRepo {
  final AddChildApi _api = AddChildApi();

  Future<void> deleteChild(int childId) async {
    final response = await _api.deleteChild(childId);
    final body = json.decode(response);

    if (body['message'] == null) {
      throw Exception('Failed to delete child');
    }
  }

  Future<void> addChild({
    required String firstName,
    required String lastName,
    required String gender,
    required String birthDate,
    required String bloodType,
    required String medicalHistory,
    required String allergies,
    File? image,
  }) async {
    final response = await _api.addChild(
      firstName: firstName,
      lastName: lastName,
      gender: gender,
      birthDate: birthDate,
      bloodType: bloodType,
      medicalHistory: medicalHistory,
      allergies: allergies,
      image: image,
    );

    final body = json.decode(response);

    if (body['child'] == null) {
      throw Exception(body['message'] ?? 'Failed to add child');
    }
  }
}

```

### File: lib\core\repos\home\appointments_repo.dart
```dart
import 'dart:convert';

import '../../../models/appointment/appointment_model.dart';
import '../../apis/home/appoimtments_api.dart';


class AppointmentsRepo {
  final AppointmentsApi _api = AppointmentsApi();

  Future<List<AppointmentModel>> getUpcoming(int childId) async {
    final response = await _api.getUpcoming(childId);
    final body = json.decode(response);

    if (body['appointments'] == null) {
      throw Exception(body['message'] ?? 'Failed to load appointments');
    }

    final List list = body['appointments'];
    return list.map((e) => AppointmentModel.fromJson(e)).toList();
  }

  Future<List<AppointmentModel>> getPast(int childId) async {
    final response = await _api.getPast(childId);
    final body = json.decode(response);

    if (body['appointments'] == null) {
      throw Exception(body['message'] ?? 'Failed to load appointments');
    }

    final List list = body['appointments'];
    return list.map((e) => AppointmentModel.fromJson(e)).toList();
  }
}

```

### File: lib\core\repos\home\home_children_repo.dart
```dart
import 'dart:convert';
import '../../../models/home/home_child_model.dart';
import '../../apis/home/home_children_api.dart';


class HomeChildrenRepo {
  final HomeChildrenApi _api = HomeChildrenApi();

  Future<List<HomeChildModel>> getChildren() async {
    final response = await _api.getChildren();
    final body = json.decode(response);

    if (body['children'] == null) {
      throw Exception(body['message'] ?? 'Failed to load children');
    }

    final List list = body['children'];
    return list.map((e) => HomeChildModel.fromJson(e)).toList();
  }
}

```

### File: lib\core\repos\home\parent_name_repo.dart
```dart
import 'dart:convert';
import '../../apis/home/parent_name_api.dart';


class ParentNameRepo {
  final ParentNameApi _api = ParentNameApi();

  Future<String> getParentName() async {
    final response = await _api.getParentName();
    final body = json.decode(response);

    if (body['user'] == null) {
      throw Exception(body['message'] ?? 'Failed to load user');
    }

    final firstName = body['user']['first_name'] ?? '';
    final lastName = body['user']['last_name'] ?? '';
    return '$firstName $lastName';
  }
}

```

### File: lib\core\repos\home\profile_repo.dart
```dart
import 'dart:convert';
import '../../../models/home/profile_model.dart';
import '../../apis/home/profile_api.dart';


class ProfileRepo {
  final ProfileApi _api = ProfileApi();

  Future<ProfileModel> getProfile() async {
    final response = await _api.getProfile();
    final body = json.decode(response);

    if (body['status'] != 'success') {
      throw Exception(body['message'] ?? 'Failed to load profile');
    }

    return ProfileModel.fromJson(body);
  }
}

```

### File: lib\core\repos\payment_repo.dart
```dart
import 'dart:convert';
import '../../models/appointment_details_model.dart';
import '../../models/payment_intent_model.dart';
import '../apis/payment_api.dart';
import '../helper/secure_storage_service.dart';

class PaymentRepo {
  final PaymentApi api = PaymentApi();

  Future<AppointmentDetailsModel> fetchAppointmentSummary(
    String appointmentId,
  ) async {
    String token = await SecureStorage.getToken();
    final response = await api.getAppointmentSummary(token, appointmentId);
    final data = jsonDecode(response);

    if (data['status'] == 'success') {
      return AppointmentDetailsModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? "Failed to parse summary details");
    }
  }

  Future<PaymentIntentModel> fetchPaymentIntent(
    String appointmentId,
    String currency,
  ) async {
    String token = await SecureStorage.getToken();
    final response = await api.createPaymentIntent(
      token,
      appointmentId,
      currency,
    );
    final data = jsonDecode(response);

    if (data['status'] == 'success') {
      return PaymentIntentModel.fromJson(data);
    } else {
      throw Exception(data['message'] ?? "Failed to process payment data");
    }
  }
}

```

### File: lib\export_code.dart
```dart
import 'dart:io';

void main() {
  // المجلد الذي نريد البحث فيه (مجلد الأكواد فقط)
  var dir = Directory('lib');
  // اسم الملف الذي سيتم إنشاؤه
  var outputFile = File('my_project_code.md');
  var output = StringBuffer();

  if (dir.existsSync()) {
    output.writeln('# KidCare Project Code\n');

    // جلب كل الملفات داخل مجلد lib
    var files = dir.listSync(recursive: true);
    for (var file in files) {
      // نأخذ فقط ملفات الدارت
      if (file is File && file.path.endsWith('.dart')) {
        output.writeln('### File: ${file.path}');
        output.writeln('```dart');
        output.writeln(file.readAsStringSync());
        output.writeln('```\n');
      }
    }

    outputFile.writeAsStringSync(output.toString());
    print('✅ تمت العملية بنجاح! تم إنشاء ملف my_project_code.md');
  } else {
    print('❌ مجلد lib غير موجود!');
  }
}
```

### File: lib\main.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

// 🌟 استيرادات اللغات والتخزين (تمت إضافتها)
import 'package:kidcare/core/helper/secure_storage_service.dart';
import 'package:kidcare/core/localization/app_translations.dart';

// الواجهات الأساسية
import 'package:kidcare/views/main_advanced.dart';
import 'package:kidcare/views/auth/login_view.dart';

// Sign Up
import 'package:kidcare/views/auth/sign_up_view.dart';
import 'package:kidcare/core/repos/auth/sign_up_repo.dart';
import 'controllers/auth/sign_up_controller.dart';

// Activation
import 'package:kidcare/views/auth/activation/otp_verification_view.dart';
import 'package:kidcare/views/auth/activation/phone_activation_view.dart';
import 'package:kidcare/views/auth/activation/set_new_password_view.dart';
import 'controllers/auth/activation_controller.dart';

// Verify OTP
import 'package:kidcare/views/auth/verify_otp_view.dart';
import 'package:kidcare/core/repos/auth/verify_otp_repo.dart';
import 'controllers/auth/verify_otp_controller.dart';

// Forgot Password
import 'package:kidcare/views/auth/forget_password/forgot_password_view.dart';
import 'package:kidcare/views/auth/forget_password/otp_view.dart';
import 'package:kidcare/views/auth/forget_password/reset_password_view.dart';
import 'package:kidcare/views/auth/forget_password/success_reset_view.dart';
import 'controllers/auth/forgot_password_controller.dart';

// Payment Routes
import 'package:kidcare/views/payment/payment_method_view.dart';
import 'package:kidcare/views/payment/checkout_summary_view.dart';
import 'package:kidcare/views/payment/payment_success_view.dart';


// Appointment Booking
import 'package:kidcare/views/HomeView.dart';
import 'package:kidcare/views/appointment/choose_doctor_view.dart';
import 'package:kidcare/views/appointment/choose_child_view.dart';
import 'package:kidcare/views/appointment/choose_date_time_view.dart';
import 'package:kidcare/controllers/appointment/department_controller.dart';
import 'package:kidcare/controllers/appointment/doctor_controller.dart';
import 'package:kidcare/controllers/appointment/child_controller.dart';
import 'package:kidcare/controllers/appointment/my_appointments_controller.dart';
import 'package:kidcare/core/repos/appointment/department_repo.dart';
import 'package:kidcare/core/repos/appointment/doctor_repo.dart';
import 'package:kidcare/core/repos/appointment/child_repo.dart';
import 'package:kidcare/core/repos/appointment/appointment_repo.dart';


import 'package:kidcare/views/settings/settings_view.dart';



void main() async {
  // لتهيئة فلاتر قبل تشغيل أي ميزة Native مثل Stripe
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = 'pk_test_';


  String? savedLang = await SecureStorage.getLanguage();
  Locale initialLocale = savedLang == 'ar'
      ? const Locale('ar', 'SA')
      : const Locale('en', 'US');


  runApp(MyApp(initialLocale: initialLocale));
}

class MyApp extends StatelessWidget {
  final Locale initialLocale;

  const MyApp({super.key, required this.initialLocale});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Kidcare',
      debugShowCheckedModeBanner: false,

      //  Localization
      translations: AppTranslations(),
      locale: initialLocale,
      fallbackLocale: const Locale('en', 'US'),

      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
      ),

      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const PediatricClinicScreen()),

        // login
        GetPage(name: '/login', page: () => const LoginView()),

        // Sign Up
        GetPage(
          name: '/register',
          page: () => const SignUpView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<SignUpController>(
                  () => SignUpController(signUpRepo: SignUpRepo()),
            );
          }),
        ),

        // Activation
        GetPage(
          name: '/activation-phone',
          page: () => const PhoneActivationView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<ActivationController>(() => ActivationController());
          }),
        ),
        GetPage(
          name: '/activation-otp',
          page: () => const OtpVerificationView(),
        ),
        GetPage(name: '/set-password', page: () => const SetNewPasswordView()),

        //  OTP
        GetPage(
          name: '/verify-otp',
          page: () => const VerifyOtpView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<VerifyOtpController>(
                  () => VerifyOtpController(verifyOtpRepo: VerifyOtpRepo()),
            );
          }),
        ),

        // Forgot Password
        GetPage(
          name: '/forgot-password',
          page: () => const ForgotPasswordView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<ForgotPasswordController>(
                  () => ForgotPasswordController(),
            );
          }),
        ),
        GetPage(name: '/forgot-otp', page: () => const OtpView()),
        GetPage(name: '/reset-password', page: () => const ResetPasswordView()),
        GetPage(name: '/success-reset', page: () => SuccessResetView()),

        //  Payment
        GetPage(name: '/payment-method', page: () => const PaymentMethodView()),
        GetPage(
          name: '/checkout-summary',
          page: () => const CheckoutSummaryView(),
        ),
        GetPage(
          name: '/payment-success',
          page: () => const PaymentSuccessView(),
        ),


        // Home
        GetPage(
          name: '/home',
          page: () => const HomeView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<ChildController>(
              () => ChildController(repo: ChildRepo()),
            );
            Get.lazyPut<MyAppointmentsController>(
              () => MyAppointmentsController(
                repo: AppointmentRepo(),
                doctorRepo: DoctorRepo(),
                childRepo: ChildRepo(),
              ),
            );
          }),
        ),

        // Appointment Booking
        GetPage(
          name: '/choose-doctor',
          page: () => const ChooseDoctorView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<DepartmentController>(
              () => DepartmentController(repo: DepartmentRepo()),
            );
            Get.lazyPut<DoctorController>(
              () => DoctorController(repo: DoctorRepo()),
            );
          }),
        ),
        // ChildController is already alive from /home — no new binding needed.
        // Re-registering would create a second instance that never sees the
        // home-scope data and breaks cache coherence.
        GetPage(
          name: '/choose-child',
          page: () => const ChooseChildView(),
        ),
        GetPage(
          name: '/choose-date-time',
          page: () => const ChooseDateTimeView(),
        ),

        // Settings
        GetPage(name: '/settings', page: () => const SettingsView()),

      ],
    );
  }
}
```

### File: lib\models\appointment\appointment_model.dart
```dart
import '../../core/helper/json_utils.dart';

class AppointmentModel {
  final int id;
  final int childId;
  final int doctorId;
  final String date;
  final String time;
  final String status;
  final num price;
  final String? doctorName;
  final String? childName;

  const AppointmentModel({
    required this.id,
    required this.childId,
    required this.doctorId,
    required this.date,
    required this.time,
    required this.status,
    required this.price,
    this.doctorName,
    this.childName,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: toIntSafe(json['id']),
      childId: toIntSafe(json['child_id']),
      doctorId: toIntSafe(json['doctor_id']),
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      price: toNumSafe(json['price']),
    );
  }

  AppointmentModel withNames({String? doctorName, String? childName}) {
    return AppointmentModel(
      id: id,
      childId: childId,
      doctorId: doctorId,
      date: date,
      time: time,
      status: status,
      price: price,
      doctorName: doctorName ?? this.doctorName,
      childName: childName ?? this.childName,
    );
  }

  DateTime? get dateAsDate => DateTime.tryParse(date);
}

```

### File: lib\models\appointment\child_model.dart
```dart
import '../../core/helper/json_utils.dart';

class ChildModel {
  final int id;
  final int parentId;
  final String firstName;
  final String lastName;
  final String gender;
  final DateTime birthDate;
  final String? bloodType;
  final String? image;
  final String? medicalHistory;
  final String? allergies;

  const ChildModel({
    required this.id,
    required this.parentId,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.birthDate,
    this.bloodType,
    this.image,
    this.medicalHistory,
    this.allergies,
  });

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      id: toIntSafe(json['id']),
      parentId: toIntSafe(json['parent_id']),
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      birthDate:
          DateTime.tryParse(json['birth_date']?.toString() ?? '') ??
              DateTime.now(),
      bloodType: json['blood_type']?.toString(),
      image: json['image']?.toString(),
      medicalHistory: json['medical_history']?.toString(),
      allergies: json['allergies']?.toString(),
    );
  }

  String get fullName => '$firstName $lastName';

  int get ageYears {
    final today = DateTime.now();
    int years = today.year - birthDate.year;
    final hadBirthdayThisYear =
        today.month > birthDate.month ||
        (today.month == birthDate.month && today.day >= birthDate.day);
    if (!hadBirthdayThisYear) years--;
    return years;
  }
}

```

### File: lib\models\appointment\department_model.dart
```dart
import '../../core/helper/json_utils.dart';

class DepartmentModel {
  final int id;
  final String name;
  final String? description;

  const DepartmentModel({
    required this.id,
    required this.name,
    this.description,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: toIntSafe(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }
}

```

### File: lib\models\appointment\doctor_availability_model.dart
```dart
import '../../core/helper/json_utils.dart';

class DoctorAvailabilityModel {
  final int id;
  final int doctorId;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isBooked;

  const DoctorAvailabilityModel({
    required this.id,
    required this.doctorId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isBooked,
  });

  factory DoctorAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return DoctorAvailabilityModel(
      id: toIntSafe(json['id']),
      doctorId: toIntSafe(json['doctor_id']),
      dayOfWeek: json['day_of_week']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      isBooked: toBoolSafe(json['is_booked']),
    );
  }
}

```

### File: lib\models\appointment\doctor_model.dart
```dart
import '../../core/helper/json_utils.dart';

class DoctorModel {
  final int id;
  final int departmentId;
  final String firstName;
  final String lastName;
  final String email;
  final String address;
  final String? profilePicture;
  final double? rating;
  final String? fee;
  final String? phone;

  const DoctorModel({
    required this.id,
    required this.departmentId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.address,
    this.profilePicture,
    this.rating,
    this.fee,
    this.phone,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: toIntSafe(json['id']),
      departmentId: toIntSafe(json['department_id']),
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      profilePicture: json['profile_picture']?.toString(),
      rating: toDoubleOrNull(json['rating']),
      fee: json['fee']?.toString(),
      phone: json['phone']?.toString(),
    );
  }

  String get fullName => 'Dr. $firstName $lastName';
}

```

### File: lib\models\appointment_details_model.dart
```dart
class AppointmentDetailsModel {
  final String patientName;
  final String patientAge;
  final String patientImageUrl;
  final String doctorName;
  final String departmentName;
  final String dateTime;
  final String price;
  final String currency;

  AppointmentDetailsModel({
    required this.patientName,
    required this.patientAge,
    required this.patientImageUrl,
    required this.doctorName,
    required this.departmentName,
    required this.dateTime,
    required this.price,
    required this.currency,
  });

  factory AppointmentDetailsModel.fromJson(Map<String, dynamic> json) {
    return AppointmentDetailsModel(
      patientName: json['patient_name'] ?? '',
      patientAge: json['patient_age'] ?? '',
      patientImageUrl: json['patient_image_url'] ?? '',
      doctorName: json['doctor_name'] ?? '',
      departmentName: json['department_name'] ?? '',
      dateTime: json['date_time'] ?? '',
      price: json['price'] ?? '0',
      currency: json['currency'] ?? '',
    );
  }
}

```

### File: lib\models\auth\sign_up_response_model.dart
```dart
class SignUpResponseModel {
  final String message;
  final String phoneNumber;
  final String nextStep;
  final String accessToken;
  final int otp;
  final String tokenType;

  SignUpResponseModel({
    required this.message,
    required this.phoneNumber,
    required this.nextStep,
    required this.accessToken,
    required this.otp,
    required this.tokenType,
  });

  factory SignUpResponseModel.fromJson(Map<String, dynamic> json) {
    return SignUpResponseModel(
      message: json['message'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      nextStep: json['next_step'] ?? '',
      accessToken: json['access_token'] ?? '',
      otp: json['otp'] ?? 0,
      tokenType: json['token_type'] ?? '',
    );
  }
}
```

### File: lib\models\auth\user_model.dart
```dart
class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String token;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String token) {
    return UserModel(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],

      phoneNumber: json['phone_number'].toString(),
      token: token,
    );
  }
}

```

### File: lib\models\home\appointments_model.dart
```dart
class AppointmentsModel {
  final int id;
  final String doctorName;
  final String specialty;
  final String date;
  final String time;
  final String status;
  final String? doctorImage;

  const AppointmentsModel({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.time,
    required this.status,
    this.doctorImage,
  });

  factory AppointmentsModel.fromJson(Map<String, dynamic> json) {
    return AppointmentsModel(
      id: json['id'] ?? 0,
      doctorName: json['doctor_name'] ?? '',
      specialty: json['specialty'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      status: json['status'] ?? '',
      doctorImage: json['doctor_image'],
    );
  }
}
```

### File: lib\models\home\child_model.dart
```dart
// lib/core/models/child_model.dart
class ChildModel {
  final String name;
  final String age;
  final String gender; // 'male' or 'female'
  final bool isSelected;

  const ChildModel({
    required this.name,
    required this.age,
    required this.gender,
    this.isSelected = false,
  });
}

```

### File: lib\models\home\home_child_model.dart
```dart
// lib/models/home_child_model.dart
class HomeChildModel {
  final int id;
  final String name;
  final int age;
  final String? image;

  const HomeChildModel({
    required this.id,
    required this.name,
    required this.age,
    this.image,
  });

  factory HomeChildModel.fromJson(Map<String, dynamic> json) {
    return HomeChildModel(
      id: json['id'],
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      image: json['image'],
    );
  }
}

```

### File: lib\models\home\profile_model.dart
```dart
// lib/models/profile_model.dart
class ProfileModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String address;
  final int childrenCount;

  ProfileModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.childrenCount,
  });

  String get fullName => '$firstName $lastName';

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return ProfileModel(
      id: user['id'] ?? 0,
      firstName: user['first_name'] ?? '',
      lastName: user['last_name'] ?? '',
      email: user['email'] ?? '',
      phoneNumber: user['phone_number'] ?? '',
      address: user['address'] ?? '',
      childrenCount: (user['children'] as List?)?.length ?? 0,
    );
  }
}

```

### File: lib\models\payment_intent_model.dart
```dart
class PaymentIntentModel {
  final String status;
  final String clientSecret;
  final String transactionId;

  PaymentIntentModel({
    required this.status,
    required this.clientSecret,
    required this.transactionId,
  });


  factory PaymentIntentModel.fromJson(Map<String, dynamic> json) {
    return PaymentIntentModel(
      status: json['status'] ?? '',
      clientSecret: json['client_secret'] ?? '',
      transactionId: json['transaction_id'] ?? '',
    );
  }
}
```

### File: lib\views\appointment\choose_child_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../controllers/appointment/appointment_controller.dart';
import '../../controllers/appointment/child_controller.dart';
import '../../core/booking_theme.dart';
import '../../models/appointment/child_model.dart';
import '../../widgets/booking_app_bar.dart';

final _fakeChildren = List<ChildModel>.generate(
  3,
  (i) => ChildModel(
    id: -i - 1,
    parentId: -1,
    firstName: 'Child',
    lastName: 'Loading',
    gender: i.isEven ? 'male' : 'female',
    birthDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
  ),
);

const _kPrimary = kBookingPrimary;
const _kBackground = kBookingBackground;
const _kTextPrimary = kBookingTextPrimary;
const _kTextSecondary = kBookingTextSecondary;
const _kBorder = kBookingBorder;
const _kBoyTint = Color(0xFFE7F7E9);
const _kGirlTint = Color(0xFFFFE7EE);
const _kSelectedBorder = Color(0xFF22C55E);

class ChooseChildView extends StatefulWidget {
  const ChooseChildView({super.key});

  @override
  State<ChooseChildView> createState() => _ChooseChildViewState();
}

class _ChooseChildViewState extends State<ChooseChildView> {
  final ChildController childController = Get.find<ChildController>();
  final AppointmentController appointmentController =
      Get.find<AppointmentController>();

  int? selectedChildId;

  void _onChildTapped(ChildModel child) {
    setState(() => selectedChildId = child.id);
    appointmentController.selectChild(child);
  }

  void _onNextPressed() {
    if (selectedChildId == null) return;
    Get.toNamed('/choose-date-time');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: bookingAppBar(subtitle: 'Choose Child'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                final isLoading = childController.isLoading;
                final children =
                    isLoading ? _fakeChildren : childController.children;

                if (!isLoading && children.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        "You haven't added any children yet.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _kTextSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }

                return Skeletonizer(
                  enabled: isLoading,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    itemCount: children.length,
                    itemBuilder: (context, index) {
                      final child = children[index];
                      return _ChildCard(
                        child: child,
                        isSelected: selectedChildId == child.id,
                        onTap:
                            isLoading ? () {} : () => _onChildTapped(child),
                      );
                    },
                  ),
                );
              }),
            ),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    final enabled = selectedChildId != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            disabledBackgroundColor: _kPrimary.withValues(alpha: 0.4),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: enabled ? _onNextPressed : null,
          child: const Text(
            'Next',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final ChildModel child;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChildCard({
    required this.child,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMale = child.gender == 'male';
    final tint = isMale ? _kBoyTint : _kGirlTint;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? tint : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? _kSelectedBorder : _kBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          children: [
            _ChildAvatar(child: child, tint: tint),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${child.ageYears} years',
                    style: const TextStyle(
                      fontSize: 13,
                      color: _kTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _SelectionIndicator(selected: isSelected),
          ],
        ),
      ),
    );
  }
}

class _ChildAvatar extends StatelessWidget {
  final ChildModel child;
  final Color tint;

  const _ChildAvatar({required this.child, required this.tint});

  @override
  Widget build(BuildContext context) {
    final isMale = child.gender == 'male';
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: child.image != null
          ? Image.network(
              child.image!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _localFallback(isMale),
            )
          : _localFallback(isMale),
    );
  }

  Widget _localFallback(bool isMale) {
    return Image.asset(
      isMale
          ? 'assets/images/boy character green.png'
          : 'assets/images/girl character.png',
      fit: BoxFit.contain,
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  final bool selected;
  const _SelectionIndicator({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: selected ? _kSelectedBorder : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? _kSelectedBorder : _kBorder,
          width: 1.5,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
          : null,
    );
  }
}


```

### File: lib\views\appointment\choose_date_time_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../controllers/appointment/appointment_controller.dart';
import '../../core/booking_theme.dart';
import '../../models/appointment/appointment_model.dart';
import '../../widgets/booking_app_bar.dart';
import '../../widgets/booking_calendar.dart';

const _fakeSlots = <String>[
  '09:00',
  '09:30',
  '10:00',
  '10:30',
  '11:00',
  '11:30',
  '12:00',
  '12:30',
  '13:00',
];

const _kPrimary = kBookingPrimary;
const _kBackground = kBookingBackground;
const _kTextPrimary = kBookingTextPrimary;
const _kTextSecondary = kBookingTextSecondary;
const _kBorder = kBookingBorder;

class ChooseDateTimeView extends StatefulWidget {
  const ChooseDateTimeView({super.key});

  @override
  State<ChooseDateTimeView> createState() => _ChooseDateTimeViewState();
}

class _ChooseDateTimeViewState extends State<ChooseDateTimeView> {
  final AppointmentController controller = Get.find<AppointmentController>();

  @override
  void initState() {
    super.initState();
    controller.loadDoctorAvailability();
    if (controller.selectedDate.value == null) {
      controller.selectDate(DateTime.now());
    }
    // Always re-fetch slots on entry â€” the user may have returned to this
    // screen after changing the doctor, or just been away long enough for
    // another user to book one of the slots we previously cached.
    controller.loadSlots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: bookingAppBar(subtitle: 'Pick Date & Time'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() {
                      return BookingCalendar(
                        selectedDate: controller.selectedDate.value,
                        minDate: DateTime.now(),
                        workingWeekdays: controller.workingWeekdays.toSet(),
                        onDateSelected: (date) {
                          controller.selectDate(date);
                          controller.loadSlots();
                        },
                      );
                    }),
                    const SizedBox(height: 20),
                    const Text(
                      'Available Times',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SlotsGrid(controller: controller),
                  ],
                ),
              ),
            ),
            _BookButton(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _SlotsGrid extends StatelessWidget {
  final AppointmentController controller;
  const _SlotsGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Read all observables up-front so the Obx subscribes to every signal
      // it depends on (itemBuilder fires lazily, outside the Obx scope).
      final selectedDate = controller.selectedDate.value;
      final isLoadingSlots = controller.isLoadingSlots.value;
      final times = controller.availableTimes.toList();
      final selectedTime = controller.selectedTime.value;

      if (selectedDate == null) {
        return const _EmptyHint(text: 'Pick a date to see available times.');
      }
      if (!isLoadingSlots && times.isEmpty) {
        return const _EmptyHint(text: 'No times available for this date.');
      }

      final shown = isLoadingSlots ? _fakeSlots : times;

      return Skeletonizer(
        enabled: isLoadingSlots,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2,
          ),
          itemCount: shown.length,
          itemBuilder: (context, index) {
            final time = shown[index];
            final isSelected = selectedTime == time;
            return _SlotChip(
              label: _formatTime12h(time),
              selected: isSelected,
              onTap:
                  isLoadingSlots ? () {} : () => controller.selectTime(time),
            );
          },
        ),
      );
    });
  }
}

class _SlotChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SlotChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _kPrimary : _kBorder,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : _kTextPrimary,
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: _kTextSecondary, fontSize: 13.5),
        ),
      ),
    );
  }
}

class _BookButton extends StatelessWidget {
  final AppointmentController controller;
  const _BookButton({required this.controller});

  Future<void> _handleBook(BuildContext context) async {
    final success = await controller.bookAppointment();
    if (!success || !context.mounted) return;

    final appointment = controller.bookedAppointment.value!;
    final doctorName = controller.selectedDoctor.value?.fullName;
    final childName = controller.selectedChild.value?.fullName;
    Get.delete<AppointmentController>(force: true);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BookingSuccessDialog(
        appointment: appointment,
        doctorName: doctorName,
        childName: childName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: Obx(() {
          final enabled =
              controller.selectedTime.value != null && !controller.isLoading;
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              disabledBackgroundColor: _kPrimary.withValues(alpha: 0.4),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: enabled ? () => _handleBook(context) : null,
            child: controller.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : const Text(
                    'Book Appointment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          );
        }),
      ),
    );
  }
}

class _BookingSuccessDialog extends StatelessWidget {
  final AppointmentModel appointment;
  final String? doctorName;
  final String? childName;

  const _BookingSuccessDialog({
    required this.appointment,
    this.doctorName,
    this.childName,
  });

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatTime(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts[1].padLeft(2, '0');
    final suffix = h >= 12 ? 'PM' : 'AM';
    final hour = h % 12 == 0 ? 12 : h % 12;
    return '$hour:$m $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 44,
                color: Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Appointment Booked!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your appointment has been confirmed.\nSee you soon!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // Details card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.person_rounded,
                    label: 'Doctor',
                    value: doctorName ?? 'Doctor #${appointment.doctorId}',
                  ),
                  const SizedBox(height: 10),
                  _DetailRow(
                    icon: Icons.child_care_rounded,
                    label: 'Child',
                    value: childName ?? 'Child #${appointment.childId}',
                  ),
                  const SizedBox(height: 10),
                  _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: _formatDate(appointment.date),
                  ),
                  const SizedBox(height: 10),
                  _DetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: _formatTime(appointment.time),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Get.offAllNamed('/home');
                },
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _kPrimary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

String _formatTime12h(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length < 2) return hhmm;
  final h = int.tryParse(parts[0]);
  if (h == null) return hhmm;
  final m = parts[1].padLeft(2, '0');
  final period = h >= 12 ? 'PM' : 'AM';
  final hh12 = h % 12 == 0 ? 12 : h % 12;
  return '${hh12.toString().padLeft(2, '0')}:$m $period';
}


```

### File: lib\views\appointment\choose_doctor_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../controllers/appointment/appointment_controller.dart';
import '../../controllers/appointment/department_controller.dart';
import '../../controllers/appointment/doctor_controller.dart';
import '../../core/booking_theme.dart';
import '../../models/appointment/department_model.dart';
import '../../models/appointment/doctor_model.dart';
import '../../widgets/booking_app_bar.dart';

final _fakeDepartments = List<DepartmentModel>.generate(
  5,
  (i) => DepartmentModel(id: -i - 1, name: 'Department'),
);

final _fakeDoctors = List<DoctorModel>.generate(
  5,
  (i) => DoctorModel(
    id: -i - 1,
    departmentId: -1,
    firstName: 'Doctor',
    lastName: 'Loading',
    email: '',
    address: '',
    rating: 4.5,
  ),
);

const _kPrimary = kBookingPrimary;
const _kBackground = kBookingBackground;
const _kTextPrimary = kBookingTextPrimary;
const _kTextSecondary = kBookingTextSecondary;
const _kBorder = kBookingBorder;
const _kAvatarTint = kBookingAvatarTint;

class ChooseDoctorView extends StatefulWidget {
  const ChooseDoctorView({super.key});

  @override
  State<ChooseDoctorView> createState() => _ChooseDoctorViewState();
}

class _ChooseDoctorViewState extends State<ChooseDoctorView> {
  final DepartmentController departmentController =
      Get.find<DepartmentController>();
  final DoctorController doctorController = Get.find<DoctorController>();
  final AppointmentController appointmentController =
      Get.find<AppointmentController>();

  DepartmentModel? selectedDepartment;
  int? selectedDoctorId;

  void _onDepartmentTapped(DepartmentModel d) {
    setState(() {
      selectedDepartment = d;
      selectedDoctorId = null;
    });
    doctorController.loadDoctors(d.id);
  }

  void _onDoctorTapped(DoctorModel doctor) {
    setState(() => selectedDoctorId = doctor.id);
    appointmentController.selectDoctor(doctor);
  }

  void _onNextPressed() {
    if (selectedDoctorId == null) return;
    Get.toNamed('/choose-child');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: bookingAppBar(subtitle: 'Choose Doctor'),
      body: SafeArea(
        child: Column(
          children: [
            _buildDepartmentChips(),
            const SizedBox(height: 8),
            Expanded(child: _buildDoctorList()),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentChips() {
    return SizedBox(
      height: 56,
      child: Obx(() {
        final isLoading = departmentController.isLoading &&
            departmentController.departments.isEmpty;
        final depts =
            isLoading ? _fakeDepartments : departmentController.departments;

        if (!isLoading && depts.isEmpty) {
          return const Center(
            child: Text(
              'No departments available',
              style: TextStyle(color: _kTextSecondary),
            ),
          );
        }

        return Skeletonizer(
          enabled: isLoading,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: depts.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final dept = depts[index];
              final isSelected = selectedDepartment?.id == dept.id;
              return _DepartmentChip(
                label: dept.name,
                selected: isSelected,
                onTap: isLoading ? () {} : () => _onDepartmentTapped(dept),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildDoctorList() {
    if (selectedDepartment == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Pick a department above to see the doctors.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _kTextSecondary, fontSize: 14),
          ),
        ),
      );
    }
    return Obx(() {
      final isLoading = doctorController.isLoading;
      final doctors = isLoading ? _fakeDoctors : doctorController.doctors;

      if (!isLoading && doctors.isEmpty) {
        return const Center(
          child: Text(
            'No doctors available in this department.',
            style: TextStyle(color: _kTextSecondary, fontSize: 14),
          ),
        );
      }

      return Skeletonizer(
        enabled: isLoading,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          itemCount: doctors.length,
          itemBuilder: (context, index) {
            final doctor = doctors[index];
            return _DoctorCard(
              doctor: doctor,
              specialty: selectedDepartment?.name ?? 'Specialty',
              isSelected: selectedDoctorId == doctor.id,
              onTap: isLoading ? () {} : () => _onDoctorTapped(doctor),
            );
          },
        ),
      );
    });
  }

  Widget _buildNextButton() {
    final enabled = selectedDoctorId != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            disabledBackgroundColor: _kPrimary.withValues(alpha: 0.4),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: enabled ? _onNextPressed : null,
          child: const Text(
            'Next',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _DepartmentChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DepartmentChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? _kPrimary : _kBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _kTextPrimary,
          ),
        ),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final String specialty;
  final bool isSelected;
  final VoidCallback onTap;

  const _DoctorCard({
    required this.doctor,
    required this.specialty,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? _kPrimary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.06 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _Avatar(url: doctor.profilePicture),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.fullName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
                    ),
                  ),
                  if (specialty.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      '$specialty Specialist',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: _kTextSecondary,
                      ),
                    ),
                  ],
                  if (doctor.rating != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFBBF24),
                          size: 16,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          doctor.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _kTextPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'rating',
                          style: TextStyle(
                            fontSize: 12,
                            color: _kTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            _SelectionDot(selected: isSelected),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  const _Avatar({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        color: _kAvatarTint,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null
          ? Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _FallbackPersonIcon(),
            )
          : const _FallbackPersonIcon(),
    );
  }
}

class _FallbackPersonIcon extends StatelessWidget {
  const _FallbackPersonIcon();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.person_rounded, color: _kPrimary, size: 30),
    );
  }
}

class _SelectionDot extends StatelessWidget {
  final bool selected;
  const _SelectionDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: selected ? _kPrimary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? _kPrimary : _kBorder,
          width: 1.5,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
          : null,
    );
  }
}


```

### File: lib\views\auth\activation\otp_verification_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

import '../../../controllers/auth/activation_controller.dart';
import '../../../widgets/activation_helpers.dart';
import '../../../widgets/custom_text_field.dart';

class OtpVerificationView extends GetView<ActivationController> {
  const OtpVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 20,
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
    );

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
              const StepProgressIndicator(currentStep: 2),
              ActivationHeader(
                imagePath: 'assets/images/mobile_blue_logo.png',
                title: 'Verify Your Phone',

                subtitle:
                    'We have sent a 4-digit verification code to\n+${controller.phoneController.text}',
              ),

              // حقل Pinput
              Directionality(
                textDirection: TextDirection.ltr,
                child: Pinput(
                  length: 4,
                  controller: controller.otpController,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyDecorationWith(
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  onCompleted: (pin) {},
                ),
              ),
              const SizedBox(height: 30),

              //  إعادة إرسال الرمز
              Obx(() => Column(
                children: [
                  const Text(
                    "Didn't receive the code?",
                    style: TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: controller.secondsRemaining.value == 0
                        ? () => controller.resendOtp()
                        : null,
                    child: Text(
                      controller.secondsRemaining.value == 0
                          ? "Resend Code"
                          : "Resend in (00:${controller.secondsRemaining.value.toString().padLeft(2, '0')})",
                      style: TextStyle(
                        color: controller.secondsRemaining.value == 0
                            ? Colors.blue
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              )),

              const SizedBox(height: 20),
              Obx(
                () => controller.isLoading
                    ? const CircularProgressIndicator()
                    : PrimaryButton(
                        text: 'Verify and Activate Account',
                        onPressed: controller.verifyOtp,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

```

### File: lib\views\auth\activation\phone_activation_view.dart
```dart
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
              const ActivationHeader(
                imagePath: 'assets/images/shield_blue_logo.png',
                title: 'Activate Account',
                subtitle: 'Enter your phone number registered at the clinic',
              ),

              CustomTextField(
                controller: controller.phoneController,
                hintText: 'phone number',
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Please enter your registered phone number',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 40),
              Obx(
                () => controller.isLoading
                    ? const CircularProgressIndicator()
                    : PrimaryButton(
                        text: 'Send Verification Code',
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

```

### File: lib\views\auth\activation\set_new_password_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth/activation_controller.dart';
import '../../../widgets/activation_helpers.dart';
import '../../../widgets/custom_text_field.dart';

class SetNewPasswordView extends GetView<ActivationController> {
  const SetNewPasswordView({super.key});

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
              const StepProgressIndicator(currentStep: 3),
              const ActivationHeader(
                imagePath: 'assets/images/lock_blue_logo.png',
                title: 'Create New Password',
                subtitle: 'Create a strong password to protect your account',
              ),

              Obx(
                () => CustomTextField(
                  controller: controller.passwordController,
                  hintText: 'New Password',
                  isPassword: controller.isPasswordHidden.value,
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isPasswordHidden.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: controller.togglePasswordVisibility,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Obx(
                () => CustomTextField(
                  controller: controller.confirmPasswordController,
                  hintText: 'Confirm Password',
                  isPassword: controller.isPasswordHidden.value,
                ),
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Password must contain:',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    SizedBox(height: 12),
                    PasswordRequirementRow(text: 'At least 8 characters'),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              Obx(
                () => controller.isLoading
                    ? const CircularProgressIndicator()
                    : PrimaryButton(
                        text: 'Set Password and Login',
                        onPressed: controller.completeActivation,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

```

### File: lib\views\auth\forget_password\forgot_password_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth/forgot_password_controller.dart';

class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Image.asset('assets/images/logo.jpg', height: 120),
              const SizedBox(height: 20),
              const Text(
                "Forgot Password?",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D2451),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Don't worry, enter your phone number and we will send you a verification code.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 40),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Phone Number",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller.phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '9639XXXXXXXX', // إضافة تلميح للمستخدم
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // الاستماع اللحظي لحالة التحميل باستخدام الكود الموحد الخاص بك
              Obx(() => SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: controller.isLoading ? null : () => controller.sendCode(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A86D1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: controller.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Send Verification Code",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              )),

              const SizedBox(height: 40),
              Image.asset('assets/images/child_welcome.png',)
            ],
          ),
        ),
      ),
    );
  }
}
```

### File: lib\views\auth\forget_password\otp_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import '../../../controllers/auth/forgot_password_controller.dart';

class OtpView extends StatelessWidget {
  const OtpView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ForgotPasswordController>();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Image.asset('assets/images/logo.jpg', height: 100),
              const SizedBox(height: 20),
              const Text(
                "Verify Your Number",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "We sent a 4-digit code to",
                style: TextStyle(color: Colors.grey),
              ),

              Text(
                controller.phoneController.text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 40),

              Pinput(
                length: 4,
                controller: controller.otpController,
                defaultPinTheme: PinTheme(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Obx(
                () => Column(
                  children: [
                    const Text(
                      "Didn't receive the code?",
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: controller.secondsRemaining.value == 0
                          ? () => controller.sendCode()
                          : null,
                      child: Text(
                        controller.secondsRemaining.value == 0
                            ? "Resend Code"
                            : "Resend in (00:${controller.secondsRemaining.value.toString().padLeft(2, '0')})",
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: controller.isLoading
                        ? null
                        : () => controller.verifyCode(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A86D1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: controller.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Verify",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 50),
              Image.asset('assets/images/shield_logo.jpg', height: 120),
            ],
          ),
        ),
      ),
    );
  }
}

```

### File: lib\views\auth\forget_password\reset_password_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth/forgot_password_controller.dart';

class ResetPasswordView extends StatelessWidget {
  const ResetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ForgotPasswordController>();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Image.asset('assets/images/logo.jpg', height: 100),
            const SizedBox(height: 20),
            const Text(
              "Create New Password",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Your new password must be different",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            Obx(
              () => TextField(
                controller: controller.passwordController,
                obscureText: !controller.isPasswordVisible.value,
                decoration: InputDecoration(
                  hintText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isPasswordVisible.value
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () => controller.isPasswordVisible.toggle(),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Obx(
              () => TextField(
                controller: controller.confirmPasswordController,
                obscureText: !controller.isConfirmVisible.value,
                decoration: InputDecoration(
                  hintText: "Confirm Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isConfirmVisible.value
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () => controller.isConfirmVisible.toggle(),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            Obx(
              () => SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: controller.isLoading
                      ? null
                      : () => controller.updatePassword(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A86D1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: controller.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Update Password",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 50),
            Image.asset('assets/images/lock_logo.jpg', height: 150),
          ],
        ),
      ),
    );
  }
}

```

### File: lib\views\auth\forget_password\success_reset_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SuccessResetView extends StatelessWidget {
  const SuccessResetView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/green_checkmark.jpg', height: 200),

              const SizedBox(height: 40),

              // العنوان الرئيسي
              const Text(
                "Password Updated!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D2755),
                ),
              ),

              const SizedBox(height: 15),

              // الوصف
              const Text(
                "Your password has been updated successfully. You can now log in with your new password.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
              ),

              const SizedBox(height: 50),

              // زر الذهاب لتسجيل الدخول
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // العودة لصفحة تسجيل الدخول ومسح كل الصفحات السابقة من الذاكرة
                    Get.offAllNamed('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A86D1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "Back to Login",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // صورة الطفل (الولد) في الأسفل
              Image.asset('assets/images/child_welcome.jpg', height: 200),
            ],
          ),
        ),
      ),
    );
  }
}

```

### File: lib\views\auth\login_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/login_controller.dart';

import '../../controllers/settings_controller.dart';
import '../../core/repos/auth/login_repo.dart';

import '../../widgets/custom_text_field.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController(loginRepo: LoginRepo()));
    final size = MediaQuery.of(context).size;
    final settingsController = Get.put(SettingsController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Obx(() {
              final isArabic = settingsController.currentLanguage.value == 'ar';
              return TextButton.icon(
                icon: const Icon(Icons.language, size: 20, color: Color(0xFF4A86D1)),
                label: Text(
                  isArabic ? 'English' : 'العربية',
                  style: const TextStyle(
                    color: Color(0xFF4A86D1),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                onPressed: () {

                  settingsController.changeLanguage(isArabic ? 'en' : 'ar');
                },
              );
            }),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.jpg',
                  height: size.height * 0.25,
                ),
                const SizedBox(height: 20),
                 Text(
                  'Welcome Back'.tr,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                CustomTextField(
                  controller: controller.phoneController,
                  hintText: 'Phone Number'.tr,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                Obx(
                  () => CustomTextField(
                    controller: controller.passwordController,
                    hintText: 'Password'.tr,
                    isPassword: controller.isPasswordHidden.value,
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.isPasswordHidden.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: controller.togglePasswordVisibility,
                    ),
                  ),
                ),

                Align(
                  alignment:AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () {
                      Get.toNamed('/forgot-password');
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child:  Text(
                      'Forgot Password?'.tr,
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Obx(
                  () => controller.isLoading
                      ? const CircularProgressIndicator()
                      : PrimaryButton(
                          text: 'Login'.tr,
                          onPressed: controller.login,
                        ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    const Expanded(
                      child: Divider(thickness: 1, color: Colors.grey),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'Or'.tr,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(thickness: 1, color: Colors.grey),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                OutlinedPrimaryButton(
                  text: 'Create New Account'.tr,
                  onPressed: () => Get.toNamed('/register'),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () => Get.toNamed('/activation-phone'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: RichText(
                    text:  TextSpan(
                      text: "Have a clinic file? ".tr,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                      children: [
                        TextSpan(
                          text: "Activate account".tr,
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

```

### File: lib\views\auth\sign_up_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/sign_up_controller.dart';
import '../../widgets/custom_text_field.dart';

class SignUpView extends StatelessWidget {
  const SignUpView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SignUpController>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: Image.asset(
          'assets/images/pediatric_clinic_logo.png',
          height: 38,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Create New Account',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Create your account to benefit from our services',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Image.asset(
              'assets/images/doctor_and_children.png',
              height: size.height * 0.18,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),

            CustomTextField(
              controller: controller.firstNameController,
              hintText: 'Enter your name',
              label: 'Name',
              labelIcon: Icons.person_outline,
            ),
            const SizedBox(height: 14),

            CustomTextField(
              controller: controller.lastNameController,
              hintText: 'Enter your last name',
              label: 'Last Name',
              labelIcon: Icons.person_outline,
            ),
            const SizedBox(height: 14),

            CustomTextField(
              controller: controller.emailController,
              hintText: 'Enter your email',
              label: 'Email',
              labelIcon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),

            CustomTextField(
              controller: controller.phoneController,
              hintText: 'Enter your phone number',
              keyboardType: TextInputType.phone,
              label: 'Phone',
              labelIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: 14),

            CustomTextField(
              controller: controller.addressController,
              hintText: 'Enter your address in detail',
              label: 'Address',
              labelIcon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 14),

            Obx(
              () => CustomTextField(
                controller: controller.passwordController,
                hintText: 'Enter your password',
                isPassword: controller.isPasswordHidden.value,
                label: 'Password',
                labelIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isPasswordHidden.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  onPressed: controller.togglePassword,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'At least 8 characters with uppercase, lowercase and a number',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
            const SizedBox(height: 14),

            Obx(
              () => CustomTextField(
                controller: controller.confirmPasswordController,
                hintText: 'Enter your password again',
                isPassword: controller.isConfirmPasswordHidden.value,
                label: 'Confirm Password',
                labelIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isConfirmPasswordHidden.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  onPressed: controller.toggleConfirmPassword,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Obx(
              () => controller.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.blue),
                    )
                  : PrimaryButton(
                      text: 'Create Account',
                      onPressed: controller.signUp,
                    ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Already have an account?',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            const SizedBox(height: 16),

            OutlinedPrimaryButton(text: 'LogIn', onPressed: () => Get.back()),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

```

### File: lib\views\auth\verify_otp_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/verify_otp_controller.dart';
import '../../widgets/custom_text_field.dart';


class VerifyOtpView extends GetView<VerifyOtpController> {
  const VerifyOtpView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),

            Image.asset(
              'assets/images/shield_lock_check_logo.png',
              height: 130,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 28),

            const Text(
              'Verify Your Phone Number',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            Text(
              'We sent a 4-digit verification code to',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              controller.maskedPhone,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 36),

            // OTP Boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OtpBox(
                  controller: controller.otp1,
                  focusNode: controller.f1,
                  onChanged: (v) =>
                      controller.onOtpChanged(v, controller.f2, null),
                ),
                const SizedBox(width: 14),
                OtpBox(
                  controller: controller.otp2,
                  focusNode: controller.f2,
                  onChanged: (v) =>
                      controller.onOtpChanged(v, controller.f3, controller.f1),
                ),
                const SizedBox(width: 14),
                OtpBox(
                  controller: controller.otp3,
                  focusNode: controller.f3,
                  onChanged: (v) =>
                      controller.onOtpChanged(v, controller.f4, controller.f2),
                ),
                const SizedBox(width: 14),
                OtpBox(
                  controller: controller.otp4,
                  focusNode: controller.f4,
                  onChanged: (v) =>
                      controller.onOtpChanged(v, null, controller.f3),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Validity timer
            Obx(
                  () => RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  children: [
                    const TextSpan(text: 'The code is valid for '),
                    TextSpan(
                      text: controller.validityFormatted,
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: ' minutes'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Resend section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Didn't receive the code?",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You can resend the code after the countdown ends',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Obx(
                              () => controller.canResend.value
                              ? GestureDetector(
                            onTap: controller.resendOtp,
                            child: Text(
                              'Resend Code',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          )
                              : Text(
                            controller.resendFormatted,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.blue.shade600,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Verify button
            Obx(
                  () => controller.isLoading
                  ? const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              )
                  : PrimaryButton(
                text: 'Verify',
                onPressed: controller.verifyOtp,
              ),
            ),
            const SizedBox(height: 14),

            // Change phone number
            OutlinedPrimaryButton(
              text: 'Change Phone Number',
              onPressed: () => Get.back(),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}
```

### File: lib\views\home\add_child_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home/add_child_controller.dart';
import '../../widgets/custom_text_field.dart';


class AddChildView extends GetView<AddChildController> {
  const AddChildView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEEF4FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Avatar ───────────────────────────────
            Center(
              child: GestureDetector(
                onTap: controller.pickImage, // ✅
                child: Obx(() => Stack(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white,
                      // ✅ يعرض الصورة المختارة أو الـ placeholder
                      backgroundImage: controller.selectedImage.value != null
                          ? FileImage(controller.selectedImage.value!)
                          : null,
                      child: controller.selectedImage.value == null
                          ? Icon(Icons.person,
                          color: Colors.blue.shade200, size: 60)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF3B9EFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                )),
              ),
            ),

            // ─── Title ────────────────────────────────
            const Center(
              child: Text(
                'Add New Child',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2E5A),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ─── Form Card ────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // First & Last Name
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('First Name',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A2E5A))),
                            const SizedBox(height: 8),
                            CustomTextField(
                              controller: controller.firstNameController,
                              hintText: 'Enter first name',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Last Name',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A2E5A))),
                            const SizedBox(height: 8),
                            CustomTextField(
                              controller: controller.lastNameController,
                              hintText: 'Enter last name',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Gender
                  const Text('Gender',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2E5A))),
                  const SizedBox(height: 10),
                  Obx(() => Row(
                    children: [
                      // Female
                      Expanded(
                        child: GestureDetector(
                          onTap: () => controller.selectGender('female'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: controller.selectedGender.value == 'female'
                                  ? const Color(0xFFFCE4EC)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: controller.selectedGender.value == 'female'
                                    ? Colors.pinkAccent
                                    : Colors.grey.shade300,
                                width: controller.selectedGender.value == 'female' ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.face_3,
                                    color: controller.selectedGender.value == 'female'
                                        ? Colors.pinkAccent
                                        : Colors.grey,
                                    size: 22),
                                const SizedBox(width: 8),
                                Text('Female',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: controller.selectedGender.value == 'female'
                                          ? Colors.pinkAccent
                                          : Colors.grey,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Male
                      Expanded(
                        child: GestureDetector(
                          onTap: () => controller.selectGender('male'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: controller.selectedGender.value == 'male'
                                  ? const Color(0xFFE3F2FD)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: controller.selectedGender.value == 'male'
                                    ? Colors.blue
                                    : Colors.grey.shade300,
                                width: controller.selectedGender.value == 'male' ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.face,
                                    color: controller.selectedGender.value == 'male'
                                        ? Colors.blue
                                        : Colors.grey,
                                    size: 22),
                                const SizedBox(width: 8),
                                Text('Male',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: controller.selectedGender.value == 'male'
                                          ? Colors.blue
                                          : Colors.grey,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),
                  const SizedBox(height: 20),

                  // Birth Date
                  const Text('Birth Date',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2E5A))),
                  const SizedBox(height: 8),
                  Obx(() => GestureDetector(
                    onTap: () => controller.pickBirthDate(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              color: Colors.blue, size: 20),
                          Text(
                            controller.selectedBirthDate.value.isEmpty
                                ? 'Select birth date'
                                : controller.selectedBirthDate.value,
                            style: TextStyle(
                              fontSize: 13,
                              color: controller.selectedBirthDate.value.isEmpty
                                  ? Colors.grey.shade400
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                  const SizedBox(height: 20),

                  // Blood Type
                  const Text('Blood Type',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2E5A))),
                  const SizedBox(height: 8),
                  Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Icon(Icons.water_drop_outlined,
                                color: Colors.blue, size: 18),
                            const SizedBox(width: 8),
                            Text('Select blood type',
                                style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 13)),
                          ],
                        ),
                        value: controller.selectedBloodType.value.isEmpty
                            ? null
                            : controller.selectedBloodType.value,
                        items: controller.bloodTypes
                            .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type,
                              textAlign: TextAlign.right),
                        ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            controller.selectedBloodType.value = val;
                          }
                        },
                      ),
                    ),
                  )),
                  const SizedBox(height: 20),

                  // Medical History
                  const Text('Medical History',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2E5A))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller.medicalHistoryController,
                    maxLines: 3,
                    textAlign: TextAlign.left,
                    decoration: InputDecoration(
                      hintText: "Enter child's medical history",
                      hintStyle: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13),
                      suffixIcon: const Icon(Icons.calendar_month_outlined,
                          color: Colors.blue),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Colors.blue, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Allergies
                  const Text('Allergies',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2E5A))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller.allergiesController,
                    maxLines: 3,
                    textAlign: TextAlign.left,
                    decoration: InputDecoration(
                      hintText: 'Enter any allergies the child has',
                      hintStyle: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13),
                      suffixIcon: const Icon(Icons.shield_outlined,
                          color: Colors.blue),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Colors.blue, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Save Button
                  Obx(() => controller.isLoading
                      ? const Center(
                      child: CircularProgressIndicator(
                          color: Colors.blue))
                      : PrimaryButton(
                    text: 'Save',
                    onPressed: controller.addChild,
                  )),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
```

### File: lib\views\home\appointments_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home/appointments_controller.dart';
import '../../models/home/appointments_model.dart';



class AppointmentsView extends GetView<AppointmentsController> {
  const AppointmentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F4FF),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Appointments',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2E5A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Color(0xFF1A2E5A), size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          //  Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Obx(() => Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  // Upcoming Tab
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.switchTab(true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: controller.showUpcoming.value
                              ? const Color(0xFF3B9EFF)
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
                                  : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Upcoming',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: controller.showUpcoming.value
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Past Tab
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.switchTab(false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !controller.showUpcoming.value
                              ? const Color(0xFF3B9EFF)
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
                                  : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Past',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: !controller.showUpcoming.value
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ),
          const SizedBox(height: 16),

          //  List
          Expanded(
            child: Obx(() {
              if (controller.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.blue),
                );
              }

              final list = controller.showUpcoming.value
                  ? controller.upcoming
                  : controller.past;

              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'No appointments found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, index) =>
                    _AppointmentCard(appointment: list[index]),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// Appointment Card

class _AppointmentCard extends StatelessWidget {
  final AppointmentsModel appointment;

  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Doctor image
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: appointment.doctorImage != null
                ? NetworkImage(appointment.doctorImage!)
                : null,
            child: appointment.doctorImage == null
                ? Icon(Icons.person,
                color: Colors.grey.shade400, size: 30)
                : null,
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.doctorName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2E5A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appointment.specialty,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 14, color: Colors.blue.shade400),
                    const SizedBox(width: 4),
                    Text(
                      appointment.date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('|',
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time_outlined,
                        size: 14, color: Colors.blue.shade400),
                    const SizedBox(width: 4),
                    Text(
                      appointment.time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### File: lib\views\home\child_profile_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home/add_child_controller.dart';
import '../../models/home/home_child_model.dart';


class ChildProfileView extends StatelessWidget {
  const ChildProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeChildModel child = Get.arguments as HomeChildModel;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Child Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2E5A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Color(0xFF1A2E5A), size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            _InfoCard(child: child),
            const SizedBox(height: 16),
            const _StatsCard(),
            const SizedBox(height: 16),
            const _AllergiesCard(),
            const SizedBox(height: 16),

            _ActionButton(
              icon: Icons.vaccines_outlined,
              label: 'Vaccination Record',
              color: Colors.blue,
              onTap: () => Get.toNamed(
                '/vaccinations',
                arguments: child.id,
              ),
            ),
            const SizedBox(height: 10),
            _ActionButton(
              icon: Icons.calendar_today_outlined,
              label: 'Appointments',
              color: Colors.blue,
              onTap: () => Get.toNamed(
                '/appointments',
                arguments: child.id,
              ),
            ),
            const SizedBox(height: 10),
            _ActionButton(
              icon: Icons.medical_information_outlined,
              label: 'Medical Prescriptions',
              color: Colors.blue,
              onTap: () {
                // TODO: Get.toNamed('/prescriptions', arguments: child.id)
              },
            ),
            const SizedBox(height: 16),

            // Delete Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.dialog(
                    AlertDialog(
                      title: const Text('Delete Child'),
                      content: const Text(
                        'Are you sure you want to delete this child profile? This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Get.back();
                            Get.find<AddChildController>()
                                .deleteChild(child.id);
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                label: const Text(
                  'Delete Child Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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

// ─── Info Card

class _InfoCard extends StatelessWidget {
  final HomeChildModel child;

  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: Colors.white,
            backgroundImage: (child.image != null && child.image!.isNotEmpty)
                ? NetworkImage(child.image!)
                : null,
            child: (child.image == null || child.image!.isEmpty)
                ? Icon(Icons.person, color: Colors.grey.shade300, size: 55)
                : null,
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                child.name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2E5A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${child.age} years',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 6),
              const Row(
                children: [
                  Text(
                    'Male',
                    style: TextStyle(fontSize: 16, color: Color(0xFF4CAF50)),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.male, color: Color(0xFF4CAF50), size: 18),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Stats Card ───────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  const _StatsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.water_drop_outlined,
              value: 'O+',
              label: 'Blood Type',
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.straighten_outlined,
              value: '95 cm',
              label: 'Height',
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.monitor_weight_outlined,
              value: '11 kg',
              label: 'Weight',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF4CAF50), size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2E5A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 60, color: Colors.grey.shade200);
  }
}

// ─── Allergies Card ───────────────────────────────────────────────────────────

class _AllergiesCard extends StatelessWidget {
  const _AllergiesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Allergies',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2E5A),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2E5A),
                  ),
                ),
              ],
            ),
            const Icon(Icons.chevron_right,
                color: Color(0xFF1A2E5A), size: 22),
          ],
        ),
      ),
    );
  }
}
```

### File: lib\views\home\home_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home/home_controller.dart';
import '../../models/home/home_child_model.dart';



class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  static const List<Map<String, dynamic>> _departments = [
    {
      'label': 'General Pediatrics',
      'icon': Icons.medical_services_outlined,
      'color': Color(0xFFE3F2FD),
      'iconColor': Color(0xFF1E88E5),
      'route': '/doctors',
      'specialty': 'General Pediatrics',
    },
    {
      'label': 'Dental Care',
      'icon': Icons.medical_information_outlined,
      'color': Color(0xFFE3F2FD),
      'iconColor': Color(0xFF1E88E5),
      'route': '/doctors',
      'specialty': 'Dental Care',
    },
    {
      'label': 'Psychiatry',
      'icon': Icons.psychology_outlined,
      'color': Color(0xFFFCE4EC),
      'iconColor': Color(0xFFE91E63),
      'route': '/doctors',
      'specialty': 'Psychiatry',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const _BottomNav(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeaderSection(),
              const SizedBox(height: 24),

              // ✅ ربط الـ Slider بالـ Controller
              Obx(() {
                if (controller.isLoading) {
                  return const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.blue),
                    ),
                  );
                }
                if (controller.children.isEmpty) {
                  return SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.child_care,
                              size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text(
                            'No children added yet',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return _ChildrenSlider(children: controller.children);
              }),

              const SizedBox(height: 20),
              const _BookButton(),
              const SizedBox(height: 28),
              _DepartmentsSection(departments: _departments),
              const SizedBox(height: 28),
              const _ClinicInfoSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _HeaderSection extends GetView<HomeController> {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ✅ صورة البروفايل مع الاسم على اليسار
        Row(
          children: [
            GestureDetector(
              onTap: () => Get.toNamed('/profile'),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: Colors.grey.shade200,
                child: Icon(Icons.person,
                    color: Colors.grey.shade400, size: 28),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                  controller.parentName.value.isEmpty
                      ? 'Welcome!'
                      : controller.parentName.value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                )),
                Text(
                  'Welcome back!',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),

        // ✅ أيقونة الإشعارات على اليمين
        Stack(
          children: [
            GestureDetector(
              onTap: () => Get.toNamed('/notifications'),
              child: const Icon(Icons.notifications_outlined,
                  size: 28, color: Colors.black87),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
// ─── Children Slider ──────────────────────────────────────────────────────────

class _ChildrenSlider extends StatefulWidget {
  final List<HomeChildModel> children;

  const _ChildrenSlider({required this.children});

  @override
  State<_ChildrenSlider> createState() => _ChildrenSliderState();
}

class _ChildrenSliderState extends State<_ChildrenSlider> {
  final PageController _pageController =
  PageController(viewportFraction: 0.5);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.length == 1) {
      return Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: _ChildCard(child: widget.children.first),
            ),
          ),
          const Expanded(child: SizedBox()),
        ],
      );
    }

    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.children.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _ChildCard(child: widget.children[index]),
          );
        },
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final HomeChildModel child;

  const _ChildCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () => Get.toNamed('/child-profile', arguments: child),

      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFD6F5D6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // ✅ صورة الطفل من السيرفر
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white,
                  backgroundImage: (child.image != null &&
                      child.image!.isNotEmpty)
                      ? NetworkImage(child.image!)
                      : null,
                  child: (child.image == null || child.image!.isEmpty)
                      ? Icon(Icons.person,
                      color: Colors.grey.shade400, size: 40)
                      : null,
                ),
              ),
            ),

            // ✅ الاسم والعمر من الـ API
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    child.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${child.age} years',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//  Book Button

class _BookButton extends StatelessWidget {
  const _BookButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: () {
          // TODO: Get.toNamed('/book-appointment')
        },
        icon: const Icon(Icons.add_circle_outline,
            color: Colors.white, size: 22),
        label: const Text(
          'Book New Appointment',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B9EFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

//  Departments

class _DepartmentsSection extends StatelessWidget {
  final List<Map<String, dynamic>> departments;

  const _DepartmentsSection({required this.departments});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'Departments',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: departments
              .map((dept) => _DepartmentItem(department: dept))
              .toList(),
        ),
      ],
    );
  }
}

class _DepartmentItem extends StatelessWidget {
  final Map<String, dynamic> department;

  const _DepartmentItem({required this.department});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.toNamed(
          department['route'],
          arguments: department['specialty'],
        );
      },
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Icon(
              department['icon'] as IconData,
              color: department['iconColor'] as Color,
              size: 36,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            department['label'],
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

//  Clinic Info

class _ClinicInfoSection extends StatelessWidget {
  const _ClinicInfoSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.local_hospital_outlined,
                color: Colors.blue.shade200, size: 48),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About the Clinic',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We provide comprehensive healthcare for your children with the highest quality standards.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    // TODO: Get.toNamed('/about-clinic')
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Read More',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: Colors.blue, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//  Bottom Navigation

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.more_horiz,
            label: 'More',
            isSelected: false,
            onTap: () => Get.toNamed('/more'),
          ),
          _NavItem(
            icon: Icons.calendar_month_outlined,
            label: 'Appointments',
            isSelected: false,
            onTap: () => Get.toNamed('/appointments'),
          ),
          GestureDetector(
            onTap: () => Get.toNamed('/add-child'),
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFF3B9EFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
          // _NavItem(
          //   icon: Icons.vaccines_outlined,
          //   label: 'Vaccinations',
          //   isSelected: false,
          //   onTap: () => Get.toNamed('/vaccinations'),
          // ),
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            isSelected: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected
                ? const Color(0xFF3B9EFF)
                : Colors.grey.shade400,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected
                  ? const Color(0xFF3B9EFF)
                  : Colors.grey.shade400,
              fontWeight:
              isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
```

### File: lib\views\home\profile_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home/profile_controller.dart';


class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Personal Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2E5A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Color(0xFF1A2E5A), size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blue),
          );
        }

        if (controller.profile.value == null) {
          return const Center(child: Text('Failed to load profile'));
        }

        final profile = controller.profile.value!;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            // ✅ تغيير إلى start
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // ─── Avatar ─── مركز دائماً
              Center(
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: const Color(0xFFE8F5E9),
                  child: Icon(Icons.person,
                      color: const Color(0xFF4CAF50).withOpacity(0.6),
                      size: 60),
                ),
              ),
              const SizedBox(height: 16),

              // ─── Full Name ✅ من اليسار
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  profile.fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2E5A),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ─── Info Items ───────────────────────────
              _ProfileItem(
                icon: Icons.email_outlined,
                label: 'Email',
                value: profile.email,
                onEdit: () {
                  // TODO: تعديل البريد الإلكتروني
                },
              ),
              const SizedBox(height: 12),

              _ProfileItem(
                icon: Icons.phone_outlined,
                label: 'Phone Number',
                value: profile.phoneNumber,
                onEdit: () {
                  // TODO: تعديل رقم الهاتف
                },
              ),
              const SizedBox(height: 12),

              _ProfileItem(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: profile.address,
                onEdit: () {
                  // TODO: تعديل العنوان
                },
              ),
              const SizedBox(height: 12),

              _ProfileItem(
                icon: Icons.group_outlined,
                label: 'Number of Children',
                value: profile.childrenCount.toString(),
                onEdit: () {
                  // TODO: الانتقال لإدارة الأطفال
                },
              ),
              const SizedBox(height: 28),

              // ─── Logout Button ────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: controller.logout,
                  icon: const Icon(Icons.logout, color: Color(0xFF1A2E5A)),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2E5A),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8EAF6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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

// ─── Profile Item ─────────────────────────────────────────────────────────────

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onEdit;

  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // ✅ عكس ترتيب الـ Row
      child: Row(
        children: [
          // ─── Icon ✅ على اليسار
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF4CAF50), size: 22),
          ),
          const SizedBox(width: 12),

          // ─── Label & Value ✅ من اليسار
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2E5A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),

          const Spacer(),

          // ─── Edit icon ✅ على اليمين
          GestureDetector(
            onTap: onEdit,
            child: const Icon(Icons.edit_outlined,
                color: Colors.blue, size: 20),
          ),
        ],
      ),
    );
  }
}
```

### File: lib\views\main_advanced.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PediatricClinicScreen extends StatefulWidget {
  final bool hasToken;
  const PediatricClinicScreen({Key? key,  this.hasToken=false}) : super(key: key);

  @override
  State<PediatricClinicScreen> createState() => _PediatricClinicScreenState();
}

class _PediatricClinicScreenState extends State<PediatricClinicScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _doctorController;
  late AnimationController _floatingController;
  late AnimationController _textController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _logoRotationAnimation;

  late Animation<Offset> _doctorSlideAnimation;
  late Animation<double> _doctorOpacityAnimation;

  late Animation<Offset> _floatingAnimation;

  late Animation<double> _textOpacityAnimation;
  late Animation<double> _textScaleAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    _logoRotationAnimation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _textController,
          curve: const Interval(0.4, 1.0, curve: Curves.easeIn)),
    );

    _textScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
          parent: _textController,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack)),
    );

    _doctorController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _doctorSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _doctorController, curve: Curves.easeOutCubic),
    );

    _doctorOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _doctorController, curve: Curves.easeIn),
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnimation =
        Tween<Offset>(
                begin: const Offset(0, -0.015), end: const Offset(0, 0.015))
            .animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _logoController.forward().then((_) => _textController.forward());

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _doctorController.forward();
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        widget.hasToken
            ? Get.offAllNamed('/home')   // ✅ يوجه لـ home إذا يوجد Token
            : Get.offAllNamed('/login');}
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _doctorController.dispose();
    _floatingController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade100,
                    Colors.white,
                    Colors.blue.shade50,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -50,
            right: -50,
            child: _buildBackgroundCircle(150, Colors.blue.withOpacity(0.1)),
          ),
          Positioned(
            bottom: 100,
            left: -30,
            child: _buildBackgroundCircle(100, Colors.pink.withOpacity(0.05)),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Center(
                    child: FadeTransition(
                      opacity: _logoOpacityAnimation,
                      child: ScaleTransition(
                        scale: _logoScaleAnimation,
                        child: RotationTransition(
                          turns: _logoRotationAnimation,
                          child: SlideTransition(
                            position: _floatingAnimation,
                            child: Hero(
                              tag: 'logo',
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.1),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/images/pediatric_clinic_logo.png',
                                  width: 140,
                                  height: 140,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: FadeTransition(
                      opacity: _textOpacityAnimation,
                      child: ScaleTransition(
                        scale: _textScaleAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Kidcare',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: Colors.blue.shade800,
                                shadows: [
                                  Shadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    offset: const Offset(2, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Premium Pediatric Care',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue.shade400,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Center(
                    child: FadeTransition(
                      opacity: _doctorOpacityAnimation,
                      child: SlideTransition(
                        position: _doctorSlideAnimation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Image.asset(
                            'assets/images/doctor_and_children.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

```

### File: lib\views\payment\checkout_summary_view.dart
```dart
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
                height: 55,
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

```

### File: lib\views\payment\payment_method_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/payment_controller.dart';
import '../../widgets/payment_widgets.dart';

class PaymentMethodView extends GetView<PaymentController> {
  const PaymentMethodView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(PaymentController());

    // إجبار الكونترولر على اختيار الأونلاين كقيمة افتراضية (2)
    controller.selectedPaymentMethod.value = 2;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Finalize Appointment',
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
              // تم إضافة صورة المحفظة الخاصة بك بدلاً من الأيقونة الزرقاء
              child: Image.asset(
                'assets/images/wallet_lock_icon.png',
                height: 250,
              ),
            ),
            const SizedBox(height: 40),

            // البطاقة الإجبارية الوحيدة (Pay Online)
            PaymentMethodCard(
              title: 'Pay Online Now',
              subtitle: 'Pay online to confirm booking',
              value: 2,
              groupValue: 2,
              // دائماً محددة
              onTap: () {},
              // لا تفعل شيئاً عند الضغط لأنها إجبارية
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
                child: const Text(
                  'Confirm & Proceed',
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

```

### File: lib\views\payment\payment_success_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
              // تم إضافة صورة النجاح الخاصة بك هنا
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

              // كارت ملخص الفاتورة
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    InvoiceRow(label: 'Date', value: 'Sun, 12 May 2024'),
                    SizedBox(height: 12),
                    InvoiceRow(label: 'Time', value: '10:00 AM'),
                    SizedBox(height: 12),
                    InvoiceRow(label: 'Doctor', value: 'Dr. Sarah Ahmed'),
                    SizedBox(height: 12),
                    InvoiceRow(label: 'Amount', value: '200 SAR'),
                    Divider(height: 30),
                    InvoiceRow(
                      label: 'Transaction ID',
                      value: '#PAY-2024-5678',
                      isBold: true,
                    ),
                  ],
                ),
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
                  onPressed: () => Get.offAllNamed('/home'),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {},
                child: Text(
                  'View Appointment Details',
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

```

### File: lib\views\settings\settings_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/settings_controller.dart';

import '../../widgets/settings/profile_card.dart';
import '../../widgets/settings/settings_section.dart';
import '../../widgets/settings/settings_tile.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SettingsController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'settings'.tr,
          style: const TextStyle(
            color: Color(0xFF1D2755),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.blue),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1.  البروفايل
            ProfileCard(
              name: 'أحمد الرحال',
              email: 'ahmed.mohamed@email.com',
              imageUrl: 'https://i.pravatar.cc/150?img=11',
              onViewProfile: () {
                // Get.toNamed('/profile');
              },
            ),
            const SizedBox(height: 25),

            // 2. قسم الحساب
            SettingsSection(
              title: 'account'.tr,
              children: [
                SettingsTile(
                  icon: Icons.person_outline,
                  title: 'profile'.tr,
                  subtitle: 'edit_personal_info'.tr,
                  onTap: () {},
                ),
                SettingsTile(
                  icon: Icons.face,
                  title: 'your_children'.tr,
                  subtitle: 'manage_children_info'.tr,
                  onTap: () {},
                ),
                SettingsTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'payment_data'.tr,
                  subtitle: 'manage_payment_methods'.tr,
                  showDivider: false,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 25),

            // 3. قسم التفضيلات
            SettingsSection(
              title: 'preferences'.tr,
              children: [
                Obx(
                  () => SettingsTile(
                    icon: Icons.language,
                    title: 'language'.tr,
                    subtitle: controller.currentLanguage.value == 'ar'
                        ? 'العربية'
                        : 'English',
                    onTap: () => _showLanguageBottomSheet(context, controller),
                  ),
                ),
                SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'theme'.tr,
                  subtitle: 'light_mode'.tr,
                  onTap: () {},
                ),
                SettingsTile(
                  icon: Icons.text_fields,
                  title: 'font_size'.tr,
                  subtitle: 'medium'.tr,
                  onTap: () {},
                ),
                SettingsTile(
                  icon: Icons.notifications_none,
                  title: 'notifications'.tr,
                  subtitle: 'manage_notifications'.tr,
                  showDivider: false,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 25),

            // 4. قسم الدعم والمزيد
            SettingsSection(
              title: 'support_and_more'.tr,
              children: [
                SettingsTile(
                  icon: Icons.help_outline,
                  title: 'help_center'.tr,
                  subtitle: 'faq_and_support'.tr,
                  onTap: () {},
                ),
                SettingsTile(
                  icon: Icons.description_outlined,
                  title: 'app_rating'.tr,
                  subtitle: 'share_your_opinion'.tr,
                  onTap: () {},
                ),
                SettingsTile(
                  icon: Icons.info_outline,
                  title: 'about_app'.tr,
                  subtitle: '${'version'.tr} 1.0.0',
                  onTap: () {},
                ),
                SettingsTile(
                  icon: Icons.logout,
                  title: 'logout'.tr,
                  subtitle: 'logout_from_account'.tr,
                  isLogout: true,
                  showDivider: false,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showLanguageBottomSheet(
    BuildContext context,
    SettingsController controller,
  ) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'change_language'.tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),


            Obx(
              () => RadioGroup<String>(
                groupValue: controller.currentLanguage.value,
                onChanged: (value) {
                  if (value != null) {
                    controller.changeLanguage(value);
                    Get.back(); // إغلاق النافذة
                  }
                },
                child: const Column(
                  children: [

                    RadioListTile<String>(
                      title: Text(
                        'English',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      value: 'en',
                      activeColor: Colors.blue,
                    ),
                    RadioListTile<String>(
                      title: Text(
                        'العربية',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      value: 'ar',
                      activeColor: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

```

### File: lib\widgets\activation_helpers.dart
```dart
import 'package:flutter/material.dart';

// 1. شريط التقدم (Step Indicator)
class StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  const StepProgressIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        bool isActive = index < currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 4,
          width: isActive ? 30 : 15,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

// 2. ترويسة الصفحة (Header Section)
class ActivationHeader extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;

  const ActivationHeader({
    super.key,
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Image.asset(imagePath, height: 200, fit: BoxFit.contain),
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// 3. صف شروط كلمة المرور
class PasswordRequirementRow extends StatelessWidget {
  final String text;
  const PasswordRequirementRow({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: Colors.grey),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
```

### File: lib\widgets\booking_app_bar.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/booking_theme.dart';

PreferredSizeWidget bookingAppBar({required String subtitle}) {
  return AppBar(
    backgroundColor: kBookingBackground,
    elevation: 0,
    scrolledUnderElevation: 0,
    toolbarHeight: 72,
    leading: Padding(
      padding: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () => Get.back(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.chevron_left_rounded,
            color: kBookingTextPrimary,
            size: 26,
          ),
        ),
      ),
    ),
    title: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Book New Appointment',
          style: TextStyle(
            color: kBookingTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            color: kBookingTextSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
    centerTitle: true,
  );
}

```

### File: lib\widgets\booking_calendar.dart
```dart
import 'package:flutter/material.dart';

const _kPrimary = Color(0xFF3B82F6);
const _kUnavailable = Color(0xFFEF4444);
const _kTextPrimary = Color(0xFF1F2937);
const _kTextSecondary = Color(0xFF6B7280);
const _kTextDisabled = Color(0xFFD1D5DB);
const _kNavButtonBg = Color(0xFFF3F4F6);

/// Inline month-view calendar used in the booking flow.
///
/// Past dates (before [minDate]) are non-tappable. Selected date is a filled
/// blue circle with a soft glow; today shows a subtle dot under the number
/// when not selected. Switching months animates with a small slide+fade.
class BookingCalendar extends StatefulWidget {
  final DateTime? selectedDate;
  final DateTime minDate;
  final DateTime? maxDate;
  final ValueChanged<DateTime> onDateSelected;

  /// Dart weekdays (Mon=1..Sun=7) the doctor works on.
  /// Empty = unknown / not loaded — calendar shows no red marks.
  /// Any weekday NOT in this set is rendered as unavailable (red line, untappable).
  final Set<int> workingWeekdays;

  const BookingCalendar({
    super.key,
    required this.selectedDate,
    required this.minDate,
    this.maxDate,
    required this.onDateSelected,
    this.workingWeekdays = const <int>{},
  });

  @override
  State<BookingCalendar> createState() => _BookingCalendarState();
}

class _BookingCalendarState extends State<BookingCalendar> {
  late DateTime _currentMonth;
  bool _slideForward = true;

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const _weekdayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void initState() {
    super.initState();
    final initial = widget.selectedDate ?? widget.minDate;
    _currentMonth = DateTime(initial.year, initial.month);
  }

  @override
  void didUpdateWidget(BookingCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newSelected = widget.selectedDate;
    if (newSelected != null &&
        (newSelected.year != _currentMonth.year ||
            newSelected.month != _currentMonth.month)) {
      _slideForward = !newSelected.isBefore(
        DateTime(_currentMonth.year, _currentMonth.month),
      );
      _currentMonth = DateTime(newSelected.year, newSelected.month);
    }
  }

  void _prev() {
    setState(() {
      _slideForward = false;
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _next() {
    setState(() {
      _slideForward = true;
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _jumpToToday() {
    final now = DateTime.now();
    final target = DateTime(now.year, now.month);
    if (target.year == _currentMonth.year &&
        target.month == _currentMonth.month) {
      return;
    }
    setState(() {
      _slideForward = target.isAfter(_currentMonth);
      _currentMonth = target;
    });
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildWeekdayLabels(),
          const SizedBox(height: 8),
          ClipRect(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final slide = Tween<Offset>(
                  begin: Offset(_slideForward ? 0.12 : -0.12, 0),
                  end: Offset.zero,
                ).animate(animation);
                return SlideTransition(
                  position: slide,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(
                  '${_currentMonth.year}-${_currentMonth.month}',
                ),
                child: _buildGrid(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final onCurrentMonth = _currentMonth.year == now.year &&
        _currentMonth.month == now.month;

    return Row(
      children: [
        _NavButton(icon: Icons.chevron_left_rounded, onTap: _prev),
        Expanded(
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _kTextPrimary,
                    letterSpacing: 0.1,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SizeTransition(
                      axis: Axis.horizontal,
                      sizeFactor: animation,
                      child: child,
                    ),
                  ),
                  child: onCurrentMonth
                      ? const SizedBox.shrink(key: ValueKey('no-pill'))
                      : Padding(
                          key: const ValueKey('today-pill'),
                          padding: const EdgeInsets.only(left: 8),
                          child: _TodayPill(onTap: _jumpToToday),
                        ),
                ),
              ],
            ),
          ),
        ),
        _NavButton(icon: Icons.chevron_right_rounded, onTap: _next),
      ],
    );
  }


  Widget _buildWeekdayLabels() {
    return Row(
      children: _weekdayLabels
          .map(
            (l) => Expanded(
              child: Center(
                child: Text(
                  l,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _kTextSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildGrid() {
    final firstOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final firstWeekday = firstOfMonth.weekday % 7;
    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final today = DateTime.now();
    final minNormalized = DateTime(
      widget.minDate.year,
      widget.minDate.month,
      widget.minDate.day,
    );

    final totalCells = firstWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              if (cellIndex < firstWeekday || cellIndex >= totalCells) {
                return const Expanded(child: SizedBox(height: 44));
              }
              final day = cellIndex - firstWeekday + 1;
              final date = DateTime(
                _currentMonth.year,
                _currentMonth.month,
                day,
              );
              final isSelected = widget.selectedDate != null &&
                  _sameDay(date, widget.selectedDate!);
              final isToday = _sameDay(date, today);
              final isPast = date.isBefore(minNormalized);
              final isUnavailable = !isPast &&
                  widget.workingWeekdays.isNotEmpty &&
                  !widget.workingWeekdays.contains(date.weekday);

              return Expanded(
                child: _DayCell(
                  day: day,
                  isSelected: isSelected,
                  isToday: isToday,
                  isPast: isPast,
                  isUnavailable: isUnavailable,
                  onTap: (isPast || isUnavailable)
                      ? null
                      : () => widget.onDateSelected(date),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isSelected;
  final bool isToday;
  final bool isPast;
  final bool isUnavailable;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.isPast,
    required this.isUnavailable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = isSelected
        ? Colors.white
        : isPast
            ? _kTextDisabled
            : isUnavailable
                ? _kTextDisabled
                : isToday
                    ? _kPrimary
                    : _kTextPrimary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: 44,
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? _kPrimary : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _kPrimary.withOpacity(0.32),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected || isToday
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: textColor,
              ),
            ),
            if (isUnavailable && !isSelected)
              Positioned(
                bottom: 7,
                child: Container(
                  width: 14,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: _kUnavailable,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              )
            else if (isToday && !isSelected)
              Positioned(
                bottom: 7,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: _kPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _kNavButtonBg,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: _kTextPrimary, size: 22),
        ),
      ),
    );
  }
}

class _TodayPill extends StatelessWidget {
  final VoidCallback onTap;
  const _TodayPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _kPrimary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Today',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

```

### File: lib\widgets\custom_text_field.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isPassword;
  final TextInputType keyboardType;

  // Eye icon on the right
  final Widget? suffixIcon;

  // Extra widget if needed
  final Widget? prefixIconWidget;

  // Label + icon
  final String? label;
  final IconData? labelIcon;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.prefixIconWidget,
    this.label,
    this.labelIcon,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasLabel = label != null;

    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      textAlign: TextAlign.left,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 13,
        ),

        // LEFT SIDE (Label + Icon)
        prefixIconConstraints: hasLabel
            ? const BoxConstraints(minHeight: 0, minWidth: 0)
            : null,

        prefixIcon: hasLabel
            ? Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.ltr,
            children: [
              if (labelIcon != null) ...[
                Icon(
                  labelIcon,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                const SizedBox(width: 8),
              ],

              Text(
                label!,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(width: 12),
            ],
          ),
        )
            : prefixIconWidget,

        // RIGHT SIDE (Password eye icon)
        suffixIcon: suffixIcon,

        filled: true,
        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.blue,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class OutlinedPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const OutlinedPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.blue,
          side: const BorderSide(color: Colors.blue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class OtpBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const OtpBox({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  State<OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<OtpBox> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.focusNode.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = widget.focusNode.hasFocus;
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused ? Colors.blue : Colors.grey.shade300,
          width: isFocused ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}
```

### File: lib\widgets\main_bottom_nav.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainBottomNav extends StatelessWidget {
  final int currentIndex;

  const MainBottomNav({super.key, required this.currentIndex});

  static const List<_NavItem> _items = [
    _NavItem(label: 'More', icon: Icons.more_horiz, route: '/more'),
    _NavItem(
      label: 'Records',
      icon: Icons.folder_outlined,
      route: '/records',
    ),
    _NavItem(label: 'Home', icon: Icons.home_rounded, route: '/home'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _items.asMap().entries.map((entry) {
          final bool isSelected = entry.key == currentIndex;
          final item = entry.value;
          return GestureDetector(
            onTap: () {
              if (isSelected) return;
              Get.offAllNamed(item.route);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  color: isSelected
                      ? const Color(0xFF3B9EFF)
                      : Colors.grey.shade400,
                  size: 26,
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected
                        ? const Color(0xFF3B9EFF)
                        : Colors.grey.shade400,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String route;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

```

### File: lib\widgets\payment_widgets.dart
```dart
import 'package:flutter/material.dart';

class PaymentMethodCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int value;
  final int groupValue;
  final VoidCallback onTap;
  final Widget? trailingWidget; // التعديل هنا: ليدعم أيقونة أو صورة

  const PaymentMethodCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onTap,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    bool isSelected = value == groupValue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF4F9FF) : Colors.white,
          border: Border.all(
              color: isSelected ? const Color(0xFF1976D2) : Colors.grey.shade300,
              width: isSelected ? 2 : 1
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF1976D2) : Colors.black87)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                ],
              ),
            ),
            if (trailingWidget != null) trailingWidget!, // عرض الأيقونة أو الصورة هنا
          ],
        ),
      ),
    );
  }
}

class PaymentOptionCard extends StatelessWidget {
  final String title;
  final int value;
  final int groupValue;
  final VoidCallback onTap;
  final Widget? trailingWidget; // التعديل هنا لدعم صور الشعارات المتعددة

  const PaymentOptionCard({
    super.key,
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onTap,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    bool isSelected = value == groupValue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
              color: isSelected ? const Color(0xFF1976D2) : Colors.grey.shade300,
              width: isSelected ? 2 : 1
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isSelected ? const Color(0xFF1976D2) : Colors.grey.shade400, size: 24),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500))),
            if (trailingWidget != null) trailingWidget!, // عرض الصور
          ],
        ),
      ),
    );
  }
}

class PaymentSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const PaymentSummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isTotal ? Colors.black87 : Colors.grey.shade600, fontWeight: isTotal ? FontWeight.bold : FontWeight.w500, fontSize: isTotal ? 16 : 14)),
        Text(value, style: TextStyle(color: isTotal ? const Color(0xFF1976D2) : Colors.black87, fontWeight: FontWeight.bold, fontSize: isTotal ? 18 : 15)),
      ],
    );
  }
}

class InvoiceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const InvoiceRow({
    super.key,
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14)
        ),
        Text(
            value,
            style: TextStyle(
                color: Colors.black87,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontSize: 14
            )
        ),
      ],
    );
  }
}
```

### File: lib\widgets\settings\profile_card.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileCard extends StatelessWidget {
  final String name;
  final String email;
  final String imageUrl;
  final VoidCallback onViewProfile;

  const ProfileCard({
    super.key,
    required this.name,
    required this.email,
    required this.imageUrl,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF2FA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(radius: 35, backgroundImage: NetworkImage(imageUrl)),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D2755),
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onViewProfile,
                  child: Row(
                    children: [
                      Text(
                        'view_profile'.tr,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.blue,
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

```

### File: lib\widgets\settings\settings_section.dart
```dart
import 'package:flutter/material.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, right: 10, left: 10),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D2755),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

```

### File: lib\widgets\settings\settings_tile.dart
```dart
import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLogout;
  final bool showDivider;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLogout = false,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          leading: Icon(
            icon,
            color: isLogout ? Colors.red : Colors.blue,
            size: 28,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isLogout ? Colors.red : const Color(0xFF1D2755),
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey,
          ),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.shade100,
            indent: 60,
            endIndent: 20,
          ),
      ],
    );
  }
}

```

### File: lib\widgets\upcoming_appointments_section.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../controllers/appointment/my_appointments_controller.dart';
import '../models/appointment/appointment_model.dart';

// Placeholder rows shown behind the skeleton shimmer while real data loads.
// Negative ids guarantee they never collide with real backend records.
final _fakeAppointments = List<AppointmentModel>.generate(
  2,
  (i) => AppointmentModel(
    id: -i - 1,
    childId: -1,
    doctorId: -1,
    date: '2026-01-01',
    time: '09:00',
    status: 'pending',
    price: 0,
    doctorName: 'Dr. Loading Name',
    childName: 'Child Name',
  ),
);

/// Home-page card listing the soonest upcoming appointments.
///
/// Reads from [MyAppointmentsController.upcoming] reactively and renders at
/// most [maxItems] entries sorted chronologically (earliest first). Shows a
/// skeleton while loading and an empty-state card when the list is empty.
class UpcomingAppointmentsSection extends StatelessWidget {
  final MyAppointmentsController controller;

  /// Caps how many appointments to render. The home page only wants a
  /// preview; the full list lives on the dedicated appointments screen.
  final int maxItems;

  const UpcomingAppointmentsSection({
    super.key,
    required this.controller,
    this.maxItems = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Upcoming Appointments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Obx(() {
          final isLoading = controller.isLoading;
          // Sort by "date time" string — works because date is ISO (YYYY-MM-DD)
          // and time is HH:mm, so lexicographic order matches chronological.
          final appointments = isLoading
              ? _fakeAppointments
              : (controller.upcoming.toList()
                  ..sort((a, b) =>
                      '${a.date} ${a.time}'.compareTo('${b.date} ${b.time}')))
                  .take(maxItems)
                  .toList();

          if (!isLoading && appointments.isEmpty) {
            return const _EmptyAppointmentsCard();
          }

          return Skeletonizer(
            enabled: isLoading,
            child: Column(
              children: appointments
                  .map(
                    (apt) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AppointmentCard(appointment: apt),
                    ),
                  )
                  .toList(),
            ),
          );
        }),
      ],
    );
  }
}

/// Placeholder shown when the user has no upcoming appointments.
class _EmptyAppointmentsCard extends StatelessWidget {
  const _EmptyAppointmentsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available_outlined,
            color: Colors.grey.shade400,
            size: 28,
          ),
          const SizedBox(height: 8),
          const Text(
            'No upcoming appointments',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

/// Single appointment row — doctor, child, status pill, date/time, and a
/// placeholder avatar. Tap should open the appointment details screen.
class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;

  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Get.toNamed('/appointment-details', arguments: appointment)
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    appointment.doctorName ?? 'Doctor #${appointment.doctorId}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appointment.childName ?? 'Child #${appointment.childId}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _StatusPill(status: appointment.status),
                      const SizedBox(width: 8),
                      Text(
                        '${appointment.date} • ${appointment.time}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.person,
                color: Colors.grey.shade400,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Color-coded status badge. Backend status strings come in lowercase, so we
/// normalize then map each known value to a (background, foreground) pair.
/// Anything unknown — including empty — falls back to the "pending" style.
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
        bg = Colors.green.shade50;
        fg = Colors.green.shade600;
        break;
      case 'cancelled':
      case 'canceled':
        bg = Colors.red.shade50;
        fg = Colors.red.shade600;
        break;
      case 'pending':
      default:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
        break;
    }

    // Capitalize the first letter for display ("pending" → "Pending").
    final label = status.isEmpty
        ? 'Pending'
        : status[0].toUpperCase() + status.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}

```

