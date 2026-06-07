# KidCare Project Code

### File: lib\controllers\appointment\appointment_controller.dart
```dart
import 'package:get/get.dart';
import '../../core/repos/appointment/appointment_repo.dart';

import '../../core/repos/appointment/doctor_repo.dart';
import '../../models/appointment/child_model.dart';
import '../../models/appointment/doctor_model.dart';
import '../base_controller.dart';

class AppointmentController extends BaseController {
  final AppointmentRepo repo;
  final DoctorRepo doctorRepo;

  AppointmentController({required this.repo, required this.doctorRepo});

  final selectedDoctor = Rxn<DoctorModel>();
  final selectedChild = Rxn<ChildModel>();
  final selectedDate = Rxn<DateTime>();
  final selectedTime = RxnString();

  final availableTimes = <String>[].obs;
  final isLoadingSlots = false.obs;
  final workingWeekdays = <int>{}.obs;


  final bookedAppointmentId = RxnString();

  void selectDoctor(DoctorModel doctor) => selectedDoctor.value = doctor;

  void selectChild(ChildModel child) => selectedChild.value = child;

  void selectDate(DateTime date) {
    selectedDate.value = date;
    selectedTime.value = null;
    availableTimes.clear();
  }

  void selectTime(String time) => selectedTime.value = time;

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
    } catch (_) {}
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
      showInfo('Please complete doctor, child, date, and time selection'.tr);
      return false;
    }

    showLoading();
    bool success = false;
    try {

      final convertedTime = _convertTo24h(time);

      bookedAppointmentId.value = await repo.book(
        doctorId: doctor.id,
        childId: child.id,
        date: _formatDate(date),
        time: convertedTime,
      );
      success = true;
    } catch (e) {
      handleError(e);
      selectedTime.value = null;
      loadSlots();
    } finally {
      hideLoading();
    }
    return success;
  }


  String _convertTo24h(String time12h) {
    try {

      if (time12h.toLowerCase().contains('am') ||
          time12h.toLowerCase().contains('pm')) {
        final parts = time12h.trim().split(' ');
        final timePart = parts[0];
        final amPm = parts[1].toLowerCase();

        final hourMin = timePart.split(':');
        int hour = int.parse(hourMin[0]);
        final String min = hourMin[1];

        if (amPm == 'pm' && hour < 12) hour += 12;
        if (amPm == 'am' && hour == 12) hour = 0;

        return '${hour.toString().padLeft(2, '0')}:$min';
      }
    } catch (_) {}
    return time12h;
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month
        .toString();
    final day = d.day.toString();
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
import '../../core/repos/appointment/favorite_repo.dart';
import '../../models/appointment/doctor_model.dart';
import '../../models/appointment/doctor_availability_model.dart';
import '../base_controller.dart';

class DoctorController extends BaseController {
  final DoctorRepo repo;
  final FavoriteRepo favoriteRepo = FavoriteRepo();

  DoctorController({required this.repo});

  final doctors = <DoctorModel>[].obs;
  final favoriteDoctors = <DoctorModel>[].obs;
  final favDoctorIds = <int>{}.obs;
  final weeklyAvailability = <DoctorAvailabilityModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadFavoriteDoctorIds();
  }


  Future<void> loadFavoriteDoctorIds() async {
    try {
      final favs = await favoriteRepo.fetchFavoriteDoctors();
      favoriteDoctors.assignAll(favs);
      favDoctorIds.assignAll(favs.map((d) => d.id));
    } catch (_) {}
  }


  Future<void> toggleFavorite(int doctorId) async {
    if (favDoctorIds.contains(doctorId)) {
      favDoctorIds.remove(doctorId);
      favoriteDoctors.removeWhere((d) => d.id == doctorId);
    } else {
      favDoctorIds.add(doctorId);

      final doc = doctors.firstWhereOrNull((d) => d.id == doctorId);
      if (doc != null) favoriteDoctors.add(doc);
    }
    favDoctorIds.refresh();

    try {

      await favoriteRepo.toggleDoctorFavorite(doctorId);
    } catch (e) {

      loadFavoriteDoctorIds();
      handleError(e);
    }
  }

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

  Future<void> loadOne(String id) async {
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
          _doctorNameCache[id] = '${'Doctor # '.tr}$id';
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
        childName: _childNameCache[a.childId] ?? '${'Child #'.tr}${a.childId}',
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
        "Notice".tr,
        phone.isEmpty
            ? "Please enter phone number".tr
            : "Phone number must be 12 numbers (e.g., 9639XXXXXXXX)".tr,
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
        "Success".tr,
        "Verification code resent successfully".tr,
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
        "Check Code".tr,
        otp.isEmpty
            ? "Please enter OTP".tr
            : "Please enter the 4-digit code correctly".tr,
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
        "Required Fields".tr,
        "Please fill in all fields".tr,
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
        "Error".tr,
        "Passwords do not match".tr,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    // 3. التحقق من طول كلمة المرور
    if (password.length < 8) {
      Get.snackbar(
        "Weak Password".tr,
        "Password must be at least 8 characters long".tr,
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
        "Success".tr,
        "Account activated successfully".tr,
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
        "Notice".tr,
        "Please enter a valid phone number".tr,
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
        "Notice".tr,
        "Please enter the 4-digit code".tr,
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
        "Weak Password".tr,
        "Password must be at least 8 characters long".tr,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    if (password != confirmPassword) {
      Get.snackbar(
        "Error".tr,
        "Passwords do not match".tr,
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
        "Required Fields".tr,
        "Please fill in all fields".tr,
        backgroundColor: Colors.grey.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    // 2. التحقق من طول رقم الهاتف
    if (phone.length != 12) {
      Get.snackbar(
        "Invalid Phone Number".tr,
        "Phone number must be exactly 12 numbers (e.g., 9639XXXXXXXX)".tr,
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
        "Success".tr,
        "${"Welcome Back,".tr} ${user.firstName}" "!" ,
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
        'Required Fields'.tr,
        'Please fill in all fields'.tr,
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
        'Invalid Phone Number'.tr,
        'Phone number must be exactly 12 numbers (e.g., 9639XXXXXXXX)'.tr,
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
        'Error'.tr,
        'Passwords do not match'.tr,
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
        'Weak Password'.tr,
        'Password must be at least 8 characters long'.tr,
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
        'Success'.tr,
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
        'Required'.tr,
        'Please enter the verification code'.tr,
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
        'Invalid Code'.tr,
        'Please enter the complete 4-digit code'.tr,
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
        'Success'.tr,
        'Phone verified successfully!'.tr,
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
        'Success'.tr,
        'Code resent successfully!'.tr,
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
    String message = "Something went wrong. Please try again.".tr;

    try {
      if (errorString.contains("401")) {

        message = "Incorrect phone number or password.".tr;
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
        message = "No Internet connection. Please check your network.".tr;
      } else if (errorString.contains("TimeoutException")) {
        message = "Request timed out. Please try again.".tr;
      }
    } catch (_) {
      // JSON parse failed — fall through to the generic message above.
    }

    Get.snackbar(
      "Error".tr,
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
      "Success".tr,
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
      "Info".tr,
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
import 'home_controller.dart';

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
        'Success'.tr,
        'Child deleted successfully!'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
      );

      await Future.delayed(const Duration(seconds: 1));
      Get.offAllNamed('/home');
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

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
    final now = DateTime.now();
    final earliestAllowedDate = DateTime(now.year - 6, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: earliestAllowedDate,
      lastDate: now,
    );
    if (picked != null) {
      selectedBirthDate.value =
      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> addChild() async {
    // التحقق من الحقول الإلزامية فقط (Mandatory Fields)
    if (firstNameController.text.isEmpty || lastNameController.text.isEmpty) {
      Get.snackbar(
        'Required Fields'.tr,
        'Please enter first and last name'.tr,
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
        'Required Fields'.tr,
        'Please select birth date'.tr,
        backgroundColor: Colors.grey.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    final birthDate = DateTime.tryParse(selectedBirthDate.value);
    if (birthDate != null) {
      final now = DateTime.now();
      final ageLimitDate = DateTime(now.year - 6, now.month, now.day);
      if (birthDate.isBefore(ageLimitDate)) {
        Get.snackbar(
          'Invalid Age',
          'Child age cannot exceed 6 years.',
          backgroundColor: Colors.grey.shade700,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(15),
          duration: const Duration(seconds: 2),
        );
        return;
      }
    }

    if (selectedBloodType.value.isEmpty) {
      Get.snackbar(
        'Required Fields'.tr,
        'Please select blood type'.tr,
        backgroundColor: Colors.grey.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // ─── منطق معالجة الحقول الاختيارية (Optional Fields Sanitization) ───
    // إذا قام المستخدم بترك الحقل فارغاً، نقوم بتمرير نص افتراضي نظيف للسيرفر
    final String medicalHistory = medicalHistoryController.text.trim().isEmpty
        ? 'No medical history'
        : medicalHistoryController.text.trim();

    final String allergies = allergiesController.text.trim().isEmpty
        ? 'No allergies'
        : allergiesController.text.trim();

    showLoading();
    try {
      await addChildRepo.addChild(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        gender: selectedGender.value,
        birthDate: selectedBirthDate.value,
        bloodType: selectedBloodType.value,
        medicalHistory: medicalHistory, // تمرير القيمة المعالجة
        allergies: allergies,           // تمرير القيمة المعالجة
        image: selectedImage.value,
      );

      Get.snackbar(
        'Success'.tr,
        'Child added successfully!'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
      );
      await Future.delayed(const Duration(seconds: 1));
      Get.back();
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().fetchChildren();
      }
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
import '../../models/home/appointments_model.dart';
import '../base_controller.dart';

class AppointmentsController extends BaseController {
  final AppointmentsRepo appointmentsRepo;

  AppointmentsController({required this.appointmentsRepo});

  // جعلناه Nullable، فإذا كان null، فهذا يعني أننا طلبنا كل المواعيد
  int? childId;

  final RxList<AppointmentsModel> upcoming = <AppointmentsModel>[].obs;
  final RxList<AppointmentsModel> past = <AppointmentsModel>[].obs;
  final RxBool showUpcoming = true.obs;

  @override
  void onInit() {
    super.onInit();
    // التقاط الـ ID إذا أتينا من شاشة الطفل، وإلا سيبقى null
    if (Get.arguments is int) {
      childId = Get.arguments as int;
    }
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
      // توجيه ذكي للطلب
      final result = childId != null
          ? await appointmentsRepo.getUpcomingForChild(childId!)
          : await appointmentsRepo.getAllUpcoming();
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
      // توجيه ذكي للطلب
      final result = childId != null
          ? await appointmentsRepo.getPastForChild(childId!)
          : await appointmentsRepo.getAllPast();
      past.assignAll(result);
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }
}
```

