import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/vaccines/vaccines_controller.dart';
import '../../widgets/vaccines/available_vaccines_list.dart';
import '../../widgets/vaccines/history_vaccines_list.dart';
import '../../widgets/vaccines/vaccine_child_header.dart';
import '../../widgets/vaccines/vaccine_tabs.dart';

class VaccinesView extends GetView<VaccinesController> {
  const VaccinesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Vaccinations'.tr,
          style: TextStyle(
            color: context.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: context.theme.iconTheme.color,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          const VaccineChildHeader(),
          const SizedBox(height: 16),
          const VaccineTabs(),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (controller.isLoading &&
                  controller.availableSchedules.isEmpty &&
                  controller.historyRecords.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(
                    color: context.theme.primaryColor,
                  ),
                );
              }

              return RefreshIndicator(
                color: context.theme.primaryColor,
                onRefresh: controller.refreshData,
                child: controller.selectedTab.value == 0
                    ? const AvailableVaccinesList()
                    : const HistoryVaccinesList(),
              );
            }),
          ),
        ],
      ),
    );
  }
}
