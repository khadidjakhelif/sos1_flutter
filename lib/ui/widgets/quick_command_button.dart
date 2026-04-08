import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/app_colors.dart';

class QuickCommandButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickCommandButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<QuickCommandButton> createState() => _QuickCommandButtonState();
}

class _QuickCommandButtonState extends State<QuickCommandButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        width: 100.w,
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: _isPressed 
            ? AppColors.surfaceLight 
            : AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: _isPressed 
              ? AppColors.primaryRed.withOpacity(0.5) 
              : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
            if (_isPressed)
              BoxShadow(
                color: AppColors.primaryRed.withOpacity(0.2),
                blurRadius: 12,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                widget.icon,
                color: AppColors.primaryRed,
                size: 28.sp,
              ),
            ),
            
            SizedBox(height: 12.h),
            
            // Label
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      )
      .animate(target: _isPressed ? 1 : 0)
      .scale(
        begin: const Offset(1, 1),
        end: const Offset(0.95, 0.95),
        duration: 100.ms,
      ),
    );
  }
}
