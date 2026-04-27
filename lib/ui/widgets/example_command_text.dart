import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/app_colors.dart';
import 'package:sos1/utils/app_language_provider.dart';
import 'package:provider/provider.dart';

class ExampleCommandText extends StatelessWidget {
  const ExampleCommandText({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(builder: (context, languageProvider, child)
    {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 30.w),
        child: Column(
          children: [
            // Example command text with highlighted word
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: languageProvider.translate('example'),
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 400.ms)
                .slideY(begin: 0.3, end: 0, duration: 600.ms, delay: 400.ms),

            SizedBox(height: 20.h),

            // Animated dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(0),
                SizedBox(width: 6.w),
                _buildDot(150),
                SizedBox(width: 6.w),
                _buildDot(300),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildDot(int delayMs) {
    return Container(
      width: 6.w,
      height: 6.w,
      decoration: const BoxDecoration(
        color: AppColors.primaryRed,
        shape: BoxShape.circle,
      ),
    )
    .animate(
      onPlay: (controller) => controller.repeat(reverse: true),
    )
    .scale(
      begin: const Offset(0.6, 0.6),
      end: const Offset(1.2, 1.2),
      duration: 800.ms,
      delay: Duration(milliseconds: delayMs),
      curve: Curves.easeInOut,
    )
    .fade(
      begin: 0.4,
      end: 1.0,
      duration: 800.ms,
      delay: Duration(milliseconds: delayMs),
    );
  }
}
