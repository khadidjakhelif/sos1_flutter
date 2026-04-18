import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'sos_history_viewmodel.dart';
import '../../../utils/app_colors.dart';
import '../../../models/sos_incident.dart';

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
            
            // Tab Bar
            _buildTabBar(viewModel),
            
            // Content
            Expanded(
              child: viewModel.incidents.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                      itemCount: viewModel.incidents.length,
                      itemBuilder: (context, index) {
                        return _buildIncidentCard(
                          viewModel.incidents[index],
                          viewModel,
                          index,
                        );
                      },
                    ),
            ),
            
            // Footer
            _buildFooter(),
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
            'SOS HISTORY',
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

  Widget _buildTabBar(SOSHistoryViewModel viewModel) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: viewModel.tabs.map((tab) {
          final isSelected = viewModel.selectedTab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () => viewModel.setTab(tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryRed : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  tab.displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textMuted,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate()
      .fadeIn(duration: 300.ms);
  }

  Widget _buildIncidentCard(SOSIncident incident, SOSHistoryViewModel viewModel, int index) {
    final isFirst = index == 0;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map Image / Header
          Container(
            height: 140.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  incident.type.color.withOpacity(0.3),
                  incident.type.color.withOpacity(0.1),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Map placeholder pattern
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.r),
                      topRight: Radius.circular(20.r),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://api.mapbox.com/styles/v1/mapbox/dark-v10/static/${incident.longitude},${incident.latitude},14,0/400x200?access_token=pk.placeholder',
                      ),
                      fit: BoxFit.cover,
                      opacity: 0.5,
                    ),
                  ),
                ),
                
                // SOS Triggered Badge (for first item)
                if (isFirst)
                  Positioned(
                    top: 12.h,
                    left: 12.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6.w,
                            height: 6.w,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'SOS TRIGGERED',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Location Pin
                Center(
                  child: Icon(
                    Icons.location_on,
                    color: incident.type.color,
                    size: 40.sp,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        incident.title,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: incident.type.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        incident.type.icon,
                        color: incident.type.color,
                        size: 24.sp,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 12.h),
                
                // Date & Time
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: AppColors.primaryRed,
                      size: 14.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '${incident.formattedDate} • ${incident.formattedTime}',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 8.h),
                
                // Location
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: AppColors.textMuted,
                      size: 14.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        incident.location,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16.h),
                
                // Action Button
                GestureDetector(
                  onTap: () => isFirst 
                      ? viewModel.viewDetails(incident.id)
                      : viewModel.reviewLog(incident.id),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    decoration: BoxDecoration(
                      color: isFirst ? Colors.white : AppColors.background,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isFirst ? Icons.visibility : Icons.refresh,
                          color: isFirst ? Colors.black : Colors.white,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          isFirst ? 'VIEW DETAILS' : 'REVIEW LOG',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: isFirst ? Colors.black : Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 400.ms, delay: Duration(milliseconds: index * 100))
      .slideY(begin: 0.2, end: 0);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            color: AppColors.textMuted,
            size: 64.sp,
          ),
          SizedBox(height: 16.h),
          Text(
            'Aucun historique',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Vos alertes SOS apparaîtront ici',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        // Red line
        Container(
          width: 40.w,
          height: 4.h,
          decoration: BoxDecoration(
            color: AppColors.primaryRed,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'END OF HISTORY',
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  @override
  SOSHistoryViewModel viewModelBuilder(BuildContext context) => SOSHistoryViewModel();

  @override
  void onViewModelReady(SOSHistoryViewModel viewModel) => viewModel.initialize();
}
