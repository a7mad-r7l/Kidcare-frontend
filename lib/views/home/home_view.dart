import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kidcare/views/home/about_app_view.dart';
import '../../controllers/home/home_controller.dart';
import '../../models/home/home_child_model.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  static const List<Map<String, dynamic>> _departments = [
    {
      'label': 'General Pediatrics',
      'icon': Icons.medical_services_outlined,
      'color': Color(0xFFE3F2FD),
      'iconColor': Color(0xFF1E88E5),
      'route': '/choose-doctor',
      'specialty': 'General Pediatrics',
      'departmentId': 1,
    },
    {
      'label': 'Dental Care',
      'icon': Icons.medical_information_outlined,
      'color': Color(0xFFE3F2FD),
      'iconColor': Color(0xFF1E88E5),
      'route': '/choose-doctor',
      'specialty': 'Dental Care',
      'departmentId': 2,
    },
    {
      'label': 'Psychiatry',
      'icon': Icons.psychology_outlined,
      'color': Color(0xFFFCE4EC),
      'iconColor': Color(0xFFE91E63),
      'route': '/choose-doctor',
      'specialty': 'Psychiatry',
      'departmentId': 3,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // ❌ تم حذف backgroundColor من الـ Scaffold ليأخذ لون السمة تلقائياً
    return Scaffold(
      bottomNavigationBar: const _BottomNav(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeaderSection(),
              const SizedBox(height: 24),

              Obx(() {
                if (controller.isLoading) {
                  return const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.blue),
                    ),
                  );
                }
                if (controller.children.isEmpty) {
                  return SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.child_care,
                            size: 48,
                            color: context.theme.dividerColor,
                          ),
                          // لون أيقونة فارغ متكيف
                          const SizedBox(height: 8),
                          Text(
                            'No children added yet'.tr,
                            style: TextStyle(
                              color: context.textTheme.bodyMedium?.color,
                            ), // نص متكيف
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return _ChildrenSlider(children: controller.children);
              }),

              const SizedBox(height: 20),
              const _BookButton(),
              const SizedBox(height: 28),
              const _DepartmentsSection(departments: _departments),
              const SizedBox(height: 28),
              const _ClinicInfoSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _HeaderSection extends GetView<HomeController> {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Get.toNamed('/profile'),
                child: CircleAvatar(
                  radius: 26,
                  // لون خلفية ذكي بناءً على الوضع
                  backgroundColor: context.isDarkMode
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                  child: Icon(
                    Icons.person,
                    color: context.isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade500,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(
                    () => Text(
                      controller.parentName.value.isEmpty
                          ? 'Welcome!'.tr
                          : controller.parentName.value,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: context.textTheme.bodyLarge?.color, // نص متكيف
                      ),
                    ),
                  ),
                  Text(
                    'Welcome back!'.tr,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textTheme.bodyMedium?.color,
                    ), // نص ثانوي متكيف
                  ),
                ],
              ),
            ],
          ),
        ),
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_none_outlined,
                color: Color(0xFF1A2E5A),
              ),
              onPressed: () => Get.toNamed(
                '/notifications-history',
              ), // 🌟 التوجيه للشاشة التاريخية
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Children Slider ──────────────────────────────────────────────────────────

class _ChildrenSlider extends StatefulWidget {
  final List<HomeChildModel> children;

  const _ChildrenSlider({required this.children});

  @override
  State<_ChildrenSlider> createState() => _ChildrenSliderState();
}

class _ChildrenSliderState extends State<_ChildrenSlider> {
  final PageController _pageController = PageController(viewportFraction: 0.5);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.length == 1) {
      return Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: _ChildCard(child: widget.children.first),
            ),
          ),
          const Expanded(child: SizedBox()),
        ],
      );
    }

    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.children.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _ChildCard(child: widget.children[index]),
          );
        },
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final HomeChildModel child;

  const _ChildCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed('/child-profile', arguments: child),
      child: Container(
        decoration: BoxDecoration(
          // استخدام لون داكن للبطاقة في الوضع الليلي ليناسب اللون الأخضر
          color: context.isDarkMode
              ? const Color(0xFF1E3A2F)
              : const Color(0xFFD6F5D6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: context.theme.scaffoldBackgroundColor,
                  // خلفية متكيفة للصورة
                  backgroundImage:
                      (child.image != null && child.image!.isNotEmpty)
                      ? NetworkImage(child.image!)
                      : null,
                  child: (child.image == null || child.image!.isEmpty)
                      ? Icon(
                          Icons.person,
                          color: context.theme.dividerColor,
                          size: 40,
                        )
                      : null,
                ),
              ),
            ),
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    child.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textTheme.bodyLarge?.color, // نص متكيف
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${child.age} ${'years'.tr}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textTheme.bodyMedium?.color, // نص متكيف
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Book Button ──────────────────────────────────────────────────────────────

