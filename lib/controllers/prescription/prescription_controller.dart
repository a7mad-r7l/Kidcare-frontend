import 'package:get/get.dart';
import '../../core/repos/prescription/prescription_repo.dart';
import '../../models/prescription/medical_assessment_model.dart';
import '../base_controller.dart';

class PrescriptionController extends BaseController {
  final PrescriptionRepo repo;

  PrescriptionController({required this.repo});

  final assessment = Rxn<MedicalAssessmentModel>();
  late final int appointmentId;

  @override
  void onInit() {
    super.onInit();
    appointmentId = Get.arguments as int? ?? 0;
    if (appointmentId != 0) {
      fetchAssessment();
    }
  }

  Future<void> fetchAssessment() async {
    showLoading();
    try {
      final data = await repo.fetchFullAssessment(appointmentId);
      assessment.value = data;
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }
}
