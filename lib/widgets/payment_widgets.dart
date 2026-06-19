import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaymentMethodCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int value;
  final int groupValue;
  final VoidCallback onTap;
  final Widget? trailingWidget;

  const PaymentMethodCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onTap,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    bool isSelected = value == groupValue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          // ─── تكييف اللون بناءً على الاختيار والوضع الليلي ───
          color: isSelected
              ? context.theme.primaryColor.withOpacity(0.1)
              : context.theme.cardColor,
          border: Border.all(
              color: isSelected ? context.theme.primaryColor : context.theme.dividerColor,
              width: isSelected ? 2 : 1
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? context.theme.primaryColor : context.textTheme.bodyLarge?.color
                      )
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle, style: TextStyle(fontSize: 14, color: context.textTheme.bodyMedium?.color)),
                ],
              ),
            ),
            if (trailingWidget != null) trailingWidget!,
          ],
        ),
      ),
    );
  }
}

class PaymentOptionCard extends StatelessWidget {
  final String title;
  final int value;
  final int groupValue;
  final VoidCallback onTap;
  final Widget? trailingWidget;

  const PaymentOptionCard({
    super.key,
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onTap,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    bool isSelected = value == groupValue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          border: Border.all(
              color: isSelected ? context.theme.primaryColor : context.theme.dividerColor,
              width: isSelected ? 2 : 1
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? context.theme.primaryColor : context.theme.dividerColor,
                size: 24
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: TextStyle(fontSize: 16, color: context.textTheme.bodyLarge?.color, fontWeight: FontWeight.w500))),
            if (trailingWidget != null) trailingWidget!,
          ],
        ),
      ),
    );
  }
}

class PaymentSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const PaymentSummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: isTotal ? context.textTheme.bodyLarge?.color : context.textTheme.bodyMedium?.color,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                fontSize: isTotal ? 16 : 14
            )
        ),
        Text(value,
            style: TextStyle(
                color: isTotal ? context.theme.primaryColor : context.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                fontSize: isTotal ? 18 : 15
            )
        ),
      ],
    );
  }
}

class InvoiceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const InvoiceRow({
    super.key,
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: context.textTheme.bodyMedium?.color, fontSize: 14)),
        Text(value,
            style: TextStyle(
                color: context.textTheme.bodyLarge?.color,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontSize: 14
            )
        ),
      ],
    );
  }
}