import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainBottomNav extends StatelessWidget {
  final int currentIndex;

  const MainBottomNav({super.key, required this.currentIndex});

  static const List<_NavItem> _items = [
    _NavItem(label: 'More', icon: Icons.more_horiz, route: '/more'),
    _NavItem(label: 'Records', icon: Icons.folder_outlined, route: '/records'),
    _NavItem(label: 'Home', icon: Icons.home_rounded, route: '/home'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        // ─── لون الخلفية متكيف (ليلي/نهاري) ───
        color: context.theme.cardColor,
        boxShadow: [
          // إخفاء الظل في الوضع الليلي لمظهر أنظف
          if (!context.isDarkMode)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _items.asMap().entries.map((entry) {
          final bool isSelected = entry.key == currentIndex;
          final item = entry.value;

          // تحديد الألوان بناءً على الحالة والوضع الليلي
          final Color activeColor = context.theme.primaryColor;
          final Color inactiveColor = context.theme.dividerColor;

          return GestureDetector(
            onTap: () {
              if (isSelected) return;
              Get.offAllNamed(item.route);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 26,
                ),
                const SizedBox(height: 4),
                Text(
                  item.label.tr,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? activeColor : inactiveColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String route;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}