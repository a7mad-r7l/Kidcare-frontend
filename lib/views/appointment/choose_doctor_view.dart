import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../controllers/appointment/appointment_controller.dart';
import '../../controllers/appointment/department_controller.dart';
import '../../controllers/appointment/doctor_controller.dart';
import '../../core/booking_theme.dart';
import '../../models/appointment/department_model.dart';
import '../../models/appointment/doctor_model.dart';
import '../../widgets/booking_app_bar.dart';

final _fakeDepartments = List<DepartmentModel>.generate(
  5,
  (i) => DepartmentModel(id: -i - 1, name: 'Department'),
);

final _fakeDoctors = List<DoctorModel>.generate(
  5,
  (i) => DoctorModel(
    id: -i - 1,
    departmentId: -1,
    firstName: 'Doctor',
    lastName: 'Loading',
    email: '',
    address: '',
    rating: 4.5,
  ),
);

const _kPrimary = kBookingPrimary;
const _kBackground = kBookingBackground;
const _kTextPrimary = kBookingTextPrimary;
const _kTextSecondary = kBookingTextSecondary;
const _kBorder = kBookingBorder;
const _kAvatarTint = kBookingAvatarTint;

class ChooseDoctorView extends StatefulWidget {
  const ChooseDoctorView({super.key});

  @override
  State<ChooseDoctorView> createState() => _ChooseDoctorViewState();
}

class _ChooseDoctorViewState extends State<ChooseDoctorView> {
  final DepartmentController departmentController =
      Get.find<DepartmentController>();
  final DoctorController doctorController = Get.find<DoctorController>();
  final AppointmentController appointmentController =
      Get.find<AppointmentController>();

  DepartmentModel? selectedDepartment;
  int? selectedDoctorId;

  void _onDepartmentTapped(DepartmentModel d) {
    setState(() {
      selectedDepartment = d;
      selectedDoctorId = null;
    });
    doctorController.loadDoctors(d.id);
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
      backgroundColor: _kBackground,
      appBar: bookingAppBar(subtitle: 'Choose Doctor'),
      body: SafeArea(
        child: Column(
          children: [
            _buildDepartmentChips(),
            const SizedBox(height: 8),
            Expanded(child: _buildDoctorList()),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentChips() {
    return SizedBox(
      height: 56,
      child: Obx(() {
        final isLoading = departmentController.isLoading &&
            departmentController.departments.isEmpty;
        final depts =
            isLoading ? _fakeDepartments : departmentController.departments;

        if (!isLoading && depts.isEmpty) {
          return const Center(
            child: Text(
              'No departments available',
              style: TextStyle(color: _kTextSecondary),
            ),
          );
        }

        return Skeletonizer(
          enabled: isLoading,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: depts.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final dept = depts[index];
              final isSelected = selectedDepartment?.id == dept.id;
              return _DepartmentChip(
                label: dept.name,
                selected: isSelected,
                onTap: isLoading ? () {} : () => _onDepartmentTapped(dept),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildDoctorList() {
    if (selectedDepartment == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Pick a department above to see the doctors.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _kTextSecondary, fontSize: 14),
          ),
        ),
      );
    }
    return Obx(() {
      final isLoading = doctorController.isLoading;
      final doctors = isLoading ? _fakeDoctors : doctorController.doctors;

      if (!isLoading && doctors.isEmpty) {
        return const Center(
          child: Text(
            'No doctors available in this department.',
            style: TextStyle(color: _kTextSecondary, fontSize: 14),
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
            return _DoctorCard(
              doctor: doctor,
              specialty: selectedDepartment?.name ?? 'Specialty',
              isSelected: selectedDoctorId == doctor.id,
              onTap: isLoading ? () {} : () => _onDoctorTapped(doctor),
            );
          },
        ),
      );
    });
  }

  Widget _buildNextButton() {
    final enabled = selectedDoctorId != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            disabledBackgroundColor: _kPrimary.withValues(alpha: 0.4),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: enabled ? _onNextPressed : null,
          child: const Text(
            'Next',
            style: TextStyle(
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

class _DepartmentChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DepartmentChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? _kPrimary : _kBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _kTextPrimary,
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

  const _DoctorCard({
    required this.doctor,
    required this.specialty,
    required this.isSelected,
    required this.onTap,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? _kPrimary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.06 : 0.04),
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
                    ),
                  ),
                  if (specialty.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      '$specialty Specialist',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: _kTextSecondary,
                      ),
                    ),
                  ],
                  if (doctor.rating != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFBBF24),
                          size: 16,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          doctor.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _kTextPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'rating',
                          style: TextStyle(
                            fontSize: 12,
                            color: _kTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
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
      decoration: const BoxDecoration(
        color: _kAvatarTint,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null
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
    return const Center(
      child: Icon(Icons.person_rounded, color: _kPrimary, size: 30),
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
        color: selected ? _kPrimary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? _kPrimary : _kBorder,
          width: 1.5,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
          : null,
    );
  }
}

