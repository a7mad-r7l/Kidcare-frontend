import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLogout;
  final bool showDivider;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLogout = false,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          leading: Icon(
            icon,
            color: isLogout ? Colors.red : Colors.blue,
            size: 28,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isLogout ? Colors.red : const Color(0xFF1D2755),
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey,
          ),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.shade100,
            indent: 60,
            endIndent: 20,
          ),
      ],
    );
  }
}
