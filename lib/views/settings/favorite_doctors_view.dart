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
    final AppointmentController appointmentController = Get.find<AppointmentController>();

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
              child: doctor.profilePicture != null && doctor.profilePicture!.isNotEmpty
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
                  // 🌟 الإصلاح: قراءة النص المباشر والآمن للقسم المرتجع من البوستمان وترجمته ديناميكياً
                  Text(
                    doctor.departmentName.isNotEmpty ? doctor.departmentName.tr : 'Specialist'.tr,
                    style: const TextStyle(fontSize: 12.5, color: Colors.grey),
                  ),
                  // 🌟 تم حذف كود شرط الـ Rating بالكامل ليتناسق هندسياً مع الـ Model المحدث
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