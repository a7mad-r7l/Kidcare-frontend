import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../controllers/appointment/appointment_controller.dart';
import '../../core/booking_theme.dart';
import '../../models/appointment/appointment_model.dart';
import '../../widgets/booking_app_bar.dart';
import '../../widgets/booking_calendar.dart';

const _fakeSlots = <String>[
  '09:00',
  '09:30',
  '10:00',
  '10:30',
  '11:00',
  '11:30',
  '12:00',
  '12:30',
  '13:00',
];

const _kPrimary = kBookingPrimary;
const _kBackground = kBookingBackground;
const _kTextPrimary = kBookingTextPrimary;
const _kTextSecondary = kBookingTextSecondary;
const _kBorder = kBookingBorder;

class ChooseDateTimeView extends StatefulWidget {
  const ChooseDateTimeView({super.key});

  @override
  State<ChooseDateTimeView> createState() => _ChooseDateTimeViewState();
}

class _ChooseDateTimeViewState extends State<ChooseDateTimeView> {
  final AppointmentController controller = Get.find<AppointmentController>();

  @override
  void initState() {
    super.initState();
    controller.loadDoctorAvailability();
    if (controller.selectedDate.value == null) {
      controller.selectDate(DateTime.now());
    }
    // Always re-fetch slots on entry â€” the user may have returned to this
    // screen after changing the doctor, or just been away long enough for
    // another user to book one of the slots we previously cached.
    controller.loadSlots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: bookingAppBar(subtitle: 'Pick Date & Time'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() {
                      return BookingCalendar(
                        selectedDate: controller.selectedDate.value,
                        minDate: DateTime.now(),
                        workingWeekdays: controller.workingWeekdays.toSet(),
                        onDateSelected: (date) {
                          controller.selectDate(date);
                          controller.loadSlots();
                        },
                      );
                    }),
                    const SizedBox(height: 20),
                    const Text(
                      'Available Times',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SlotsGrid(controller: controller),
                  ],
                ),
              ),
            ),
            _BookButton(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _SlotsGrid extends StatelessWidget {
  final AppointmentController controller;
  const _SlotsGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Read all observables up-front so the Obx subscribes to every signal
      // it depends on (itemBuilder fires lazily, outside the Obx scope).
      final selectedDate = controller.selectedDate.value;
      final isLoadingSlots = controller.isLoadingSlots.value;
      final times = controller.availableTimes.toList();
      final selectedTime = controller.selectedTime.value;

      if (selectedDate == null) {
        return const _EmptyHint(text: 'Pick a date to see available times.');
      }
      if (!isLoadingSlots && times.isEmpty) {
        return const _EmptyHint(text: 'No times available for this date.');
      }

      final shown = isLoadingSlots ? _fakeSlots : times;

      return Skeletonizer(
        enabled: isLoadingSlots,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2,
          ),
          itemCount: shown.length,
          itemBuilder: (context, index) {
            final time = shown[index];
            final isSelected = selectedTime == time;
            return _SlotChip(
              label: _formatTime12h(time),
              selected: isSelected,
              onTap:
                  isLoadingSlots ? () {} : () => controller.selectTime(time),
            );
          },
        ),
      );
    });
  }
}

class _SlotChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SlotChip({
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
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _kPrimary : _kBorder,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : _kTextPrimary,
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: _kTextSecondary, fontSize: 13.5),
        ),
      ),
    );
  }
}

class _BookButton extends StatelessWidget {
  final AppointmentController controller;
  const _BookButton({required this.controller});

  Future<void> _handleBook(BuildContext context) async {
    final success = await controller.bookAppointment();
    if (!success || !context.mounted) return;

    final appointmentId = controller.bookedAppointmentId.value!;

    Get.delete<AppointmentController>(force: true);

    Get.offNamed('/payment-method', arguments: appointmentId);

    // await showDialog<void>(
    //   context: context,
    //   barrierDismissible: false,
    //   builder: (_) => _BookingSuccessDialog(
    //     appointment: appointment,
    //     doctorName: doctorName,
    //     childName: childName,
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: Obx(() {
          final enabled =
              controller.selectedTime.value != null && !controller.isLoading;
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              disabledBackgroundColor: _kPrimary.withValues(alpha: 0.4),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: enabled ? () => _handleBook(context) : null,
            child: controller.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : const Text(
                    'Book Appointment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          );
        }),
      ),
    );
  }
}

class _BookingSuccessDialog extends StatelessWidget {
  final AppointmentModel appointment;
  final String? doctorName;
  final String? childName;

  const _BookingSuccessDialog({
    required this.appointment,
    this.doctorName,
    this.childName,
  });

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatTime(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts[1].padLeft(2, '0');
    final suffix = h >= 12 ? 'PM' : 'AM';
    final hour = h % 12 == 0 ? 12 : h % 12;
    return '$hour:$m $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 44,
                color: Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Appointment Booked!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your appointment has been confirmed.\nSee you soon!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // Details card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.person_rounded,
                    label: 'Doctor',
                    value: doctorName ?? 'Doctor #${appointment.doctorId}',
                  ),
                  const SizedBox(height: 10),
                  _DetailRow(
                    icon: Icons.child_care_rounded,
                    label: 'Child',
                    value: childName ?? 'Child #${appointment.childId}',
                  ),
                  const SizedBox(height: 10),
                  _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: _formatDate(appointment.date),
                  ),
                  const SizedBox(height: 10),
                  _DetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: _formatTime(appointment.time),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Get.offAllNamed('/home');
                },
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _kPrimary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

String _formatTime12h(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length < 2) return hhmm;
  final h = int.tryParse(parts[0]);
  if (h == null) return hhmm;
  final m = parts[1].padLeft(2, '0');
  final period = h >= 12 ? 'PM' : 'AM';
  final hh12 = h % 12 == 0 ? 12 : h % 12;
  return '${hh12.toString().padLeft(2, '0')}:$m $period';
}

