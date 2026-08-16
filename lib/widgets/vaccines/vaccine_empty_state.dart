import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VaccineEmptyState extends StatelessWidget {
  final IconData icon;
  final String text;

  const VaccineEmptyState({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.4,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: context.theme.dividerColor),
            const SizedBox(height: 16),
            Text(
              text,
              style: TextStyle(color: context.theme.hintColor, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
