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

    controller.loadSlots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: bookingAppBar(subtitle: 'Pick Date & Time'.tr),
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
                     Text(
                      'Available Times'.tr,
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


      final selectedDate = controller.selectedDate.value;
      final isLoadingSlots = controller.isLoadingSlots.value;
      final times = controller.availableTimes.toList();
      final selectedTime = controller.selectedTime.value;

      if (selectedDate == null) {
        return  _EmptyHint(text: 'Pick a date to see available times.'.tr);
      }
      if (!isLoadingSlots && times.isEmpty) {
        return  _EmptyHint(text: 'No times available for this date.'.tr);
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
                :  Text(
                    'Book Appointment'.tr,
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

