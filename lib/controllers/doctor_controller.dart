import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// === 1. موديل بيانات الطبيب ===
class DoctorModel {
  final int id;
  final int departmentId;
  final String firstName;
  final String lastName;
  final int experienceYears;
  final String education;
  final String? profilePicture; 
  final double rating;
  final String fee;

  DoctorModel({
    required this.id,
    required this.departmentId,
    required this.firstName,
    required this.lastName,
    required this.experienceYears,
    required this.education,
    this.profilePicture,
    required this.rating,
    required this.fee,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'] ?? 0,
      departmentId: json['department_id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      experienceYears: json['experience_years'] ?? 0,
      education: json['education'] ?? '',
      profilePicture: json['profile_picture'], 
      // الـ rating بالبوست مان null، لهيك عطيناه قيمة 4.5 افتراضية من الديزاين
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : 4.5, 
      fee: json['fee'] ?? '0',
    );
  }

  // ميثود مدمجة ليعطينا الاسم الكامل فورا Dr. Rania Yassin
  String get fullName => 'Dr. $firstName $lastName';
}

// === 2. كونترولر جلب البيانات والربط بالباك ===
class DoctorController extends GetxController {
  var isLoading = true.obs;
  var doctorsList = <DoctorModel>[].obs;

  // ملاحظة: إذا عم تجربي على محاكي أندرويد حطي الـ IP هاد 10.0.2.2 بدل localhost
  final String baseUrl = "http://127.0.0.1:8000/api"; 

  void fetchDoctors(int departmentId) async {
    try {
      isLoading(true);
      
      // الرابط الديناميكي اللي بياخد الـ ID تبع القسم المكبوس
      var url = Uri.parse('$baseUrl/departments/$departmentId/doctors'); 
      
      var response = await http.get(url, headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
      });

      if (response.statusCode == 200) {
        List responseData = json.decode(response.body);
        // تحويل المصفوفة القادمة من الباك لموديلات Dart وتخزينها
        doctorsList.value = responseData.map((doc) => DoctorModel.fromJson(doc)).toList();
      } else {
        Get.snackbar("Server Error", "Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
      Get.snackbar("Connection Error", "Check your backend server");
    } finally {
      isLoading(false);
    }
  }
}