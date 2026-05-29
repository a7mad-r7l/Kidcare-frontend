import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileCard extends StatelessWidget {
  final String name;
  final String email;
  final String imageUrl;
  final VoidCallback onViewProfile;

  const ProfileCard({
    super.key,
    required this.name,
    required this.email,
    required this.imageUrl,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF2FA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(radius: 35, backgroundImage: NetworkImage(imageUrl)),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D2755),
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onViewProfile,
                  child: Row(
                    children: [
                      Text(
                        'view_profile'.tr,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.blue,
                        size: 12,
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
