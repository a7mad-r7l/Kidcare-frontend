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
import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../../core/helper/secure_storage_service.dart';
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
  // دالة مخصصة لضرب مسار الـ POST الخاص بالحجز السريع
  Future<String> bookQuickAppointmentApi(int doctorId, int childId, String date, String time) async {
    final token = await SecureStorage.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/appointment'), // مسار الـ POST الذي جربته في Postman
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {
        'doctor_id': doctorId.toString(),
        'child_id': childId.toString(),
        'date': date,
        'time': time,
      },
    );

    final data = jsonDecode(response.body);

    // 201 Created تعني نجاح الحجز كما ظهر معك في Postman
    if (response.statusCode == 201 && data['status'] == 'success') {
      return data['appointment_id']; // إرجاع الـ UUID الخاص بالموعد
    } else {
      throw Exception(data['message'] ?? 'Failed to book appointment');
    }
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

### File: lib\controllers\appointment\closest_appointments_controller.dart
```dart
import 'package:get/get.dart';
import '../../core/repos/appointment/department_repo.dart';
import '../../core/repos/appointment/doctor_repo.dart';
import '../../models/appointment/department_model.dart';
import '../../models/appointment/closest_appointment_model.dart';
import '../base_controller.dart';

class ClosestAppointmentsController extends BaseController {
  final DepartmentRepo departmentRepo;
  final DoctorRepo doctorRepo;

  ClosestAppointmentsController({
    required this.departmentRepo,
    required this.doctorRepo,
  });

  final departments = <DepartmentModel>[].obs;
  final selectedDepartmentId = RxnInt();
  final closestAppointments = <ClosestAppointmentModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initData();
  }

  Future<void> _initData() async {
    showLoading();
    try {
      // 1. جلب الأقسام
      departments.value = await departmentRepo.fetchAll();

      // 2. تحديد أول قسم افتراضياً وجلب مواعيده
      if (departments.isNotEmpty) {
        selectedDepartmentId.value = departments.first.id;
        await fetchClosestAppointments(departments.first.id);
      }
    } catch (e, stackTrace) {
      // إضافة الطباعة هنا لمعرفة سبب الخطأ عند تهيئة الواجهة
      print('=== Error in _initData ===');
      print('Exception: $e');
      print('StackTrace: $stackTrace');
      print('==========================');

      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> fetchClosestAppointments(int departmentId) async {
    showLoading();
    try {
      selectedDepartmentId.value = departmentId;
      closestAppointments.value = await doctorRepo.fetchClosestAppointments(departmentId);
    } catch (e, stackTrace) {
      // إضافة الطباعة هنا لمعرفة سبب الخطأ عند جلب المواعيد
      print('=== Error in fetchClosestAppointments ===');
      print('Exception: $e');
      print('StackTrace: $stackTrace');
      print('=========================================');

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
    showLoading();
    try {
      final favs = await favoriteRepo.fetchFavoriteDoctors();
      favoriteDoctors.assignAll(favs);
      favDoctorIds.assignAll(favs.map((d) => d.id));
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
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
// ─── 1. إضافة استدعاء ملف خدمة التنبيهات ───
import '../../core/helper/notification_service.dart';

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

      // ─── 2. إضافة سطر رفع توكن الإشعارات فور نجاح التفعيل وتسجيل الدخول ───
      await NotificationService.uploadFcmToken();

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
// ─── 1. التعديل الأول: استدعاء ملف خدمة التنبيهات ───
import '../../core/helper/notification_service.dart';

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

      // ─── 2. التعديل الثاني: رفع التوكن فور نجاح تسجيل الدخول ───
      await NotificationService.uploadFcmToken();

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

import '../core/helper/secure_storage_service.dart';

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
        SecureStorage.removeToken();
        if (Get.currentRoute != '/login') {
          Get.offAllNamed('/login');
          return;
        }
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

### File: lib\controllers\growth\child_growth_controller.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/repos/growth/child_growth_repo.dart';
import '../../models/growth/child_growth_response_model.dart';
import '../base_controller.dart';

class ChildGrowthController extends BaseController {
  final ChildGrowthRepo repo;

  ChildGrowthController({required this.repo});

  late int childId;
  final Rxn<ChildGrowthResponseModel> growthData =
      Rxn<ChildGrowthResponseModel>();

  final weightController = TextEditingController();
  final heightController = TextEditingController();
  final RxString selectedDate = ''.obs;

  @override
  void onInit() {
    super.onInit();

    if (Get.arguments is int) {
      childId = Get.arguments as int;
    } else {
      childId = 0; // Fallback
    }

    if (childId != 0) {
      getGrowthDashboard();
    }
  }

  /// 1. جلب بيانات النمو والمخطط من السيرفر (GET)
  Future<void> getGrowthDashboard() async {
    showLoading();
    try {
      final result = await repo.fetchChildGrowthData(childId);
      growthData.value = result;
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  /// 2. إضافة سجل قياس وزني وطولي جديد (POST)
  Future<void> addMeasurement() async {
    final String weightText = weightController.text.trim();
    final String heightText = heightController.text.trim();
    final String recordDate = selectedDate.value;

    final double? weight = double.tryParse(weightText);
    final double? height = double.tryParse(heightText);

    if (weight == null ||
        height == null ||
        weight <= 0 ||
        height <= 0 ||
        recordDate.isEmpty) {
      showInfo('Please enter valid weight and height'.tr);
      return;
    }

    showLoading();
    try {
      final statusResult = await repo.addNewGrowthRecord(
        childId: childId,
        height: height,
        weight: weight,
        recordDate: recordDate,
      );

      Get.back();
      _clearForm();

      showSuccess(
        '${'Measurement saved successfully'.tr} (${statusResult.tr})',
      );

      await getGrowthDashboard();
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  /// 3. حذف سجل قياس سابق  (DELETE)
  Future<void> deleteMeasurement(int growthId) async {
    showLoading();
    try {
      await repo.removeGrowthRecord(growthId);

      await getGrowthDashboard();
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> pickRecordDate(BuildContext context) async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 6),
      lastDate: now,
    );
    if (picked != null) {
      selectedDate.value =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  void _clearForm() {
    weightController.clear();
    heightController.clear();
    selectedDate.value = '';
  }

  @override
  void onClose() {
    weightController.dispose();
    heightController.dispose();
    super.onClose();
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
    // 1. التحقق من الحقول الإلزامية (Client-Side Validation)
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

    // التحقق من العمر (ألا يتجاوز 6 سنوات)
    final birthDate = DateTime.tryParse(selectedBirthDate.value);
    if (birthDate != null) {
      final now = DateTime.now();
      final ageLimitDate = DateTime(now.year - 6, now.month, now.day);
      if (birthDate.isBefore(ageLimitDate)) {
        Get.snackbar(
          'Invalid Age'.tr,
          'Child age cannot exceed 6 years.'.tr,
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

    // 2. معالجة الحقول الاختيارية (Data Sanitization)
    final String medicalHistory = medicalHistoryController.text.trim().isEmpty
        ? 'No medical history'.tr
        : medicalHistoryController.text.trim();

    final String allergies = allergiesController.text.trim().isEmpty
        ? 'No allergies'.tr
        : allergiesController.text.trim();

    showLoading();
    try {
      // 3. إرسال الطلب للـ API عبر الـ Repository
      await addChildRepo.addChild(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        gender: selectedGender.value,
        birthDate: selectedBirthDate.value,
        bloodType: selectedBloodType.value,
        medicalHistory: medicalHistory,
        allergies: allergies,
        image: selectedImage.value,
      );

      // 4. عرض رسالة النجاح
      Get.snackbar(
        'Success'.tr,
        'Child added successfully!'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
      );

      // تأخير بسيط ليتمكن المستخدم من قراءة رسالة النجاح
      await Future.delayed(const Duration(seconds: 1));

      // 5. التوجيه الشامل للرئيسية لضمان تحديث البيانات ومسح الـ Stack
      Get.offAllNamed('/home');

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
import 'package:flutter/material.dart';
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
  Future<void> cancelAppointment(int appointmentId) async {
    try {
      // إظهار دائرة التحميل
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // استدعاء دالة الحذف من الـ Repo
      final response = await appointmentsRepo.cancelAppointment(appointmentId);

      // إغلاق دائرة التحميل
      Get.back();

      // 1. حذف الموعد من قائمة "المواعيد القادمة" في الواجهة فوراً
      upcoming.removeWhere((appointment) => appointment.id == appointmentId);

      // 2. تصفير قائمة المواعيد السابقة لتهيئتها للاستجابة الجديدة
      past.clear();

      // 3. الانتقال التلقائي إلى تبويب المواعيد السابقة (Past) وجلب البيانات المحدثة
      switchTab(false);

      // إظهار رسالة النجاح متوافقة مع لغة التطبيق النشطة
      Get.snackbar(
        'Success'.tr,
        response['message'] ?? 'Appointment canceled successfully'.tr,
        backgroundColor: Get.isDarkMode ? Colors.green.withValues(alpha: 0.8) : Colors.green.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

    } catch (e) {
      Get.back(); // إغلاق دائرة التحميل في حالة الخطأ
      handleError(e); // معالجة الخطأ عبر الـ BaseController
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
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/repos/home/child_profile_repo.dart';
import '../../models/appointment/child_model.dart';
import '../../models/home/home_child_model.dart';
import '../base_controller.dart';
import 'home_controller.dart';

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

  // الآن الدالة تستخدم الـ repo الخاص بـ هذا الـ Controller مباشرة
  Future<void> deleteCurrentChild() async {
    showLoading();
    try {
      // استدعاء دالة الحذف التي أضفناها للـ Repo
      await repo.deleteChild(childId);
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().fetchChildren(); // أو دالة التحديث الموجودة عندك
      }

      // بعد نجاح الحذف، نغلق شاشة البروفايل ونعود للرئيسية
      Get.back();
      Get.snackbar(
        'Success'.tr,
        'Child deleted successfully'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
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

### File: lib\controllers\home\notification_history_controller.dart
```dart
import 'package:get/get.dart';
import '../../core/repos/home/notification_history_repo.dart';
import '../../models/home/notification_history_model.dart';
import '../base_controller.dart';

class NotificationHistoryController extends BaseController {
  final NotificationHistoryRepo repo;

  NotificationHistoryController({required this.repo});

  final RxList<NotificationHistoryModel> notifications =
      <NotificationHistoryModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    getNotifications();
  }

  Future<void> getNotifications() async {
    showLoading();
    try {
      final result = await repo.fetchNotifications();
      notifications.assignAll(result);
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }
}

