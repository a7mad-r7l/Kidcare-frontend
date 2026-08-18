import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/prescription/prescription_controller.dart';
import '../../models/prescription/medical_assessment_model.dart'; // 👈 ضروري للتعرف على المودل

class PrescriptionView extends GetView<PrescriptionController> {
  const PrescriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Medical Assessment'.tr,
          style: TextStyle(
            color: context.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
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
        if (controller.isLoading && controller.assessment.value == null) {
          return Center(
            child: CircularProgressIndicator(color: context.theme.primaryColor),
          );
        }

        final data = controller.assessment.value;
        if (data == null) {
          return Center(
            child: Text(
              'No medical assessment found'.tr,
              style: TextStyle(color: context.theme.hintColor),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDoctorHeader(context, data.doctorName),
              const SizedBox(height: 20),
              _buildDiagnosisCard(context, data.diagnosis, data.doctorNotes),
              const SizedBox(height: 20),
              Text(
                'Prescribed Medications'.tr,
                style: context.theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 12),

              // 👈 معالجة عرض الأدوية أو رسالة "لا يوجد"
              if (data.medications.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: context.theme.dividerColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    'No medications prescribed'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.theme.hintColor),
                  ),
                )
              else
                ...data.medications.map(
                  (med) => _buildMedicationCard(context, med),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDoctorHeader(BuildContext context, String doctorName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.theme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: context.theme.primaryColor.withValues(alpha: 0.2),
            child: Icon(Icons.person, color: context.theme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attending Doctor'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.theme.hintColor,
                  ),
                ),
                Text(
                  doctorName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.theme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisCard(
    BuildContext context,
    String diagnosis,
    String notes,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.theme.dividerColor.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: context.theme.shadowColor.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.monitor_heart_outlined,
                color: context.theme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Clinical Diagnosis'.tr,
                style: context.theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            diagnosis.isNotEmpty ? diagnosis : 'No diagnosis recorded'.tr,
            style: TextStyle(
              color: context.textTheme.bodyLarge?.color,
              height: 1.5,
            ),
          ),
          if (notes.isNotEmpty && notes.toLowerCase() != 'nothing') ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                height: 1,
                color: context.theme.dividerColor.withValues(alpha: 0.2),
              ),
            ),
            Row(
              children: [
                Icon(Icons.notes, color: context.theme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Doctor Notes'.tr,
                  style: context.theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              notes,
              style: TextStyle(color: context.theme.hintColor, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  // 👈 هنا بطاقة الدواء مصممة بعناية وتعمل بدون أخطاء
  Widget _buildMedicationCard(BuildContext context, MedicationItemModel med) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      // 👈 التعديل الأول: تفعيل قص الحواف للحاوية الخارجية
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        // 👈 التعديل الثاني: إطار موحد يمنع الكراش
        border: Border.all(
          color: context.theme.dividerColor.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: context.theme.shadowColor.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // 👈 التعديل الثالث: حاوية داخلية لرسم الخط الجانبي بأمان
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: context.theme.primaryColor, width: 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.medication_outlined,
                  color: context.theme.primaryColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    med.name,
                    style: context.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMedDetail(
                  context,
                  Icons.vaccines,
                  'Dosage'.tr,
                  med.dosage,
                ),
                const SizedBox(width: 12),
                _buildMedDetail(
                  context,
                  Icons.repeat,
                  'Frequency'.tr,
                  med.frequency,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMedDetail(
                  context,
                  Icons.access_time,
                  'Timing'.tr,
                  med.timing,
                ),
                const SizedBox(width: 12),
                _buildMedDetail(
                  context,
                  Icons.date_range,
                  'Duration'.tr,
                  med.duration,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedDetail(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: context.theme.hintColor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.theme.hintColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: context.textTheme.bodyLarge?.color,
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