### File: lib\controllers\home\child_profile_controller.dart
```dart
import 'package:get/get.dart';
import '../../core/repos/home/child_profile_repo.dart';
import '../../models/appointment/child_model.dart';
import '../../models/home/home_child_model.dart';
import '../base_controller.dart';
import 'add_child_controller.dart';

class ChildProfileController extends BaseController {
  final ChildProfileRepo repo;

  ChildProfileController({required this.repo});

  final Rx<ChildModel?> child = Rx<ChildModel?>(null);
  late int childId;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;

    // استخراج الـ ID سواء تم تمرير HomeChildModel أو ID مباشر
    if (arg is HomeChildModel) {
      childId = arg.id;
    } else if (arg is int) {
      childId = arg;
    } else {
      childId = 0;
    }

    if (childId != 0) {
      fetchChildDetails();
    }
  }

  Future<void> fetchChildDetails() async {
    showLoading();
    try {
      final result = await repo.getChildDetails(childId);
      child.value = result;
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  // استخدام دالة الحذف الموجودة في AddChildController لتجنب تكرار الكود
  Future<void> deleteCurrentChild() async {
    if (Get.isRegistered<AddChildController>()) {
      Get.find<AddChildController>().deleteChild(childId);
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
```

### File: lib\controllers\settings_controller.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/helper/secure_storage_service.dart';

class SettingsController extends GetxController {

  var currentLanguage = 'system'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    String? savedLang = await SecureStorage.getLanguage();

    if (savedLang != null) {
      currentLanguage.value = savedLang;
      _applyLocale(savedLang);
    } else {

      currentLanguage.value = 'system';
      _applyLocale('system');
    }
  }

  Future<void> changeLanguage(String langCode) async {
    if (currentLanguage.value == langCode) return;

    currentLanguage.value = langCode;
    await SecureStorage.storeLanguage(langCode);
    _applyLocale(langCode);
  }

  void _applyLocale(String langCode) {
    Locale targetLocale;

    if (langCode == 'system') {

      Locale? deviceLocale = Get.deviceLocale;
      if (deviceLocale != null && deviceLocale.languageCode == 'ar') {
        targetLocale = const Locale('ar', 'SA');
      } else {
        targetLocale = const Locale('en', 'US');
      }
    } else if (langCode == 'ar') {
      targetLocale = const Locale('ar', 'SA');
    } else {
      targetLocale = const Locale('en', 'US');
    }


    Get.updateLocale(targetLocale);
  }
}
```

### File: lib\core\apis\appointment\appointment_api.dart
```dart
import 'package:http/http.dart' as http;
import '../../constants.dart';
import 'package:get/get.dart';

class AppointmentApi {
  final http.Client client = http.Client();

  Future<String> create(String token, Map<String, dynamic> body) async {
    final response = await client.post(
      Uri.parse('$baseUrl/appointment'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
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
        'Accept-Language': Get.locale?.languageCode ?? 'en',
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
        'Accept-Language': Get.locale?.languageCode ?? 'en',
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
        'Accept-Language': Get.locale?.languageCode ?? 'en',
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
        'Accept-Language': Get.locale?.languageCode ?? 'en',
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
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );
    return response.body;
  }

  Future<String> getById(String token, String appointmentId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/appointments/$appointmentId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );
    return response.body;
  }

  Future<String> update(
    String token,
      String appointmentId,
    Map<String, dynamic> body,
  ) async {
    final response = await client.put(
      Uri.parse('$baseUrl/appointments/$appointmentId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
      body: body.map((k, v) => MapEntry(k, v.toString())),
    );
    return response.body;
  }

  Future<String> delete(String token, String appointmentId) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/appointments/$appointmentId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
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
import 'package:get/get.dart';

class ChildApi {
  final http.Client client = http.Client();

  Future<String> getMine(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/children'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        "Accept-Language": Get.locale?.languageCode ?? "en",
      },
    );
    return response.body;
  }
}

```

### File: lib\core\apis\appointment\department_api.dart
```dart
import 'package:get/get.dart';
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
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );
    return response.body;
  }
}

```

### File: lib\core\apis\appointment\doctor_api.dart
```dart
import 'dart:convert';
import 'package:get/get.dart';
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
        "Accept-Language": Get.locale?.languageCode ?? "en",
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
        "Accept-Language": Get.locale?.languageCode ?? "en",
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
        "Accept-Language": Get.locale?.languageCode ?? "en",
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
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        "Accept-Language": Get.locale?.languageCode ?? "en",
      },
      body: jsonEncode({'date': date}),
    );
    return response.body;
  }
}

```

### File: lib\core\apis\appointment\favorite_api.dart
```dart
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../constants.dart';

class FavoriteApi {
  final http.Client client = http.Client();


  Future<String> getFavorites(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/favorites'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );
    return response.body;
  }


  Future<String> toggleFavorite(String token, int doctorId) async {
    final response = await client.post(
      Uri.parse('$baseUrl/doctors/$doctorId/favorite'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );
    return response.body;
  }
}
```

### File: lib\core\apis\auth\activation_api.dart
```dart
import 'package:http/http.dart' as http;
import '../../constants.dart';
import 'package:get/get.dart';

class ActivationApi {
  final http.Client client = http.Client();

  // 1. طلب إرسال رمز OTP
  Future<String> sendOtp(String phoneNumber) async {
    final response = await client.post(
      Uri.parse("$baseUrl/sendOtp"),
      headers: {
        "Accept": "application/json",
        "Accept-Language": Get.locale?.languageCode ?? "en",
      },
      body: {"phone_number": phoneNumber},
    );
    return response.body;
  }

  // 2. التحقق من الرمز
  Future<String> verifyOtp(String phoneNumber, String otp) async {
    final response = await client.post(
      Uri.parse("$baseUrl/verifyOtp"),
      headers: {
        "Accept": "application/json",
        "Accept-Language": Get.locale?.languageCode ?? "en",
      },
      body: {"phone_number": phoneNumber, "otp": otp},
    );
    return response.body;
  }

