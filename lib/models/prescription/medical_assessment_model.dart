class MedicalAssessmentModel {
  final int recordId;
  final int appointmentId;
  final String diagnosis;
  final String doctorNotes;
  final String doctorName;
  final List<MedicationItemModel> medications;

  MedicalAssessmentModel({
    required this.recordId,
    required this.appointmentId,
    required this.diagnosis,
    required this.doctorNotes,
    required this.doctorName,
    required this.medications,
  });

  factory MedicalAssessmentModel.fromCombinedJson(
    Map<String, dynamic> recordJson,
    Map<String, dynamic> prescriptionJson,
  ) {
    final record = recordJson['medical_record'] ?? {};
    final prescription = prescriptionJson['prescription'] ?? {};
    final doctor = prescription['doctor'] ?? {};

    // تأمين جلب المصفوفة
    final medsList = prescription['medications'] as List? ?? [];

    return MedicalAssessmentModel(
      recordId: int.tryParse(record['id']?.toString() ?? '0') ?? 0,
      appointmentId:
          int.tryParse(record['appointment_id']?.toString() ?? '0') ?? 0,
      diagnosis: record['diagnosis']?.toString() ?? '',
      doctorNotes: record['doctor_notes']?.toString() ?? '',
      doctorName: doctor['name']?.toString() ?? '',
      // تحويل كل عنصر بأمان
      medications: medsList
          .map((e) => MedicationItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MedicationItemModel {
  final int id;
  final String name;
  final String dosage;
  final String frequency;
  final String timing;
  final String duration;

  MedicationItemModel({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.timing,
    required this.duration,
  });

  factory MedicationItemModel.fromJson(Map<String, dynamic> json) {
    return MedicationItemModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      dosage: json['dosage']?.toString() ?? '',
      frequency: json['frequency']?.toString() ?? '',
      timing: json['timing']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
    );
  }
}