class _BookButton extends StatelessWidget {
  const _BookButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: () => Get.toNamed('/closest-appointments'),
        icon: const Icon(
          Icons.add_circle_outline,
          color: Colors.white,
          size: 22,
        ),
        label: Text(
          'Book New Appointment'.tr,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: context.theme.primaryColor,
          // استخدام اللون الأساسي للسمة
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

// ─── Departments ──────────────────────────────────────────────────────────────

class _DepartmentsSection extends StatelessWidget {
  final List<Map<String, dynamic>> departments;

  const _DepartmentsSection({required this.departments});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Departments'.tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textTheme.bodyLarge?.color, // نص متكيف
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: departments
              .map((dept) => _DepartmentItem(department: dept))
              .toList(),
        ),
      ],
    );
  }
}

class _DepartmentItem extends StatelessWidget {
  final Map<String, dynamic> department;

  const _DepartmentItem({required this.department});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.toNamed(
          department['route'],
          arguments: {
            'departmentId': department['departmentId'],
            'specialty': department['specialty'],
          },
        );
      },
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              // لون البطاقة يتكيف مع الوضع الليلي
              color: context.isDarkMode
                  ? context.theme.cardColor
                  : const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.isDarkMode
                    ? Colors.transparent
                    : Colors.blue.shade100,
              ),
            ),
            child: Icon(
              department['icon'] as IconData,
              color: department['iconColor'] as Color,
              size: 36,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            department['label'].toString().tr,
            style: TextStyle(
              fontSize: 12,
              color: context.textTheme.bodyLarge?.color,
            ),
            // نص متكيف
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Clinic Info ──────────────────────────────────────────────────────────────

class _ClinicInfoSection extends StatelessWidget {
  const _ClinicInfoSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? context.theme.cardColor
            : const Color(0xFFF0F4FF), // لون متكيف
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? Colors.blue.withValues(alpha: 0.1)
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.local_hospital_outlined,
              color: Colors.blue.shade300,
              size: 48,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About the Clinic'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textTheme.bodyLarge?.color, // متكيف
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We provide comprehensive healthcare for your children with the highest quality standards.'
                      .tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textTheme.bodyMedium?.color, // متكيف
                    height: 1.5,
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Get.to(() => const AboutAppView());
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Read More'.tr,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: context.theme.primaryColor,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Navigation ───────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.bottomNavigationBarTheme.backgroundColor,
        // لون الـ BottomNav من السمة
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.transparent
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home'.tr,
                isSelected: true,
                onTap: () {},
              ),
              _NavItem(
                icon: Icons.calendar_month_outlined,
                label: 'Appointments'.tr,
                isSelected: false,
                onTap: () => Get.toNamed('/appointments'),
              ),

              GestureDetector(
                onTap: () => Get.toNamed('/add-child'),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B9EFF), Color(0xFF1565C0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: context.isDarkMode
                            ? Colors.transparent
                            : const Color(0xFF3B9EFF).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),

              _NavItem(
                icon: Icons.vaccines_outlined,
                label: 'Vaccinations'.tr,
                isSelected: false,
                onTap: () => Get.find<HomeController>().onVaccinesTabTapped(),
              ),

              _NavItem(
                icon: Icons.more_horiz,
                label: 'More'.tr,
                isSelected: false,
                onTap: () => Get.toNamed('/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // الألوان المتكيفة للـ BottomNav
    final selectedColor =
        context.theme.bottomNavigationBarTheme.selectedItemColor;
    final unselectedColor =
        context.theme.bottomNavigationBarTheme.unselectedItemColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor?.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? selectedColor : unselectedColor,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? selectedColor : unselectedColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
