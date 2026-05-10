import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/child_model.dart';
import '../models/appointment_model.dart';
import '../widgets/custom_text_field.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  static const List<ChildModel> _children = [
    ChildModel(name: 'Adam', age: '3 years', gender: 'male', isSelected: true),
    ChildModel(name: 'Lina', age: '5 years', gender: 'female', isSelected: false),
  ];

  static const List<AppointmentModel> _appointments = [
    AppointmentModel(
      doctorName: 'Dr. Sara Ahmed',
      specialty: 'General Pediatrics',
      date: 'Sunday, May 12 2024 - 10:00 AM',
      status: 'Confirmed',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      bottomNavigationBar: const _BottomNav(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeaderSection(),
              const SizedBox(height: 24),
              _ChildrenSection(children: _children),
              const SizedBox(height: 20),
              const _BookButton(),
              const SizedBox(height: 28),
              _UpcomingAppointmentsSection(appointments: _appointments),
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
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.notifications_outlined,
                size: 22, color: Colors.black87),
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
                child: Icon(Icons.person,
                    color: Colors.grey.shade400, size: 28),
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
  final List<ChildModel> children;

  const _ChildrenSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: children
          .map((child) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: _ChildCard(child: child),
        ),
      ))
          .toList(),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final ChildModel child;

  const _ChildCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final bool isMale = child.gender == 'male';
    final Color bgColor =
    isMale ? const Color(0xFFD6F5D6) : const Color(0xFFFFD6E0);
    final Color badgeColor =
    child.isSelected ? Colors.green : const Color(0xFFFF6B8A);

    return GestureDetector(
      onTap: () {
        // TODO: Get.toNamed('/child-profile', arguments: child)
      },
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // ─── صورة الطفل ───────────────────────────
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Image.asset(
                  isMale
                      ? 'assets/images/boy character green.png'
                      : 'assets/images/girl character.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Name & age
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    child.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    child.age,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Badge
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
                  child.isSelected ? Icons.check : Icons.keyboard_arrow_down,
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
}

// ─── Book Button ──────────────────────────────────────────────────────────────

class _BookButton extends StatelessWidget {
  const _BookButton();

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      text: 'Book New Appointment',
      onPressed: () {
        // TODO: Get.toNamed('/book-appointment')
      },
    );
  }
}

// ─── Upcoming Appointments ────────────────────────────────────────────────────

class _UpcomingAppointmentsSection extends StatelessWidget {
  final List<AppointmentModel> appointments;

  const _UpcomingAppointmentsSection({required this.appointments});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'Upcoming Appointments',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 14),
        ...appointments.map((apt) => _AppointmentCard(appointment: apt)),
      ],
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;

  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Get.toNamed('/appointment-details', arguments: appointment)
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    appointment.doctorName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appointment.specialty,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          appointment.status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        appointment.date,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.person,
                  color: Colors.grey.shade400, size: 30),
            ),
          ],
        ),
      ),
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
        const Text(
          'Quick Services',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
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

// ─── Bottom Navigation ────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  static const List<Map<String, dynamic>> _items = [
    {'label': 'More', 'icon': Icons.more_horiz, 'route': '/more'},
    {'label': 'Records', 'icon': Icons.folder_outlined, 'route': '/records'},
    {'label': 'Appointments', 'icon': Icons.calendar_month_outlined, 'route': '/appointments'},
    {'label': 'Home', 'icon': Icons.home_rounded, 'route': '/home'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _items.asMap().entries.map((entry) {
          final bool isSelected = entry.key == 3;
          return GestureDetector(
            onTap: () {
              // TODO: Get.toNamed(entry.value['route'])
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  entry.value['icon'] as IconData,
                  color: isSelected
                      ? const Color(0xFF3B9EFF)
                      : Colors.grey.shade400,
                  size: 26,
                ),
                const SizedBox(height: 4),
                Text(
                  entry.value['label'],
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected
                        ? const Color(0xFF3B9EFF)
                        : Colors.grey.shade400,
                    fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}