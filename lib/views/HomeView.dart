import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../controllers/appointment/appointment_controller.dart';
import '../controllers/appointment/child_controller.dart';
import '../controllers/appointment/my_appointments_controller.dart';
import '../core/repos/appointment/appointment_repo.dart';
import '../core/repos/appointment/doctor_repo.dart';
import '../models/appointment/child_model.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/main_bottom_nav.dart';
import '../widgets/upcoming_appointments_section.dart';

final _fakeHomeChildren = List<ChildModel>.generate(
  2,
  (i) => ChildModel(
    id: -i - 1,
    parentId: -1,
    firstName: 'Child',
    lastName: 'Loading',
    gender: i.isEven ? 'male' : 'female',
    birthDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
  ),
);

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ChildController childController = Get.find<ChildController>();
  final MyAppointmentsController myAppointmentsController =
      Get.find<MyAppointmentsController>();

  final Rxn<int> _selectedChildId = Rxn<int>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      myAppointmentsController.loadUpcoming();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      bottomNavigationBar: const MainBottomNav(currentIndex: 2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeaderSection(),
              const SizedBox(height: 24),
              _ChildrenSection(
                controller: childController,
                selectedChildId: _selectedChildId,
              ),
              const SizedBox(height: 20),
              const _BookButton(),
              const SizedBox(height: 28),
              UpcomingAppointmentsSection(
                controller: myAppointmentsController,
              ),
              const SizedBox(height: 28),
              const _QuickServicesSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            // TODO: Get.toNamed('/notifications')
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_outlined,
              size: 22,
              color: Colors.black87,
            ),
          ),
        ),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Ahmed Mohammed',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Welcome back!',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                // TODO: Get.toNamed('/profile')
              },
              child: CircleAvatar(
                radius: 26,
                backgroundColor: Colors.grey.shade200,
                child: Icon(
                  Icons.person,
                  color: Colors.grey.shade400,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Children ─────────────────────────────────────────────────────────────────

class _ChildrenSection extends StatelessWidget {
  final ChildController controller;
  final Rxn<int> selectedChildId;

  const _ChildrenSection({
    required this.controller,
    required this.selectedChildId,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = controller.isLoading;
      final children = isLoading
          ? _fakeHomeChildren
          : controller.children.take(2).toList();

      if (!isLoading && children.isEmpty) {
        return Container(
          height: 100,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'No children added yet.',
            style: TextStyle(color: Colors.grey),
          ),
        );
      }

      // Default selection to the first real child once loaded.
      if (!isLoading &&
          selectedChildId.value == null &&
          children.isNotEmpty) {
        selectedChildId.value = children.first.id;
      }

      return Skeletonizer(
        enabled: isLoading,
        child: Row(
          children: children
              .map(
                (child) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: _ChildCard(
                      child: child,
                      isSelected: selectedChildId.value == child.id,
                      onTap: () => selectedChildId.value = child.id,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      );
    });
  }
}

class _ChildCard extends StatelessWidget {
  final ChildModel child;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChildCard({
    required this.child,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMale = child.gender == 'male';
    final Color bgColor = isMale
        ? const Color(0xFFD6F5D6)
        : const Color(0xFFFFD6E0);
    final Color badgeColor = isSelected
        ? Colors.green
        : const Color(0xFFFF6B8A);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: child.image != null
                    ? ClipOval(
                        child: Image.network(
                          child.image!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _fallbackImage(isMale),
                        ),
                      )
                    : _fallbackImage(isMale),
              ),
            ),
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    child.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${child.ageYears} years',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 44,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSelected ? Icons.check : Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackImage(bool isMale) {
    return Image.asset(
      isMale
          ? 'assets/images/boy character green.png'
          : 'assets/images/girl character.png',
      width: 100,
      height: 100,
      fit: BoxFit.contain,
    );
  }
}

// ─── Book Button ──────────────────────────────────────────────────────────────

class _BookButton extends StatelessWidget {
  const _BookButton();

  void _onPressed() {
    if (Get.isRegistered<AppointmentController>()) {
      Get.delete<AppointmentController>(force: true);
    }
    Get.put<AppointmentController>(
      AppointmentController(
        repo: AppointmentRepo(),
        doctorRepo: DoctorRepo(),
      ),
      permanent: true,
    );
    Get.toNamed('/choose-doctor');
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      text: 'Book New Appointment',
      onPressed: _onPressed,
    );
  }
}

// ─── Quick Services ───────────────────────────────────────────────────────────

class _QuickServicesSection extends StatelessWidget {
  const _QuickServicesSection();

  static const List<Map<String, dynamic>> _services = [
    {
      'label': 'Follow-up',
      'icon': Icons.receipt_long_outlined,
      'color': Color(0xFFEDE7FF),
      'iconColor': Color(0xFF7C3AED),
      'route': '/follow-up',
    },
    {
      'label': 'Prescriptions',
      'icon': Icons.medical_services_outlined,
      'color': Color(0xFFE8F5E9),
      'iconColor': Color(0xFF2E7D32),
      'route': '/prescriptions',
    },
    {
      'label': 'Vaccinations',
      'icon': Icons.vaccines_outlined,
      'color': Color(0xFFFFF3E0),
      'iconColor': Color(0xFFE65100),
      'route': '/vaccinations',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Quick Services',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _services
              .map((service) => _ServiceItem(service: service))
              .toList(),
        ),
      ],
    );
  }
}

class _ServiceItem extends StatelessWidget {
  final Map<String, dynamic> service;

  const _ServiceItem({required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Get.toNamed(service['route'])
      },
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: service['color'] as Color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              service['icon'] as IconData,
              color: service['iconColor'] as Color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            service['label'],
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
