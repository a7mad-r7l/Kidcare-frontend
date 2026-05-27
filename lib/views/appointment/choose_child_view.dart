import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../controllers/appointment/appointment_controller.dart';
import '../../controllers/appointment/child_controller.dart';
import '../../core/booking_theme.dart';
import '../../models/appointment/child_model.dart';
import '../../widgets/booking_app_bar.dart';

final _fakeChildren = List<ChildModel>.generate(
  3,
  (i) => ChildModel(
    id: -i - 1,
    parentId: -1,
    firstName: 'Child',
    lastName: 'Loading',
    gender: i.isEven ? 'male' : 'female',
    birthDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
  ),
);

const _kPrimary = kBookingPrimary;
const _kBackground = kBookingBackground;
const _kTextPrimary = kBookingTextPrimary;
const _kTextSecondary = kBookingTextSecondary;
const _kBorder = kBookingBorder;
const _kBoyTint = Color(0xFFE7F7E9);
const _kGirlTint = Color(0xFFFFE7EE);
const _kSelectedBorder = Color(0xFF22C55E);

class ChooseChildView extends StatefulWidget {
  const ChooseChildView({super.key});

  @override
  State<ChooseChildView> createState() => _ChooseChildViewState();
}

class _ChooseChildViewState extends State<ChooseChildView> {
  final ChildController childController = Get.find<ChildController>();
  final AppointmentController appointmentController =
      Get.find<AppointmentController>();

  int? selectedChildId;

  void _onChildTapped(ChildModel child) {
    setState(() => selectedChildId = child.id);
    appointmentController.selectChild(child);
  }

  void _onNextPressed() {
    if (selectedChildId == null) return;
    Get.toNamed('/choose-date-time');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: bookingAppBar(subtitle: 'Choose Child'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                final isLoading = childController.isLoading;
                final children =
                    isLoading ? _fakeChildren : childController.children;

                if (!isLoading && children.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        "You haven't added any children yet.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _kTextSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }

                return Skeletonizer(
                  enabled: isLoading,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    itemCount: children.length,
                    itemBuilder: (context, index) {
                      final child = children[index];
                      return _ChildCard(
                        child: child,
                        isSelected: selectedChildId == child.id,
                        onTap:
                            isLoading ? () {} : () => _onChildTapped(child),
                      );
                    },
                  ),
                );
              }),
            ),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    final enabled = selectedChildId != null;
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
    final isMale = child.gender == 'male';
    final tint = isMale ? _kBoyTint : _kGirlTint;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? tint : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? _kSelectedBorder : _kBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          children: [
            _ChildAvatar(child: child, tint: tint),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${child.ageYears} years',
                    style: const TextStyle(
                      fontSize: 13,
                      color: _kTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _SelectionIndicator(selected: isSelected),
          ],
        ),
      ),
    );
  }
}

class _ChildAvatar extends StatelessWidget {
  final ChildModel child;
  final Color tint;

  const _ChildAvatar({required this.child, required this.tint});

  @override
  Widget build(BuildContext context) {
    final isMale = child.gender == 'male';
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: child.image != null
          ? Image.network(
              child.image!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _localFallback(isMale),
            )
          : _localFallback(isMale),
    );
  }

  Widget _localFallback(bool isMale) {
    return Image.asset(
      isMale
          ? 'assets/images/boy character green.png'
          : 'assets/images/girl character.png',
      fit: BoxFit.contain,
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  final bool selected;
  const _SelectionIndicator({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: selected ? _kSelectedBorder : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? _kSelectedBorder : _kBorder,
          width: 1.5,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
          : null,
    );
  }
}

