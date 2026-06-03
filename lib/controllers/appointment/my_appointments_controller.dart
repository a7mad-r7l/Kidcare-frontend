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