```

### File: lib\controllers\home\profile_controller.dart
```dart
import 'package:flutter/material.dart';
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

  // ─── دالة جديدة لتحديث حقل معين ───
  Future<void> updateProfileField(String key, String newValue) async {
    if (newValue.trim().isEmpty) return;

    showLoading();
    try {
      // إرسال البيانات كـ Map (مثال: {'first_name': 'Louay'})
      await profileRepo.updateProfile({key: newValue.trim()});

      // جلب البيانات من جديد لتحديث الواجهة تلقائياً
      await fetchProfile();

      Get.back(); // إغلاق نافذة التعديل (Dialog)
      Get.snackbar(
        'Success'.tr,
        'Profile updated successfully'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
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
import 'home/appointments_controller.dart';

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

      // ----------------------------------------------------------------------
      // 1. إعطاء مهلة للباك إند (Laravel) لتحديث حالة الموعد في قاعدة البيانات
      await Future.delayed(const Duration(seconds: 2));

      // 2. معالجة تحديث واجهة المواعيد بشكل آمن
      if (Get.isRegistered<AppointmentsController>()) {
        Get.find<AppointmentsController>().fetchUpcoming();
      } else {
        // إذا كان التنقل قد مسح الكنترولر، نجبر GetX على نسيانه ليبنيه من جديد عند العودة للشاشة
        Get.delete<AppointmentsController>(force: true);
      }
      // ----------------------------------------------------------------------

      Get.offAllNamed('/payment-success', arguments:{
        'summary': appointmentSummary.value,
        'transaction_id': transactionId.value,
      });

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
import '../core/repos/auth/login_repo.dart';
import 'base_controller.dart';

class SettingsController extends BaseController {
  var currentLanguage = 'system'.obs;
  final RxBool isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedLanguage();

    isDarkMode.value = Get.isDarkMode;
  }

  void toggleTheme() async {
    isDarkMode.value = !isDarkMode.value;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);

    await SecureStorage.storeThemeMode(isDarkMode.value ? 'dark' : 'light');
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

  void deleteAccount() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Get.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Account'.tr,
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone.'
              .tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel'.tr,
              style: TextStyle(color: Get.theme.hintColor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Get.back();
              await _confirmDeleteAccount();
            },
            child: Text(
              'Delete'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    showLoading();
    try {
      final loginRepo = LoginRepo();

      final msg = await loginRepo.deletePatientAccount();

      showSuccess(msg);

      await SecureStorage.removeAll();
      Get.offAllNamed('/login');
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }
}

```

### File: lib\controllers\theme_controller.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemeController extends GetxController {
  // حالة المتغير لمراقبة الوضع الحالي
  final RxBool isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    // قراءة حالة النظام الحالية عند بدء التطبيق
    isDarkMode.value = Get.isDarkMode;
  }

  void toggleTheme() {
    // تبديل القيمة
    isDarkMode.value = !isDarkMode.value;

    // أمر GetX بتغيير السمة في كامل التطبيق فوراً
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
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
      Uri.parse('$baseUrl/appointments'),
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
      Uri.parse('$baseUrl/appointment/$appointmentId'),
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
      Uri.parse('$baseUrl/appointment/$appointmentId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );
    // التحقق من نجاح الطلب
    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.body;
    } else {
      throw Exception("Error ${response.statusCode}: ${response.body}");
  }}
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

  // أضف هذه الدالة داخل كلاس DoctorApi
  Future<String> getClosestAppointments(String token, int departmentId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/departments/$departmentId/closest-appointments'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        "Accept-Language": Get.locale?.languageCode ?? "en",
      },
    );
    return response.body;
  }

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
      Uri.parse('$baseUrl/favorite-doctors'),
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
import '../../helper/secure_storage_service.dart';

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

  Future<String> deletePatientAccount() async {
    final token = await SecureStorage.getToken();

    final url = Uri.parse('$baseUrl/parent/account/terminate');

    final response = await http
        .delete(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Accept-Language': Get.locale?.languageCode ?? 'en',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    return response.body;
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

### File: lib\core\apis\growth\child_growth_api.dart
```dart
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';
import '../../helper/secure_storage_service.dart';

class ChildGrowthApi {
  final http.Client client;

  ChildGrowthApi({http.Client? client}) : client = client ?? http.Client();

  /// 1. show child growth (GET)
  Future<http.Response> getGrowthData(int childId) async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) {
      throw Exception('Session expired. Please login again.'.tr);
    }

    final response = await client.get(
      Uri.parse('$baseUrl/children/$childId/growth'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );
    return response;
  }

  /// 2. store growth (Post)
  Future<http.Response> storeGrowthRecord({
    required int childId,
    required double height,
    required double weight,
    required String recordDate,
  }) async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) {
      throw Exception('Session expired. Please login again.'.tr);
    }

    final response = await client.post(
      Uri.parse('$baseUrl/growth'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
      body: {
        'child_id': childId.toString(),
        'height': height.toString(),
        'weight': weight.toString(),
        'date': recordDate,
      },
    );
    return response;
  }

  /// 3. delete growth (Delete)
  Future<http.Response> deleteGrowthRecord(int growthId) async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) {
      throw Exception('Session expired. Please login again.'.tr);
    }

    final response = await client.delete(
      Uri.parse('$baseUrl/growth/$growthId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );
    return response;
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
import 'dart:convert'; // أضفنا هذا لفك تشفير الخطأ إذا حدث

class AppointmentsApi {
  final http.Client client = http.Client();

  // 1- Upcoming (لجميع مواعيد المستخدم)
  Future<String> getAllUpcoming() async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) throw Exception('Session expired. Please login again.');
    final response = await client.get(
      Uri.parse('$baseUrl/appointments/upcoming'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true' // يفضل إضافته لكل الطلبات
      },
    );
    return response.body;
  }

  // 2- Past (لجميع مواعيد المستخدم)
  Future<String> getAllPast() async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) throw Exception('Session expired. Please login again.');
    final response = await client.get(
      Uri.parse('$baseUrl/appointments/past'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true'
      },
    );
    return response.body;
  }

  // 3- Upcoming by Child (لمواعيد طفل محدد)
  Future<String> getUpcomingForChild(int childId) async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) throw Exception('Session expired. Please login again.');
    final response = await client.get(
      Uri.parse('$baseUrl/appointments/upcoming/$childId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true'
      },
    );
    return response.body;
  }

  // 4- Past by Child (لمواعيد طفل محدد)
  Future<String> getPastForChild(int childId) async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) throw Exception('Session expired. Please login again.');
    final response = await client.get(
      Uri.parse('$baseUrl/appointments/past/$childId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true'
      },
    );
    return response.body;
  }

  // 5- Cancel Appointment (الدالة الجديدة لإلغاء الموعد)
  Future<String> cancelAppointment(int appointmentId) async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) throw Exception('Session expired. Please login again.');

    final response = await client.delete(
      Uri.parse('$baseUrl/appointments/$appointmentId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true', // ضروري جداً هنا
      },
    );

    // طباعة النتيجة في الكونسول لمعرفة الخطأ الحقيقي إن وُجد
    print('🚨 Cancel Status: ${response.statusCode}');
    print('🚨 Cancel Body: ${response.body}');

    // التحقق من نجاح العملية (200 OK)
    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.body;
    } else {
      // محاولة استخراج رسالة الخطأ من السيرفر وعرضها للمستخدم
      try {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to cancel appointment');
      } catch (e) {
        throw Exception('Server error: ${response.statusCode}');
      }
    }
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

  // 1. الدالة المسؤولة عن جلب التفاصيل من السيرفر
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

  // 2. الدالة المسؤولة عن إرسال طلب الحذف (DELETE)
  Future<String> deleteChild(int childId) async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) {
      throw Exception('Session expired. Please login again.');
    }

    final response = await client.delete(
      Uri.parse('$baseUrl/children/$childId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    // التحقق من حالة الطلب
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to delete child: ${response.statusCode}');
    }
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

### File: lib\core\apis\home\notification_history_api.dart
```dart

import 'package:http/http.dart' as http;
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';

class NotificationHistoryApi {
  Future<http.Response> getNotificationsHistory() async {
    final token = await SecureStorage.getToken();
    final lang = await SecureStorage.getLanguage() ?? 'en';

    return await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Accept-Language': lang,
      },
    );
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
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';

class ProfileApi {
  final http.Client client = http.Client();

  // ─── 1. دالة جلب البيانات ───
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

  // ─── 2. دالة تحديث البيانات (تم إخراجها لتصبح دالة مستقلة) ───
  Future<String> updateParentProfile(Map<String, dynamic> updatedData) async {
    final token = await SecureStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Session expired. Please login again.');
    }

    final response = await client.put(
      Uri.parse('$baseUrl/updateparentProfile'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json', // مهم جداً لإرسال الـ Body
        'Authorization': 'Bearer $token',
      },
      body: json.encode(updatedData),
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to update profile: ${response.statusCode}');
    }
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
const String baseUrl = 'https://kidcare.sy/api';

//const String baseUrl = 'https://deputize-daylong-puritan.ngrok-free.dev/api';

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
import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:kidcare/core/helper/secure_storage_service.dart';

import '../constants.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log("📩 إشعار جديد في الخلفية (Background/Terminated): ${message.messageId}");
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _appointmentsChannel =
  AndroidNotificationChannel(
    'appointments_channel', // channelId
    'Appointments Notifications', // channelName
    description: 'This channel is used for appointments updates.',
    importance: Importance.max,
    playSound: true,
  );

  static const AndroidNotificationChannel _chatChannel =
  AndroidNotificationChannel(
    'chat_channel', // channelId
    'Chat Notifications', // channelName
    description: 'This channel is used for direct doctor chats.',
    importance: Importance.max,
    playSound: true,
  );

  static Future<void> initialize() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log("🔔 تم منح صلاحيات الإشعارات بنجاح من قبل المستخدم.");
    }

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
    >()
        ?.createNotificationChannel(_appointmentsChannel);

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
    >()
        ?.createNotificationChannel(_chatChannel);

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          _handleNotificationClick(response.payload!);
        }
      },
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log("📥 استلام إشعار حي والتطبيق مفتوح: ${message.notification?.title}");
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log("🖱️ تم النقر على الإشعار والتطبيق بالخلفية: ${message.data}");
      if (message.data.containsKey('type')) {
        _handleNotificationClick(message.data['type'].toString());
      }
    });

    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null && initialMessage.data.containsKey('type')) {
      log("🚀 أقع التطبيق من الصفر بنقرة إشعار: ${initialMessage.data}");
      _handleNotificationClick(initialMessage.data['type'].toString());
    }

    // ─── التعديل الأول: استدعاء الدالة بالاسم الجديد ───
    await uploadFcmToken();
  }

  // ─── التعديل الثاني: إزالة الشرطة السفلية وتغيير الاسم لتصبح عامة ───
  static Future<void> uploadFcmToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        log("🔑 🔑 🔑 MY DEVICE FCM TOKEN = $token");

        // 🌟 إرسال التوكن إلى السيرفر
        await _saveTokenToBackend(token);
      }
    } catch (e) {
      log("❌ فشل توليد الـ FCM Token: $e");
    }
  }

  static Future<void> _saveTokenToBackend(String fcmToken) async {
    try {
      String userToken = await SecureStorage.getToken();

      if (userToken.isEmpty) return;

      final response = await http.post(
        Uri.parse('$baseUrl/parent/save-fcm-token'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: {'fcm_token': fcmToken},
      );

      if (response.statusCode == 200) {
        log("✅ تم حفظ الـ FCM Token في الباك إند بنجاح!");
      } else {
        log("⚠️ فشل حفظ التوكن في الباك إند: ${response.body}");
      }
    } catch (e) {
      log("❌ خطأ أثناء إرسال التوكن للسيرفر: $e");
    }
  }

  static void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      String notificationType = message.data['type']?.toString() ?? 'general';
      AndroidNotificationChannel targetChannel = _appointmentsChannel;

      if (notificationType == 'chat') {
        targetChannel = _chatChannel;
      }

      _localNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            targetChannel.id,
            targetChannel.name,
            channelDescription: targetChannel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: android.smallIcon,
            playSound: true,
          ),
        ),
        payload: notificationType,
      );
    }
  }

  static void _handleNotificationClick(String type) {
    log("🔀 جاري توجيه المستخدم بناءً على نوع الإشعار: $type");

    switch (type) {
      case 'appointment_accepted':
      case 'appointment_rejected':
      case 'appointment_reminder':
        Get.toNamed('/appointments');
        break;
      default:
        Get.toNamed('/home');
        break;
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
  // استرجاع السمة
  static Future<String?> getThemeMode() async {
    return await secureStorage.read(key: 'theme_mode');
  }

  // حفظ السمة
  static Future<void> storeThemeMode(String theme) async {
    await secureStorage.write(key: 'theme_mode', value: theme);
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
      'Create your account to benefit from our services':
          'Create your account to benefit from our services',
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
      'At least 8 characters with uppercase, lowercase and a number':
          'At least 8 characters with uppercase, lowercase and a number',
      'Enter your password again': 'Enter your password again',
      'Confirm Password': 'Confirm Password',
      'Create Account': 'Create Account',
      'Already have an account?': 'Already have an account?',

      //read more
      'About App': 'About App',
      'Pediatric Clinic Management': 'Pediatric Clinic Management System',
      'Our Vision': 'Our Vision',
      'Our Mission': 'Our Mission',
      'Key Features': 'Key Features',
      'Version 1.0.0': 'Version 1.0.0',
      'app_vision_desc':
          'We aim to redefine pediatric healthcare by providing a seamless, integrated digital environment that bridges the gap between parents and specialized doctors, putting your child\'s health and comfort first.',

      'app_mission_desc':
          'Empowering parents through a unified platform that allows them to easily create and manage medical profiles for all their children, book appointments with complete flexibility, and track health records safely and reliably anytime, anywhere.',

      'app_features_desc':
          '• Comprehensive Family Management: A main account with separate profiles for each child.\n• Smart & Fast Booking: Schedule medical appointments with a single click.\n• Real-Time Tracking: Monitor appointment status (Confirmed, Pending, Cancelled).\n• Secure Digital Payment: Multiple and reliable electronic payment options.\n• Eye-Friendly Design: Interfaces supporting both Dark and Light modes for the best user experience.',

      // --- Activation & OTP Views ---
      'Activate Account': 'Activate Account',
      'Enter your phone number registered at the clinic':
          'Enter your phone number registered at the clinic',
      'phone number': 'phone number',
      'Please enter your registered phone number':
          'Please enter your registered phone number',
      'Send Verification Code': 'Send Verification Code',
      'Verify Your Phone': 'Verify Your Phone',
      'Verify Your Phone Number': 'Verify Your Phone Number',
      'Verify Your Number': 'Verify Your Number',
      "Didn't receive the code?": "Didn't receive the code?",
      'Resend Code': 'Resend Code',
      'Resend in': 'Resend in',
      'Verify and Activate Account': 'Verify and Activate Account',
      'Create New Password': 'Create New Password',
      'Create a strong password to protect your account':
          'Create a strong password to protect your account',
      'New Password': 'New Password',
      'Password must contain:': 'Password must contain:',
      'At least 8 characters': 'At least 8 characters',
      'Set Password and Login': 'Set Password and Login',
      'The code is valid for ': 'The code is valid for ',
      ' minutes': ' minutes',
      'You can resend the code after the countdown ends':
          'You can resend the code after the countdown ends',
      'Change Phone Number': 'Change Phone Number',

      // --- Forgot Password ---
      "Don't worry, enter your phone number and we will send you a verification code.":
          "Don't worry, enter your phone number and we will send you a verification code.",
      'We sent a 4-digit code to': 'We sent a 4-digit code to',
      'Your new password must be different':
          'Your new password must be different',
      'Update Password': 'Update Password',
      'Password Updated!': 'Password Updated!',
      'Your password has been updated successfully. You can now log in with your new password.':
          'Your password has been updated successfully. You can now log in with your new password.',
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
      'We provide comprehensive healthcare for your children with the highest quality standards.':
          'We provide comprehensive healthcare for your children with the highest quality standards.',
      'Read More': 'Read More',
      'Vaccinations': 'Vaccinations',

      // --- Add Child & Child Profile ---
      'Child Profile': 'Child Profile',
      'Add New Child': 'Add New Child',
      'First Name': 'First Name',
      'Enter first name': 'Enter first name',
      'Enter last name': 'Enter last name',
      'Gender': 'Gender',
      'Female': 'female',
      'Male': 'male',
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
      'Are you sure you want to delete this child profile? This action cannot be undone.':
          'Are you sure you want to delete this child profile? This action cannot be undone.',
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
      'Pick a department above to see the doctors.':
          'Pick a department above to see the doctors.',
      'No doctors available in this department.':
          'No doctors available in this department.',
      'Specialist': 'Specialist',
      'rating': 'rating',
      'Choose Child': 'Choose Child',
      "You haven't added any children yet.":
          "You haven't added any children yet.",
      'years': 'years',
      'Pick Date & Time': 'Pick Date & Time',
      'Available Times': 'Available Times',
      'Pick a date to see available times.':
          'Pick a date to see available times.',
      'No times available for this date.': 'No times available for this date.',
      'Book Appointment': 'Book Appointment',
      'Appointment Booked!': 'Appointment Booked!',
      'Your appointment has been confirmed.\nSee you soon!':
          'Your appointment has been confirmed.\nSee you soon!',
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

      // --- New Additions (Add Child, Appointments, Session) ---
      'Invalid Age': 'Invalid Age',
      'No medical history': 'No medical history',
      'No allergies': 'No allergies',
      'Unknown Child': 'Unknown Child',
      'Unknown Doctor': 'Unknown Doctor',
      'Patient': 'Patient',
      'General': 'General',
      'Session Expired': 'Session Expired',
      'Please login again to continue.': 'Please login again to continue.',
      'Failed to load appointment data.': 'Failed to load appointment data.',

      // --- Appointment Status ---
      'Confirmed': 'Confirmed',
      'Pending': 'Pending',
      'Cancelled': 'Cancelled',
      'Canceled': 'Canceled', // تحسباً لاختلاف الإملاء من الباك إند
      'Completed': 'Completed',

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
      'Phone number must be 12 numbers (e.g., 9639XXXXXXXX)':
          'Phone number must be 12 numbers (e.g., 9639XXXXXXXX)',
      'Success': 'Success',
      'Verification code resent successfully':
          'Verification code resent successfully',
      'Check Code': 'Check Code',
      'Please enter OTP': 'Please enter the verification code',
      'Please enter the 4-digit code correctly':
          'Please enter the 4-digit code correctly',
      'Passwords do not match': 'Passwords do not match',
      'Weak Password': 'Weak Password',
      'Password must be at least 8 characters long':
          'Password must be at least 8 characters long',
      'Account activated successfully': 'Account activated successfully',
      'Please enter a valid phone number': 'Please enter a valid phone number',
      'Please enter the 4-digit code': 'Please enter the 4-digit code',
      'Password Updated Successfully!': 'Password Updated Successfully!',
      'Invalid Phone Number': 'Invalid Phone Number',
      'Welcome Back,': 'Welcome Back,',
      'Required': 'Required',
      'Please enter the verification code':
          'Please enter the verification code',
      'Invalid Code': 'Invalid Code',
      'Please enter the complete 4-digit code':
          'Please enter the complete 4-digit code',
      'Phone verified successfully!': 'Phone verified successfully!',
      'Code resent successfully!': 'Code resent successfully!',
      'Something went wrong. Please try again.':
          'Something went wrong. Please try again.',
      'Incorrect phone number or password.':
          'Incorrect phone number or password.',
      'No Internet connection. Please check your network.':
          'No Internet connection. Please check your network.',
      'Request timed out. Please try again.':
          'Request timed out. Please try again.',
      'Error': 'Error',
      'Info': 'Info',
      'Child deleted successfully!': 'Child deleted successfully!',
      'Please enter first and last name': 'Please enter first and last name',
      'Please select birth date': 'Please select birth date',
      'Please select blood type': 'Please select blood type',
      'Child added successfully!': 'Child added successfully!',
      'Failed to load profile': 'Failed to load profile',
      'Error Loading Details': 'Error Loading Details',
      'No appointment data found to process':
          'No appointment data found to process',
      'KidCare Clinic': 'KidCare Clinic',
      'Payment Error': 'Payment Error',
      'Payment Cancelled': 'Payment Cancelled',
      'User cancelled the payment': 'User cancelled the payment',
      'An unexpected error occurred': 'An unexpected error occurred',
      'favorite_doctors': 'Favorite Doctors',
      'view_favorite_doctors': 'View your favorite doctors',
      'Session expired. Please login again.':
          'Session expired. Please login again.',
      'Weight (kg)': 'Weight (kg)',
      'Height (cm)': 'Height (cm)',
      'Record Date': 'Record Date',
      'Save Measurement': 'Save Measurement',
      'Please enter valid weight and height':
          'Please enter valid weight and height',
      'Measurement saved successfully': 'Measurement saved successfully',
      'Are you sure you want to delete this record?':
          'Are you sure you want to delete this record?',
      'Growth History': 'Growth History',
      'Age (Months)': 'Age (Months)',
      'Ideal Weight (WHO)': 'Ideal Weight (WHO)',
      'Max Limit (WHO)': 'Max Limit (WHO)',
      'Min Limit (WHO)': 'Min Limit (WHO)',
      'Child Growth Chart': 'Child Growth Chart',
      'Status: ': 'Status: ',
      'Current Weight': 'Current Weight',
      'Current Height': 'Current Height',
      'Months': 'Months',
      'Growth Chart & Weight': 'Growth Chart & Weight',
      'Appointments & Files': 'Appointments & Files',
      'Medical Assessment': 'Medical Assessment',
      'Needs Review': 'Needs Review',
      'Add Measurement': 'Add Measurement',
      'Notifications': 'Notifications',
      'No notifications found': 'No notifications found',
      'Delete Account': 'Delete Account',
      'Permanently delete your account from the app':
          'Permanently delete your account from the app',
      'Are you sure you want to permanently delete your account? This action cannot be undone.':
          'Are you sure you want to permanently delete your account? This action cannot be undone.',
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
      'Or': 'أو',
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
      'Create your account to benefit from our services':
          'أنشئ حسابك للاستفادة من خدماتنا',
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
      'At least 8 characters with uppercase, lowercase and a number':
          '8 أحرف على الأقل، تتضمن أحرف كبيرة وصغيرة ورقم',
      'Enter your password again': 'أدخل كلمة المرور مرة أخرى',
      'Confirm Password': 'تأكيد كلمة المرور',
      'Create Account': 'إنشاء الحساب',
      'Already have an account?': 'لديك حساب بالفعل؟',

      // --- Activation & OTP Views ---
      'Activate Account': 'تفعيل الحساب',
      'Enter your phone number registered at the clinic':
          'أدخل رقم هاتفك المسجل في العيادة',
      'phone number': 'رقم الهاتف',
      'Please enter your registered phone number':
          'يرجى إدخال رقم هاتفك المسجل',
      'Send Verification Code': 'إرسال رمز التحقق',
      'Verify Your Phone': 'تحقق من رقم الهاتف',
      'Verify Your Phone Number': 'تحقق من رقم الهاتف',
      'Verify Your Number': 'تحقق من رقمك',
      "Didn't receive the code?": "لم يصلك الرمز؟",
      'Resend Code': 'إعادة إرسال الرمز',
      'Resend in': 'إعادة الإرسال خلال',
      'Verify and Activate Account': 'تحقق وفعل الحساب',
      'Create New Password': 'إنشاء كلمة مرور جديدة',
      'Create a strong password to protect your account':
          'أنشئ كلمة مرور قوية لحماية حسابك',
      'New Password': 'كلمة المرور الجديدة',
      'Password must contain:': 'يجب أن تحتوي كلمة المرور على:',
      'At least 8 characters': '8 أحرف على الأقل',
      'Set Password and Login': 'تعيين كلمة المرور وتسجيل الدخول',
      'The code is valid for ': 'الرمز صالح لمدة ',
      ' minutes': ' دقائق',
      'You can resend the code after the countdown ends':
          'يمكنك إعادة إرسال الرمز بعد انتهاء العداد',
      'Change Phone Number': 'تغيير رقم الهاتف',

      // --- Forgot Password ---
      "Don't worry, enter your phone number and we will send you a verification code.":
          "لا تقلق، أدخل رقم هاتفك وسنرسل لك رمز التحقق.",
      'We sent a 4-digit code to': 'أرسلنا رمزاً من 4 أرقام إلى',
      'Your new password must be different':
          'يجب أن تكون كلمة المرور جديدة ومختلفة',
      'Update Password': 'تحديث كلمة المرور',
      'Password Updated!': 'تم تحديث كلمة المرور!',
      'Your password has been updated successfully. You can now log in with your new password.':
          'تم تحديث كلمة المرور بنجاح. يمكنك الآن تسجيل الدخول بكلمة المرور الجديدة.',
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
      'We provide comprehensive healthcare for your children with the highest quality standards.':
          'نقدم رعاية صحية شاملة لأطفالك بأعلى معايير الجودة.',
      'Read More': 'اقرأ المزيد',
      'Vaccinations': 'اللقاحات',

      //read more
      'About App': 'عن التطبيق',
      'Pediatric Clinic Management': 'نظام إدارة عيادة الأطفال',
      'Our Vision': 'رؤيتنا',
      'Our Mission': 'رسالتنا',
      'Key Features': 'أبرز المميزات',
      'Version 1.0.0': 'الإصدار 1.0.0',
      'app_vision_desc':
          'نسعى لإعادة صياغة تجربة الرعاية الصحية للأطفال من خلال تقديم بيئة رقمية متكاملة وسهلة الاستخدام، تقرب المسافات بين الآباء والأطباء المتخصصين وتضع راحة وصحة طفلك في المقام الأول.',

      'app_mission_desc':
          'تمكين الآباء والأمهات من خلال منصة موحدة تتيح لهم إنشاء وإدارة الملفات الطبية لجميع أطفالهم بسهولة، حجز المواعيد بمرونة تامة، ومتابعة السجلات الصحية بكل أمان وموثوقية في أي وقت ومن أي مكان.',

      'app_features_desc':
          '• إدارة عائلية متكاملة: حساب أساسي يضم ملفات منفصلة لكل طفل.\n• حجز ذكي وسريع: جدولة المواعيد الطبية بضغطة زر.\n• تتبع حي للمواعيد: متابعة حالة الحجز (مؤكد، قيد الانتظار، ملغي).\n• دفع إلكتروني آمن: خيارات دفع متعددة وموثوقة.\n• تصميم مريح للعين: واجهات تدعم الوضعين الليلي والنهاري لضمان أفضل تجربة استخدام.',

      // --- Add Child & Child Profile ---
      'Child Profile': 'ملف الطفل',
      'Add New Child': 'إضافة طفل جديد',
      'First Name': 'الاسم الأول',
      'Enter first name': 'أدخل الاسم الأول',
      'Enter last name': 'أدخل اسم العائلة',
      'Gender': 'الجنس',
      'famale': 'أنثى',
      'male': 'ذكر',
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
      'Are you sure you want to delete this child profile? This action cannot be undone.':
          'هل أنت متأكد أنك تريد حذف ملف هذا الطفل؟ لا يمكن التراجع عن هذا الإجراء.',
      'Age': 'العمر',
      'Child age cannot exceed 6 years.':
          'عمر الطفل لا يمكن أن يتجاوز 6 سنوات.',

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
      'Pick a department above to see the doctors.':
          'اختر قسماً من الأعلى لرؤية الأطباء.',
      'No doctors available in this department.':
          'لا يوجد أطباء متاحين في هذا القسم.',
      'Specialist': 'أخصائي',
      'rating': 'تقييم',
      'Choose Child': 'اختر الطفل',
      "You haven't added any children yet.": "لم تقم بإضافة أي أطفال بعد.",
      'years': ' سنوات',
      'Pick Date & Time': 'اختر التاريخ والوقت',
      'Available Times': 'الأوقات المتاحة',
      'Pick a date to see available times.':
          'اختر تاريخاً لرؤية الأوقات المتاحة.',
      'No times available for this date.': 'لا توجد أوقات متاح في هذا التاريخ.',
      'Book Appointment': 'تأكيد الحجز',
      'Appointment Booked!': 'تم حجز الموعد!',
      'Your appointment has been confirmed.\nSee you soon!':
          'تم تأكيد موعدك.\nنراك قريباً!',
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

      // --- New Additions (Add Child, Appointments, Session) ---
      'Invalid Age': 'عمر غير مقبول',
      'No medical history': 'لا يوجد سجل طبي',
      'No allergies': 'لا يعاني من حساسية',
      'Unknown Child': 'طفل غير معروف',
      'Unknown Doctor': 'طبيب غير معروف',
      'Patient': 'المريض',
      'General': 'عام',
      'Session Expired': 'انتهت الجلسة',
      'Please login again to continue.': 'يرجى تسجيل الدخول مرة أخرى للمتابعة.',
      'Failed to load appointment data.': 'فشل في تحميل بيانات الموعد.',

      // --- Appointment Status ---
      'Confirmed': 'مؤكد',
      'Pending': 'قيد الانتظار',
      'Cancelled': 'ملغي',
      'Canceled': 'ملغي',
      'Completed': 'تم',

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
      'Phone number must be 12 numbers (e.g., 9639XXXXXXXX)':
          'يجب أن يتكون رقم الهاتف من 12 رقماً (مثال: 9639XXXXXXXX)',
      'Success': 'نجاح',
      'Verification code resent successfully':
          'تم إعادة إرسال رمز التحقق بنجاح',
      'Check Code': 'التحقق من الرمز',
      'Please enter OTP': 'يرجى إدخال رمز التحقق',
      'Please enter the 4-digit code correctly':
          'يرجى إدخال الرمز المكون من 4 أرقام بشكل صحيح',
      'Passwords do not match': 'كلمتا المرور غير متطابقتين',
      'Weak Password': 'كلمة مرور ضعيفة',
      'Password must be at least 8 characters long':
          'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل',
      'Account activated successfully': 'تم تفعيل الحساب بنجاح',
      'Please enter a valid phone number': 'يرجى إدخال رقم هاتف صحيح',
      'Please enter the 4-digit code': 'يرجى إدخال الرمز المكون من 4 أرقام',
      'Password Updated Successfully!': 'تم تحديث كلمة المرور بنجاح!',
      'Invalid Phone Number': 'رقم هاتف غير صحيح',
      'Welcome Back,': 'مرحباً بك مجدداً،',
      'Required': 'مطلوب',
      'Please enter the verification code': 'يرجى إدخال رمز التحقق',
      'Invalid Code': 'رمز غير صحيح',
      'Please enter the complete 4-digit code':
          'يرجى إدخال رمز التحقق كاملاً المكون من 4 أرقام',
      'Phone verified successfully!': 'تم التحقق من رقم الهاتف بنجاح!',
      'Code resent successfully!': 'تم إعادة إرسال الرمز بنجاح!',
      'Something went wrong. Please try again.':
          'حدث خطأ ما، يرجى المحاولة مرة أخرى.',
      'Incorrect phone number or password.':
          'رقم الهاتف أو كلمة المرور غير صحيحة.',
      'No Internet connection. Please check your network.':
          'لا يوجد اتصال بالإنترنت، يرجى التحقق من الشبكة.',
      'Request timed out. Please try again.':
          'انتهت مهلة الطلب، يرجى المحاولة مجدداً.',
      'Error': 'خطأ',
      'Info': 'معلومات',
      'Child deleted successfully!': 'تم حذف ملف الطفل بنجاح!',
      'Please enter first and last name': 'يرجى إدخال الاسم الأول واسم العائلة',
      'Please select birth date': 'يرجى تحديد تاريخ الميلاد',
      'Please select blood type': 'يرجى اختيار فصيلة الدم',
      'Child added successfully!': 'تم إضافة الطفل بنجاح!',
      'Failed to load profile': 'فشل في تحميل بيانات الملف الشخصي',
      'Error Loading Details': 'خطأ في تحميل التفاصيل',
      'No appointment data found to process':
          'لم يتم العثور على بيانات للموعد لإتمام العملية',
      'KidCare Clinic': 'عيادة كيد كير',
      'Payment Error': 'خطأ في عملية الدفع',
      'Payment Cancelled': 'تم إلغاء الدفع',
      'User cancelled the payment': 'قام المستخدم بإلغاء عملية الدفع',
      'An unexpected error occurred': 'حدث خطأ غير متوقع',
      'favorite_doctors': 'الأطباء المفضلون',
      'view_favorite_doctors': 'عرض قائمة أطبائك المفضلين',
      'Session expired. Please login again.':
          'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مجدداً.',
      'Weight (kg)': 'الوزن (كجم)',
      'Height (cm)': 'الطول (سم)',
      'Record Date': 'تاريخ القياس',
      'Save Measurement': 'حفظ القياس',
      'Please enter valid weight and height': 'يرجى إدخال وزن وطول صحيحين',
      'Measurement saved successfully': 'تم حفظ القياس بنجاح',
      'Are you sure you want to delete this record?':
          'هل أنت متأكد من حذف هذا السجل؟',
      'Growth History': 'سجلات النمو',
      'Age (Months)': 'العمر (شهر)',
      'Ideal Weight (WHO)': 'المعدل المثالي (WHO)',
      'Max Limit (WHO)': 'الحد الأقصى للوزن',
      'Min Limit (WHO)': 'الحد الأدنى للوزن',
      'Child Growth Chart': 'منحنى النمو والوزن',
      'Status: ': 'الحالة: ',
      'Current Weight': 'الوزن الحالي',
      'Current Height': 'الطول الحالي',
      'Months': 'شهر',
      'Growth Chart & Weight': 'منحنى النمو والوزن',
      'Appointments & Files': 'المواعيد والملفات',
      'Medical Assessment': 'التقييم الطبي المفصل',
      'Needs Review': 'يحتاج متابعة',
      'Add Measurement': 'إضافة قياس',
      'Notifications': 'الإشعارات',
      'No notifications found': 'لا توجد إشعارات حالياً',
      'Delete Account': 'حذف الحساب',
      'Permanently delete your account from the app':
          'حذف حسابك بشكل دائم من التطبيق',
      'Are you sure you want to permanently delete your account? This action cannot be undone.':
          'هل أنت متأكد أنك تريد حذف حسابك نهائياً؟ هذا الإجراء لا يمكن التراجع عنه.',
    },
  };
}

```

### File: lib\core\repos\appointment\appointment_repo.dart
```dart
import 'dart:convert';


import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:http/http.dart' as http;

import '../../apis/appointment/appointment_api.dart';
import '../../constants.dart';
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
// دالة مخصصة لضرب مسار الـ POST الخاص بالحجز السريع
  Future<String> bookQuickAppointmentApi(int doctorId, int childId, String date, String time) async {
    final token = await SecureStorage.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/appointment'), // مسار الـ POST الذي جربته في Postman
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {
        'doctor_id': doctorId.toString(),
        'child_id': childId.toString(),
        'date': date,
        'time': time,
      },
    );

    final data = jsonDecode(response.body);

    // 201 Created تعني نجاح الحجز كما ظهر معك في Postman
    if (response.statusCode == 201 && data['status'] == 'success') {
      return data['appointment_id']; // إرجاع الـ UUID الخاص بالموعد
    } else {
      throw Exception(data['message'] ?? 'Failed to book appointment');
    }
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

  Future<String> cancel(String id) async {
    final token = await SecureStorage.getToken();
    final response = await _api.delete(token, id);

    if (response.isEmpty) return "Appointment cancelled successfully".tr;

    final decoded = jsonDecode(response);

    // إرجاع رسالة السيرفر (مثل: تم إلغاء الموعد وجاري إعادة المبلغ)
    if (decoded is Map && decoded['message'] != null) {
      return decoded['message'].toString();
    }

    return "Appointment cancelled successfully".tr;
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

    // 🌟 فحص مرن ومطاطي لاستخراج مصفوفة الأطفال أينما وجدت بداخل الـ JSON
    List<dynamic> listToMap = [];
    if (decoded is List) {
      listToMap = decoded;
    } else if (decoded is Map) {
      if (decoded['children'] is List) {
        listToMap = decoded['children'];
      } else if (decoded['data'] is List) {
        listToMap = decoded['data'];
      }
    }

    if (listToMap.isNotEmpty || (decoded is Map && decoded['status'] == 'success')) {
      return listToMap
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

    // 🌟 التعديل هنا: استخراج المصفوفة بمرونة سواء كانت مباشرة أو داخل غلاف (data أو departments)
    List<dynamic> listToMap = [];
    if (decoded is List) {
      listToMap = decoded;
    } else if (decoded is Map) {
      if (decoded['departments'] is List) {
        listToMap = decoded['departments'];
      } else if (decoded['data'] is List) {
        listToMap = decoded['data'];
      }
    }

    // التحقق من وجود البيانات أو رسالة النجاح
    if (listToMap.isNotEmpty || (decoded is Map && decoded['status'] == 'success')) {
      return listToMap
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
import '../../../models/appointment/closest_appointment_model.dart';

class DoctorRepo {
  final DoctorApi _api;

  DoctorRepo({DoctorApi? api}) : _api = api ?? DoctorApi();

  Future<List<ClosestAppointmentModel>> fetchClosestAppointments(int departmentId) async {
    final token = await SecureStorage.getToken();
    final response = await _api.getClosestAppointments(token, departmentId);
    final decoded = jsonDecode(response);

    if (decoded is Map && decoded['status'] == 'success') {
      final List data = decoded['data'] ?? [];
      return data.map((e) => ClosestAppointmentModel.fromJson(e as Map<String, dynamic>)).toList();
    }

    final msg = (decoded is Map && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Failed to load closest appointments';
    throw Exception(msg);
  }

  Future<List<DoctorModel>> fetchByDepartment(int departmentId) async {
    final token = await SecureStorage.getToken();
    final response = await _api.getByDepartment(token, departmentId);
    final decoded = jsonDecode(response);

    // 🌟 تحصين دفاعي: استخراج المصفوفة بأمان سواء أتت خام أو مغلفة بداخل مفتاح بسبب اللغات
    List<dynamic> listToMap = [];
    if (decoded is List) {
      listToMap = decoded;
    } else if (decoded is Map) {
      if (decoded['doctors'] is List) {
        listToMap = decoded['doctors'];
      } else if (decoded['data'] is List) {
        listToMap = decoded['data'];
      }
    }

    if (listToMap.isNotEmpty || (decoded is Map && decoded['status'] == 'success')) {
      return listToMap
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
      return DoctorModel.fromJson(raw);
    }

    final msg = (decoded is Map && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Failed to load doctor';
    throw Exception(msg);
  }

  Future<List<DoctorAvailabilityModel>> fetchWeeklyAvailability(int doctorId) async {
    final token = await SecureStorage.getToken();
    final response = await _api.getAvailabilities(token, doctorId);
    final decoded = jsonDecode(response);

    List<dynamic> listToMap = [];
    if (decoded is List) {
      listToMap = decoded;
    } else if (decoded is Map) {
      if (decoded['availabilities'] is List) {
        listToMap = decoded['availabilities'];
      } else if (decoded['data'] is List) {
        listToMap = decoded['data'];
      }
    }

    return listToMap
        .map((j) => DoctorAvailabilityModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> fetchSlots(int doctorId, String date) async {
    final token = await SecureStorage.getToken();
    final response = await _api.getAvailableTimes(token, doctorId, date);
    final decoded = jsonDecode(response);

    if (decoded is Map && decoded['times'] is List) {
      return List<String>.from(
        (decoded['times'] as List).map((e) => e.toString()),
      );
    }
    if (decoded is Map && decoded['data'] is Map && decoded['data']['times'] is List) {
      return List<String>.from(
        (decoded['data']['times'] as List).map((e) => e.toString()),
      );
    }
    return [];
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
  final LoginApi _api = LoginApi();

  Future<UserModel> loginUser(String phone, String password) async {
    var response = await _api.login(phone, password);
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

  Future<String> deletePatientAccount() async {
    String rawResponse = await _api.deletePatientAccount();

    if (rawResponse.contains('{')) {
      rawResponse = rawResponse.substring(rawResponse.indexOf('{'));
    }

    final decoded = jsonDecode(rawResponse);

    if (decoded['status'] == 'success' || decoded['message'] != null) {
      return decoded['message'] ?? 'Account terminated successfully.';
    } else {
      throw Exception('Failed to terminate account');
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

### File: lib\core\repos\growth\child_growth_repo.dart
```dart
import 'dart:convert';
import '../../../models/growth/child_growth_response_model.dart';
import '../../apis/growth/child_growth_api.dart';

class ChildGrowthRepo {
  final ChildGrowthApi api;

  ChildGrowthRepo({ChildGrowthApi? api}) : api = api ?? ChildGrowthApi();

  /// 1. معالجة  بيانات مخطط النمو (GET)

  Future<ChildGrowthResponseModel> fetchChildGrowthData(int childId) async {
    final response = await api.getGrowthData(childId);

    if (response.statusCode == 200) {
      final Map<String, dynamic> decodedData = json.decode(response.body);
      return ChildGrowthResponseModel.fromJson(decodedData);
    } else if (response.statusCode == 401) {
      throw Exception('401');
    } else {
      throw _parseError(response.body);
    }
  }

  /// 2. معالجة  إضافة سجل قياس جديد (POST)

  Future<String> addNewGrowthRecord({
    required int childId,
    required double height,
    required double weight,
    required String recordDate,
  }) async {
    final response = await api.storeGrowthRecord(
      childId: childId,
      height: height,
      weight: weight,
      recordDate: recordDate,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> decodedData = json.decode(response.body);

      return decodedData['status']?.toString() ??
          decodedData['message']?.toString() ??
          'Success';
    } else if (response.statusCode == 401) {
      throw Exception('401');
    } else {
      throw _parseError(response.body);
    }
  }

  /// 3. معالجة حذف سجل قياس سابق (DELETE)
  Future<void> removeGrowthRecord(int growthId) async {
    final response = await api.deleteGrowthRecord(growthId);

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401) {
      throw Exception('401');
    } else {
      throw _parseError(response.body);
    }
  }

  ///  مساعدة لقراءة تفاصيل الخطأ  من الـ API
  dynamic _parseError(String responseBody) {
    try {
      final decoded = json.decode(responseBody);
      if (decoded is Map && decoded.containsKey('message')) {
        return decoded['message'];
      }
    } catch (_) {}
    return 'Something went wrong. Please try again.';
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
import 'package:http/http.dart' as http;

import '../../../models/home/appointments_model.dart';
import '../../apis/home/appointments_api.dart';
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';

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
  Future<Map<String, dynamic>> cancelAppointment(int appointmentId) async {
    final token = await SecureStorage.getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/appointments/$appointmentId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true', // 👈 هذا هو السطر المنقذ!
      },
    );

    // ─── طباعة النتيجة في الكونسول للمراقبة ───
    print('🚨 Delete Status: ${response.statusCode}');
    print('🚨 Delete Body: ${response.body}');

    // التحقق من نجاح العملية قبل محاولة فك التشفير
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return data; // إرجاع الريسبونس (الذي يحتوي على رسالة النجاح وقيمة الاسترداد)
    } else {
      // محاولة استخراج رسالة الخطأ من السيرفر بشكل آمن
      try {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to cancel appointment');
      } catch (e) {
        throw Exception('Server error: ${response.statusCode}');
      }
    }
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

    if (response.contains('{')) {
      response = response.substring(response.indexOf('{'));
    }

    final body = json.decode(response);

    // 🌟 تحصين دفاعي: فحص ما إذا كانت البيانات قادمة مغلفة بداخل كائن 'data' بسبب مخرجات السيرفر الجديدة
    if (body is Map<String, dynamic>) {
      final rawChild = body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : body;

      if (rawChild['id'] != null) {
        return ChildModel.fromJson(rawChild);
      }
    }

    throw Exception(body['message'] ?? 'Failed to load child details');
  }

  Future<void> deleteChild(int childId) async {
    final response = await _api.deleteChild(childId);
    final body = json.decode(response);

    if (body['message'] != null &&
        (body['message'].toString().toLowerCase().contains('success') ||
            body['message'].toString().toLowerCase().contains('deleted'))) {
      return;
    }
    throw Exception(body['message'] ?? 'Failed to delete child');
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

### File: lib\core\repos\home\notification_history_repo.dart
```dart
import 'dart:convert';
import '../../../models/home/notification_history_model.dart';
import '../../apis/home/notification_history_api.dart';

class NotificationHistoryRepo {
  final NotificationHistoryApi _api = NotificationHistoryApi();

  Future<List<NotificationHistoryModel>> fetchNotifications() async {
    final response = await _api.getNotificationsHistory();

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      if (decoded is List) {
        return decoded
            .map(
              (json) => NotificationHistoryModel.fromJson(
                json as Map<String, dynamic>,
              ),
            )
            .toList();
      } else if (decoded is Map && decoded['notifications'] is List) {
        return (decoded['notifications'] as List)
            .map(
              (json) => NotificationHistoryModel.fromJson(
                json as Map<String, dynamic>,
              ),
            )
            .toList();
      } else if (decoded is Map && decoded['data'] is List) {
        return (decoded['data'] as List)
            .map(
              (json) => NotificationHistoryModel.fromJson(
                json as Map<String, dynamic>,
              ),
            )
            .toList();
      }
      return [];
    } else {
      throw Exception('Failed to load notifications history.');
    }
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
  Future<void> updateProfile(Map<String, dynamic> data) async {
    final response = await _api.updateParentProfile(data);
    final body = json.decode(response);

    if (body['status'] == 'success') {
      return; // تم التحديث بنجاح
    }

    throw Exception(body['message'] ?? 'Failed to update profile');
  }

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

### File: lib\core\theme\app_themes.dart
```dart
import 'package:flutter/material.dart';

class AppThemes {
  // ─── الوضع النهاري (مطابق لتصميمك الحالي تماماً) ───
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF0F4FF), // لون الخلفية العام
    cardColor: Colors.white, // لون البطاقات
    primaryColor: const Color(0xFF3B9EFF), // اللون الأساسي (الأزرق)
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF0F4FF),
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF1A2E5A)),
      titleTextStyle: TextStyle(
        color: Color(0xFF1A2E5A),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: const TextStyle(color: Color(0xFF1A2E5A)), // النصوص الأساسية
      bodyMedium: TextStyle(color: Colors.grey.shade600), // النصوص الثانوية
    ),
    dividerColor: const Color(0xFFE2E8F0),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF3B9EFF),
      unselectedItemColor: Colors.grey,
    ),
  );

  // ─── الوضع الليلي (Dark Mode) ───
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212), // خلفية داكنة مريحة للعين
    cardColor: const Color(0xFF1E1E1E), // بطاقات بدرجة أفتح قليلاً
    primaryColor: const Color(0xFF3B9EFF),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: const TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.grey.shade400),
    ),
    dividerColor: const Color(0xFF2C2C2C),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: Color(0xFF3B9EFF),
      unselectedItemColor: Colors.grey,
    ),
  );
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
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:kidcare/core/helper/secure_storage_service.dart';
import 'package:kidcare/core/localization/app_translations.dart';
import 'package:kidcare/core/repos/home/add_child_repo.dart';
import 'package:kidcare/views/appointment/closest_appointments_view.dart';
import 'package:kidcare/views/home/add_child_view.dart';
import 'package:kidcare/views/home/appointments_view.dart';
import 'package:kidcare/views/home/child_profile_view.dart';
import 'package:kidcare/views/home/home_view.dart';
import 'package:kidcare/views/home/notification_history_view.dart';
import 'package:kidcare/views/home/profile_view.dart';

