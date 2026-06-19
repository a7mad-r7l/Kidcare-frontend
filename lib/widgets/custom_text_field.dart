import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isPassword;
  final TextInputType keyboardType;

  // Eye icon on the right
  final Widget? suffixIcon;

  // Extra widget if needed
  final Widget? prefixIconWidget;

  // Label + icon
  final String? label;
  final IconData? labelIcon;

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
    final isRtl = Get.locale?.languageCode == 'ar';

    // ─── استخراج الثيم المحلي بدلاً من الجلوبال ───
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      textAlign: isRtl ? TextAlign.right : TextAlign.left,
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,

      // ─── ضبط لون النص المكتوب ───
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          // ─── ضبط لون التلميح (Hint) ───
          color: theme.textTheme.bodyMedium?.color ?? theme.hintColor,
          fontSize: 13,
        ),

        // LEFT SIDE (Label + Icon)
        prefixIconConstraints: hasLabel
            ? const BoxConstraints(minHeight: 0, minWidth: 0)
            : null,

        prefixIcon: hasLabel
            ? Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            children: [
              if (labelIcon != null) ...[
                Icon(
                  labelIcon,
                  // ─── ضبط لون أيقونة الـ Label ───
                  color: theme.iconTheme.color,
                  size: 20,
                ),
                const SizedBox(width: 8),
              ],

              Text(
                label!,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  // ─── ضبط لون نص الـ Label ───
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),

              const SizedBox(width: 12),
            ],
          ),
        )
            : prefixIconWidget,

        // RIGHT SIDE (Password eye icon)
        suffixIcon: suffixIcon,

        filled: true,
        // ─── قراءة لون الخلفية من الثيم المحلي ───
        fillColor: theme.scaffoldBackgroundColor,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            // ─── ضبط لون الإطار الطبيعي ───
            color: theme.dividerColor,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            // ─── ضبط لون الإطار المفعل ───
            color: theme.dividerColor,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            // ─── ضبط لون الإطار عند التركيز (Focus) ───
            color: theme.primaryColor,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          // ─── استخدام اللون الأساسي من الثيم المحلي ───
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class OutlinedPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const OutlinedPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          // ─── استخدام اللون الأساسي من الثيم المحلي ───
          foregroundColor: theme.primaryColor,
          side: BorderSide(color: theme.primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class OtpBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const OtpBox({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  State<OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<OtpBox> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.focusNode.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = widget.focusNode.hasFocus;
    final theme = Theme.of(context);

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        // ─── قراءة لون الصندوق المتكيف من الثيم المحلي ───
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          // ─── استخدام ألوان الثيم المحلي لتبديل الإطار عند التركيز ───
          color: isFocused ? theme.primaryColor : theme.dividerColor,
          width: isFocused ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          // ─── لون الرقم المدخل يتكيف مع الثيم المحلي ───
          color: theme.textTheme.bodyLarge?.color,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}