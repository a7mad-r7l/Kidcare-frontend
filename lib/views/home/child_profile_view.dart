import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/home/child_profile_controller.dart';
import '../../models/appointment/child_model.dart';
import '../../widgets/custom_text_field.dart';
import '../growth/child_growth_tab_view.dart';

class ChildProfileView extends GetView<ChildProfileController> {
  const ChildProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final RxBool isGrowthTab = true.obs;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Child Profile'.tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textTheme.bodyLarge?.color,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.iconColor, size: 20),
          onPressed: () => Get.back(),
        ),
        // ─── إضافة زر التعديل هنا ───
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: context.theme.primaryColor),
            onPressed: () {
              final child = controller.child.value;
              if (child != null) {
                Get.bottomSheet(
                  _EditChildSheet(child: child),
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                );
              }
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: context.theme.primaryColor),
          );
        }

        final child = controller.child.value;
        if (child == null) {
          return Center(
            child: Text(
              'Failed to load profile'.tr,
              style: TextStyle(color: context.textTheme.bodyMedium?.color),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _InfoCard(child: child),
            ),
            const SizedBox(height: 16),

            // Tabs Switcher
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: context.theme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => isGrowthTab.value = true,
                        child: Obx(
                              () => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isGrowthTab.value
                                  ? Colors.green
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.show_chart_rounded,
                                  color: isGrowthTab.value
                                      ? Colors.white
                                      : Colors.grey,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Growth Chart & Weight'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isGrowthTab.value
                                        ? Colors.white
                                        : context.textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => isGrowthTab.value = false,
                        child: Obx(
                              () => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !isGrowthTab.value
                                  ? context.theme.primaryColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  color: !isGrowthTab.value
                                      ? Colors.white
                                      : Colors.grey,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Appointments & Files'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: !isGrowthTab.value
                                        ? Colors.white
                                        : context.textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: Obx(() {
                if (isGrowthTab.value) {
                  return ChildGrowthTabView(childId: controller.childId);
                } else {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    child: Column(
                      children: [
                        _StatsCard(child: child),
                        const SizedBox(height: 16),
                        if (child.medicalHistory != null &&
                            child.medicalHistory!.isNotEmpty) ...[
                          _DataCard(
                            title: 'Medical History'.tr,
                            content: child.medicalHistory!,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (child.allergies != null &&
                            child.allergies!.isNotEmpty) ...[
                          _DataCard(
                            title: 'Allergies'.tr,
                            content: child.allergies!,
                          ),
                          const SizedBox(height: 16),
                        ],
                        _ActionButton(
                          icon: Icons.vaccines_outlined,
                          label: 'Vaccination Record'.tr,
                          color: context.theme.primaryColor,
                          onTap: () =>
                              Get.toNamed('/vaccinations', arguments: child.id),
                        ),
                        const SizedBox(height: 10),
                        _ActionButton(
                          icon: Icons.calendar_today_outlined,
                          label: 'Appointments'.tr,
                          color: context.theme.primaryColor,
                          onTap: () =>
                              Get.toNamed('/appointments', arguments: child.id),
                        ),
                        const SizedBox(height: 16),
                        // زر الحذف
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: controller.isLoading
                                ? null
                                : () => Get.dialog(
                              AlertDialog(
                                backgroundColor: context.theme.cardColor,
                                title: Text(
                                  'Delete Child'.tr,
                                  style: TextStyle(
                                    color: context.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                content: Text(
                                  'Are you sure you want to delete this child profile? This action cannot be undone.'.tr,
                                  style: TextStyle(
                                    color: context.textTheme.bodyMedium?.color,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Get.back(),
                                    child: Text('Cancel'.tr),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Get.back();
                                      controller.deleteCurrentChild();
                                    },
                                    child: Text(
                                      'Delete'.tr,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            icon: controller.isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                            label: Text(
                              controller.isLoading
                                  ? 'Deleting...'.tr
                                  : 'Delete Child Profile'.tr,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: controller.isLoading
                                  ? Colors.grey
                                  : Colors.red.shade400,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  );
                }
              }),
            ),
          ],
        );
      }),
    );
  }
}


class _EditChildSheet extends StatefulWidget {
  final ChildModel child;
  const _EditChildSheet({required this.child});

  @override
  State<_EditChildSheet> createState() => _EditChildSheetState();
}

class _EditChildSheetState extends State<_EditChildSheet> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _medicalHistoryController;
  late TextEditingController _allergiesController;

  String _selectedGender = 'male';
  String _selectedBloodType = '';
  String _selectedBirthDate = '';
  File? _selectedImage;

  final List<String> bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.child.firstName);
    _lastNameController = TextEditingController(text: widget.child.lastName);
    _medicalHistoryController = TextEditingController(text: widget.child.medicalHistory ?? '');
    _allergiesController = TextEditingController(text: widget.child.allergies ?? '');

    _selectedGender = widget.child.gender.toLowerCase() == 'female' ? 'female' : 'male';
    _selectedBloodType = widget.child.bloodType ?? '';

    final d = widget.child.birthDate;
    _selectedBirthDate = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _medicalHistoryController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _pickBirthDate(BuildContext context) async {
    final now = DateTime.now();
    final earliestAllowedDate = DateTime(now.year - 6, now.month, now.day);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.child.birthDate.isBefore(earliestAllowedDate) ? earliestAllowedDate : widget.child.birthDate,
      firstDate: earliestAllowedDate,
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _selectedBirthDate = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _onSave() {
    final controller = Get.find<ChildProfileController>();
    controller.updateChildData(
      fields: {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'gender': _selectedGender,
        'birth_date': _selectedBirthDate,
        'blood_type': _selectedBloodType,
        'medical_history': _medicalHistoryController.text.trim(),
        'allergies': _allergiesController.text.trim(),
      },
      image: _selectedImage,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 إعطاء النافذة ارتفاع ثابت (85% من الشاشة) لحماية التصميم من الانضغاط
    final sheetHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ─── القسم العلوي الثابت (لا يتأثر بالتمرير) ───
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: context.theme.dividerColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Edit Profile'.tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 16),

          // ─── القسم القابل للتمرير (يحتوي على مساحة ديناميكية للوحة المفاتيح) ───
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
                // 🌟 هذا السطر يرفع المحتوى للأعلى تلقائياً عند ظهور لوحة المفاتيح
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // تعديل الصورة
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: context.theme.cardColor,
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!) as ImageProvider
                                : (widget.child.image != null && widget.child.image!.isNotEmpty
                                ? NetworkImage(widget.child.image!)
                                : null),
                            child: _selectedImage == null && (widget.child.image == null || widget.child.image!.isEmpty)
                                ? Icon(Icons.person, color: context.theme.dividerColor, size: 50)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: context.theme.primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: context.theme.scaffoldBackgroundColor, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // الاسم الأول والأخير
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _firstNameController,
                          hintText: 'First Name'.tr,
                          label: 'First Name'.tr,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: _lastNameController,
                          hintText: 'Last Name'.tr,
                          label: 'Last Name'.tr,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // الجنس
                  Text(
                    'Gender'.tr,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedGender = 'female'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedGender == 'female'
                                  ? (context.isDarkMode ? Colors.pinkAccent.withValues(alpha: 0.15) : const Color(0xFFFCE4EC))
                                  : context.theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedGender == 'female' ? Colors.pinkAccent : context.theme.dividerColor,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.face_3, color: _selectedGender == 'female' ? Colors.pinkAccent : Colors.grey, size: 20),
                                const SizedBox(width: 6),
                                Text('Female'.tr, style: TextStyle(color: _selectedGender == 'female' ? Colors.pinkAccent : Colors.grey, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedGender = 'male'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedGender == 'male'
                                  ? (context.isDarkMode ? Colors.blue.withValues(alpha: 0.15) : const Color(0xFFE3F2FD))
                                  : context.theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedGender == 'male' ? Colors.blue : context.theme.dividerColor,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.face, color: _selectedGender == 'male' ? Colors.blue : Colors.grey, size: 20),
                                const SizedBox(width: 6),
                                Text('Male'.tr, style: TextStyle(color: _selectedGender == 'male' ? Colors.blue : Colors.grey, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // تاريخ الميلاد
                  Text(
                    'Birth Date'.tr,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickBirthDate(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      decoration: BoxDecoration(
                        color: context.theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.theme.dividerColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedBirthDate,
                            style: TextStyle(fontSize: 14, color: context.textTheme.bodyLarge?.color),
                          ),
                          const Icon(Icons.calendar_today_outlined, color: Colors.blue, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // فصيلة الدم
                  Text(
                    'Blood Type'.tr,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: context.theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.theme.dividerColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: context.theme.cardColor,
                        value: _selectedBloodType.isEmpty ? null : _selectedBloodType,
                        hint: Text('Select blood type'.tr, style: TextStyle(color: context.textTheme.bodyMedium?.color, fontSize: 14)),
                        items: bloodTypes.map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type, style: TextStyle(color: context.textTheme.bodyLarge?.color)),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedBloodType = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // التاريخ الطبي
                  Text(
                    'Medical History'.tr,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _medicalHistoryController,
                    maxLines: 2,
                    style: TextStyle(color: context.textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: "Enter child's medical history".tr,
                      hintStyle: TextStyle(color: context.textTheme.bodyMedium?.color, fontSize: 13),
                      filled: true,
                      fillColor: context.theme.cardColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.theme.dividerColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.theme.dividerColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // الحساسية
                  Text(
                    'Allergies'.tr,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _allergiesController,
                    maxLines: 2,
                    style: TextStyle(color: context.textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: "Enter any allergies the child has".tr,
                      hintStyle: TextStyle(color: context.textTheme.bodyMedium?.color, fontSize: 13),
                      filled: true,
                      fillColor: context.theme.cardColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.theme.dividerColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.theme.dividerColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // زر الحفظ
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.theme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _onSave,
                      child: Text(
                        'Save'.tr,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── باقي الأكواد المساعدة الخاصة بالواجهة لم يتم المساس بها ───
class _InfoCard extends StatelessWidget {
  final ChildModel child;

  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? Colors.green.withValues(alpha: 0.15)
            : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: context.theme.scaffoldBackgroundColor,
            backgroundImage: (child.image != null && child.image!.isNotEmpty)
                ? NetworkImage(child.image!)
                : null,
            child: (child.image == null || child.image!.isEmpty)
                ? Icon(Icons.person, color: context.theme.dividerColor, size: 55)
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.fullName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: context.textTheme.bodyLarge?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '${child.ageNumber} ${child.ageType.tr}',
                  style: TextStyle(
                    fontSize: 16,
                    color: context.textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      child.gender.toLowerCase() == 'female' ? Icons.female : Icons.male,
                      color: Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      child.gender.tr.capitalizeFirst ?? '',
                      style: const TextStyle(fontSize: 16, color: Colors.green),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final ChildModel child;

  const _StatsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.transparent
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.water_drop_outlined,
              value: child.bloodType ?? 'N/A',
              label: 'Blood Type'.tr,
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.calendar_month_outlined,
              value: '${child.ageNumber}',
              label: 'Age'.tr,
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _StatItem(
              icon: child.gender.toLowerCase() == 'female'
                  ? Icons.female
                  : Icons.male,
              value: child.gender.tr.capitalizeFirst ?? '',
              label: 'Gender'.tr,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 60, color: context.theme.dividerColor);
  }
}

class _DataCard extends StatelessWidget {
  final String title;
  final String content;

  const _DataCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.transparent
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: context.textTheme.bodyMedium?.color,
                height: 1.5,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: context.isDarkMode
                  ? Colors.transparent
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.chevron_right,
              color: context.textTheme.bodyLarge?.color,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}