//theme
import 'package:kidcare/core/theme/app_themes.dart';

// الواجهات الأساسية
import 'package:kidcare/views/main_advanced.dart';
import 'package:kidcare/views/auth/login_view.dart';

// Sign Up
import 'package:kidcare/views/auth/sign_up_view.dart';
import 'package:kidcare/core/repos/auth/sign_up_repo.dart';
import 'package:kidcare/views/settings/favorite_doctors_view.dart';
import 'controllers/appointment/appointment_controller.dart';
import 'controllers/appointment/closest_appointments_controller.dart';
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
import 'controllers/home/child_profile_controller.dart';
import 'controllers/home/home_controller.dart';
import 'controllers/home/notification_history_controller.dart';
import 'controllers/home/profile_controller.dart';
import 'controllers/payment_controller.dart';
import 'core/helper/notification_service.dart';
import 'core/repos/home/appointments_repo.dart';
import 'core/repos/home/child_profile_repo.dart';
import 'core/repos/home/home_children_repo.dart';
import 'core/repos/home/notification_history_repo.dart';
import 'core/repos/home/parent_name_repo.dart';
import 'core/repos/home/profile_repo.dart';

void main() async {
  // لتهيئة فلاتر قبل تشغيل أي ميزة Native مثل Stripe
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey =
      'pk_test_51TVx1BA9J421R1e0fArsBqsC3bNgwlcmhH407ymZp4Ncu9aVgwtEMgXg6lWcswqESufx6ZL7arNccQCdJCHA3QUG00GUsDRB6Q';
  await Firebase.initializeApp();
  await NotificationService.initialize();
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

  String? savedTheme = await SecureStorage.getThemeMode();
  ThemeMode initialThemeMode = ThemeMode.system;
  if (savedTheme == 'dark') {
    initialThemeMode = ThemeMode.dark;
  } else if (savedTheme == 'light') {
    initialThemeMode = ThemeMode.light;
  }


  runApp(MyApp(initialLocale: initialLocale, initialThemeMode: initialThemeMode));
}

