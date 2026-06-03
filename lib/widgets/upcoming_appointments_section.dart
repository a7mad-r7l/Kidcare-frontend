import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../controllers/appointment/my_appointments_controller.dart';
import '../models/appointment/appointment_model.dart';

final _fakeAppointments = List<AppointmentModel>.generate(
  2,
  (i) => AppointmentModel(
    id: (-i - 1).toString(),
    childId: -1,
    doctorId: -1,
    date: '2026-01-01',
    time: '09:00',
    status: 'pending',
    price: 0,
    doctorName: 'Dr. Loading Name',
    childName: 'Child Name',
  ),
);

class UpcomingAppointmentsSection extends StatelessWidget {
  final MyAppointmentsController controller;

  final int maxItems;

  const UpcomingAppointmentsSection({
    super.key,
    required this.controller,
    this.maxItems = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Upcoming Appointments'.tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Obx(() {
          final isLoading = controller.isLoading;

          final appointments = isLoading
              ? _fakeAppointments
              : (controller.upcoming.toList()..sort(
                      (a, b) => '${a.date} ${a.time}'.compareTo(
                        '${b.date} ${b.time}',
                      ),
                    ))
                    .take(maxItems)
                    .toList();

          if (!isLoading && appointments.isEmpty) {
            return const _EmptyAppointmentsCard();
          }

          return Skeletonizer(
            enabled: isLoading,
            child: Column(
              children: appointments
                  .map(
                    (apt) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AppointmentCard(appointment: apt),
                    ),
                  )
                  .toList(),
            ),
          );
        }),
      ],
    );
  }
}

/// Placeholder shown when the user has no upcoming appointments.
class _EmptyAppointmentsCard extends StatelessWidget {
  const _EmptyAppointmentsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available_outlined,
            color: Colors.grey.shade400,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            'No upcoming appointments'.tr,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
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
              color: Colors.black.withValues(alpha: 0.05),
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
                    appointment.doctorName ?? '${'Doctor'.tr} #${appointment.doctorId}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appointment.childName ?? '${'Child'.tr} #${appointment.childId}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _StatusPill(status: appointment.status),
                      const SizedBox(width: 8),
                      Text(
                        '${appointment.date} • ${appointment.time}',
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
              child: Icon(Icons.person, color: Colors.grey.shade400, size: 30),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    late final Color bg;
    late final Color fg;
    switch (normalized) {
      case 'confirmed':
        bg = Colors.green.shade50;
        fg = Colors.green.shade600;
        break;
      case 'cancelled':
      case 'canceled':
        bg = Colors.red.shade50;
        fg = Colors.red.shade600;
        break;
      case 'pending':
      default:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
        break;
    }

    // Capitalize the first letter for display ("pending" → "Pending").
    final label = status.isEmpty
        ? 'Pending'
        : status[0].toUpperCase() + status.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