  // 3. تعيين كلمة المرور
  Future<String> setPassword(String phoneNumber, String password) async {
    final response = await client.post(
      Uri.parse("$baseUrl/SetPassword"),
      headers: {
        "Accept": "application/json",
        "Accept-Language": Get.locale?.languageCode ?? "en",
      },
      body: {
        "phone_number": phoneNumber,
        "password": password,
        "password_confirmation": password,
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
import 'package:get/get.dart';
import '../../constants.dart';

class LoginApi {
  Future<String> login(String phoneNumber, String password) async {
    try {
      var response = await http
          .post(
            Uri.parse("$baseUrl/login"),
            headers: {
              "Accept": "application/json",
              "Accept-Language": Get.locale?.languageCode ?? "en",
            },
            body: {"phone_number": phoneNumber, "password": password},
          )
          .timeout(const Duration(seconds: 15));

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
import 'package:get/get.dart';

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
        "Accept-Language": Get.locale?.languageCode ?? "en",
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
import 'package:get/get.dart';

class VerifyOtpApi {
  final http.Client client = http.Client();

  // مهمة الدالة فقط إرسال البيانات وإرجاع الرد كـ String
  Future<String> verify({required String phone, required String otp}) async {
    debugPrint('── VerifyOtpApi.verify ─────────────────');
    debugPrint('phone=$phone | otp=$otp');

    final response = await client.post(
      Uri.parse('$baseUrl/verifyOtp'),
      headers: {
        'Accept': 'application/json',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
      body: {'phone_number': phone, 'otp': otp},
    );

    debugPrint('Status: ${response.statusCode} | Body: ${response.body}');
    return response.body;
  }

  Future<String> resend({required String phone}) async {
    debugPrint('── VerifyOtpApi.resend ─────────────────');

    final response = await client.post(
      Uri.parse('$baseUrl/sendOtp'),
      headers: {
        'Accept': 'application/json',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
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
import 'package:get/get.dart';
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
        'Accept-Language': Get.locale?.languageCode ?? 'en',
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
      'Accept-Language': Get.locale?.languageCode ?? 'en',
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

### File: lib\core\apis\home\appointments_api.dart
```dart
import 'package:http/http.dart' as http;
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';
import 'package:get/get.dart';

class AppointmentsApi {
  final http.Client client = http.Client();

  // 1- Upcoming (لجميع مواعيد المستخدم)
  Future<String> getAllUpcoming() async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) throw Exception('Session expired. Please login again.');
    final response = await client.get(
      Uri.parse('$baseUrl/appointments/upcoming'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    return response.body;
  }

  // 2- Past (لجميع مواعيد المستخدم)
  Future<String> getAllPast() async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) throw Exception('Session expired. Please login again.');
    final response = await client.get(
      Uri.parse('$baseUrl/appointments/past'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    return response.body;
  }

  // 3- Upcoming by Child (لمواعيد طفل محدد)
  Future<String> getUpcomingForChild(int childId) async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) throw Exception('Session expired. Please login again.');
    final response = await client.get(
      Uri.parse('$baseUrl/appointments/upcoming/$childId'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    return response.body;
  }

  // 4- Past by Child (لمواعيد طفل محدد)
  Future<String> getPastForChild(int childId) async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) throw Exception('Session expired. Please login again.');
    final response = await client.get(
      Uri.parse('$baseUrl/appointments/past/$childId'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    return response.body;
  }
}
```

### File: lib\core\apis\home\child_profile_api.dart
```dart
import 'package:http/http.dart' as http;
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';

class ChildProfileApi {
  final http.Client client = http.Client();

  Future<String> getChildDetails(int childId) async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) {
      throw Exception('Session expired. Please login again.');
    }

    final response = await client.get(
      Uri.parse('$baseUrl/children/$childId'),
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
import 'package:get/get.dart';
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
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );

    return response.body;
  }
}

```

### File: lib\core\apis\home\parent_name_api.dart
```dart
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
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
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );

    return response.body;
  }
}

```

### File: lib\core\apis\home\profile_api.dart
```dart
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
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
        'Accept-Language': Get.locale?.languageCode ?? 'en',
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
import 'package:get/get.dart';
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
          'Accept-Language': Get.locale?.languageCode ?? 'en',
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


      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/payment/checkout'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      });

      request.fields['appointment_id'] = appointmentId;
      request.fields['currency'] = currency.toUpperCase();

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);



      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.body;
      } else {
        var errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Backend Error: ${response.body}',
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
const String baseUrl = 'https://deputize-daylong-puritan.ngrok-free.dev/api';

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

### File: lib\core\helper\notification_service.dart
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../helper/secure_storage_service.dart';
import '../constants.dart';

// 🌟 1.  الخلفية ( Top Level Function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  //  تهيئة فايربيس ً لأن التطبيق (Terminated)
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // 1.  الاستماع في الخلفية (Background & Terminated)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. طلب الصلاحيات من المستخدم
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('🔔 Notification permission granted.');

      // رفع التوكن الحالي
      await uploadFcmToken();

      //  3. تحديث التوكن التلقائي
      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('🔄 FCM Token Refreshed: $newToken');
        await uploadFcmToken(forcedToken: newToken);
      });
    }

    // 4. حالة الـ Foreground (التطبيق مفتوح )
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Got a message while in the foreground!');
      if (message.notification != null) {
        Get.snackbar(
          message.notification!.title ?? 'Notification'.tr,
          message.notification!.body ?? '',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
        );
      }
    });

    // 5. حالة الـ Background (التطبيق في الخلفية )
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔓 Notification clicked! Opened app from background.');
      _handleNotificationClick(message);
    });

    //  6. حالة الـ Terminated (التطبيق كان مغلقاً تماماً )
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🚀 App launched from terminated state via notification.');
      _handleNotificationClick(initialMessage);
    }
  }

  //  توجيه المستخدم عند الضغط على الإشعار
  static void _handleNotificationClick(RemoteMessage message) {
    // يمكنك لاحقاً قراءة message.data لتوجيه المستخدم لشاشة معينة
    // حالياً سنوجهه لشاشة المواعيد كافتراضي
    Get.toNamed('/appointments');
  }

  //  رفع التوكن للباك إند
  static Future<void> uploadFcmToken({String? forcedToken}) async {
    try {
      String? fcmToken = forcedToken ?? await _messaging.getToken();
      debugPrint('🔑 🔑 🔑 MY DEVICE FCM TOKEN = $fcmToken');
      if (fcmToken == null) return;

      String userToken = await SecureStorage.getToken();
      if (userToken.isEmpty) return;

      final response = await http.post(
        Uri.parse('$baseUrl/user/update-fcm-token'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $userToken',
          'Accept-Language': Get.locale?.languageCode ?? 'en',
        },
        body: {
          'fcm_token': fcmToken,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ FCM Token synced with Laravel successfully.');
      } else {
        debugPrint('⚠️ Failed to sync FCM Token: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error syncing FCM Token: $e');
    }
  }
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
      'Home': 'Home',
      'Appointments': 'Appointments',
      'Records': 'Records',
      'More': 'More',
      'Next': 'Next',
      'Or': 'Or',
      'Cancel': 'Cancel',
      'Delete': 'Delete',
      'Save': 'Save',
      'Done': 'Done',
      'Verify': 'Verify',
      'Today': 'Today',
      'version': 'Version',

      // --- Login View ---
      'Welcome Back': 'Welcome Back',
      'Phone Number': 'Phone Number',
      'Password': 'Password',
      'Forgot Password?': 'Forgot Password?',
      'Login': 'Login',
      'Create New Account': 'Create New Account',
      'Have a clinic file? ': 'Have a clinic file? ',
      'Activate account': 'Activate account',
      'LogIn': 'LogIn',

      // --- Sign Up View ---
      'Create your account to benefit from our services': 'Create your account to benefit from our services',
      'Enter your name': 'Enter your name',
      'Name': 'Name',
      'Enter your last name': 'Enter your last name',
      'Last Name': 'Last Name',
      'Enter your email': 'Enter your email',
      'Email': 'Email',
      'Enter your phone number': 'Enter your phone number',
      'Phone': 'Phone',
      'Enter your address in detail': 'Enter your address in detail',
      'Address': 'Address',
      'Enter your password': 'Enter your password',
      'At least 8 characters with uppercase, lowercase and a number': 'At least 8 characters with uppercase, lowercase and a number',
      'Enter your password again': 'Enter your password again',
      'Confirm Password': 'Confirm Password',
      'Create Account': 'Create Account',
      'Already have an account?': 'Already have an account?',

      // --- Activation & OTP Views ---
      'Activate Account': 'Activate Account',
      'Enter your phone number registered at the clinic': 'Enter your phone number registered at the clinic',
      'phone number': 'phone number',
      'Please enter your registered phone number': 'Please enter your registered phone number',
      'Send Verification Code': 'Send Verification Code',
      'Verify Your Phone': 'Verify Your Phone',
      'Verify Your Phone Number': 'Verify Your Phone Number',
      'Verify Your Number': 'Verify Your Number',
      "Didn't receive the code?": "Didn't receive the code?",
      'Resend Code': 'Resend Code',
      'Resend in': 'Resend in',
      'Verify and Activate Account': 'Verify and Activate Account',
      'Create New Password': 'Create New Password',
      'Create a strong password to protect your account': 'Create a strong password to protect your account',
      'New Password': 'New Password',
      'Password must contain:': 'Password must contain:',
      'At least 8 characters': 'At least 8 characters',
      'Set Password and Login': 'Set Password and Login',
      'The code is valid for ': 'The code is valid for ',
      ' minutes': ' minutes',
      'You can resend the code after the countdown ends': 'You can resend the code after the countdown ends',
      'Change Phone Number': 'Change Phone Number',

      // --- Forgot Password ---
      "Don't worry, enter your phone number and we will send you a verification code.": "Don't worry, enter your phone number and we will send you a verification code.",
      'We sent a 4-digit code to': 'We sent a 4-digit code to',
      'Your new password must be different': 'Your new password must be different',
      'Update Password': 'Update Password',
      'Password Updated!': 'Password Updated!',
      'Your password has been updated successfully. You can now log in with your new password.': 'Your password has been updated successfully. You can now log in with your new password.',
      'Back to Login': 'Back to Login',

      // --- Home View ---
      'Welcome!': 'Welcome!',
      'Welcome back!': 'Welcome back!',
      'No children added yet': 'No children added yet',
      'Book New Appointment': 'Book New Appointment',
      'Departments': 'Departments',
      'General Pediatrics': 'General Pediatrics',
      'Dental Care': 'Dental Care',
      'Psychiatry': 'Psychiatry',
      'About the Clinic': 'About the Clinic',
      'We provide comprehensive healthcare for your children with the highest quality standards.': 'We provide comprehensive healthcare for your children with the highest quality standards.',
      'Read More': 'Read More',

      // --- Add Child & Child Profile ---
      'Child Profile': 'Child Profile',
      'Add New Child': 'Add New Child',
      'First Name': 'First Name',
      'Enter first name': 'Enter first name',
      'Enter last name': 'Enter last name',
      'Gender': 'Gender',
      'Female': 'Female',
      'Male': 'Male',
      'Birth Date': 'Birth Date',
      'Select birth date': 'Select birth date',
      'Blood Type': 'Blood Type',
      'Select blood type': 'Select blood type',
      'Medical History': 'Medical History',
      "Enter child's medical history": "Enter child's medical history",
      'Allergies': 'Allergies',
      'Enter any allergies the child has': 'Enter any allergies the child has',
      'Height': 'Height',
      'Weight': 'Weight',
      'Vaccination Record': 'Vaccination Record',
      'Medical Prescriptions': 'Medical Prescriptions',
      'Delete Child Profile': 'Delete Child Profile',
      'Delete Child': 'Delete Child',
      'Are you sure you want to delete this child profile? This action cannot be undone.': 'Are you sure you want to delete this child profile? This action cannot be undone.',
      'Age': 'Age',
      'Child age cannot exceed 6 years.': 'Child age cannot exceed 6 years.',

      // --- Appointments List View ---
      'My Appointments': 'My Appointments',
      'Child Appointments': 'Child Appointments',
      'Upcoming': 'Upcoming',
      'Past': 'Past',
      'No appointments found': 'No appointments found',
      'Upcoming Appointments': 'Upcoming Appointments',

      // --- Booking Flow ---
      'Choose Doctor': 'Choose Doctor',
      'No departments available': 'No departments available',
      'Pick a department above to see the doctors.': 'Pick a department above to see the doctors.',
      'No doctors available in this department.': 'No doctors available in this department.',
      'Specialist': 'Specialist',
      'rating': 'rating',
      'Choose Child': 'Choose Child',
      "You haven't added any children yet.": "You haven't added any children yet.",
      ' years': ' years',
      'Pick Date & Time': 'Pick Date & Time',
      'Available Times': 'Available Times',
      'Pick a date to see available times.': 'Pick a date to see available times.',
      'No times available for this date.': 'No times available for this date.',
      'Book Appointment': 'Book Appointment',
      'Appointment Booked!': 'Appointment Booked!',
      'Your appointment has been confirmed.\nSee you soon!': 'Your appointment has been confirmed.\nSee you soon!',
      'Dr. ': 'Dr. ',

      // --- Payment & Checkout ---
      'Finalize Appointment': 'Finalize Appointment',
      'Pay Online Now': 'Pay Online Now',
      'Pay online to confirm booking': 'Pay online to confirm booking',
      'Confirm & Proceed': 'Confirm & Proceed',
      'Review & Pay': 'Review & Pay',
      'Date & Time': 'Date & Time',
      'Consultation Fee': 'Consultation Fee',
      'Total': 'Total',
      'Choose how to pay': 'Choose how to pay',
      'Mada': 'Mada',
      'Credit Card (Visa/Mastercard)': 'Credit Card (Visa/Mastercard)',
      'Apple Pay': 'Apple Pay',
      'STC Pay': 'STC Pay',
      'Payment Successful!': 'Payment Successful!',
      'Your appointment is confirmed': 'Your appointment is confirmed',
      'Doctor': 'Doctor',
      'Child': 'Child',
      'Date': 'Date',
      'Time': 'Time',
      'Amount': 'Amount',
      'Transaction ID': 'Transaction ID',
      'Back to Home': 'Back to Home',
      'View My Appointments': 'View My Appointments',
      'Pay ': 'Pay ',

      // --- Profile & Settings ---
      'Personal Profile': 'Personal Profile',
      'Number of Children': 'Number of Children',
      'Logout': 'Logout',
      'settings': 'Settings',
      'language': 'Language',
      'change_language': 'Change Language',
      'theme': 'Theme',
      'light_mode': 'Light Mode',
      'support_and_more': 'Support & More',
      'help_center': 'Help Center',
      'faq_and_support': 'FAQs and Support',
      'app_rating': 'Rate App',
      'share_your_opinion': 'Share your opinion with us',
      'about_app': 'About App',
      'Delete account': 'Delete account',
      'account': 'Account',
      'preferences': 'Preferences',
      'Notice': 'Notice',
      'Please enter phone number': 'Please enter phone number',
      'Phone number must be 12 numbers (e.g., 9639XXXXXXXX)': 'Phone number must be 12 numbers (e.g., 9639XXXXXXXX)',
      'Success': 'Success',
      'Verification code resent successfully': 'Verification code resent successfully',
      'Check Code': 'Check Code',
      'Please enter OTP': 'Please enter the verification code',
      'Please enter the 4-digit code correctly': 'Please enter the 4-digit code correctly',
      'Passwords do not match': 'Passwords do not match',
      'Weak Password': 'Weak Password',
      'Password must be at least 8 characters long': 'Password must be at least 8 characters long',
      'Account activated successfully': 'Account activated successfully',
      'Please enter a valid phone number': 'Please enter a valid phone number',
      'Please enter the 4-digit code': 'Please enter the 4-digit code',
      'Password Updated Successfully!': 'Password Updated Successfully!',
      'Invalid Phone Number': 'Invalid Phone Number',
      'Welcome Back,': 'Welcome Back,',
      'Required': 'Required',
      'Please enter the verification code': 'Please enter the verification code',
      'Invalid Code': 'Invalid Code',
      'Please enter the complete 4-digit code': 'Please enter the complete 4-digit code',
      'Phone verified successfully!': 'Phone verified successfully!',
      'Code resent successfully!': 'Code resent successfully!',
      'Something went wrong. Please try again.': 'Something went wrong. Please try again.',
      'Incorrect phone number or password.': 'Incorrect phone number or password.',
      'No Internet connection. Please check your network.': 'No Internet connection. Please check your network.',
      'Request timed out. Please try again.': 'Request timed out. Please try again.',
      'Error': 'Error',
      'Info': 'Info',
      'Child deleted successfully!': 'Child deleted successfully!',
      'Please enter first and last name': 'Please enter first and last name',
      'Please select birth date': 'Please select birth date',
      'Please select blood type': 'Please select blood type',
      'Child added successfully!': 'Child added successfully!',
      'Failed to load profile': 'Failed to load profile',
      'Error Loading Details': 'Error Loading Details',
      'No appointment data found to process': 'No appointment data found to process',
      'KidCare Clinic': 'KidCare Clinic',
      'Payment Error': 'Payment Error',
      'Payment Cancelled': 'Payment Cancelled',
      'User cancelled the payment': 'User cancelled the payment',
      'An unexpected error occurred': 'An unexpected error occurred',
      'favorite_doctors': 'Favorite Doctors',
      'view_favorite_doctors': 'View your favorite doctors',
    },

    // ==========================================================
    // 2. ARABIC LOCALE (ar_SA)
    // ==========================================================
    'ar_SA': {
      'Home': 'الرئيسية',
      'Appointments': 'المواعيد',
      'Records': 'الملفات',
      'More': 'المزيد',
      'Next': 'التالي',
      'Or': 'أأو',
      'Cancel': 'إلغاء',
      'Delete': 'حذف',
      'Save': 'حفظ',
      'Done': 'تم',
      'Verify': 'تحقق',
      'Today': 'اليوم',
      'version': 'الإصدار',

      // --- Login View ---
      'Welcome Back': 'مرحباً بك مجدداً',
      'Phone Number': 'رقم الهاتف',
      'Password': 'كلمة المرور',
      'Forgot Password?': 'نسيت كلمة المرور؟',
      'Login': 'تسجيل الدخول',
      'Create New Account': 'إنشاء حساب جديد',
      'Have a clinic file? ': 'لديك ملف بالعيادة؟ ',
      'Activate account': 'تفعيل الحساب',
      'LogIn': 'تسجيل الدخول',

      // --- Sign Up View ---
      'Create your account to benefit from our services': 'أنشئ حسابك للاستفادة من خدماتنا',
      'Enter your name': 'أدخل اسمك',
      'Name': 'الاسم',
      'Enter your last name': 'أدخل اسم العائلة',
      'Last Name': 'اسم العائلة',
      'Enter your email': 'أدخل بريدك الإلكتروني',
      'Email': 'البريد الإلكتروني',
      'Enter your phone number': 'أدخل رقم هاتفك',
      'Phone': 'الهاتف',
      'Enter your address in detail': 'أدخل عنوانك بالتفصيل',
      'Address': 'العنوان',
      'Enter your password': 'أدخل كلمة المرور',
      'At least 8 characters with uppercase, lowercase and a number': '8 أحرف على الأقل، تتضمن أحرف كبيرة وصغيرة ورقم',
      'Enter your password again': 'أدخل كلمة المرور مرة أخرى',
      'Confirm Password': 'تأكيد كلمة المرور',
      'Create Account': 'إنشاء الحساب',
      'Already have an account?': 'لديك حساب بالفعل؟',

      // --- Activation & OTP Views ---
      'Activate Account': 'تفعيل الحساب',
      'Enter your phone number registered at the clinic': 'أدخل رقم هاتفك المسجل في العيادة',
      'phone number': 'رقم الهاتف',
      'Please enter your registered phone number': 'يرجى إدخال رقم هاتفك المسجل',
      'Send Verification Code': 'إرسال رمز التحقق',
      'Verify Your Phone': 'تحقق من رقم الهاتف',
      'Verify Your Phone Number': 'تحقق من رقم الهاتف',
      'Verify Your Number': 'تحقق من رقمك',
      "Didn't receive the code?": "لم يصلك الرمز؟",
      'Resend Code': 'إعادة إرسال الرمز',
      'Resend in': 'إعادة الإرسال خلال',
      'Verify and Activate Account': 'تحقق وفعل الحساب',
      'Create New Password': 'إنشاء كلمة مرور جديدة',
      'Create a strong password to protect your account': 'أنشئ كلمة مرور قوية لحماية حسابك',
      'New Password': 'كلمة المرور الجديدة',
      'Password must contain:': 'يجب أن تحتوي كلمة المرور على:',
      'At least 8 characters': '8 أحرف على الأقل',
      'Set Password and Login': 'تعيين كلمة المرور وتسجيل الدخول',
      'The code is valid for ': 'الرمز صالح لمدة ',
      ' minutes': ' دقائق',
      'You can resend the code after the countdown ends': 'يمكنك إعادة إرسال الرمز بعد انتهاء العداد',
      'Change Phone Number': 'تغيير رقم الهاتف',

      // --- Forgot Password ---
      "Don't worry, enter your phone number and we will send you a verification code.": "لا تقلق، أدخل رقم هاتفك وسنرسل لك رمز التحقق.",
      'We sent a 4-digit code to': 'أرسلنا رمزاً من 4 أرقام إلى',
      'Your new password must be different': 'يجب أن تكون كلمة المرور جديدة ومختلفة',
      'Update Password': 'تحديث كلمة المرور',
      'Password Updated!': 'تم تحديث كلمة المرور!',
      'Your password has been updated successfully. You can now log in with your new password.': 'تم تحديث كلمة المرور بنجاح. يمكنك الآن تسجيل الدخول بكلمة المرور الجديدة.',
      'Back to Login': 'العودة لتسجيل الدخول',

      // --- Home View ---
      'Welcome!': 'مرحباً بك!',
      'Welcome back!': 'مرحباً بك مجدداً!',
      'No children added yet': 'لم يتم إضافة أطفال بعد',
      'Book New Appointment': 'حجز موعد جديد',
      'Departments': 'الأقسام',
      'General Pediatrics': 'طب الأطفال العام',
      'Dental Care': 'عناية الأسنان',
      'Psychiatry': 'الطب النفسي',
      'About the Clinic': 'عن العيادة',
      'We provide comprehensive healthcare for your children with the highest quality standards.': 'نقدم رعاية صحية شاملة لأطفالك بأعلى معايير الجودة.',
      'Read More': 'اقرأ المزيد',

      // --- Add Child & Child Profile ---
      'Child Profile': 'ملف الطفل',
      'Add New Child': 'إضافة طفل جديد',
      'First Name': 'الاسم الأول',
      'Enter first name': 'أدخل الاسم الأول',
      'Enter last name': 'أدخل اسم العائلة',
      'Gender': 'الجنس',
      'Female': 'أنثى',
      'Male': 'ذكر',
      'Birth Date': 'تاريخ الميلاد',
      'Select birth date': 'اختر تاريخ الميلاد',
      'Blood Type': 'فصيلة الدم',
      'Select blood type': 'اختر فصيلة الدم',
      'Medical History': 'التاريخ الطبي',
      "Enter child's medical history": "أدخل التاريخ الطبي للطفل",
      'Allergies': 'الحساسية',
      'Enter any allergies the child has': 'أدخل أي حساسية يعاني منها الطفل',
      'Height': 'الطول',
      'Weight': 'الوزن',
      'Vaccination Record': 'سجل اللقاحات',
      'Medical Prescriptions': 'الوصفات الطبية',
      'Delete Child Profile': 'حذف ملف الطفل',
      'Delete Child': 'حذف الطفل',
      'Are you sure you want to delete this child profile? This action cannot be undone.': 'هل أنت متأكد أنك تريد حذف ملف هذا الطفل؟ لا يمكن التراجع عن هذا الإجراء.',
      'Age': 'العمر',
      'Child age cannot exceed 6 years.': 'عمر الطفل لا يمكن أن يتجاوز 6 سنوات.',

      // --- Appointments List View ---
      'My Appointments': 'مواعيدي',
      'Child Appointments': 'مواعيد الطفل',
      'Upcoming': 'القادمة',
      'Past': 'السابقة',
      'No appointments found': 'لا توجد مواعيد',
      'Upcoming Appointments': 'المواعيد القادمة',

      // --- Booking Flow ---
      'Choose Doctor': 'اختر الطبيب',
      'No departments available': 'لا توجد أقسام متاحة',
      'Pick a department above to see the doctors.': 'اختر قسماً من الأعلى لرؤية الأطباء.',
      'No doctors available in this department.': 'لا يوجد أطباء متاحين في هذا القسم.',
      'Specialist': 'أخصائي',
      'rating': 'تقييم',
      'Choose Child': 'اختر الطفل',
      "You haven't added any children yet.": "لم تقم بإضافة أي أطفال بعد.",
      ' years': ' سنوات',
      'Pick Date & Time': 'اختر التاريخ والوقت',
      'Available Times': 'الأوقات المتاحة',
      'Pick a date to see available times.': 'اختر تاريخاً لرؤية الأوقات المتاحة.',
      'No times available for this date.': 'لا توجد أوقات متاح في هذا التاريخ.',
      'Book Appointment': 'تأكيد الحجز',
      'Appointment Booked!': 'تم حجز الموعد!',
      'Your appointment has been confirmed.\nSee you soon!': 'تم تأكيد موعدك.\nنراك قريباً!',
      'Dr. ': 'د. ',

      // --- Payment & Checkout ---
      'Finalize Appointment': 'إتمام الحجز',
      'Pay Online Now': 'الدفع الآن إلكترونياً',
      'Pay online to confirm booking': 'ادفع إلكترونياً لتأكيد الحجز',
      'Confirm & Proceed': 'تأكيد ومتابعة',
      'Review & Pay': 'مراجعة ودفع',
      'Date & Time': 'التاريخ والوقت',
      'Consultation Fee': 'رسوم الكشف',
      'Total': 'الإجمالي',
      'Choose how to pay': 'اختر طريقة الدفع',
      'Mada': 'مدى',
      'Credit Card (Visa/Mastercard)': 'بطاقة ائتمان (فيزا/ماستركارد)',
      'Apple Pay': 'أبل باي',
      'STC Pay': 'إس تي سي باي',
      'Payment Successful!': 'تمت عملية الدفع بنجاح!',
      'Your appointment is confirmed': 'تم تأكيد موعدك',
      'Doctor': 'الطبيب',
      'Child': 'الطفل',
      'Date': 'التاريخ',
      'Time': 'الوقت',
      'Amount': 'المبلغ',
      'Transaction ID': 'رقم العملية',
      'Back to Home': 'العودة للرئيسية',
      'View My Appointments': 'عرض مواعيدي',
      'Pay ': 'دفع ',

      // --- Profile & Settings ---
      'Personal Profile': 'الملف الشخصي',
      'Number of Children': 'عدد الأطفال',
      'Logout': 'تسجيل الخروج',
      'settings': 'الإعدادات',
      'language': 'اللغة',
      'change_language': 'تغيير اللغة',
      'theme': 'المظهر',
      'light_mode': 'الوضع الفاتح',
      'support_and_more': 'الدعم والمزيد',
      'help_center': 'مركز المساعدة',
      'faq_and_support': 'الأسئلة الشائعة والدعم',
      'app_rating': 'تقييم التطبيق',
      'share_your_opinion': 'شاركنا رأيك',
      'about_app': 'عن التطبيق',
      'Delete account': 'حذف الحساب',
      'account': 'الحساب',
      'preferences': 'التفضيلات',
      'Required Fields': 'الحقول المطلوبة',
      'Please fill in all fields': 'يرجى ملء جميع الحقول',
      'Notice': 'تنبيه',
      'Please enter phone number': 'يرجى إدخال رقم الهاتف',
      'Phone number must be 12 numbers (e.g., 9639XXXXXXXX)': 'يجب أن يتكون رقم الهاتف من 12 رقماً (مثال: 9639XXXXXXXX)',
      'Success': 'نجاح',
      'Verification code resent successfully': 'تم إعادة إرسال رمز التحقق بنجاح',
      'Check Code': 'التحقق من الرمز',
      'Please enter OTP': 'يرجى إدخال رمز التحقق',
      'Please enter the 4-digit code correctly': 'يرجى إدخال الرمز المكون من 4 أرقام بشكل صحيح',
      'Passwords do not match': 'كلمتا المرور غير متطابقتين',
      'Weak Password': 'كلمة مرور ضعيفة',
      'Password must be at least 8 characters long': 'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل',
      'Account activated successfully': 'تم تفعيل الحساب بنجاح',
      'Please enter a valid phone number': 'يرجى إدخال رقم هاتف صحيح',
      'Please enter the 4-digit code': 'يرجى إدخال الرمز المكون من 4 أرقام',
      'Password Updated Successfully!': 'تم تحديث كلمة المرور بنجاح!',
      'Invalid Phone Number': 'رقم هاتف غير صحيح',
      'Welcome Back,': 'مرحباً بك مجدداً،',
      'Required': 'مطلوب',
      'Please enter the verification code': 'يرجى إدخال رمز التحقق',
      'Invalid Code': 'رمز غير صحيح',
      'Please enter the complete 4-digit code': 'يرجى إدخال رمز التحقق كاملاً المكون من 4 أرقام',
      'Phone verified successfully!': 'تم التحقق من رقم الهاتف بنجاح!',
      'Code resent successfully!': 'تم إعادة إرسال الرمز بنجاح!',
      'Something went wrong. Please try again.': 'حدث خطأ ما، يرجى المحاولة مرة أخرى.',
      'Incorrect phone number or password.': 'رقم الهاتف أو كلمة المرور غير صحيحة.',
      'No Internet connection. Please check your network.': 'لا يوجد اتصال بالإنترنت، يرجى التحقق من الشبكة.',
      'Request timed out. Please try again.': 'انتهت مهلة الطلب، يرجى المحاولة مجدداً.',
      'Error': 'خطأ',
      'Info': 'معلومات',
      'Child deleted successfully!': 'تم حذف ملف الطفل بنجاح!',
      'Please enter first and last name': 'يرجى إدخال الاسم الأول واسم العائلة',
      'Please select birth date': 'يرجى تحديد تاريخ الميلاد',
      'Please select blood type': 'يرجى اختيار فصيلة الدم',
      'Child added successfully!': 'تم إضافة الطفل بنجاح!',
      'Failed to load profile': 'فشل في تحميل بيانات الملف الشخصي',
      'Error Loading Details': 'خطأ في تحميل التفاصيل',
      'No appointment data found to process': 'لم يتم العثور على بيانات للموعد لإتمام العملية',
      'KidCare Clinic': 'عيادة كيد كير',
      'Payment Error': 'خطأ في عملية الدفع',
      'Payment Cancelled': 'تم إلغاء الدفع',
      'User cancelled the payment': 'قام المستخدم بإلغاء عملية الدفع',
      'An unexpected error occurred': 'حدث خطأ غير متوقع',
      'favorite_doctors': 'الأطباء المفضلون',
      'view_favorite_doctors': 'عرض قائمة أطبائك المفضلين',
    },
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

  Future<String> book({
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

    if (decoded is Map) {

      if (decoded['appointment_id'] != null) {
        return decoded['appointment_id'].toString();
      }

      final raw = decoded['appointment'] ?? decoded['data'];
      if (raw is Map && raw['id'] != null) {
        return raw['id'].toString();
      }
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

  Future<AppointmentModel> fetchOne(String id) async {
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
      String id, {
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

  Future<void> cancel(String id) async {
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

### File: lib\core\repos\appointment\favorite_repo.dart
```dart
import 'dart:convert';
import '../../apis/appointment/favorite_api.dart';
import '../../helper/secure_storage_service.dart';
import '../../../models/appointment/doctor_model.dart';

class FavoriteRepo {
  final FavoriteApi _api = FavoriteApi();


  Future<List<DoctorModel>> fetchFavoriteDoctors() async {
    final token = await SecureStorage.getToken();
    final response = await _api.getFavorites(token);
    final decoded = jsonDecode(response);

    if (decoded is List) {
      return decoded.map((j) => DoctorModel.fromJson(j as Map<String, dynamic>)).toList();
    } else if (decoded is Map && decoded['favorites'] is List) {
      return (decoded['favorites'] as List).map((j) => DoctorModel.fromJson(j as Map<String, dynamic>)).toList();
    }

    throw Exception(decoded['message'] ?? 'Failed to load favorite doctors');
  }


  Future<bool> toggleDoctorFavorite(int doctorId) async {
    final token = await SecureStorage.getToken();
    final response = await _api.toggleFavorite(token, doctorId);
    final decoded = jsonDecode(response);

    if (decoded is Map && decoded['status'] == 'success') {
      return true;
    }
    return false;
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
    String response = await _api.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      address: address,
      password: password,
    );

    // ─── Defensive Programming: Sanitize Backend Response ───
    // تجاهل أي رسائل خطأ أو HTML تسبق بداية الـ JSON الحقيقي
    final int startIndex = response.indexOf(RegExp(r'[\{\[]'));
    if (startIndex != -1) {
      response = response.substring(startIndex);
    }

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
import '../../../models/home/appointments_model.dart';
import '../../apis/home/appointments_api.dart';

class AppointmentsRepo {
  final AppointmentsApi _api = AppointmentsApi();

  // دالة مساعدة لتنظيف الرد القادم من الباك إند وتجنب أخطاء الـ HTML/PHP
  List<AppointmentsModel> _parseResponse(String response) {
    final int startIndex = response.indexOf(RegExp(r'[\{\[]'));
    if (startIndex != -1) {
      response = response.substring(startIndex);
    }

    final body = json.decode(response);

    if (body['appointments'] == null) {
      throw Exception(body['message'] ?? 'Failed to load appointments');
    }

    final List list = body['appointments'];
    return list.map((e) => AppointmentsModel.fromJson(e)).toList();
  }

  Future<List<AppointmentsModel>> getAllUpcoming() async {
    final response = await _api.getAllUpcoming();
    return _parseResponse(response);
  }

  Future<List<AppointmentsModel>> getAllPast() async {
    final response = await _api.getAllPast();
    return _parseResponse(response);
  }

  Future<List<AppointmentsModel>> getUpcomingForChild(int childId) async {
    final response = await _api.getUpcomingForChild(childId);
    return _parseResponse(response);
  }

  Future<List<AppointmentsModel>> getPastForChild(int childId) async {
    final response = await _api.getPastForChild(childId);
    return _parseResponse(response);
  }
}
```

### File: lib\core\repos\home\child_profile_repo.dart
```dart
import 'dart:convert';
import '../../../models/appointment/child_model.dart';
import '../../apis/home/child_profile_api.dart';

class ChildProfileRepo {
  final ChildProfileApi _api = ChildProfileApi();

  Future<ChildModel> getChildDetails(int childId) async {
    String response = await _api.getChildDetails(childId);

    // معالجة دفاعية: تنظيف النص في حال كان السيرفر يرسل تحذيرات HTML قبل الـ JSON
    if (response.contains('{')) {
      response = response.substring(response.indexOf('{'));
    }

    final body = json.decode(response);

    if (body is Map<String, dynamic> && body['id'] != null) {
      return ChildModel.fromJson(body);
    }

    throw Exception(body['message'] ?? 'Failed to load child details');
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
    String response = await _api.getChildren();

    // ─── Defensive Programming: Sanitize Backend Response ───
    // البحث عن أول ظهور لقوس بداية الـ JSON لتجاهل أي تحذيرات PHP أو HTML تسبقه
    final int startIndex = response.indexOf(RegExp(r'[\{\[]'));
    if (startIndex != -1) {
      response = response.substring(startIndex);
    }

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
    String response = await _api.getParentName();

    // ─── Defensive Programming: Sanitize Backend Response ───
    final int startIndex = response.indexOf(RegExp(r'[\{\[]'));
    if (startIndex != -1) {
      response = response.substring(startIndex);
    }

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

    // ✅ التعديل هنا: الباك إند يرسل البيانات مباشرة بدون غلاف status أو data
    if (data is Map<String, dynamic> && data.containsKey('patient_name')) {
      return AppointmentDetailsModel.fromJson(data);
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

    // ✅ التعديل هنا: نعتمد على وجود الـ client_secret بدلاً من كلمة success
    if (data['client_secret'] != null) {
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
  var dir = Directory('lib');

  var outputFile = File('project_code.md');
  var output = StringBuffer();

  if (dir.existsSync()) {
    output.writeln('# KidCare Project Code\n');

    // جلب كل الملفات داخل مجلد lib
    var files = dir.listSync(recursive: true);
    for (var file in files) {
      if (file is File && file.path.endsWith('.dart')) {
        output.writeln('### File: ${file.path}');
        output.writeln('```dart');
        output.writeln(file.readAsStringSync());
        output.writeln('```\n');
      }
    }

    outputFile.writeAsStringSync(output.toString());
    print(
      '  The operation was successful! The my_project_code.md file was created ',
    );
  } else {
    print(' lib folder not found !');
  }
}

```

### File: lib\firebase_test.dart
```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  await FirebaseMessaging.instance.requestPermission();

  String? token = await FirebaseMessaging.instance.getToken();

  print("FCM TOKEN = $token");

  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Firebase Test'),
        ),
      ),
    ),
  );
}
```

### File: lib\main.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:kidcare/core/helper/secure_storage_service.dart';
import 'package:kidcare/core/localization/app_translations.dart';
import 'package:kidcare/core/repos/home/add_child_repo.dart';
import 'package:kidcare/views/home/add_child_view.dart';
import 'package:kidcare/views/home/appointments_view.dart';
import 'package:kidcare/views/home/child_profile_view.dart';
import 'package:kidcare/views/home/home_view.dart';
import 'package:kidcare/views/home/profile_view.dart';

// الواجهات الأساسية
import 'package:kidcare/views/main_advanced.dart';
import 'package:kidcare/views/auth/login_view.dart';

// Sign Up
import 'package:kidcare/views/auth/sign_up_view.dart';
import 'package:kidcare/core/repos/auth/sign_up_repo.dart';
import 'controllers/appointment/appointment_controller.dart';
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

import 'controllers/home/add_child_controller.dart';
import 'controllers/home/appointments_controller.dart';
import 'controllers/home/home_controller.dart';
import 'controllers/home/profile_controller.dart';
import 'controllers/payment_controller.dart';
import 'core/repos/home/appointments_repo.dart';
import 'core/repos/home/home_children_repo.dart';
import 'core/repos/home/parent_name_repo.dart';
import 'core/repos/home/profile_repo.dart';

void main() async {
  // لتهيئة فلاتر قبل تشغيل أي ميزة Native مثل Stripe
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey =
      'pk_test_51TVx1BA9J421R1e0fArsBqsC3bNgwlcmhH407ymZp4Ncu9aVgwtEMgXg6lWcswqESufx6ZL7arNccQCdJCHA3QUG00GUsDRB6Q';

  String? savedLang = await SecureStorage.getLanguage();
  Locale initialLocale;
  if (savedLang == null || savedLang == 'system') {
    Locale? deviceLocale = WidgetsBinding.instance.platformDispatcher.locales.isNotEmpty
        ? WidgetsBinding.instance.platformDispatcher.locales.first
        : null;

    if (deviceLocale != null && deviceLocale.languageCode == 'ar') {
      initialLocale = const Locale('ar', 'SA');
    } else {
      initialLocale = const Locale('en', 'US');
    }
  } else if (savedLang == 'ar') {
    initialLocale = const Locale('ar', 'SA');
  } else {
    initialLocale = const Locale('en', 'US');
  }


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

      initialBinding: BindingsBuilder(() {
        Get.lazyPut<AppointmentController>(
          () => AppointmentController(
            repo: AppointmentRepo(),
            doctorRepo: DoctorRepo(),
          ),
          fenix: true,
        );
      }),

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
          binding: BindingsBuilder(() {
            Get.lazyPut(() => PaymentController());
          }),
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
            Get.lazyPut<HomeController>(
              () => HomeController(
                homeChildrenRepo: HomeChildrenRepo(),
                parentNameRepo: ParentNameRepo(),
              ),
            );

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
            Get.lazyPut(() => DepartmentController(repo: DepartmentRepo()));
            Get.lazyPut(() => DoctorController(repo: DoctorRepo()));

            Get.lazyPut<AppointmentController>(
              () => AppointmentController(
                repo: AppointmentRepo(),
                doctorRepo: DoctorRepo(),
              ),
            );
          }),
        ),

        GetPage(
          name: '/choose-child',
          page: () => const ChooseChildView(),

          binding: BindingsBuilder(() {
            Get.lazyPut<ChildController>(
              () => ChildController(repo: ChildRepo()),
            );
          }),
        ),
        GetPage(
          name: '/choose-date-time',
          page: () => const ChooseDateTimeView(),
        ),

        // Settings
        GetPage(name: '/settings', page: () => const SettingsView()),

        GetPage(
          name: '/appointments',
          page: () => const AppointmentsView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<AppointmentsController>(
              () =>
                  AppointmentsController(appointmentsRepo: AppointmentsRepo()),
            );
          }),
        ),

        GetPage(name: '/child-profile', page: () => const ChildProfileView()),
        GetPage(
          name: '/profile',
          page: () => const ProfileView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => ProfileController(profileRepo: ProfileRepo()));
          }),
        ),
        GetPage(
          name: '/add-child',
          page: () => const AddChildView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => AddChildController(addChildRepo: AddChildRepo()));
          }),
        ),
      ],
    );
  }
}

```

### File: lib\models\appointment\appointment_model.dart
```dart
import '../../core/helper/json_utils.dart';

class AppointmentModel {
  final String id;
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
      id:  json['id']?.toString() ?? '',
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

    String rawUrl = json['patient_image_url']?.toString() ?? '';
    if (rawUrl.contains('storage/http')) {
      rawUrl = rawUrl.split('storage/').last;
    }

    return AppointmentDetailsModel(
      patientName: json['patient_name']?.toString() ?? '',
      patientAge: json['patient_age']?.toString() ?? '',
      patientImageUrl: rawUrl,
      doctorName: json['doctor_name']?.toString() ?? '',
      departmentName: json['department_name']?.toString() ?? '',
      dateTime: json['date_time']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      currency: json['currency']?.toString() ?? '',
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
      status: json['status']?.toString() ?? '',
      clientSecret: json['client_secret']?.toString() ?? '',
      transactionId: json['transaction_id']?.toString() ?? '',
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
      appBar: bookingAppBar(subtitle: 'Choose Child'.tr),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                final isLoading = childController.isLoading;
                final children =
                    isLoading ? _fakeChildren : childController.children;

                if (!isLoading && children.isEmpty) {
                  return  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        "You haven't added any children yet.".tr,
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
          child:  Text(
            'Next'.tr,
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
                    '${child.ageYears} ${'years'.tr}',
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

    controller.loadSlots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: bookingAppBar(subtitle: 'Pick Date & Time'.tr),
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
                     Text(
                      'Available Times'.tr,
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


      final selectedDate = controller.selectedDate.value;
      final isLoadingSlots = controller.isLoadingSlots.value;
      final times = controller.availableTimes.toList();
      final selectedTime = controller.selectedTime.value;

      if (selectedDate == null) {
        return  _EmptyHint(text: 'Pick a date to see available times.'.tr);
      }
      if (!isLoadingSlots && times.isEmpty) {
        return  _EmptyHint(text: 'No times available for this date.'.tr);
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

    final appointmentId = controller.bookedAppointmentId.value!;

    Get.delete<AppointmentController>(force: true);

    Get.offNamed('/payment-method', arguments: appointmentId);


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
                :  Text(
                    'Book Appointment'.tr,
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
import '../../controllers/appointment/doctor_controller.dart';
import '../../core/booking_theme.dart';
import '../../models/appointment/doctor_model.dart';
import '../../widgets/booking_app_bar.dart';

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
  final DoctorController doctorController = Get.find<DoctorController>();
  final AppointmentController appointmentController = Get.find<AppointmentController>();

  int? selectedDoctorId;


  late final int departmentId;
  late final String specialty;

  @override
  void initState() {
    super.initState();


    final args = Get.arguments as Map<String, dynamic>?;
    departmentId = args?['departmentId'] ?? 1;
    specialty = args?['specialty'] ?? 'General Pediatrics';


    doctorController.loadDoctors(departmentId);
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

      appBar: bookingAppBar(subtitle: '${'Choose Doctor'.tr} - $specialty'),
      body: SafeArea(
        child: Column(
          children: [

            const SizedBox(height: 16),
            Expanded(child: _buildDoctorList()),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorList() {
    return Obx(() {
      final isLoading = doctorController.isLoading;
      final doctors = isLoading ? _fakeDoctors : doctorController.doctors;

      if (!isLoading && doctors.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'No doctors available in this department.'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kTextSecondary, fontSize: 14),
            ),
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


            return Obx(
                  () => _DoctorCard(
                doctor: doctor,
                specialty: specialty,
                isSelected: selectedDoctorId == doctor.id,
                isFavorite: doctorController.favDoctorIds.contains(doctor.id),
                onTap: isLoading ? () {} : () => _onDoctorTapped(doctor),
                onFavoriteTap: isLoading
                    ? () {}
                    : () => doctorController.toggleFavorite(doctor.id),
              ),
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
          child: Text(
            'Next'.tr,
            style: const TextStyle(
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

class _DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final String specialty;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  const _DoctorCard({
    required this.doctor,
    required this.specialty,
    required this.isSelected,
    required this.onTap,
    required this.isFavorite,
    required this.onFavoriteTap,
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
                      '$specialty ${'Specialist'.tr}',
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
                          'rating'.tr,
                          style: const TextStyle(
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

            GestureDetector(
              onTap: onFavoriteTap,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.redAccent : Colors.grey.shade400,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 4),
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
        border: Border.all(color: selected ? _kPrimary : _kBorder, width: 1.5),
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
                title: 'Verify Your Phone'.tr,

                subtitle:
                    '${'We have sent a 4-digit verification code to'.tr}\n+${controller.phoneController.text}',
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
                   Text(
                    "Didn't receive the code?".tr,
                    style: TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: controller.secondsRemaining.value == 0
                        ? () => controller.resendOtp()
                        : null,
                    child: Text(
                      controller.secondsRemaining.value == 0
                          ? "Resend Code".tr
                          : "${"Resend in".tr} (00:${controller.secondsRemaining.value.toString().padLeft(2, '0')})",
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
                        text: 'Verify and Activate Account'.tr,
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
               ActivationHeader(
                imagePath: 'assets/images/lock_blue_logo.png',
                title: 'Create New Password'.tr,
                subtitle: 'Create a strong password to protect your account'.tr,
              ),

              Obx(
                () => CustomTextField(
                  controller: controller.passwordController,
                  hintText: 'New Password'.tr,
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
                  hintText: 'Confirm Password'.tr,
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
                child:  Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Password must contain:'.tr,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    SizedBox(height: 12),
                    PasswordRequirementRow(text: 'At least 8 characters'.tr),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              Obx(
                () => controller.isLoading
                    ? const CircularProgressIndicator()
                    : PrimaryButton(
                        text: 'Set Password and Login'.tr,
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
              Text(
                "Forgot Password?".tr,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D2451),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Don't worry, enter your phone number and we will send you a verification code."
                    .tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 40),
              Align(
                alignment:AlignmentDirectional.topStart,
                child: Text(
                  "Phone Number".tr,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller.phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '9639XXXXXXXX',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // الاستماع اللحظي لحالة التحميل باستخدام الكود الموحد الخاص بك
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: controller.isLoading
                        ? null
                        : () => controller.sendCode(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A86D1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: controller.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "Send Verification Code".tr,
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
              Image.asset('assets/images/child_welcome.png'),
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
              Text(
                "Verify Your Number".tr,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "We sent a 4-digit code to".tr,
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
                    Text(
                      "Didn't receive the code?".tr,
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: controller.secondsRemaining.value == 0
                          ? () => controller.sendCode()
                          : null,
                      child: Text(
                        controller.secondsRemaining.value == 0
                            ? "Resend Code".tr
                            : "${"Resend in".tr} (00:${controller.secondsRemaining.value.toString().padLeft(2, '0')})",
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
                        : Text(
                            "Verify".tr,
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
            Text(
              "Create New Password".tr,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Your new password must be different".tr,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            Obx(
              () => TextField(
                controller: controller.passwordController,
                obscureText: !controller.isPasswordVisible.value,
                decoration: InputDecoration(
                  hintText: "Password".tr,
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
                  hintText: "Confirm Password".tr,
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
                      : Text(
                          "Update Password".tr,
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
              Text(
                "Your password has been updated successfully. You can now log in with your new password."
                    .tr,
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
                  child: Text(
                    "Back to Login".tr,
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
                  alignment:AlignmentDirectional.topStart,
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
            Text(
              'Create New Account'.tr,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Create your account to benefit from our services'.tr,
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
              hintText: 'Enter your name'.tr,
              label: 'Name'.tr,
              labelIcon: Icons.person_outline,
            ),
            const SizedBox(height: 14),

            CustomTextField(
              controller: controller.lastNameController,
              hintText: 'Enter your last name'.tr,
              label: 'Last Name'.tr,
              labelIcon: Icons.person_outline,
            ),
            const SizedBox(height: 14),

            CustomTextField(
              controller: controller.emailController,
              hintText: 'Enter your email'.tr,
              label: 'Email'.tr,
              labelIcon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),

            CustomTextField(
              controller: controller.phoneController,
              hintText: 'Enter your phone number'.tr,
              keyboardType: TextInputType.phone,
              label: 'Phone'.tr,
              labelIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: 14),

            CustomTextField(
              controller: controller.addressController,
              hintText: 'Enter your address in detail'.tr,
              label: 'Address'.tr,
              labelIcon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 14),

            Obx(
              () => CustomTextField(
                controller: controller.passwordController,
                hintText: 'Enter your password'.tr,
                isPassword: controller.isPasswordHidden.value,
                label: 'Password'.tr,
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
                'At least 8 characters with uppercase, lowercase and a number'
                    .tr,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
            const SizedBox(height: 14),

            Obx(
              () => CustomTextField(
                controller: controller.confirmPasswordController,
                hintText: 'Enter your password again'.tr,
                isPassword: controller.isConfirmPasswordHidden.value,
                label: 'Confirm Password'.tr,
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
                      text: 'Create Account'.tr,
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
                    'Already have an account?'.tr,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            const SizedBox(height: 16),

            OutlinedPrimaryButton(text: 'Login'.tr, onPressed: () => Get.back()),
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

            Text(
              'Verify Your Phone Number'.tr,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            Text(
              'We sent a 4-digit verification code to'.tr,
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
                    TextSpan(text: 'The code is valid for '.tr),
                    TextSpan(
                      text: controller.validityFormatted,
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(text: ' minutes'.tr),
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
                        Text(
                          "Didn't receive the code?".tr,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You can resend the code after the countdown ends'.tr,
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
                                    'Resend Code'.tr,
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
                      text: 'Verify'.tr,
                      onPressed: controller.verifyOtp,
                    ),
            ),
            const SizedBox(height: 14),

            // Change phone number
            OutlinedPrimaryButton(
              text: 'Change Phone Number'.tr,
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
             Center(
              child: Text(
                'Add New Child'.tr,
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
                             Text('First Name'.tr,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A2E5A))),
                            const SizedBox(height: 8),
                            CustomTextField(
                              controller: controller.firstNameController,
                              hintText: 'Enter first name'.tr,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text('Last Name'.tr,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A2E5A))),
                            const SizedBox(height: 8),
                            CustomTextField(
                              controller: controller.lastNameController,
                              hintText: 'Enter last name'.tr,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Gender
                   Text('Gender'.tr,
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
                                Text('Female'.tr,
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
                                Text('Male'.tr,
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
                   Text('Birth Date'.tr,
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
                                ? 'Select birth date'.tr
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
                   Text('Blood Type'.tr,
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
                            Text('Select blood type'.tr,
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
                   Text('Medical History'.tr,
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
                      hintText: "Enter child's medical history".tr,
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
                   Text('Allergies'.tr,
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
                      hintText: 'Enter any allergies the child has'.tr,
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
                    text: 'Save'.tr,
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
        title: Text(
          // تغيير العنوان ديناميكياً
          controller.childId == null ? 'My Appointments'.tr : 'Child Appointments'.tr,
          style: const TextStyle(
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

          // ─── Tabs (Slider) ───
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
                              'Upcoming'.tr,
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
                              'Past'.tr,
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

          // ─── List ───
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
                        'No appointments found'.tr,
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

// ─── Appointment Card ───
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
            backgroundImage: (appointment.doctorImage != null && appointment.doctorImage!.isNotEmpty)
                ? NetworkImage(appointment.doctorImage!)
                : null,
            child: (appointment.doctorImage == null || appointment.doctorImage!.isEmpty)
                ? Icon(Icons.person, color: Colors.grey.shade400, size: 30)
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
                    const Text('|', style: TextStyle(color: Colors.grey)),
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
import '../../controllers/home/child_profile_controller.dart';
import '../../models/appointment/child_model.dart';

class ChildProfileView extends GetView<ChildProfileController> {
  const ChildProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
        centerTitle: true,
        title:  Text(
          'Child Profile'.tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2E5A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A2E5A), size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator(color: Colors.blue));
        }

        final child = controller.child.value;
        if (child == null) {
          return  Center(child: Text('Failed to load profile'.tr));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              _InfoCard(child: child),
              const SizedBox(height: 16),
              _StatsCard(child: child),
              const SizedBox(height: 16),

              // كارت التاريخ الطبي
              if (child.medicalHistory != null && child.medicalHistory!.isNotEmpty) ...[
                _DataCard(title: 'Medical History'.tr, content: child.medicalHistory!),
                const SizedBox(height: 16),
              ],

              // كارت الحساسية
              if (child.allergies != null && child.allergies!.isNotEmpty) ...[
                _DataCard(title: 'Allergies'.tr, content: child.allergies!),
                const SizedBox(height: 16),
              ],

              _ActionButton(
                icon: Icons.vaccines_outlined,
                label: 'Vaccination Record'.tr,
                color: Colors.blue,
                onTap: () => Get.toNamed('/vaccinations', arguments: child.id),
              ),
              const SizedBox(height: 10),
              _ActionButton(
                icon: Icons.calendar_today_outlined,
                label: 'Appointments'.tr,
                color: Colors.blue,
                onTap: () => Get.toNamed('/appointments', arguments: child.id),
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
                        title:  Text('Delete Child'.tr),
                        content:  Text(
                          'Are you sure you want to delete this child profile? This action cannot be undone.'.tr,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child:  Text('Cancel'.tr),
                          ),
                          TextButton(
                            onPressed: () {
                              Get.back();
                              controller.deleteCurrentChild();
                            },
                            child:  Text('Delete'.tr, style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  label:  Text(
                    'Delete Child Profile'.tr,
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
        );
      }),
    );
  }
}

// ─── Info Card ───
class _InfoCard extends StatelessWidget {
  final ChildModel child;

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // تم التعديل لتتناسق الواجهة
              children: [
                Text(
                  child.fullName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2E5A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '${child.ageYears} ${' years'.tr}',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                        child.gender.toLowerCase() == 'female' ? Icons.female : Icons.male,
                        color: const Color(0xFF4CAF50),
                        size: 18
                    ),
                    const SizedBox(width: 4),
                    Text(
                      child.gender.capitalizeFirst ?? '',
                      style: const TextStyle(fontSize: 16, color: Color(0xFF4CAF50)),
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

// ─── Stats Card ───
class _StatsCard extends StatelessWidget {
  final ChildModel child;
  const _StatsCard({required this.child});

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
              value: child.bloodType ?? 'N/A',
              label: 'Blood Type'.tr,
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.calendar_month_outlined,
              value: '${child.ageYears}',
              label: 'Age'.tr,
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _StatItem(
              icon: child.gender.toLowerCase() == 'female' ? Icons.female : Icons.male,
              value: child.gender.capitalizeFirst ?? '',
              label: 'Gender'.tr,
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

  const _StatItem({required this.icon, required this.value, required this.label});

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

// ─── Data Card (للحساسية والتاريخ الطبي) ───
class _DataCard extends StatelessWidget {
  final String title;
  final String content;

  const _DataCard({required this.title, required this.content});

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
          Text(
            title,
            style: const TextStyle(
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
              content,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Button ───
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon, required this.label, required this.color, required this.onTap,
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
            const Icon(Icons.chevron_right, color: Color(0xFF1A2E5A), size: 22),
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
      'route': '/choose-doctor', // عدلت هون
      'specialty': 'General Pediatrics',
      'departmentId': 1,
    },
    {
      'label': 'Dental Care',
      'icon': Icons.medical_information_outlined,
      'color': Color(0xFFE3F2FD),
      'iconColor': Color(0xFF1E88E5),
      'route': '/choose-doctor', // عدلت هون
      'specialty': 'Dental Care',
      'departmentId': 2,
    },
    {
      'label': 'Psychiatry',
      'icon': Icons.psychology_outlined,
      'color': Color(0xFFFCE4EC),
      'iconColor': Color(0xFFE91E63),
      'route': '/choose-doctor', // عدلت هون
      'specialty': 'Psychiatry',
      'departmentId': 3,
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

              // ربط الـ Slider بالـ Controller
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
                            'No children added yet'.tr,
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
        // صورة البروفايل مع الاسم على اليسار
        Expanded(
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Get.toNamed('/profile'), // تم التصحيح ليطابق الـ main
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
                        ? 'Welcome!'.tr
                        : controller.parentName.value,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  )),
                  Text(
                    'Welcome back!'.tr,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
        ),

        // أيقونة الإشعارات على اليمين
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
            // صورة الطفل من السيرفر
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

            // الاسم والعمر من الـ API
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
                    '${child.age} ${'years'.tr}',
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

// ─── Book Button ──────────────────────────────────────────────────────────────

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
        label:  Text(
          'Book New Appointment'.tr,
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

// ─── Departments

class _DepartmentsSection extends StatelessWidget {
  final List<Map<String, dynamic>> departments;

  const _DepartmentsSection({required this.departments});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Departments'.tr,
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
          arguments: {
            'departmentId': department['departmentId'],
            'specialty': department['specialty'],
          },
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
            department['label'].toString().tr,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Clinic Info ──────────────────────────────────────────────────────────────

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
                 Text(
                  'About the Clinic'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We provide comprehensive healthcare for your children with the highest quality standards.'.tr,
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
                        'Read More'.tr,
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

// ─── Bottom Navigation (المعدل بالكامل) ──────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // ─── Home ─────────────────────────────
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home'.tr,
                isSelected: true,
                onTap: () {},
              ),

              // ─── Appointments ──────────────────────
              _NavItem(
                icon: Icons.calendar_month_outlined,
                label: 'Appointments'.tr,
                isSelected: false,
                onTap: () => Get.toNamed('/appointments'),
              ),

              // ─── زر + في المنتصف ───────────────────
              GestureDetector(
                onTap: () => Get.toNamed('/add-child'),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B9EFF), Color(0xFF1565C0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B9EFF).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),

              // ─── Vaccinations ──────────────────────
              _NavItem(
                icon: Icons.vaccines_outlined,
                label: 'Vaccinations'.tr,
                isSelected: false,
                onTap: () => Get.toNamed('/vaccinations'),
              ),

              // ─── More ──────────────────────────────
              _NavItem(
                icon: Icons.more_horiz,
                label: 'More'.tr,
                isSelected: false,
                onTap: () => Get.toNamed('/settings'),
              ),
            ],
          ),
        ),
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
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3B9EFF).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF3B9EFF)
                  : Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? const Color(0xFF3B9EFF)
                    : Colors.grey.shade400,
                fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
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
        title:  Text(
          'Personal Profile'.tr,
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
          return  Center(child: Text('Failed to load profile'.tr));
        }

        final profile = controller.profile.value!;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // ─── Avatar ───
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

              // ─── Full Name
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
                label: 'Email'.tr,
                value: profile.email,
                onEdit: () {
                  // TODO: تعديل البريد الإلكتروني
                },
              ),
              const SizedBox(height: 12),

              _ProfileItem(
                icon: Icons.phone_outlined,
                label: 'Phone Number'.tr,
                value: profile.phoneNumber,
                onEdit: () {
                  // TODO: تعديل رقم الهاتف
                },
              ),
              const SizedBox(height: 12),

              _ProfileItem(
                icon: Icons.location_on_outlined,
                label: 'Address'.tr,
                value: profile.address,
                onEdit: () {
                  // TODO: تعديل العنوان
                },
              ),
              const SizedBox(height: 12),

              _ProfileItem(
                icon: Icons.group_outlined,
                label: 'Number of Children'.tr,
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
                  label:  Text(
                    'Logout'.tr,
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

      child: Row(
        children: [
          // ─── Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF4CAF50), size: 22),
          ),
          const SizedBox(width: 12),

          // ─── Label & Value
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

          // ─── Edit icon
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

import '../core/helper/secure_storage_service.dart';

class PediatricClinicScreen extends StatefulWidget {
  final bool hasToken;
  const PediatricClinicScreen({super.key,  this.hasToken=false});

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

    // ✅ التعديل هنا: قمنا باستدعاء دالة فحص التوكن بدلاً من الكود القديم
    _checkLoginStatus();
  }

  // ✅ الدالة الجديدة التي ستقوم بالفحص بصمت في الخلفية
  Future<void> _checkLoginStatus() async {
    // 1. ننتظر 4 ثواني لكي تكتمل الـ Animations الجميلة الخاصة بك
    await Future.delayed(const Duration(seconds: 4));

    // 2. نقرأ التوكن من الذاكرة المشفرة
    String? token = await SecureStorage.getToken();

    // 3. نوجه المستخدم بناءً على وجود التوكن
    if (mounted) {
      if (token != null && token.isNotEmpty) {
        Get.offAllNamed('/home'); // يوجه للرئيسية إذا كان مسجلاً للدخول
      } else {
        Get.offAllNamed('/login'); // يوجه لتسجيل الدخول إذا لم يكن هناك توكن
      }
    }
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
                              'Premium Pediatric Care'.tr,
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
        title:  Text(
          'Review & Pay'.tr,
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
          return  Center(child: Text("Failed to load appointment data.".tr));
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
                      label: 'Date & Time'.tr,
                      value: summary.dateTime, // التاريخ و الوقت
                    ),
                    const SizedBox(height: 12),
                    PaymentSummaryRow(
                      label: 'Consultation Fee'.tr,
                      value:
                          '${summary.price} ${summary.currency}', // السعر و العملة
                    ),
                    const Divider(
                      height: 30,
                      color: Colors.black12,
                      thickness: 1,
                    ),
                    PaymentSummaryRow(
                      label: 'Total'.tr,
                      value: '${summary.price} ${summary.currency}', // الإجمالي

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
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              //  طرق الدفع الثابتة
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
                    'Pay'.tr + ' ${summary.price} ${summary.currency}',
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

```

### File: lib\views\payment\payment_success_view.dart
```dart
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
              Text(
                'Payment Successful!'.tr,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your appointment is confirmed'.tr,
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
                          value:
                              '${summary?.price ?? 0} ${summary?.currency ?? ''}',
                        ),
                        const Divider(height: 30),
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
                    backgroundColor: Colors.blue.shade700,
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
                    style: TextStyle(fontSize: 18, color: Colors.white),
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

### File: lib\views\settings\favorite_doctors_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/appointment/appointment_controller.dart';
import '../../controllers/appointment/doctor_controller.dart';
import '../../models/appointment/doctor_model.dart';

class FavoriteDoctorsView extends StatelessWidget {
  const FavoriteDoctorsView({super.key});

  @override
  Widget build(BuildContext context) {
    final DoctorController doctorController = Get.find<DoctorController>();
    final AppointmentController appointmentController =
        Get.find<AppointmentController>();

    doctorController.loadFavoriteDoctorIds();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          'favorite_doctors'.tr,
          style: const TextStyle(
            color: Color(0xFF1D2755),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.blue),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          final favorites = doctorController.favoriteDoctors;

          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No doctors available in this department.'.tr,

                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final doctor = favorites[index];
              return _FavoriteDoctorCard(
                doctor: doctor,

                onCardTap: () {
                  appointmentController.selectDoctor(doctor);

                  Get.toNamed('/choose-child');
                },

                onFavoriteTap: () => doctorController.toggleFavorite(doctor.id),
              );
            },
          );
        }),
      ),
    );
  }
}

class _FavoriteDoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onCardTap;
  final VoidCallback onFavoriteTap;

  const _FavoriteDoctorCard({
    required this.doctor,
    required this.onCardTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCardTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFF0F4FF),
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: doctor.profilePicture != null
                  ? Image.network(
                      doctor.profilePicture!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person_rounded,
                        color: Colors.blue,
                        size: 30,
                      ),
                    )
                  : const Icon(
                      Icons.person_rounded,
                      color: Colors.blue,
                      size: 30,
                    ),
            ),
            const SizedBox(width: 14),
            // بيانات الطبيب
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.fullName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D2755),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Specialist'.tr,
                    style: const TextStyle(fontSize: 12.5, color: Colors.grey),
                  ),
                  if (doctor.rating != null) ...[
                    const SizedBox(height: 6),
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            GestureDetector(
              onTap: onFavoriteTap,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.favorite, color: Colors.redAccent, size: 24),
              ),
            ),
          ],
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
                  icon: Icons.favorite_border_rounded,
                  title: 'favorite_doctors'.tr,
                  subtitle: 'view_favorite_doctors'.tr,
                  onTap: () {
                    Get.toNamed('/favorites');
                  },
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
                  icon: Icons.delete_forever_rounded,
                  title: 'Delete account'.tr,
                  subtitle: ''.tr,
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D2755),
              ),
            ),
            const SizedBox(height: 20),

            Obx(
              () => RadioGroup<String>(
                groupValue: controller.currentLanguage.value,
                onChanged: (value) {
                  if (value != null) {
                    controller.changeLanguage(value);
                    Get.back();
                  }
                },
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text(
                        'English',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      value: 'en',
                      activeColor: Colors.blue,
                    ),
                    RadioListTile<String>(
                      title: const Text(
                        'العربية',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      value: 'ar',
                      activeColor: Colors.blue,
                    ),
                    RadioListTile<String>(
                      title: const Text(
                        'System Default (لغة النظام)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      value: 'system',
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
         Text(
          'Book New Appointment'.tr,
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
import 'package:get/get.dart';

const _kPrimary = Color(0xFF3B82F6);
const _kUnavailable = Color(0xFFEF4444);
const _kTextPrimary = Color(0xFF1F2937);
const _kTextSecondary = Color(0xFF6B7280);
const _kTextDisabled = Color(0xFFD1D5DB);
const _kNavButtonBg = Color(0xFFF3F4F6);


class BookingCalendar extends StatefulWidget {
  final DateTime? selectedDate;
  final DateTime minDate;
  final DateTime? maxDate;
  final ValueChanged<DateTime> onDateSelected;


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
          child:  Text(
            'Today'.tr,
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
import 'package:get/get.dart';

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
    final isRtl = Get.locale?.languageCode == 'ar';

    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      textAlign: isRtl ? TextAlign.right : TextAlign.left,
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
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
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
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
                  item.label.tr,
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
  final Widget? trailingWidget;

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
            ?trailingWidget,
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
  final Widget? trailingWidget;

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
            ?trailingWidget,
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

final _fakeAppointments = List<AppointmentModel>.generate(
  2,
  (i) => AppointmentModel(
    id: (-i - 1).toString(),
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

class UpcomingAppointmentsSection extends StatelessWidget {
  final MyAppointmentsController controller;

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
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Upcoming Appointments'.tr,
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

          final appointments = isLoading
              ? _fakeAppointments
              : (controller.upcoming.toList()..sort(
                      (a, b) => '${a.date} ${a.time}'.compareTo(
                        '${b.date} ${b.time}',
                      ),
                    ))
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
          Text(
            'No upcoming appointments'.tr,
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
                    appointment.doctorName ?? '${'Doctor'.tr} #${appointment.doctorId}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appointment.childName ?? '${'Child'.tr} #${appointment.childId}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
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
              child: Icon(Icons.person, color: Colors.grey.shade400, size: 30),
            ),
          ],
        ),
      ),
    );
  }
}

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
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}

```

