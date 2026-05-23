import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/HomeChildModel.dart';

class ChildProfileView extends StatelessWidget {
  const ChildProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ استقبال الـ child من الـ arguments
    final HomeChildModel child = Get.arguments as HomeChildModel;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Child Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2E5A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Color(0xFF1A2E5A), size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // ─── Info Card ────────────────────────────
            _InfoCard(child: child),
            const SizedBox(height: 16),

            // ─── Stats Card ───────────────────────────
            const _StatsCard(),
            const SizedBox(height: 16),

            // ─── Allergies Card ───────────────────────
            const _AllergiesCard(),
            const SizedBox(height: 16),

            // ─── Action Buttons ───────────────────────
            _ActionButton(
              icon: Icons.vaccines_outlined,
              label: 'Vaccination Record',
              color: Colors.blue,
              onTap: () {
                // TODO: Get.toNamed('/vaccinations', arguments: child.id)
              },
            ),
            const SizedBox(height: 10),
            _ActionButton(
              icon: Icons.calendar_today_outlined,
              label: 'Appointments',
              color: Colors.blue,
              onTap: () {
                // TODO: Get.toNamed('/previous-appointments', arguments: child.id)
              },
            ),
            const SizedBox(height: 10),
            _ActionButton(
              icon: Icons.medical_information_outlined,
              label: 'Medical Prescriptions',
              color: Colors.blue,
              onTap: () {
                // TODO: Get.toNamed('/prescriptions', arguments: child.id)
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ─── Info Card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final HomeChildModel child;

  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // ✅ صورة الطفل من السيرفر
          CircleAvatar(
            radius: 55,
            backgroundColor: Colors.white,
            backgroundImage: (child.image != null && child.image!.isNotEmpty)
                ? NetworkImage(child.image!)
                : null,
            child: (child.image == null || child.image!.isEmpty)
                ? Icon(Icons.person,
                color: Colors.grey.shade300, size: 55)
                : null,
          ),
          const SizedBox(width: 20),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ✅ الاسم من الـ API
              Text(
                child.name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2E5A),
                ),
              ),
              const SizedBox(height: 6),
              // ✅ العمر من الـ API
              Text(
                '${child.age} years',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 6),
              // TODO: أضف gender للـ API لاحقاً
              const Row(
                children: [
                  Text(
                    'Male',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.male,
                      color: Color(0xFF4CAF50), size: 18),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Stats Card ───────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  const _StatsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
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
              value: 'O+', // TODO: من الـ API
              label: 'Blood Type',
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.straighten_outlined,
              value: '95 cm', // TODO: من الـ API
              label: 'Height',
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.monitor_weight_outlined,
              value: '11 kg', // TODO: من الـ API
              label: 'Weight',
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
        Icon(icon, color: const Color(0xFF4CAF50), size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2E5A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 60, color: Colors.grey.shade200);
  }
}

// ─── Allergies Card ───────────────────────────────────────────────────────────

class _AllergiesCard extends StatelessWidget {
  const _AllergiesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // ✅
        children: [
          const Text(
            'Allergies',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2E5A),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              textAlign: TextAlign.left, // ✅
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ✅ الأيقونة والنص على اليسار
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2E5A),
                  ),
                ),
              ],
            ),
            // ✅ السهم على اليمين
            const Icon(Icons.chevron_right,
                color: Color(0xFF1A2E5A), size: 22),
          ],
        ),
      ),
    );
  }
}