class MyApp extends StatelessWidget {
  final Locale initialLocale;
  final ThemeMode initialThemeMode;

  const MyApp({super.key, required this.initialLocale, required this.initialThemeMode});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(

      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: initialThemeMode,

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


      translations: AppTranslations(),
      locale: initialLocale,
      fallbackLocale: const Locale('en', 'US'),



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
        GetPage(
          name: '/closest-appointments',
          page: () => const ClosestAppointmentsView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => ClosestAppointmentsController(
              departmentRepo: DepartmentRepo(),
              doctorRepo: DoctorRepo(),
            ));
            // استخدام Get.put لضمان تهيئة المتحكم
            Get.put(AppointmentController(
                repo: AppointmentRepo(),
                doctorRepo: DoctorRepo()
            ));
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

        GetPage(
          name: '/child-profile',
          page: () => const ChildProfileView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<ChildProfileController>(
                  () => ChildProfileController(repo: ChildProfileRepo()),
            );
          }),
        ),
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

        GetPage(
          name: '/favorites',
          page: () => const FavoriteDoctorsView(),
          binding: BindingsBuilder(() {

            if (!Get.isRegistered<DoctorController>()) {
              Get.lazyPut(() => DoctorController(repo: DoctorRepo()));
            }
            if (!Get.isRegistered<AppointmentController>()) {
              Get.lazyPut(() => AppointmentController(repo: AppointmentRepo(), doctorRepo: DoctorRepo()));
            }
          }),
        ),
        GetPage(
          name: '/notifications-history',
          page: () => const NotificationHistoryView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => NotificationHistoryController(repo: NotificationHistoryRepo()));
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

### File: lib\models\appointment\closest_appointment_model.dart
```dart
class ClosestAppointmentModel {
  final int doctorId;
  final String doctorName;
  final String? profilePictureUrl;
  final String date;
  final String time;
  final String dayName;

  ClosestAppointmentModel({
    required this.doctorId,
    required this.doctorName,
    this.profilePictureUrl,
    required this.date,
    required this.time,
    required this.dayName,
  });

  factory ClosestAppointmentModel.fromJson(Map<String, dynamic> json) {
    final appointment = json['closest_appointment'] ?? {};
    return ClosestAppointmentModel(
      doctorId: json['doctor_id'] ?? 0,
      doctorName: json['doctor_name']?.toString() ?? '',
      profilePictureUrl: json['profile_picture_url']?.toString(),
      date: appointment['date']?.toString() ?? '',
      time: appointment['time']?.toString() ?? '',
      dayName: appointment['day_name']?.toString() ?? '',
    );
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
class DoctorModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String address;
  final String? departmentName;
  final String? profilePicture;
  final bool isFavorite;
  final String? department;

  DoctorModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.address,
    this.departmentName,
    this.profilePicture,
    required this.isFavorite,
    this.department,
  });

  String get fullName => '$firstName $lastName';

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    bool favoriteValue = false;
    final fav = json['is_favorite'] ?? json['isFavorite'];
    if (fav != null) {
      if (fav is bool) favoriteValue = fav;
      if (fav is int) favoriteValue = fav == 1;
      if (fav is String) {
        favoriteValue = fav == '1' || fav.toLowerCase() == 'true';
      }
    }

    return DoctorModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      firstName:
          json['first_name']?.toString() ?? json['firstName']?.toString() ?? '',
      lastName:
          json['last_name']?.toString() ?? json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      departmentName:
          json['department_name']?.toString() ??
          json['departmentName']?.toString() ??
          '',
      profilePicture: json['profile_picture']?.toString(),
      department: json['department']?.toString() ?? '',
      isFavorite: favoriteValue,
    );
  }
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

### File: lib\models\growth\child_growth_response_model.dart
```dart
import '../../core/helper/json_utils.dart';
import 'growth_record_model.dart';
import 'who_standard_model.dart';

class ChildGrowthResponseModel {
  final String childName;
  final String childGender;
  final double currentAgeMonths;
  final List<GrowthRecordModel> growthHistory;
  final List<WhoStandardModel> whoStandards;

  const ChildGrowthResponseModel({
    required this.childName,
    required this.childGender,
    required this.currentAgeMonths,
    required this.growthHistory,
    required this.whoStandards,
  });

