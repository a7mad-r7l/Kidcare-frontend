import 'dart:convert';
import '../../../models/prescription/medical_assessment_model.dart';
import '../../apis/prescription/prescription_api.dart';
import '../../helper/secure_storage_service.dart';

class PrescriptionRepo {
  final PrescriptionApi _api = PrescriptionApi();

  String _cleanJson(String response) {
    final startIndex = response.indexOf(RegExp(r'[\{\[]'));
    if (startIndex != -1) return response.substring(startIndex);
    return response;
  }

  Future<MedicalAssessmentModel> fetchFullAssessment(int appointmentId) async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) throw Exception('Session expired. Please login again.');

    // 1. جلب السجل الطبي بدلالة رقم الموعد
    final recordRes = await _api.getMedicalRecord(token, appointmentId);
    final recordDecoded = jsonDecode(_cleanJson(recordRes.body));

    if (recordRes.statusCode != 200 || recordDecoded['status'] != 'success') {
      throw Exception(
        recordDecoded['message'] ?? 'Failed to load medical record',
      );
    }

    final int recordId =
        int.tryParse(
          recordDecoded['medical_record']['id']?.toString() ?? '0',
        ) ??
        0;

    if (recordId == 0) {
      throw Exception('Invalid record ID received');
    }

    // 2. جلب الأدوية بدلالة رقم السجل
    final prescriptionRes = await _api.getPrescription(token, recordId);
    final prescriptionDecoded = jsonDecode(_cleanJson(prescriptionRes.body));

    if (prescriptionRes.statusCode != 200 ||
        prescriptionDecoded['status'] != 'success') {
      throw Exception(
        prescriptionDecoded['message'] ?? 'Failed to load prescription',
      );
    }

    // 3. دمج البيانات وإرجاع النموذج
    return MedicalAssessmentModel.fromCombinedJson(
      recordDecoded,
      prescriptionDecoded,
    );
  }
}
