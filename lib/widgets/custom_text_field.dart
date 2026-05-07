import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isPassword;
  final TextInputType keyboardType;
  final Widget? suffixIcon;       // used by login (eye toggle as sole suffix)
  final Widget? prefixIconWidget; // used by sign-up password fields (eye toggle on left)
  final String? label;            // sign-up: label text rendered in suffix
  final IconData? labelIcon;      // sign-up: icon rendered next to label

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.prefixIconWidget,
    this.label,
    this.labelIcon,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasLabel = label != null;

    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: prefixIconWidget,
        suffixIconConstraints: hasLabel
            ? const BoxConstraints(minHeight: 0, minWidth: 0)
            : null,
        suffixIcon: hasLabel
            ? Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label!,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87),
                    ),
                    if (labelIcon != null) ...[
                      const SizedBox(width: 8),
                      Icon(labelIcon, color: Colors.grey.shade500, size: 20),
                    ],
                  ],
                ),
              )
            : suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const PrimaryButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(text,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
    );
  }
}

class OutlinedPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const OutlinedPrimaryButton(
      {super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.blue,
          side: const BorderSide(color: Colors.blue),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onPressed,
        child: Text(text,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