  factory ChildGrowthResponseModel.fromJson(Map<String, dynamic> json) {
    return ChildGrowthResponseModel(
      childName: json['child_name']?.toString() ?? '',
      childGender: json['child_gender']?.toString() ?? 'male',
      currentAgeMonths: toDoubleOrNull(json['current_age_months']) ?? 0.0,
      growthHistory:
          (json['growth_history'] as List?)
              ?.map(
                (e) => GrowthRecordModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      whoStandards:
          (json['who_standards'] as List?)
              ?.map((e) => WhoStandardModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

```

### File: lib\models\growth\growth_record_model.dart
```dart
import '../../core/helper/json_utils.dart';

class GrowthRecordModel {
  final int id;
  final double height;
  final double weight;
  final String date;
  final int ageInMonths; // الباك إند يعيدها كـ double في حقل القياس
  final double bmi;
  final String statusText;
  final String statusColor;

  const GrowthRecordModel({
    required this.id,
    required this.height,
    required this.weight,
    required this.date,
    required this.ageInMonths,
    required this.bmi,
    required this.statusText,
    required this.statusColor,
  });

  factory GrowthRecordModel.fromJson(Map<String, dynamic> json) {
    return GrowthRecordModel(
      id: toIntSafe(json['id']),
      height: toDoubleOrNull(json['height']) ?? 0.0,
      weight: toDoubleOrNull(json['weight']) ?? 0.0,
      date: json['date']?.toString() ?? json['record_date']?.toString() ?? '',

      ageInMonths: toIntSafe(json['age_in_months'] ?? json['age']),
      bmi: toDoubleOrNull(json['bmi']) ?? 0.0,
      statusText: json['status_text']?.toString() ?? 'Normal',
      statusColor: json['status_color']?.toString() ?? '#4CAF50',
    );
  }
}

```

### File: lib\models\growth\who_standard_model.dart
```dart
import '../../core/helper/json_utils.dart';

class WhoStandardModel {
  final int ageInMonths;
  final double whoMinWeight;
  final double whoIdeal;
  final double whoMaxWeight;

  const WhoStandardModel({
    required this.ageInMonths,
    required this.whoMinWeight,
    required this.whoIdeal,
    required this.whoMaxWeight,
  });

  factory WhoStandardModel.fromJson(Map<String, dynamic> json) {
    return WhoStandardModel(
      ageInMonths: toIntSafe(json['age_in_months']),
      whoMinWeight: toDoubleOrNull(json['who_min_weight']) ?? 0.0,
      whoIdeal: toDoubleOrNull(json['who_ideal']) ?? 0.0,
      whoMaxWeight: toDoubleOrNull(json['who_max_weight']) ?? 0.0,
    );
  }
}

```

### File: lib\models\home\appointments_model.dart
```dart
import 'package:get/get.dart'; // ─── استيراد مكتبة Get ضروري لاستخدام .tr ───

class AppointmentsModel {
  final int id;
  final String doctorName;
  final String specialty;
  final String date;
  final String time;
  final String status;
  final String? doctorImage;

  // الحقول الخاصة بالطفل
  final String childName;
  final String? childImage;

  const AppointmentsModel({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.time,
    required this.status,
    this.doctorImage,
    required this.childName,
    this.childImage,
  });

  factory AppointmentsModel.fromJson(Map<String, dynamic> json) {
    // 1. استخراج بيانات الطبيب من الكائن المتداخل (Nested Object)
    final doctor = json['doctor'] as Map<String, dynamic>?;

    // إضافة .tr للقيم الافتراضية
    final doctorName = doctor != null
        ? (doctor['full_name'] ?? 'Unknown Doctor'.tr)
        : (json['doctor_name'] ?? 'Unknown Doctor'.tr);

    final specialty = doctor != null
        ? (doctor['specialty'] ?? doctor['department'] ?? 'General'.tr)
        : (json['specialty'] ?? json['department'] ?? 'General'.tr);

    final doctorImage = doctor != null ? doctor['image'] : json['doctor_image'];

    // 2. استخراج بيانات الطفل من الكائن المتداخل (Nested Object)
    final child = json['child'] as Map<String, dynamic>?;

    // إضافة .tr للقيم الافتراضية
    final childName = child != null
        ? (child['first_name'] ?? 'Unknown Child'.tr)
        : (json['child_name'] ?? 'Unknown Child'.tr);

    final childImage = child != null ? child['image'] : json['child_image'];

    // 🌟 التعديل الجوهري هنا: تحصين الـ ID ضد أخطاء النوع (String vs Int)
    int parsedId = 0;
    if (json['id'] != null) {
      if (json['id'] is int) {
        parsedId = json['id'];
      } else {
        parsedId = int.tryParse(json['id'].toString()) ?? 0;
      }
    }

    return AppointmentsModel(
      id: parsedId, // استخدام الـ ID الآمن
      doctorName: doctorName,
      specialty: specialty,
      date: json['date']?.toString() ?? '', // تحصين التاريخ
      time: json['time']?.toString() ?? '', // تحصين الوقت
      status: json['status']?.toString() ?? 'pending',
      doctorImage: doctorImage?.toString(),
      childName: childName,
      childImage: childImage?.toString(),
    );
  }
}
```

### File: lib\models\home\child_model.dart
```dart
class ChildModel {
  final int id;
  final int parentId;
  final String name;
  final String gender;
  final String birthDate;
  final String? profilePicture;

  ChildModel({
    required this.id,
    required this.parentId,
    required this.name,
    required this.gender,
    required this.birthDate,
    this.profilePicture,
  });

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      parentId: json['parent_id'] is int ? json['parent_id'] : int.tryParse(json['parent_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      // 🌟 حماية حقل الجنس المترجم من الباك إند لمنع الكراش الشهير
      gender: json['gender']?.toString() ?? '',
      birthDate: json['birth_date']?.toString() ?? json['birthDate']?.toString() ?? '',
      profilePicture: json['profile_picture']?.toString(),
    );
  }
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

### File: lib\models\home\notification_history_model.dart
```dart
class NotificationHistoryModel {
  final int id;
  final String title;
  final String body;
  final String? type;
  final String createdAt;

  NotificationHistoryModel({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    required this.createdAt,
  });

  factory NotificationHistoryModel.fromJson(Map<String, dynamic> json) {
    return NotificationHistoryModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
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

// تم إزالة الألوان الثابتة الخاصة بالخلفية والنصوص لأننا سنعتمد على الـ Theme
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
  Future<void> _onNextPressed() async {
    if (selectedChildId == null) return;

    // 1. التحقق مما إذا كان المستخدم قادماً من واجهة الحجز السريع
    final args = Get.arguments as Map<String, dynamic>?;
    final isQuickBook = args?['is_quick_book'] ?? false;

    if (isQuickBook) {
      // 2. البحث عن كائن الطفل (ChildModel) الذي يطابق الـ ID المختار
      // (تأكد أن اسم مصفوفة الأطفال هو children أو استبدلها بالاسم الصحيح في childController)
      final selectedChildModel = childController.children.firstWhereOrNull(
            (c) => c.id == selectedChildId,
      );

      if (selectedChildModel != null) {
        // 3. حقن كائن الطفل كاملاً في متحكم الحجز ليتجاوز شرط الـ Validation
        appointmentController.selectChild(selectedChildModel);

        // 4. استدعاء دالة الحجز
        final bool success = await appointmentController.bookAppointment();

        if (success) {
          final appointmentId = appointmentController.bookedAppointmentId.value!;
          Get.offNamed('/payment-method', arguments: appointmentId);
        } else {
          print('--- فشل الحجز محلياً: يرجى التحقق من بيانات DoctorModel ---');
        }
      }
    } else {
      // المسار الطبيعي
      Get.toNamed('/choose-date-time');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ❌ تم إزالة backgroundColor ليقرأ من النظام (AppThemes)
      appBar: bookingAppBar(subtitle: 'Choose Child'.tr),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                final isLoading = childController.isLoading;
                final children = isLoading
                    ? _fakeChildren
                    : childController.children;

                if (!isLoading && children.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        "You haven't added any children yet.".tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.textTheme.bodyMedium?.color, // ─── نص متكيف ───
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
                        onTap: isLoading ? () {} : () => _onChildTapped(child),
                      );
                    },
                  ),
                );
              }),
            ),
            _buildNextButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton(BuildContext context) {
    final enabled = selectedChildId != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: context.theme.primaryColor, // ─── استخدام اللون الأساسي من السمة ───
            disabledBackgroundColor: context.theme.primaryColor.withValues(alpha: 0.4),
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

    // ─── تكييف الألوان الخلفية للبطاقة المحددة حسب الوضع (ليلي/نهاري) ───
    final Color lightTint = isMale ? _kBoyTint : _kGirlTint;
    final Color darkTint = isMale ? Colors.blue.withValues(alpha: 0.15) : Colors.pinkAccent.withValues(alpha: 0.15);
    final Color tint = context.isDarkMode ? darkTint : lightTint;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          // ─── تكييف خلفية البطاقة ───
          color: isSelected ? tint : context.theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            // ─── تكييف لون الإطار ───
            color: isSelected ? _kSelectedBorder : context.theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected || context.isDarkMode // إخفاء الظل في الوضع الليلي أو عند التحديد
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.textTheme.bodyLarge?.color, // ─── نص متكيف ───
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${child.ageYears} ${'years'.tr}',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textTheme.bodyMedium?.color, // ─── نص متكيف ───
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
        // ─── تكييف خلفية المؤشر ───
        color: selected ? _kSelectedBorder : context.theme.scaffoldBackgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          // ─── تكييف إطار المؤشر ───
          color: selected ? _kSelectedBorder : context.theme.dividerColor,
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
      // ❌ تم إزالة backgroundColor ليقرأ خلفية النظام تلقائياً
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
                        color: context.textTheme.bodyLarge?.color, // ─── نص متكيف ───
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
        return _EmptyHint(text: 'Pick a date to see available times.'.tr);
      }
      if (!isLoadingSlots && times.isEmpty) {
        return _EmptyHint(text: 'No times available for this date.'.tr);
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
              onTap: isLoadingSlots ? () {} : () => controller.selectTime(time),
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
          // ─── خلفية الشريحة متكيفة (اللون الأساسي إذا حُددت، ولون البطاقة إذا لم تُحدد) ───
          color: selected ? context.theme.primaryColor : context.theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            // ─── إطار متكيف ───
            color: selected ? context.theme.primaryColor : context.theme.dividerColor,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            // ─── لون النص متكيف (أبيض إذا حُدد، ولون النص الأساسي إذا لم يُحدد) ───
            color: selected ? Colors.white : context.textTheme.bodyLarge?.color,
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
          // ─── لون نص ثانوي متكيف ───
          style: TextStyle(color: context.textTheme.bodyMedium?.color, fontSize: 13.5),
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
              // ─── اللون الأساسي للزر متكيف ───
              backgroundColor: context.theme.primaryColor,
              disabledBackgroundColor: context.theme.primaryColor.withValues(alpha: 0.4),
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
                : Text(
              'Book Appointment'.tr,
              style: const TextStyle(
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
import '../../models/appointment/doctor_model.dart';
import '../../widgets/booking_app_bar.dart';

// 🌟 المعطيات المزيفة
final _fakeDoctors = List<DoctorModel>.generate(
  5,
  (i) => DoctorModel(
    id: -i - 1,
    firstName: 'Doctor',
    lastName: 'Loading',
    email: '',
    address: '',
    departmentName: 'Loading...',
    isFavorite: false,
  ),
);

class ChooseDoctorView extends StatefulWidget {
  const ChooseDoctorView({super.key});

  @override
  State<ChooseDoctorView> createState() => _ChooseDoctorViewState();
}

class _ChooseDoctorViewState extends State<ChooseDoctorView> {
  final DoctorController doctorController = Get.find<DoctorController>();
  final AppointmentController appointmentController =
      Get.find<AppointmentController>();

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
      // ❌ تم إزالة backgroundColor ليقرأ خلفية النظام تلقائياً
      appBar: bookingAppBar(
        subtitle: '${'Choose Doctor'.tr} - ${specialty.tr}',
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Expanded(child: _buildDoctorList()),
            _buildNextButton(context),
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
              // ─── لون النص متكيف ───
              style: TextStyle(
                color: context.textTheme.bodyMedium?.color,
                fontSize: 14,
              ),
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

  Widget _buildNextButton(BuildContext context) {
    final enabled = selectedDoctorId != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            // ─── استخدام اللون الأساسي من السمة ───
            backgroundColor: context.theme.primaryColor,
            disabledBackgroundColor: context.theme.primaryColor.withValues(
              alpha: 0.4,
            ),
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
          // ─── خلفية البطاقة متكيفة ───
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            // ─── لون الإطار متكيف عند التحديد ───
            color: isSelected ? context.theme.primaryColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              // ─── إخفاء الظل في الوضع الليلي ───
              color: context.isDarkMode
                  ? Colors.transparent
                  : Colors.black.withValues(alpha: isSelected ? 0.06 : 0.04),
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      // ─── نص الاسم متكيف ───
                      color: context.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    (doctor.departmentName != null &&
                            doctor.departmentName!.isNotEmpty)
                        ? doctor.departmentName!.tr
                        : '$specialty ${'Specialist'.tr}',
                    style: TextStyle(
                      fontSize: 12.5,
                      // ─── نص التخصص متكيف ───
                      color: context.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onFavoriteTap,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  // ─── لون أيقونة المفضلة متكيف (أحمر للمفضلة، ورمادي/داكن لغير المفضلة) ───
                  color: isFavorite
                      ? Colors.redAccent
                      : context.theme.dividerColor,
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
      decoration: BoxDecoration(
        // ─── لون خلفية الأفاتار متكيف (شفاف وأزرق ليلاً، باستيل أزرق نهاراً) ───
        color: context.isDarkMode
            ? Colors.blue.withOpacity(0.15)
            : const Color(0xFFE3F2FD),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url!.isNotEmpty
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
    return Center(
      // ─── لون الأيقونة البديلة متكيف ───
      child: Icon(
        Icons.person_rounded,
        color: context.theme.primaryColor,
        size: 30,
      ),
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
        color: selected ? context.theme.primaryColor : Colors.transparent,
        shape: BoxShape.circle,
        // ─── إطار الدائرة متكيف ───
        border: Border.all(
          color: selected
              ? context.theme.primaryColor
              : context.theme.dividerColor,
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

### File: lib\views\appointment\closest_appointments_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../controllers/appointment/appointment_controller.dart';
import '../../controllers/appointment/closest_appointments_controller.dart';
import '../../models/appointment/closest_appointment_model.dart';
import '../../models/appointment/doctor_model.dart';
import '../../widgets/booking_app_bar.dart';

class ClosestAppointmentsView extends GetView<ClosestAppointmentsController> {
  const ClosestAppointmentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: bookingAppBar(subtitle: 'Closest Appointments'.tr),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildDepartmentsSlider(context),
          const SizedBox(height: 16),
          Expanded(child: _buildAppointmentsList()),
        ],
      ),
    );
  }

  Widget _buildDepartmentsSlider(BuildContext context) {
    return Obx(() {
      if (controller.departments.isEmpty && controller.isLoading) {
        return const SizedBox(height: 45, child: Center(child: CircularProgressIndicator()));
      }

      return SizedBox(
        height: 45,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: controller.departments.length,
          itemBuilder: (context, index) {
            final dept = controller.departments[index];
            final isSelected = controller.selectedDepartmentId.value == dept.id;

            return GestureDetector(
              onTap: () => controller.fetchClosestAppointments(dept.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? context.theme.primaryColor : context.theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? context.theme.primaryColor : context.theme.dividerColor,
                  ),
                ),
                child: Text(
                  dept.name.tr,
                  style: TextStyle(
                    color: isSelected ? Colors.white : context.textTheme.bodyLarge?.color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildAppointmentsList() {
    return Obx(() {
      if (controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.closestAppointments.isEmpty) {
        return Center(
          child: Text(
            'No upcoming appointments available for this department.'.tr,
            style: TextStyle(color: Get.context!.textTheme.bodyMedium?.color),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: controller.closestAppointments.length,
        itemBuilder: (context, index) {
          final item = controller.closestAppointments[index];
          return _ClosestAppointmentCard(item: item);
        },
      );
    });
  }
}

class _ClosestAppointmentCard extends StatelessWidget {
  final ClosestAppointmentModel item;

  const _ClosestAppointmentCard({required this.item});

  void _onCardTapped() {
    final aptCtrl = Get.find<AppointmentController>();

    // 1. تمرير مودل وهمي للطبيب يحتوي على الـ ID والاسم الأساسي فقط لأننا لا نحتاج الباقي هنا
    aptCtrl.selectDoctor(DoctorModel(
      id: item.doctorId,
      firstName: item.doctorName,
      lastName: '',
      email: '',
      address: '',
      isFavorite: false,
    ));

    // 2. تحديد التاريخ والوقت تلقائياً
    aptCtrl.selectDate(DateTime.parse(item.date));
    aptCtrl.selectTime(item.time);

    // 3. الانتقال لاختيار الطفل مع تمرير Flag ليخبر الواجهة أن هذا "حجز سريع"
    Get.toNamed('/choose-child', arguments: {'is_quick_book': true});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onCardTapped,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.theme.dividerColor),
          boxShadow: [
            if (!context.isDarkMode)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: context.isDarkMode ? Colors.blue.withValues(alpha: 0.15) : Colors.blue.shade50,
              backgroundImage: item.profilePictureUrl != null ? NetworkImage(item.profilePictureUrl!) : null,
              child: item.profilePictureUrl == null ? Icon(Icons.person, color: context.theme.primaryColor) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.doctorName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 16, color: context.theme.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        '${item.date} (${item.dayName.tr})',
                        style: TextStyle(fontSize: 13, color: context.textTheme.bodyMedium?.color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 16, color: Colors.orange.shade600),
                      const SizedBox(width: 6),
                      Text(
                        item.time,
                        style: TextStyle(fontSize: 13, color: context.textTheme.bodyMedium?.color, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.theme.dividerColor),
          ],
        ),
      ),
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
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:  Icon(Icons.arrow_back_ios, color: context.theme.iconTheme.color),
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
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: context.theme.iconTheme.color),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Image.asset('assets/images/logo.png', height: 120),
              const SizedBox(height: 20),
              Text(
                "Forgot Password?".tr,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Don't worry, enter your phone number and we will send you a verification code."
                    .tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.theme.hintColor),
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
                style: TextStyle(color: context.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: '9639XXXXXXXX',
                  filled: true,
                  fillColor: context.theme.cardColor,
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 30),


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
              Image.asset('assets/images/logo.png', height: 100),
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
            Image.asset('assets/images/logo.png', height: 100),
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
      backgroundColor: context.theme.scaffoldBackgroundColor,
      // 👈 تصحيح الخلفية
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Obx(() {
              final isArabic = settingsController.currentLanguage.value == 'ar';
              return TextButton.icon(
                icon: Icon(
                  Icons.language,
                  size: 20,
                  color: context.theme.primaryColor,
                ), // 👈 تصحيح اللون
                label: Text(
                  isArabic ? 'English' : 'العربية',
                  style: TextStyle(
                    color: context.theme.primaryColor, // 👈 تصحيح اللون
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
                  'assets/images/logo.png',
                  height: size.height * 0.25,
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome Back'.tr,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.textTheme.bodyLarge?.color, // 👈 تصحيح اللون
                  ),
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
                        color: context.theme.hintColor, // 👈 تصحيح اللون
                      ),
                      onPressed: controller.togglePasswordVisibility,
                    ),
                  ),
                ),

                Align(
                  alignment: AlignmentDirectional.topStart,
                  child: TextButton(
                    onPressed: () {
                      Get.toNamed('/forgot-password');
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Forgot Password?'.tr,
                      style: TextStyle(
                        color: context.theme.primaryColor, // 👈 تصحيح اللون
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
                    Expanded(
                      child: Divider(
                        thickness: 1,
                        color: context.theme.dividerColor,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'Or'.tr,
                        style: TextStyle(
                          color: context.theme.hintColor, // 👈 تصحيح اللون
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        thickness: 1,
                        color: context.theme.dividerColor,
                      ),
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
                    text: TextSpan(
                      text: "Have a clinic file? ".tr,
                      style: TextStyle(
                        color: context.theme.hintColor,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: "Activate account".tr,
                          style: TextStyle(
                            color: context.theme.primaryColor, // 👈 تصحيح اللون
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
      backgroundColor: context.theme.scaffoldBackgroundColor,
      // 👈 إزالة الثيم الصلب
      appBar: AppBar(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: context.theme.iconTheme.color,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: Image.asset(
          'assets/images/pediatric_clinic_logo.png',
          height: 38,
          fit: BoxFit.contain,
          // قد تحتاج لاستخدام color ليطابق الوضع الليلي إذا كان الشعار داكناً:
          color: context.isDarkMode ? Colors.white : null,
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
                color: context.textTheme.bodyLarge?.color, // 👈 لون متكيف
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Create your account to benefit from our services'.tr,
              style: TextStyle(fontSize: 13, color: context.theme.hintColor),
              // 👈 لون متكيف
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
                    color: context.theme.hintColor,
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
                style: TextStyle(fontSize: 11, color: context.theme.hintColor),
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
                    color: context.theme.hintColor,
                    size: 20,
                  ),
                  onPressed: controller.toggleConfirmPassword,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Obx(
              () => controller.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: context.theme.primaryColor,
                      ),
                    )
                  : PrimaryButton(
                      text: 'Create Account'.tr,
                      onPressed: controller.signUp,
                    ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: Divider(color: context.theme.dividerColor)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Already have an account?'.tr,
                    style: TextStyle(
                      color: context.theme.hintColor,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: context.theme.dividerColor)),
              ],
            ),
            const SizedBox(height: 16),

            OutlinedPrimaryButton(
              text: 'Login'.tr,
              onPressed: () => Get.back(),
            ),
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

### File: lib\views\growth\child_growth_tab_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/growth/child_growth_controller.dart';
import '../../../core/repos/growth/child_growth_repo.dart';
import '../../widgets/growth/add_growth_sheet.dart';
import '../../widgets/growth/growth_chart_widget.dart';
import '../../widgets/growth/growth_history_list.dart';

class ChildGrowthTabView extends StatelessWidget {
  final int childId;

  const ChildGrowthTabView({super.key, required this.childId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChildGrowthController(repo: ChildGrowthRepo()));

    controller.childId = childId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getGrowthDashboard();
    });

    return Scaffold(
      // ❌ تم إزالة backgroundColor ليقرأ خلفية النظام تلقائياً

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.selectedDate.value = '';
          Get.bottomSheet(const AddGrowthSheet(), isScrollControlled: true);
        },
        // ─── لون الزر العائم متكيف مع السمة ───
        backgroundColor: context.theme.primaryColor,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),

      body: Obx(() {
        // 1. حالة التحميل
        if (controller.isLoading && controller.growthData.value == null) {
          return Center(
            // ─── مؤشر التحميل متكيف ───
            child: CircularProgressIndicator(color: context.theme.primaryColor),
          );
        }

        final data = controller.growthData.value;
        if (data == null) {
          return Center(
            child: Text(
              'Failed to load profile'.tr,
              // ─── نص متكيف ───
              style: TextStyle(color: context.textTheme.bodyMedium?.color),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.getGrowthDashboard(),
          // ─── لون مؤشر التحديث متكيف ───
          color: context.theme.primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //  كروت القياسات العلوية السريعة
                _buildQuickStatsSection(
                  context, // ─── نمرر الـ context لاستخدامه في تكييف الألوان ───
                  data.growthHistory,
                  data.currentAgeMonths,
                ),
                const SizedBox(height: 16),

                // المخطط البياني (قد يحتاج لتعديل داخلي إذا كانت ألوانه ثابتة)
                GrowthChartWidget(data: data),
                const SizedBox(height: 20),

                //   سجلات النمو السفلية
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Growth History'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        // ─── نص متكيف ───
                        color: context.textTheme.bodyLarge?.color,
                      ),
                    ),
                    Icon(
                      Icons.sort_rounded,
                      // ─── أيقونة متكيفة ───
                      color: context.textTheme.bodyMedium?.color,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                //  قائمة القياسات التاريخية (قد تحتاج لتعديل داخلي إذا كانت ألوانها ثابتة)
                GrowthHistoryList(data: data),
                const SizedBox(height: 60),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// اللوحة العلوية للقياسات
  Widget _buildQuickStatsSection(BuildContext context, List<dynamic> history, double rawAge) {
    final latestRecord = history.isNotEmpty ? history.first : null;
    final displayWeight = latestRecord != null
        ? '${latestRecord.weight} ${'kg'.tr}'
        : '--';
    final displayHeight = latestRecord != null
        ? '${latestRecord.height} ${'cm'.tr}'
        : '--';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // ─── لون خلفية البطاقة متكيف ───
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        // ─── إطار البطاقة متكيف ───
        border: Border.all(color: context.theme.dividerColor),
      ),
      child: Row(
        children: [
          // كارت الوزن
          Expanded(
            child: _QuickStatCard(
              icon: Icons.scale_outlined,
              label: 'Current Weight'.tr,
              value: displayWeight,
            ),
          ),
          // ─── خط فاصل متكيف ───
          Container(width: 1, height: 40, color: context.theme.dividerColor),
          // كارت الطول
          Expanded(
            child: _QuickStatCard(
              icon: Icons.straighten_outlined,
              label: 'Current Height'.tr,
              value: displayHeight,
            ),
          ),
          // ─── خط فاصل متكيف ───
          Container(width: 1, height: 40, color: context.theme.dividerColor),
          // كارت العمر
          Expanded(
            child: _QuickStatCard(
              icon: Icons.calendar_month_outlined,
              label: 'Age'.tr,
              value: '${rawAge.toInt()} ${'Months'.tr}',
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _QuickStatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ─── لون الأيقونة متكيف ───
        Icon(icon, color: context.theme.primaryColor, size: 22),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            // ─── نص ثانوي متكيف ───
            color: context.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            // ─── نص أساسي متكيف ───
            color: context.textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }
}

```

### File: lib\views\home\about_app_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AboutAppView extends StatelessWidget {
  const AboutAppView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('About App'.tr),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // شعار التطبيق
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 120,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // عنوان ترحيبي
            Text(
              'Pediatric Clinic Management'.tr,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // الوصف الرئيسي
            _buildSection(
              context,
              title: 'Our Vision'.tr,
              content: 'app_vision_desc'.tr,
              icon: Icons.lightbulb_outline,
            ),

            const SizedBox(height: 20),

            _buildSection(
              context,
              title: 'Our Mission'.tr,
              content: 'app_mission_desc'.tr,
              icon: Icons.track_changes,
            ),

            const SizedBox(height: 20),

            _buildSection(
              context,
              title: 'Key Features'.tr,
              content: 'app_features_desc'.tr,
              icon: Icons.star_border,
            ),

            const SizedBox(height: 40),

            // رقم الإصدار أو الحقوق
            Text(
              'Version 1.0.0'.tr,
              style: TextStyle(color: theme.hintColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required String content, required IconData icon}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.primaryColor, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              height: 1.6,
              fontSize: 14,
            ),
          ),
        ],
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
      // ❌ تم إزالة backgroundColor للـ Scaffold والـ AppBar
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.iconColor, size: 20), // أيقونة متكيفة
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
                onTap: controller.pickImage,
                child: Obx(() => Stack(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: context.theme.scaffoldBackgroundColor, // لون خلفية متكيف
                      backgroundImage: controller.selectedImage.value != null
                          ? FileImage(controller.selectedImage.value!)
                          : null,
                      child: controller.selectedImage.value == null
                          ? Icon(Icons.person,
                          color: context.theme.dividerColor, size: 60)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.theme.primaryColor, // اللون الأساسي من السمة
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
                  color: context.textTheme.bodyLarge?.color, // نص متكيف
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ─── Form Card ────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.theme.cardColor, // كرت متكيف
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
                                    color: context.textTheme.bodyLarge?.color)),
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
                                    color: context.textTheme.bodyLarge?.color)),
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
                          color: context.textTheme.bodyLarge?.color)),
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
                              // لون متكيف بذكاء للوضع الليلي
                              color: controller.selectedGender.value == 'female'
                                  ? (context.isDarkMode ? Colors.pinkAccent.withOpacity(0.15) : const Color(0xFFFCE4EC))
                                  : context.theme.scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: controller.selectedGender.value == 'female'
                                    ? Colors.pinkAccent
                                    : context.theme.dividerColor,
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
                              // لون متكيف بذكاء للوضع الليلي
                              color: controller.selectedGender.value == 'male'
                                  ? (context.isDarkMode ? Colors.blue.withOpacity(0.15) : const Color(0xFFE3F2FD))
                                  : context.theme.scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: controller.selectedGender.value == 'male'
                                    ? Colors.blue
                                    : context.theme.dividerColor,
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
                          color: context.textTheme.bodyLarge?.color)),
                  const SizedBox(height: 8),
                  Obx(() => GestureDetector(
                    onTap: () => controller.pickBirthDate(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 15),
                      decoration: BoxDecoration(
                        color: context.theme.scaffoldBackgroundColor, // لون متكيف
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.theme.dividerColor), // إطار متكيف
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
                                  ? context.textTheme.bodyMedium?.color
                                  : context.textTheme.bodyLarge?.color,
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
                          color: context.textTheme.bodyLarge?.color)),
                  const SizedBox(height: 8),
                  Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: context.theme.scaffoldBackgroundColor, // خلفية متكيفة
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.theme.dividerColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: context.theme.cardColor, // لون القائمة المنسدلة في الوضع الليلي
                        hint: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Icon(Icons.water_drop_outlined,
                                color: Colors.blue, size: 18),
                            const SizedBox(width: 8),
                            Text('Select blood type'.tr,
                                style: TextStyle(
                                    color: context.textTheme.bodyMedium?.color,
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
                              style: TextStyle(color: context.textTheme.bodyLarge?.color), // نص القائمة
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
                          color: context.textTheme.bodyLarge?.color)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller.medicalHistoryController,
                    maxLines: 3,
                    textAlign: TextAlign.left,
                    style: TextStyle(color: context.textTheme.bodyLarge?.color), // لون النص
                    decoration: InputDecoration(
                      hintText: "Enter child's medical history".tr,
                      hintStyle: TextStyle(
                          color: context.textTheme.bodyMedium?.color, fontSize: 13),
                      suffixIcon: const Icon(Icons.calendar_month_outlined,
                          color: Colors.blue),
                      filled: true,
                      fillColor: context.theme.scaffoldBackgroundColor, // لون الخلفية
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: context.theme.dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: context.theme.dividerColor),
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
                          color: context.textTheme.bodyLarge?.color)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller.allergiesController,
                    maxLines: 3,
                    textAlign: TextAlign.left,
                    style: TextStyle(color: context.textTheme.bodyLarge?.color), // لون النص
                    decoration: InputDecoration(
                      hintText: 'Enter any allergies the child has'.tr,
                      hintStyle: TextStyle(
                          color: context.textTheme.bodyMedium?.color, fontSize: 13),
                      suffixIcon: const Icon(Icons.shield_outlined,
                          color: Colors.blue),
                      filled: true,
                      fillColor: context.theme.scaffoldBackgroundColor, // لون الخلفية
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: context.theme.dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: context.theme.dividerColor),
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
    final bool isSingleChild =
        controller.childId != null && controller.childId != 0;

    // ─── إحاطة الواجهة بـ PopScope للتحكم بزر الرجوع في النظام ───
    return PopScope(
      canPop: false, // نمنع الرجوع الافتراضي
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        // ─── توجيه المستخدم للرئيسية عند ضغط زر الهاتف ───
        Get.offAllNamed('/home');
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title: Text(
            isSingleChild ? 'Child Appointments'.tr : 'My Appointments'.tr,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.textTheme.bodyLarge?.color,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: context.iconColor,
              size: 20,
            ),
            onPressed: () {
              // ─── العودة إلى الرئيسية مباشرة من زر الواجهة ───
              Get.offAllNamed('/home');
            },
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 16),

            // ─── Tabs (Slider) ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Obx(
                    () => Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.theme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => controller.switchTab(true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: controller.showUpcoming.value
                                  ? context.theme.primaryColor
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
                                      : context.textTheme.bodyMedium?.color,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Upcoming'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: controller.showUpcoming.value
                                        ? Colors.white
                                        : context.textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => controller.switchTab(false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !controller.showUpcoming.value
                                  ? context.theme.primaryColor
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
                                      : context.textTheme.bodyMedium?.color,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Past'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: !controller.showUpcoming.value
                                        ? Colors.white
                                        : context.textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── List مع ميزة التحديث بالسحب ───
            Expanded(
              child: Obx(() {
                final list = controller.showUpcoming.value
                    ? controller.upcoming
                    : controller.past;

                // نظهر دائرة التحميل فقط إذا كانت القائمة فارغة (لتجنب اختفاء المواعيد عند التحديث اليدوي)
                if (controller.isLoading && list.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  );
                }

                return RefreshIndicator(
                  color: context.theme.primaryColor,
                  onRefresh: () async {
                    if (controller.showUpcoming.value) {
                      await controller.fetchUpcoming();
                    } else {
                      await controller.fetchPast();
                    }
                  },
                  child: list.isEmpty
                      ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.6,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 60,
                            color: context.theme.dividerColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No appointments found'.tr,
                            style: TextStyle(
                              fontSize: 16,
                              color: context.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    // ضروري لعمل السحب
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    itemCount: list.length,
                    separatorBuilder: (_, _) =>
                    const SizedBox(height: 12),
                    itemBuilder: (_, index) => _AppointmentCard(
                      appointment: list[index],
                      isSingleChild: isSingleChild,
                      isUpcoming: controller
                          .showUpcoming
                          .value, // 👈 إرسال حالة التبويب للبطاقة
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Appointment Card ───
class _AppointmentCard extends StatelessWidget {
  final AppointmentsModel appointment;
  final bool isSingleChild;
  final bool isUpcoming; // 👈 متغير لتحديد ظهور زر الإلغاء

  const _AppointmentCard({
    required this.appointment,
    required this.isSingleChild,
    required this.isUpcoming,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.transparent
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isSingleChild
          ? _buildSingleChildLayout(context)
          : _buildAllAppointmentsLayout(context),
    );
  }

  // ─── زر الإلغاء المخصص ───
  Widget _buildCancelButton() {
    final AppointmentsController controller =
    Get.find<AppointmentsController>();
    return IconButton(
      icon: const Icon(Icons.cancel_outlined, color: Colors.red),
      tooltip: 'Cancel Appointment'.tr,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      // لتقليل المساحة المحيطة بالزر
      onPressed: () {
        Get.defaultDialog(
          title: 'Cancel Appointment'.tr,
          middleText:
          'Are you sure you want to cancel this appointment? A refund will be initiated.'
              .tr,
          titleStyle: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
          textConfirm: 'Yes, Cancel'.tr,
          textCancel: 'No'.tr,
          confirmTextColor: Colors.white,
          buttonColor: Colors.red,
          cancelTextColor: Colors.black,
          onConfirm: () {
            Get.back(); // إغلاق نافذة التأكيد
            controller.cancelAppointment(
              appointment.id,
            ); // استدعاء دالة الحذف من الكنترولر
          },
        );
      },
    );
  }

  Widget _buildAllAppointmentsLayout(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: context.isDarkMode
                  ? Colors.blue.withValues(alpha: 0.15)
                  : Colors.blue.shade50,
              backgroundImage:
              appointment.childImage != null &&
                  appointment.childImage!.isNotEmpty
                  ? NetworkImage(appointment.childImage!)
                  : null,
              child:
              appointment.childImage == null ||
                  appointment.childImage!.isEmpty
                  ? Icon(
                Icons.child_care,
                color: Colors.blue.shade300,
                size: 24,
              )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.childName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Patient'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
            _StatusPill(status: appointment.status),
            // 👈 إضافة زر الإلغاء هنا بجانب الحالة مع شرط الإخفاء الإضافي
            if (isUpcoming && appointment.status.toLowerCase() != 'cancelled' && appointment.status.toLowerCase() != 'canceled') ...[
              const SizedBox(width: 8),
              _buildCancelButton()
            ],
          ],
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Divider(
            height: 1,
            thickness: 1,
            color: context.theme.dividerColor,
          ),
        ),

        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? context.theme.scaffoldBackgroundColor
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                image:
                appointment.doctorImage != null &&
                    appointment.doctorImage!.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(appointment.doctorImage!),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child:
              appointment.doctorImage == null ||
                  appointment.doctorImage!.isEmpty
                  ? Icon(Icons.person, color: context.theme.dividerColor)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.doctorName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: context.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    appointment.specialty,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        _buildDateTimeSection(context),
      ],
    );
  }

  Widget _buildSingleChildLayout(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? context.theme.scaffoldBackgroundColor
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
                image:
                appointment.doctorImage != null &&
                    appointment.doctorImage!.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(appointment.doctorImage!),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child:
              appointment.doctorImage == null ||
                  appointment.doctorImage!.isEmpty
                  ? Icon(
                Icons.medical_services_outlined,
                color: Colors.blue.shade400,
                size: 26,
              )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          appointment.doctorName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.textTheme.bodyLarge?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _StatusPill(status: appointment.status),
                          // 👈 إضافة زر الإلغاء هنا بجانب الحالة مع شرط الإخفاء الإضافي
                          if (isUpcoming && appointment.status.toLowerCase() != 'cancelled' && appointment.status.toLowerCase() != 'canceled') ...[
                            const SizedBox(width: 8),
                            _buildCancelButton(),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    appointment.specialty,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDateTimeSection(context),
      ],
    );
  }

  Widget _buildDateTimeSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? context.theme.scaffoldBackgroundColor
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 16,
            color: context.isDarkMode
                ? Colors.blue.shade300
                : Colors.blue.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            appointment.date,
            style: TextStyle(
              fontSize: 13,
              color: context.isDarkMode
                  ? Colors.blue.shade300
                  : Colors.blue.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '|',
              style: TextStyle(color: context.theme.dividerColor),
            ),
          ),
          Icon(
            Icons.access_time_outlined,
            size: 16,
            color: context.isDarkMode
                ? Colors.blue.shade300
                : Colors.blue.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            appointment.time,
            style: TextStyle(
              fontSize: 13,
              color: context.isDarkMode
                  ? Colors.blue.shade300
                  : Colors.blue.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
      case 'success':
        bg = context.isDarkMode
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.green.shade50;
        fg = context.isDarkMode ? Colors.greenAccent : Colors.green.shade600;
        break;
      case 'cancelled':
      case 'canceled':
        bg = context.isDarkMode
            ? Colors.red.withValues(alpha: 0.2)
            : Colors.red.shade50;
        fg = context.isDarkMode ? Colors.redAccent : Colors.red.shade600;
        break;
      case 'pending':
      default:
        bg = context.isDarkMode
            ? Colors.orange.withValues(alpha: 0.2)
            : Colors.orange.shade50;
        fg = context.isDarkMode ? Colors.orangeAccent : Colors.orange.shade700;
        break;
    }

    final label = status.isEmpty
        ? 'Pending'
        : status[0].toUpperCase() + status.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.tr,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
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
import '../growth/child_growth_tab_view.dart';

class ChildProfileView extends GetView<ChildProfileController> {
  const ChildProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final RxBool isGrowthTab = true.obs;

    return Scaffold(
      // ❌ تم إزالة اللون الأبيض الثابت
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Child Profile'.tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textTheme.bodyLarge?.color, // ─── نص متكيف ───
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.iconColor, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: context.theme.primaryColor),
          );
        }

        final child = controller.child.value;
        if (child == null) {
          return Center(
            child: Text(
              'Failed to load profile'.tr,
              style: TextStyle(color: context.textTheme.bodyMedium?.color),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _InfoCard(child: child),
            ),
            const SizedBox(height: 16),

            // Tabs Switcher
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: context.theme.cardColor, // ─── خلفية التابز متكيفة ───
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => isGrowthTab.value = true,
                        child: Obx(
                          () => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isGrowthTab.value
                                  ? Colors.green
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.show_chart_rounded,
                                  color: isGrowthTab.value
                                      ? Colors.white
                                      : Colors.grey,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Growth Chart & Weight'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isGrowthTab.value
                                        ? Colors.white
                                        : context.textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => isGrowthTab.value = false,
                        child: Obx(
                          () => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !isGrowthTab.value
                                  ? context.theme.primaryColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  color: !isGrowthTab.value
                                      ? Colors.white
                                      : Colors.grey,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Appointments & Files'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: !isGrowthTab.value
                                        ? Colors.white
                                        : context.textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: Obx(() {
                if (isGrowthTab.value) {
                  return ChildGrowthTabView(childId: controller.childId);
                } else {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    child: Column(
                      children: [
                        _StatsCard(child: child),
                        const SizedBox(height: 16),
                        if (child.medicalHistory != null &&
                            child.medicalHistory!.isNotEmpty) ...[
                          _DataCard(
                            title: 'Medical History'.tr,
                            content: child.medicalHistory!,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (child.allergies != null &&
                            child.allergies!.isNotEmpty) ...[
                          _DataCard(
                            title: 'Allergies'.tr,
                            content: child.allergies!,
                          ),
                          const SizedBox(height: 16),
                        ],
                        _ActionButton(
                          icon: Icons.vaccines_outlined,
                          label: 'Vaccination Record'.tr,
                          color: context.theme.primaryColor,
                          onTap: () =>
                              Get.toNamed('/vaccinations', arguments: child.id),
                        ),
                        const SizedBox(height: 10),
                        _ActionButton(
                          icon: Icons.calendar_today_outlined,
                          label: 'Appointments'.tr,
                          color: context.theme.primaryColor,
                          onTap: () =>
                              Get.toNamed('/appointments', arguments: child.id),
                        ),
                        const SizedBox(height: 16),
                        // زر الحذف
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: controller.isLoading
                                ? null // تعطيل الزر إذا كان التطبيق في حالة تحميل
                                : () => Get.dialog(
                                    AlertDialog(
                                      backgroundColor: context.theme.cardColor,
                                      title: Text(
                                        'Delete Child'.tr,
                                        style: TextStyle(
                                          color: context
                                              .textTheme
                                              .bodyLarge
                                              ?.color,
                                        ),
                                      ),
                                      content: Text(
                                        'Are you sure you want to delete this child profile? This action cannot be undone.'
                                            .tr,
                                        style: TextStyle(
                                          color: context
                                              .textTheme
                                              .bodyMedium
                                              ?.color,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Get.back(),
                                          child: Text('Cancel'.tr),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Get.back(); // إغلاق الـ Dialog
                                            controller
                                                .deleteCurrentChild(); // تنفيذ دالة الحذف المعدلة
                                          },
                                          child: Text(
                                            'Delete'.tr,
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                            icon: controller.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.delete_outline,
                                    color: Colors.white,
                                  ),
                            label: Text(
                              controller.isLoading
                                  ? 'Deleting...'.tr
                                  : 'Delete Child Profile'.tr,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: controller.isLoading
                                  ? Colors.grey
                                  : Colors.red.shade400,
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
                }
              }),
            ),
          ],
        );
      }),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final ChildModel child;

  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // ─── لون الخلفية متكيف (أخضر خفيف جداً ليلاً ونهاراً) ───
        color: context.isDarkMode
            ? Colors.green.withOpacity(0.15)
            : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: context.theme.scaffoldBackgroundColor,
            backgroundImage: (child.image != null && child.image!.isNotEmpty)
                ? NetworkImage(child.image!)
                : null,
            child: (child.image == null || child.image!.isEmpty)
                ? Icon(
                    Icons.person,
                    color: context.theme.dividerColor,
                    size: 55,
                  )
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.fullName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: context.textTheme.bodyLarge?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '${child.ageYears} ${'years'.tr}',
                  style: TextStyle(
                    fontSize: 16,
                    color: context.textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      child.gender.toLowerCase() == 'female'
                          ? Icons.female
                          : Icons.male,
                      color: Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      child.gender.capitalizeFirst ?? '',
                      style: const TextStyle(fontSize: 16, color: Colors.green),
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

class _StatsCard extends StatelessWidget {
  final ChildModel child;

  const _StatsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.transparent
                : Colors.black.withOpacity(0.04),
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
              icon: child.gender.toLowerCase() == 'female'
                  ? Icons.female
                  : Icons.male,
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

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 60, color: context.theme.dividerColor);
  }
}

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
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.transparent
                : Colors.black.withOpacity(0.04),
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: context.textTheme.bodyMedium?.color,
                height: 1.5,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

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
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: context.isDarkMode
                  ? Colors.transparent
                  : Colors.black.withOpacity(0.04),
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.chevron_right,
              color: context.textTheme.bodyLarge?.color,
              size: 22,
            ),
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
import 'package:kidcare/views/home/about_app_view.dart';
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
      'route': '/choose-doctor',
      'specialty': 'General Pediatrics',
      'departmentId': 1,
    },
    {
      'label': 'Dental Care',
      'icon': Icons.medical_information_outlined,
      'color': Color(0xFFE3F2FD),
      'iconColor': Color(0xFF1E88E5),
      'route': '/choose-doctor',
      'specialty': 'Dental Care',
      'departmentId': 2,
    },
    {
      'label': 'Psychiatry',
      'icon': Icons.psychology_outlined,
      'color': Color(0xFFFCE4EC),
      'iconColor': Color(0xFFE91E63),
      'route': '/choose-doctor',
      'specialty': 'Psychiatry',
      'departmentId': 3,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // ❌ تم حذف backgroundColor من الـ Scaffold ليأخذ لون السمة تلقائياً
    return Scaffold(
      bottomNavigationBar: const _BottomNav(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeaderSection(),
              const SizedBox(height: 24),

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
                              size: 48, color: context.theme.dividerColor), // لون أيقونة فارغ متكيف
                          const SizedBox(height: 8),
                          Text(
                            'No children added yet'.tr,
                            style: TextStyle(color: context.textTheme.bodyMedium?.color), // نص متكيف
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
              const _DepartmentsSection(departments: _departments),
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
        Expanded(
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Get.toNamed('/profile'),
                child: CircleAvatar(
                  radius: 26,
                  // لون خلفية ذكي بناءً على الوضع
                  backgroundColor: context.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                  child: Icon(Icons.person,
                      color: context.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500, size: 28),
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
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: context.textTheme.bodyLarge?.color, // نص متكيف
                    ),
                  )),
                  Text(
                    'Welcome back!'.tr,
                    style: TextStyle(
                        fontSize: 13, color: context.textTheme.bodyMedium?.color), // نص ثانوي متكيف
                  ),
                ],
              ),
            ],
          ),
        ),
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_outlined, color: Color(0xFF1A2E5A)),
              onPressed: () => Get.toNamed('/notifications-history'), // 🌟 التوجيه للشاشة التاريخية
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
          // استخدام لون داكن للبطاقة في الوضع الليلي ليناسب اللون الأخضر
          color: context.isDarkMode ? const Color(0xFF1E3A2F) : const Color(0xFFD6F5D6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: context.theme.scaffoldBackgroundColor, // خلفية متكيفة للصورة
                  backgroundImage: (child.image != null &&
                      child.image!.isNotEmpty)
                      ? NetworkImage(child.image!)
                      : null,
                  child: (child.image == null || child.image!.isEmpty)
                      ? Icon(Icons.person,
                      color: context.theme.dividerColor, size: 40)
                      : null,
                ),
              ),
            ),
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    child.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textTheme.bodyLarge?.color, // نص متكيف
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${child.age} ${'years'.tr}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textTheme.bodyMedium?.color, // نص متكيف
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
        onPressed: ()=> Get.toNamed('/closest-appointments'),
        icon: const Icon(Icons.add_circle_outline,
            color: Colors.white, size: 22),
        label: Text(
          'Book New Appointment'.tr,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: context.theme.primaryColor, // استخدام اللون الأساسي للسمة
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

// ─── Departments ──────────────────────────────────────────────────────────────

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
            color: context.textTheme.bodyLarge?.color, // نص متكيف
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
              // لون البطاقة يتكيف مع الوضع الليلي
              color: context.isDarkMode ? context.theme.cardColor : const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: context.isDarkMode ? Colors.transparent : Colors.blue.shade100),
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
            style: TextStyle(fontSize: 12, color: context.textTheme.bodyLarge?.color), // نص متكيف
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
        color: context.isDarkMode ? context.theme.cardColor : const Color(0xFFF0F4FF), // لون متكيف
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: context.isDarkMode ? Colors.blue.withValues(alpha: 0.1) : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.local_hospital_outlined,
                color: Colors.blue.shade300, size: 48),
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
                    color: context.textTheme.bodyLarge?.color, // متكيف
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We provide comprehensive healthcare for your children with the highest quality standards.'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textTheme.bodyMedium?.color, // متكيف
                    height: 1.5,
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Get.to(()=>const AboutAppView());
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Read More'.tr,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: context.theme.primaryColor, size: 18),
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

