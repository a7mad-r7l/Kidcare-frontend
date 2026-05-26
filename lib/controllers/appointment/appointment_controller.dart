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
