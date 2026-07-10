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