// ─── Bottom Navigation ───────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.bottomNavigationBarTheme.backgroundColor, // لون الـ BottomNav من السمة
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            // إخفاء الظل في الوضع الليلي
            color: context.isDarkMode ? Colors.transparent : Colors.black.withValues(alpha: 0.08),
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
              _NavItem(icon: Icons.home_rounded, label: 'Home'.tr, isSelected: true, onTap: () {}),
              _NavItem(icon: Icons.calendar_month_outlined, label: 'Appointments'.tr, isSelected: false, onTap: () => Get.toNamed('/appointments')),

              // زر الوسط
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
                        color: context.isDarkMode ? Colors.transparent : const Color(0xFF3B9EFF).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),

              _NavItem(icon: Icons.vaccines_outlined, label: 'Vaccinations'.tr, isSelected: false, onTap: () => Get.toNamed('/vaccinations')),
              _NavItem(icon: Icons.more_horiz, label: 'More'.tr, isSelected: false, onTap: () => Get.toNamed('/settings')),
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

  const _NavItem({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // الألوان المتكيفة للـ BottomNav
    final selectedColor = context.theme.bottomNavigationBarTheme.selectedItemColor;
    final unselectedColor = context.theme.bottomNavigationBarTheme.unselectedItemColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor?.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? selectedColor : unselectedColor, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? selectedColor : unselectedColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### File: lib\views\home\notification_history_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/home/notification_history_controller.dart';
import '../../models/home/notification_history_model.dart';

class NotificationHistoryView extends GetView<NotificationHistoryController> {
  const NotificationHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'.tr),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.theme.iconTheme.color, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: context.theme.primaryColor),
          );
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: Text(
              'No notifications found'.tr,
              style: TextStyle(color: context.textTheme.bodyMedium?.color),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.notifications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final notification = controller.notifications[index];
            return _buildNotificationCard(context, notification);
          },
        );
      }),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationHistoryModel item) {
    // معالجة وتنسيق التاريخ
    String formattedDate = item.createdAt;
    try {
      final DateTime parsedDate = DateTime.parse(item.createdAt).toLocal();
      formattedDate = DateFormat('dd MMM yyyy, hh:mm a', Get.locale?.languageCode).format(parsedDate);
    } catch (_) {}

    return InkWell(
      onTap: () => _handleNotificationTap(item.type),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.theme.dividerColor.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.theme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_active_outlined,
                color: context.theme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: context.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textTheme.bodyMedium?.color,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.theme.hintColor,
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

  // التوجيه الذكي بناءً على نوع الإشعار
  void _handleNotificationTap(String? type) {
    if (type == null) return;
    switch (type) {
      case 'appointment_accepted':
      case 'appointment_rejected':
      case 'appointment_reminder':
        Get.toNamed('/appointments');
        break;
      case 'chat':
      // Get.toNamed('/chat'); // مسار المحادثة مستقبلاً
        break;
      default:
        break;
    }
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

  //  دالة مساعدة لظهور نافذة التعديل المنبثقة
  void _showEditDialog(BuildContext context, String title, String key, String currentValue) {
    final TextEditingController textController = TextEditingController(text: currentValue);

    Get.dialog(
      AlertDialog(
        backgroundColor: context.theme.cardColor,
        title: Text(
          'Edit $title'.tr,
          style: TextStyle(color: context.textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: textController,
          style: TextStyle(color: context.textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            hintText: 'Enter new $title'.tr,
            hintStyle: TextStyle(color: context.theme.hintColor),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: context.theme.dividerColor),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: context.theme.primaryColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'.tr, style: TextStyle(color: context.textTheme.bodyMedium?.color)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // استدعاء دالة التحديث في الـ Controller وإرسال المفتاح والقيمة الجديدة
              controller.updateProfileField(key, textController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.theme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Save'.tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Personal Profile'.tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textTheme.bodyLarge?.color,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.iconColor, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: context.theme.primaryColor),
          );
        }

        if (controller.profile.value == null) {
          return Center(
            child: Text(
              'Failed to load profile'.tr,
              style: TextStyle(color: context.textTheme.bodyMedium?.color),
            ),
          );
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
                  backgroundColor: context.isDarkMode ? Colors.green.withValues(alpha: 0.15) : const Color(0xFFE8F5E9),
                  child: Icon(Icons.person,
                      color: context.isDarkMode ? Colors.greenAccent : const Color(0xFF4CAF50).withValues(alpha: 0.6),
                      size: 60),
                ),
              ),
              const SizedBox(height: 16),

              // ─── Full Name
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  profile.fullName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              //  Info Items
              _ProfileItem(
                icon: Icons.email_outlined,
                label: 'Email'.tr,
                value: profile.email,
                onEdit: () => _showEditDialog(context, 'Email', 'email', profile.email),
              ),
              const SizedBox(height: 12),

              _ProfileItem(
                icon: Icons.phone_outlined,
                label: 'Phone Number'.tr,
                value: profile.phoneNumber,
                // تمرير المفتاح phone_number كما هو مطلوب في الـ API
                onEdit: () => _showEditDialog(context, 'Phone Number', 'phone_number', profile.phoneNumber),
              ),
              const SizedBox(height: 12),

              _ProfileItem(
                icon: Icons.location_on_outlined,
                label: 'Address'.tr,
                value: profile.address,
                onEdit: () => _showEditDialog(context, 'Address', 'address', profile.address),
              ),
              const SizedBox(height: 12),

              // إزالة زر التعديل بتمرير null إلى onEdit
              _ProfileItem(
                icon: Icons.group_outlined,
                label: 'Number of Children'.tr,
                value: profile.childrenCount.toString(),
                onEdit: null,
              ),
              const SizedBox(height: 28),

              //  Logout Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: controller.logout,
                  icon: Icon(
                    Icons.logout,
                    color: context.isDarkMode ? Colors.redAccent : const Color(0xFF1A2E5A),
                  ),
                  label: Text(
                    'Logout'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.isDarkMode ? Colors.redAccent : const Color(0xFF1A2E5A),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.isDarkMode ? Colors.red.withValues(alpha: 0.1) : const Color(0xFFE8EAF6),
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

// ─── Profile Item

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onEdit; // أصبح اختيارياً بقبول القيمة null

  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.value,
    this.onEdit, // إزالة required
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode ? Colors.transparent : Colors.black.withValues(alpha: 0.04),
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
              color: context.isDarkMode ? Colors.green.withValues(alpha: 0.15) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: context.isDarkMode ? Colors.greenAccent : const Color(0xFF4CAF50), size: 22),
          ),
          const SizedBox(width: 12),

          // ─── Label & Value
          Expanded( // استخدام Expanded لمنع مشاكل المساحات في الشاشات الصغيرة
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),

          // ─── Edit icon
          // لن يظهر الأيقونة إلا إذا كان onEdit يحتوي على دالة
          if (onEdit != null)
            GestureDetector(
              onTap: onEdit,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0), // إعطاء مساحة نقر أفضل
                child: Icon(
                    Icons.edit_outlined,
                    color: context.isDarkMode ? Colors.blue.shade300 : Colors.blue,
                    size: 20
                ),
              ),
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
      appBar: AppBar(
        title: Text(
          'Review & Pay'.tr,
          style: TextStyle(
            color: context.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        iconTheme: IconThemeData(color: context.iconColor),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isDetailsLoading.value) {
          return Center(child: CircularProgressIndicator(color: context.theme.primaryColor));
        }

        final summary = controller.appointmentSummary.value;
        if (summary == null) {
          return Center(
            child: Text(
              "Failed to load appointment data.".tr,
              style: TextStyle(color: context.textTheme.bodyMedium?.color),
            ),
          );
        }

        // ─── تم إعادة الهيكلة هنا لحل مشكلة الـ Overflow ───
        return Column(
          children: [
            // 1. الجزء القابل للتمرير (المحتوى)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // كارت تفاصيل الموعد
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? context.theme.cardColor : const Color(0xFFEDF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: context.isDarkMode ? Border.all(color: context.theme.dividerColor) : null,
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: context.isDarkMode ? Colors.purple.withOpacity(0.15) : Colors.purple.shade100,
                                backgroundImage: summary.patientImageUrl.isNotEmpty
                                    ? NetworkImage(summary.patientImageUrl)
                                    : null,
                                child: summary.patientImageUrl.isEmpty
                                    ? Icon(
                                  Icons.person,
                                  color: context.isDarkMode ? Colors.purpleAccent : Colors.purple.shade700,
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
                                      summary.patientName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: context.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      summary.patientAge,
                                      style: TextStyle(
                                        color: context.textTheme.bodyMedium?.color,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: context.isDarkMode ? Colors.blue.withOpacity(0.15) : Colors.blue.shade100,
                                          child: Icon(
                                            Icons.medical_services,
                                            size: 14,
                                            color: context.isDarkMode ? Colors.blueAccent : Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${summary.doctorName} - ${summary.departmentName}',
                                            style: TextStyle(
                                              color: context.textTheme.bodyLarge?.color,
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
                          Divider(
                            height: 30,
                            color: context.theme.dividerColor,
                            thickness: 1,
                          ),
                          PaymentSummaryRow(
                            label: 'Date & Time'.tr,
                            value: summary.dateTime,
                          ),
                          const SizedBox(height: 12),
                          PaymentSummaryRow(
                            label: 'Consultation Fee'.tr,
                            value: '${summary.price} ${summary.currency}',
                          ),
                          Divider(
                            height: 30,
                            color: context.theme.dividerColor,
                            thickness: 1,
                          ),
                          PaymentSummaryRow(
                            label: 'Total'.tr,
                            value: '${summary.price} ${summary.currency}',
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
                        color: context.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // طرق الدفع
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
                  ],
                ),
              ),
            ),

            // 2. الجزء السفلي الثابت (زر الدفع)
            SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                decoration: BoxDecoration(
                  color: context.theme.scaffoldBackgroundColor,
                  boxShadow: [
                    if (!context.isDarkMode)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      )
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.theme.primaryColor,
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
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
```

### File: lib\views\settings\favorite_doctors_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/appointment/appointment_controller.dart';
import '../../controllers/appointment/doctor_controller.dart';
import '../../models/appointment/doctor_model.dart';

class FavoriteDoctorsView extends StatefulWidget {
  const FavoriteDoctorsView({super.key});

  @override
  State<FavoriteDoctorsView> createState() => _FavoriteDoctorsViewState();
}

class _FavoriteDoctorsViewState extends State<FavoriteDoctorsView> {
  final DoctorController controller = Get.find<DoctorController>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadFavoriteDoctorIds();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Favorite Doctors'.tr,
          style: TextStyle(
            color: context.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: context.theme.iconTheme.color,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        // 1. حالة التحميل
        if (controller.isLoading && controller.favoriteDoctors.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: context.theme.primaryColor),
          );
        }

        // 2. حالة القائمة الفارغة
        if (controller.favoriteDoctors.isEmpty) {
          return Center(
            child: Text(
              'No favorite doctors found'.tr,
              style: TextStyle(color: context.theme.hintColor, fontSize: 15),
            ),
          );
        }

        // 3. عرض البيانات
        return RefreshIndicator(
          onRefresh: () => controller.loadFavoriteDoctorIds(),
          color: context.theme.primaryColor,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: controller.favoriteDoctors.length,
            itemBuilder: (context, index) {
              final doctor = controller.favoriteDoctors[index];
              return _buildFavoriteCard(context, doctor);
            },
          ),
        );
      }),
    );
  }

  Widget _buildFavoriteCard(BuildContext context, DoctorModel doctor) {
    final String specialtyText =
        (doctor.department != null && doctor.department!.isNotEmpty)
        ? '${doctor.department!.tr} ${'Specialist'.tr}'
        : 'Specialist'.tr;

    return GestureDetector(
      onTap: () {
        final appointmentController = Get.find<AppointmentController>();
        appointmentController.selectDoctor(doctor);
        Get.toNamed('/choose-child');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.theme.dividerColor.withOpacity(0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: context.isDarkMode
                  ? Colors.transparent
                  : Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: context.isDarkMode
                  ? Colors.blue.withOpacity(0.15)
                  : Colors.blue.shade50,
              backgroundImage:
                  doctor.profilePicture != null &&
                      doctor.profilePicture!.isNotEmpty
                  ? NetworkImage(doctor.profilePicture!)
                  : null,
              child:
                  doctor.profilePicture == null ||
                      doctor.profilePicture!.isEmpty
                  ? Icon(Icons.person, color: context.theme.primaryColor)
                  : null,
            ),
            const SizedBox(width: 16),
            // بيانات الطبيب
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.fullName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    specialtyText,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textTheme.bodyMedium?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => controller.toggleFavorite(doctor.id),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.favorite, color: Colors.redAccent, size: 26),
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
      // ❌ تم إزالة backgroundColor ليقرأ خلفية النظام التلقائية (بيضاء/داكنة)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'settings'.tr,
          style: TextStyle(
            color: context.textTheme.bodyLarge?.color, // ─── لون النص متكيف ───
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.iconColor),
          // ─── أيقونة متكيفة ───
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
                Obx(
                  () => SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'theme'.tr,
                    subtitle: controller.isDarkMode.value
                        ? 'Dark Mode'
                        : 'Light Mode',
                    onTap: () {
                      controller.toggleTheme();
                    },
                  ),
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
                  subtitle: 'Permanently delete your account from the app'.tr,
                  isLogout: true,
                  showDivider: false,
                  onTap: () => controller.deleteAccount(),
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
        decoration: BoxDecoration(
          // ─── لون خلفية النافذة المنبثقة متكيف ───
          color: context.theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'change_language'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                // ─── لون العنوان متكيف ───
                color: context.textTheme.bodyLarge?.color,
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
                      title: Text(
                        'English',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          // ─── لون الخيار متكيف ───
                          color: context.textTheme.bodyLarge?.color,
                        ),
                      ),
                      value: 'en',
                      activeColor: context
                          .theme
                          .primaryColor, // ─── لون التحديد متكيف ───
                    ),
                    RadioListTile<String>(
                      title: Text(
                        'العربية',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: context.textTheme.bodyLarge?.color,
                        ),
                      ),
                      value: 'ar',
                      activeColor: context.theme.primaryColor,
                    ),
                    RadioListTile<String>(
                      title: Text(
                        'System Default (لغة النظام)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: context.textTheme.bodyLarge?.color,
                        ),
                      ),
                      value: 'system',
                      activeColor: context.theme.primaryColor,
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

PreferredSizeWidget bookingAppBar({required String subtitle}) {
  return AppBar(
    // 1. استخدام context هنا يتطلب تعديل طفيف لنجعله دالة تأخذ context
    // ولكن بما أن الـ AppBar دالة خارجية، سنستخدم Get.context
    backgroundColor: Get.theme.scaffoldBackgroundColor,
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
            // 2. استخدام لون البطاقة المتكيف بدلاً من الأبيض الثابت
            color: Get.theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (!Get.isDarkMode) // إخفاء الظل في الوضع الليلي
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Icon(
            Icons.chevron_left_rounded,
            // 3. لون أيقونة الرجوع متكيف
            color: Get.textTheme.bodyLarge?.color,
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
            // 4. ألوان النصوص متكيفة
            color: Get.textTheme.bodyLarge?.color,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            color: Get.textTheme.bodyMedium?.color,
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
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
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
    if (target.year == _currentMonth.year && target.month == _currentMonth.month) return;
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
        // ─── خلفية متكيفة ───
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          if (!context.isDarkMode) // إخفاء الظل ليلاً
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildWeekdayLabels(context),
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
                return SlideTransition(position: slide, child: FadeTransition(opacity: animation, child: child));
              },
              child: KeyedSubtree(
                key: ValueKey('${_currentMonth.year}-${_currentMonth.month}'),
                child: _buildGrid(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    final onCurrentMonth = _currentMonth.year == now.year && _currentMonth.month == now.month;

    return Row(
      children: [
        _NavButton(icon: Icons.chevron_left_rounded, onTap: _prev),
        Expanded(
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_monthNames[_currentMonth.month - 1].tr} ${_currentMonth.year}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: context.textTheme.bodyLarge?.color, // ─── نص متكيف ───
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
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

  Widget _buildWeekdayLabels(BuildContext context) {
    return Row(
      children: _weekdayLabels.map((l) => Expanded(
        child: Center(
          child: Text(
            l.tr,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: context.textTheme.bodyMedium?.color, // ─── نص متكيف ───
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final firstOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final firstWeekday = firstOfMonth.weekday % 7;
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final today = DateTime.now();
    final minNormalized = DateTime(widget.minDate.year, widget.minDate.month, widget.minDate.day);

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
              final date = DateTime(_currentMonth.year, _currentMonth.month, day);
              final isSelected = widget.selectedDate != null && _sameDay(date, widget.selectedDate!);
              final isToday = _sameDay(date, today);
              final isPast = date.isBefore(minNormalized);
              final isUnavailable = !isPast && widget.workingWeekdays.isNotEmpty && !widget.workingWeekdays.contains(date.weekday);

              return Expanded(
                child: _DayCell(
                  day: day,
                  isSelected: isSelected,
                  isToday: isToday,
                  isPast: isPast,
                  isUnavailable: isUnavailable,
                  onTap: (isPast || isUnavailable) ? null : () => widget.onDateSelected(date),
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

  const _DayCell({required this.day, required this.isSelected, required this.isToday, required this.isPast, required this.isUnavailable, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // الألوان هنا أصبحت تستخدم السمات مباشرة
    final Color primary = context.theme.primaryColor;
    final Color textColor = isSelected ? Colors.white : (isPast || isUnavailable) ? context.theme.dividerColor : context.textTheme.bodyLarge!.color!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 44,
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text('$day', style: TextStyle(fontSize: 14, fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500, color: textColor)),
            if (isUnavailable && !isSelected)
              Positioned(bottom: 7, child: Container(width: 14, height: 2.5, decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(2)))),
            if (isToday && !isSelected)
              Positioned(bottom: 7, child: Container(width: 4, height: 4, decoration: BoxDecoration(color: primary, shape: BoxShape.circle))),
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
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: context.theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(10)),
        alignment: Alignment.center,
        child: Icon(icon, color: context.textTheme.bodyLarge?.color, size: 22),
      ),
    );
  }
}

class _TodayPill extends StatelessWidget {
  final VoidCallback onTap;
  const _TodayPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: context.theme.primaryColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
        child: Text('Today'.tr, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: context.theme.primaryColor)),
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

    // ─── استخراج الثيم المحلي بدلاً من الجلوبال ───
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      textAlign: isRtl ? TextAlign.right : TextAlign.left,
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,

      // ─── ضبط لون النص المكتوب ───
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          // ─── ضبط لون التلميح (Hint) ───
          color: theme.textTheme.bodyMedium?.color ?? theme.hintColor,
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
                  // ─── ضبط لون أيقونة الـ Label ───
                  color: theme.iconTheme.color,
                  size: 20,
                ),
                const SizedBox(width: 8),
              ],

              Text(
                label!,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  // ─── ضبط لون نص الـ Label ───
                  color: theme.textTheme.bodyLarge?.color,
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
        // ─── قراءة لون الخلفية من الثيم المحلي ───
        fillColor: theme.scaffoldBackgroundColor,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            // ─── ضبط لون الإطار الطبيعي ───
            color: theme.dividerColor,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            // ─── ضبط لون الإطار المفعل ───
            color: theme.dividerColor,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            // ─── ضبط لون الإطار عند التركيز (Focus) ───
            color: theme.primaryColor,
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
          // ─── استخدام اللون الأساسي من الثيم المحلي ───
          backgroundColor: Theme.of(context).primaryColor,
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
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          // ─── استخدام اللون الأساسي من الثيم المحلي ───
          foregroundColor: theme.primaryColor,
          side: BorderSide(color: theme.primaryColor),
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
    final theme = Theme.of(context);

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        // ─── قراءة لون الصندوق المتكيف من الثيم المحلي ───
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          // ─── استخدام ألوان الثيم المحلي لتبديل الإطار عند التركيز ───
          color: isFocused ? theme.primaryColor : theme.dividerColor,
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
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          // ─── لون الرقم المدخل يتكيف مع الثيم المحلي ───
          color: theme.textTheme.bodyLarge?.color,
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

### File: lib\widgets\growth\add_growth_sheet.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/growth/child_growth_controller.dart';

class AddGrowthSheet extends StatelessWidget {
  const AddGrowthSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChildGrowthController>();

    return Container(
      decoration: BoxDecoration(
        // ─── خلفية متكيفة للوضع الليلي والنهاري ───
        color: context.theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 45,
                height: 4,
                decoration: BoxDecoration(
                  color: context.theme.dividerColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Add Measurement'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                // ─── لون العنوان متكيف ───
                color: context.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 20),

            // حقول الإدخال
            _buildInputField(
              label: 'Weight (kg)'.tr,
              controller: controller.weightController,
              icon: Icons.scale_outlined,
              context: context,
            ),
            const SizedBox(height: 16),

            _buildInputField(
              label: 'Height (cm)'.tr,
              controller: controller.heightController,
              icon: Icons.straighten_outlined,
              context: context,
            ),
            const SizedBox(height: 16),

            // اختيار التاريخ
            Text(
              'Record Date'.tr,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 8),
            Obx(
                  () => GestureDetector(
                onTap: () => controller.pickRecordDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.theme.dividerColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        controller.selectedDate.value.isEmpty
                            ? 'YYYY-MM-DD'
                            : controller.selectedDate.value,
                        style: TextStyle(
                          color: controller.selectedDate.value.isEmpty
                              ? context.theme.hintColor
                              : context.textTheme.bodyLarge?.color,
                          fontSize: 14,
                        ),
                      ),
                      Icon(Icons.calendar_month_outlined, color: context.theme.hintColor, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // زر الحفظ
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => controller.addMeasurement(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  'Save Measurement'.tr,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// مساعد لبناء حقول الإدخال بشكل متناسق ومتكيف
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required BuildContext context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textTheme.bodyMedium?.color)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: context.textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            hintText: '0.0',
            hintStyle: TextStyle(color: context.theme.hintColor),
            prefixIcon: Icon(icon, size: 20, color: context.theme.primaryColor),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.theme.primaryColor),
            ),
          ),
        ),
      ],
    );
  }
}

```

### File: lib\widgets\growth\growth_chart_widget.dart
```dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import '../../../models/growth/child_growth_response_model.dart';
import '../../../models/growth/growth_record_model.dart';
import 'dart:math' as math;

class GrowthChartWidget extends StatelessWidget {
  final ChildGrowthResponseModel data;

  const GrowthChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isRtl = Get.locale?.languageCode == 'ar';

    return Container(
      height: 320,
      padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
      decoration: BoxDecoration(
        // ─── لون خلفية البطاقة متكيف ───
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        // ─── لون إطار البطاقة متكيف ───
        border: Border.all(color: context.theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLegend(context),
          const SizedBox(height: 16),
          Expanded(child: LineChart(_buildChartData(context, isRtl))),
        ],
      ),
    );
  }

  /// الألوان والخطوط أعلى المخطط (Legend)
  Widget _buildLegend(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _LegendItem(
            color: Colors.blue,
            label: '${'weight'.tr} ${data.childName}',
            isDot: false,
          ),
          const SizedBox(width: 12),
          _LegendItem(
            color: Colors.green,
            label: 'Ideal Weight (WHO)'.tr,
            isDot: true,
          ),
          const SizedBox(width: 12),
          _LegendItem(
            color: Colors.redAccent,
            label: 'Max Limit (WHO)'.tr,
            isDot: true,
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData(BuildContext context, bool isRtl) {
    // 1. خط منظمة الصحة العالمية (المثالي)
    final List<FlSpot> idealSpots = data.whoStandards
        .map((e) => FlSpot(e.ageInMonths.toDouble(), e.whoIdeal))
        .toList();

    // 2. خط منظمة الصحة العالمية (الأقصى)
    final List<FlSpot> maxSpots = data.whoStandards
        .map((e) => FlSpot(e.ageInMonths.toDouble(), e.whoMaxWeight))
        .toList();

    // 3. خط منظمة الصحة العالمية (الأدنى)
    final List<FlSpot> minSpots = data.whoStandards
        .map((e) => FlSpot(e.ageInMonths.toDouble(), e.whoMinWeight))
        .toList();

    // 4. خط نمو الطفل الفعلي
    final List<GrowthRecordModel> sortedHistory = List.from(data.growthHistory)
      ..sort((a, b) => a.ageInMonths.compareTo(b.ageInMonths));

    final List<FlSpot> childSpots = sortedHistory
        .map((e) => FlSpot(e.ageInMonths.toDouble(), e.weight))
        .toList();

    final double maxAgeInData = sortedHistory.isNotEmpty
        ? sortedHistory.last.ageInMonths.toDouble()
        : 0;
    final double maxWeightInData = sortedHistory.isNotEmpty
        ? sortedHistory.map((e) => e.weight).reduce(math.max)
        : 0;

    final double calculatedMaxX = math.max(36.0, maxAgeInData + 2);
    final double calculatedMaxY = math.max(20.0, maxWeightInData + 5);

    return LineChartData(
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 5,
        verticalInterval: 6,
        // ─── ألوان خطوط الشبكة الأفقية والعمودية متكيفة ───
        getDrawingHorizontalLine: (value) =>
            FlLine(color: context.theme.dividerColor, strokeWidth: 1),
        getDrawingVerticalLine: (value) =>
            FlLine(color: context.theme.dividerColor, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          axisNameWidget: Text(
            'Age (Months)'.tr,
            style: TextStyle(
              fontSize: 11,
              // ─── لون عناوين المحاور متكيف ───
              color: context.textTheme.bodyMedium?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          axisNameSize: 20,
          sideTitles: SideTitles(
            showTitles: true,
            interval: 6,
            getTitlesWidget: (value, meta) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                value.toInt().toString(),
                // ─── أرقام المحاور متكيفة ───
                style: TextStyle(color: context.textTheme.bodyMedium?.color, fontSize: 11),
              ),
            ),
          ),
        ),
        leftTitles: AxisTitles(
          axisNameWidget: Text(
            'Weight (kg)'.tr,
            style: TextStyle(
              fontSize: 11,
              // ─── لون عناوين المحاور متكيف ───
              color: context.textTheme.bodyMedium?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          axisNameSize: 20,
          sideTitles: SideTitles(
            showTitles: true,
            interval: 5,
            getTitlesWidget: (value, meta) => Text(
              value.toInt().toString(),
              // ─── أرقام المحاور متكيفة ───
              style: TextStyle(color: context.textTheme.bodyMedium?.color, fontSize: 11),
            ),
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: calculatedMaxX,
      minY: 0,
      maxY: calculatedMaxY,
      lineBarsData: [
        LineChartBarData(
          spots: minSpots,
          isCurved: true,
          color: Colors.redAccent.withOpacity(0.4),
          barWidth: 1.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          dashArray: [4, 4],
        ),
        LineChartBarData(
          spots: maxSpots,
          isCurved: true,
          color: Colors.redAccent.withOpacity(0.6),
          barWidth: 1.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          dashArray: [4, 4],
        ),
        LineChartBarData(
          spots: idealSpots,
          isCurved: true,
          color: Colors.green.withOpacity(0.7),
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          dashArray: [4, 4],
        ),
        // خط نمو الطفل الفعلي
        LineChartBarData(
          spots: childSpots,
          isCurved: false,
          color: Colors.blue.shade700,
          barWidth: 3.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
                  radius: 5,
                  color: Colors.blue.shade800,
                  strokeWidth: 2,
                  // ─── لون الإطار الأبيض للنقطة يصبح متكيفاً ───
                  strokeColor: context.theme.cardColor,
                ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          // ─── لون نافذة التلميح متكيف (أفتح قليلاً في الوضع الليلي) ───
          getTooltipColor: (touchedSpot) => context.isDarkMode ? const Color(0xFF303030) : const Color(0xFF212121),
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((barSpot) {
              if (barSpot.barIndex == 3) {
                final index = barSpot.spotIndex;
                if (index < sortedHistory.length) {
                  final record = sortedHistory[index];
                  return LineTooltipItem(
                    '${record.date}\n${'Weight (kg)'.tr}: ${record.weight}\n${'Status: '.tr}${record.statusText.tr}',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  );
                }
              }
              return null;
            }).toList();
          },
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDot;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.isDot,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDot)
          Row(
            children: List.generate(
              3,
                  (index) => Container(
                width: 5,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                color: color,
              ),
            ),
          )
        else
          Container(width: 14, height: 3, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            // ─── لون نص الدليل متكيف ───
            color: context.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

```

### File: lib\widgets\growth\growth_history_list.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/growth/child_growth_controller.dart';
import '../../../models/growth/child_growth_response_model.dart';
import '../../../models/growth/growth_record_model.dart';

class GrowthHistoryList extends StatelessWidget {
  final ChildGrowthResponseModel data;

  const GrowthHistoryList({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChildGrowthController>();

    // 1. ترتيب السجلات تنازلياً (الأحدث أولاً)
    final List<GrowthRecordModel> sortedHistory = List.from(data.growthHistory)
      ..sort((a, b) => b.ageInMonths.compareTo(a.ageInMonths));

    if (sortedHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(
            'No appointments found'.tr,
            // ─── نص ثانوي متكيف ───
            style: TextStyle(color: context.textTheme.bodyMedium?.color, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedHistory.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final record = sortedHistory[index];
        return _HistoryCard(record: record, controller: controller);
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final GrowthRecordModel record;
  final ChildGrowthController controller;

  const _HistoryCard({required this.record, required this.controller});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    try {
      badgeColor = Color(int.parse(record.statusColor.replaceAll('#', '0xFF')));
    } catch (_) {
      badgeColor = const Color(0xFF4CAF50);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // ─── لون البطاقة متكيف ───
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // ─── إخفاء الظل في الوضع الليلي ───
            color: context.isDarkMode ? Colors.transparent : Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        // ─── إطار البطاقة متكيف ───
        border: Border.all(color: context.theme.dividerColor),
      ),
      child: Row(
        children: [
          // 1. أيقونة الميزان الجانبية
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              // ─── خلفية الأيقونة متكيفة للوضع الليلي والنهاري ───
              color: context.isDarkMode ? Colors.blue.withOpacity(0.15) : const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.assignment_outlined,
              // ─── أيقونة متكيفة ───
              color: context.isDarkMode ? Colors.blue.shade300 : Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),

          // 2. عمود تفاصيل الوزن والطول
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                        '${'Weight'.tr}: ${record.weight} ${'kg'.tr}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          // ─── نص أساسي متكيف ───
                          color: context.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '|  ${'Height'.tr}: ${record.height} ${'cm'.tr}',
                        style: TextStyle(
                          fontSize: 12,
                          // ─── نص ثانوي متكيف ───
                          color: context.textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      record.date,
                      style: TextStyle(
                        fontSize: 10,
                        // ─── نص ثانوي متكيف ───
                        color: context.textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // ─── لون النقطة الفاصلة متكيف ───
                        color: context.theme.dividerColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${'Age'.tr} ${record.ageInMonths.toInt()} ${'months_old'.tr}',
                        style: TextStyle(
                          fontSize: 10,
                          // ─── نص ثانوي متكيف ───
                          color: context.textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // 3. قسم الشارة التفاعلية وزر الحذف
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showStatusDetailsDialog(context, badgeColor),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        // ─── جعل الشارة أكثر شفافية لتناسب الوضعين ───
                        color: badgeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              record.statusText.contains('ينصح')
                                  ? 'Needs Review'.tr
                                  : record.statusText.tr,
                              style: TextStyle(
                                color: badgeColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.info_outline_rounded,
                            color: badgeColor,
                            size: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _confirmDelete(context, record.id),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    // ─── لون أيقونة الحذف متكيف ───
                    color: context.isDarkMode ? Colors.redAccent : Colors.red.shade400,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusDetailsDialog(BuildContext context, Color color) {
    Get.dialog(
      AlertDialog(
        // ─── خلفية نافذة الحوار متكيفة ───
        backgroundColor: context.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.analytics_outlined, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              'Medical Assessment'.tr,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                // ─── نص العنوان متكيف ───
                color: context.textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Text(
                record.statusText,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  // ─── نص التفاصيل متكيف ───
                  color: context.textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Close'.tr,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                // ─── لون الزر متكيف ───
                color: context.theme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int growthId) {
    Get.dialog(
      AlertDialog(
        // ─── خلفية نافذة التأكيد متكيفة ───
        backgroundColor: context.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete'.tr,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            // ─── نص العنوان متكيف ───
            color: context.textTheme.bodyLarge?.color,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this record?'.tr,
          // ─── نص المحتوى متكيف ───
          style: TextStyle(color: context.textTheme.bodyLarge?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel'.tr,
              // ─── لون زر الإلغاء متكيف ───
              style: TextStyle(color: context.textTheme.bodyMedium?.color),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteMeasurement(growthId);
            },
            child: Text(
              'Delete'.tr,
              style: TextStyle(
                // ─── لون زر الحذف متكيف ───
                color: context.isDarkMode ? Colors.redAccent : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
    _NavItem(label: 'Records', icon: Icons.folder_outlined, route: '/records'),
    _NavItem(label: 'Home', icon: Icons.home_rounded, route: '/home'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        // ─── لون الخلفية متكيف (ليلي/نهاري) ───
        color: context.theme.cardColor,
        boxShadow: [
          // إخفاء الظل في الوضع الليلي لمظهر أنظف
          if (!context.isDarkMode)
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

          // تحديد الألوان بناءً على الحالة والوضع الليلي
          final Color activeColor = context.theme.primaryColor;
          final Color inactiveColor = context.theme.dividerColor;

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
                  color: isSelected ? activeColor : inactiveColor,
                  size: 26,
                ),
                const SizedBox(height: 4),
                Text(
                  item.label.tr,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? activeColor : inactiveColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
import 'package:get/get.dart';

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
          // ─── تكييف اللون بناءً على الاختيار والوضع الليلي ───
          color: isSelected
              ? context.theme.primaryColor.withOpacity(0.1)
              : context.theme.cardColor,
          border: Border.all(
              color: isSelected ? context.theme.primaryColor : context.theme.dividerColor,
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
                  Text(title,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? context.theme.primaryColor : context.textTheme.bodyLarge?.color
                      )
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle, style: TextStyle(fontSize: 14, color: context.textTheme.bodyMedium?.color)),
                ],
              ),
            ),
            if (trailingWidget != null) trailingWidget!,
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
          color: context.theme.cardColor,
          border: Border.all(
              color: isSelected ? context.theme.primaryColor : context.theme.dividerColor,
              width: isSelected ? 2 : 1
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? context.theme.primaryColor : context.theme.dividerColor,
                size: 24
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: TextStyle(fontSize: 16, color: context.textTheme.bodyLarge?.color, fontWeight: FontWeight.w500))),
            if (trailingWidget != null) trailingWidget!,
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
        Text(label,
            style: TextStyle(
                color: isTotal ? context.textTheme.bodyLarge?.color : context.textTheme.bodyMedium?.color,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                fontSize: isTotal ? 16 : 14
            )
        ),
        Text(value,
            style: TextStyle(
                color: isTotal ? context.theme.primaryColor : context.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                fontSize: isTotal ? 18 : 15
            )
        ),
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
        Text(label, style: TextStyle(color: context.textTheme.bodyMedium?.color, fontSize: 14)),
        Text(value,
            style: TextStyle(
                color: context.textTheme.bodyLarge?.color,
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
import 'package:get/get.dart'; // ─── تمت إضافته للوصول إلى السمة ───

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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              // ─── لون العنوان متكيف ───
              color: context.textTheme.bodyLarge?.color,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            // ─── خلفية القسم متكيفة ───
            color: context.theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            // ─── إطار القسم متكيف ───
            border: Border.all(color: context.theme.dividerColor),
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
import 'package:get/get.dart'; // ─── تمت إضافته للوصول إلى السمة ───

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
            // ─── تكييف لون الأيقونة (أحمر مريح ليلاً لتسجيل الخروج، ولون أساسي للبقية) ───
            color: isLogout
                ? (context.isDarkMode ? Colors.redAccent : Colors.red)
                : context.theme.primaryColor,
            size: 28,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              // ─── تكييف لون العنوان ───
              color: isLogout
                  ? (context.isDarkMode ? Colors.redAccent : Colors.red)
                  : context.textTheme.bodyLarge?.color,
            ),
          ),
          subtitle: Text(
            subtitle,
            // ─── تكييف لون النص الثانوي ───
            style: TextStyle(fontSize: 12, color: context.textTheme.bodyMedium?.color),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            // ─── تكييف لون السهم ───
            color: context.theme.dividerColor,
          ),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            // ─── تكييف لون الفاصل ───
            color: context.theme.dividerColor,
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

import '../../controllers/appointment/my_appointments_controller.dart';
import '../../models/appointment/appointment_model.dart';

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
              color: context.textTheme.bodyLarge?.color, // ─── نص متكيف ───
            ),
          ),
        ),
        const SizedBox(height: 14),
        Obx(() {
          final isLoading = controller.isLoading;
          final appointments = isLoading
              ? _fakeAppointments
              : (controller.upcoming.toList()..sort(
                (a, b) => '${a.date} ${a.time}'.compareTo('${b.date} ${b.time}'),
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
                  .map((apt) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AppointmentCard(appointment: apt),
              ))
                  .toList(),
            ),
          );
        }),
      ],
    );
  }
}

class _EmptyAppointmentsCard extends StatelessWidget {
  const _EmptyAppointmentsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.theme.cardColor, // ─── خلفية البطاقة متكيفة ───
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.event_available_outlined, color: context.theme.dividerColor, size: 28),
          const SizedBox(height: 8),
          Text(
            'No upcoming appointments'.tr,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textTheme.bodyMedium?.color),
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
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.theme.cardColor, // ─── خلفية البطاقة متكيفة ───
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!context.isDarkMode) // ─── إخفاء الظل في الوضع الليلي ───
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.doctorName ?? '${'Doctor'.tr} #${appointment.doctorId}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appointment.childName ?? '${'Child'.tr} #${appointment.childId}',
                    style: TextStyle(fontSize: 13, color: context.textTheme.bodyMedium?.color),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _StatusPill(status: appointment.status),
                      const SizedBox(width: 8),
                      Text(
                        '${appointment.date} • ${appointment.time}',
                        style: TextStyle(fontSize: 12, color: context.textTheme.bodyMedium?.color),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: context.theme.scaffoldBackgroundColor, // ─── لون الخلفية متكيف ───
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.person, color: context.theme.dividerColor, size: 30),
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

    // ─── تكييف ألوان الشارات للوضع الليلي والنهاري ───
    final bool isDark = context.isDarkMode;
    Color bg, fg;

    switch (normalized) {
      case 'confirmed':
        bg = isDark ? Colors.green.shade900.withOpacity(0.3) : Colors.green.shade50;
        fg = Colors.green.shade600;
        break;
      case 'cancelled':
      case 'canceled':
        bg = isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50;
        fg = Colors.red.shade600;
        break;
      default:
        bg = isDark ? Colors.orange.shade900.withOpacity(0.3) : Colors.orange.shade50;
        fg = Colors.orange.shade700;
        break;
    }

    final label = status.isEmpty ? 'Pending' : status[0].toUpperCase() + status.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}
```

