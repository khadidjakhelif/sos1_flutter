import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';
import 'sos_history_viewmodel.dart';
import '../../../utils/app_colors.dart';

class SOSHistoryView extends StackedView<SOSHistoryViewModel> {
  const SOSHistoryView({super.key});

  @override
  Widget builder(
    BuildContext context,
    SOSHistoryViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(viewModel),
            
            // Content
            Expanded(
              child: viewModel.incidents.isEmpty
                  ? Center(child: Text("Aucune urgence enregistrée.", style: TextStyle(color: Colors.white, fontSize: 16.sp)))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                      itemCount: viewModel.incidents.length,
                      itemBuilder: (context, index) {
                        final incident = viewModel.incidents[index];
                        final isResolved = incident.status == 'resolved';
                        
                        return Container(
                          margin: EdgeInsets.only(bottom: 16.h),
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: AppColors.surfaceLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    incident.type.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color: isResolved ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(
                                        color: isResolved ? Colors.green : Colors.orange,
                                      ),
                                    ),
                                    child: Text(
                                      isResolved ? 'RÉSOLUE' : incident.status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.bold,
                                        color: isResolved ? Colors.green : Colors.orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 14.sp, color: Colors.grey),
                                  SizedBox(width: 4.w),
                                  Text(
                                    "${incident.startedAt.day.toString().padLeft(2, '0')}/${incident.startedAt.month.toString().padLeft(2, '0')}/${incident.startedAt.year} à ${incident.startedAt.hour.toString().padLeft(2, '0')}:${incident.startedAt.minute.toString().padLeft(2, '0')}",
                                    style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                                  ),
                                ],
                              ),
                              if (incident.responderType != null) ...[
                                SizedBox(height: 8.h),
                                Row(
                                  children: [
                                    Icon(Icons.local_police, size: 14.sp, color: Colors.blue),
                                    SizedBox(width: 4.w),
                                    Text(
                                      "Intervenant: ${incident.responderType}",
                                      style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                                    ),
                                  ],
                                ),
                              ],
                              if (incident.etaMinutes != null) ...[
                                SizedBox(height: 8.h),
                                Row(
                                  children: [
                                    Icon(Icons.timer, size: 14.sp, color: Colors.orange),
                                    SizedBox(width: 4.w),
                                    Text(
                                      "ETA: ${incident.etaMinutes} min",
                                      style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                                    ),
                                  ],
                                ),
                              ],
                              if (incident.notes != null && incident.notes!.isNotEmpty) ...[
                                SizedBox(height: 12.h),
                                Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    incident.notes!,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13.sp,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(SOSHistoryViewModel viewModel) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: viewModel.goBack,
            child: Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          const Spacer(),
          Text(
            'HISTORIQUE',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          SizedBox(width: 24.w),
        ],
      ),
    );
  }

  @override
  SOSHistoryViewModel viewModelBuilder(BuildContext context) =>
      SOSHistoryViewModel();
}
