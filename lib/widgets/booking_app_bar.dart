import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/booking_theme.dart';

PreferredSizeWidget bookingAppBar({required String subtitle}) {
  return AppBar(
    backgroundColor: kBookingBackground,
    elevation: 0,
    scrolledUnderElevation: 0,
    toolbarHeight: 72,
    leading: Padding(
      padding: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () => Get.back(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.chevron_left_rounded,
            color: kBookingTextPrimary,
            size: 26,
          ),
        ),
      ),
    ),
    title: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Book New Appointment',
          style: TextStyle(
            color: kBookingTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            color: kBookingTextSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
    centerTitle: true,
  );
}
