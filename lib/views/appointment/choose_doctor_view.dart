 import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kidcare/controllers/doctor_controller.dart';
// تعديل المسار ليخرج من فولدر views ويروح على فولدر controllers


class ChooseDoctorView extends StatefulWidget {
  final int departmentId; 
  final String departmentName; 

  const ChooseDoctorView({
    Key? key, 
    this.departmentId = 5, 
    this.departmentName = "Dentistry", 
  }) : super(key: key);

  @override
  State<ChooseDoctorView> createState() => _ChooseDoctorViewState();
}

class _ChooseDoctorViewState extends State<ChooseDoctorView> {
  // استدعاء الكونترولر من الفولدر التاني
  final DoctorController doctorController = Get.put(DoctorController());
  int selectedDoctorId = -1; 

  @override
  void initState() {
    super.initState();
    doctorController.fetchDoctors(widget.departmentId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.blueGrey, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Column(
          children: [
            const Text(
              'Choose Doctor',
              style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 2),
            Text(
              widget.departmentName,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                if (doctorController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (doctorController.doctorsList.isEmpty) {
                  return const Center(
                    child: Text(
                      "No doctors available in this department.",
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: doctorController.doctorsList.length,
                  itemBuilder: (context, index) {
                    var doctor = doctorController.doctorsList[index];
                    bool isSelected = selectedDoctorId == doctor.id;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDoctorId = doctor.id;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF4299E1) : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              // تعديل متوافق مع كل إصدارات فلاتر للشفافية بدون أخطاء
                              color: Colors.black.withOpacity(0.03),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // 1. التقييم على اليسار
                            Row(
                              children: [
 const Icon(Icons.star, color: Color(0xFFFFB020), size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  doctor.rating.toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3748)),
                                ),
                              ],
                            ),
                            const Spacer(),
                            
                            // 2. التفاصيل بالمنتصف ومحاذاة يمين متل التصميم
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  doctor.fullName, 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D3748)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  doctor.education, 
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${doctor.experienceYears} Years Experience",
                                  style: const TextStyle(color: Color(0xFF718096), fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            
                            // 3. الصورة على اليمين
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.grey[100],
                              backgroundImage: doctor.profilePicture != null
                                  ? NetworkImage(doctor.profilePicture!)
                                  : const NetworkImage("https://via.placeholder.com/150") as ImageProvider,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4299E1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: selectedDoctorId == -1 
                      ? null 
                      : () {
                          // الانتقال للواجهة التالية
                        },
                  child: const Text(
                    'Next',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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