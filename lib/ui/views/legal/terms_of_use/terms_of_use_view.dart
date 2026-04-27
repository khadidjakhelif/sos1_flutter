import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';
import '../../../../utils/app_colors.dart';
import 'terms_of_use_viewmodel.dart';
import 'package:sos1/utils/app_language_provider.dart';
import 'package:provider/provider.dart';

class TermsOfUseView extends ViewModelBuilderWidget<TermsOfUseViewModel> {
  const TermsOfUseView({Key? key}) : super(key: key);

  @override
  TermsOfUseViewModel viewModelBuilder(BuildContext context) => TermsOfUseViewModel();

  @override
  Widget builder(BuildContext context, TermsOfUseViewModel viewModel, Widget? child) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(viewModel),

            Expanded(
              child: Consumer<LanguageProvider>(
                builder: (context, lp, child) => SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.black, Colors.red[900]!]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.description, size: 64, color: Colors.white),
                            const SizedBox(height: 12),
                            Text(
                              lp.translate('app_name'),
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              lp.translate('terms_of_use'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Emergency numbers
                      _buildEmergencyNumbersCard(context, lp),

                      const SizedBox(height: 24),

                      // Disclaimer
                      _buildDisclaimerCard(context, lp),

                      const SizedBox(height: 20),

                      // Responsibilities
                      _buildResponsibilitiesCard(context, lp),

                      const SizedBox(height: 20),

                      // BBA Footer
                      _buildBbaFooter(context, lp),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(TermsOfUseViewModel viewModel) {
    return Consumer<LanguageProvider>(builder: (context, lp, child) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Row(
          children: [
            GestureDetector(
              onTap: viewModel.goBack,
              child: Row(
                children: [
                  Icon(Icons.arrow_back_ios, color: Colors.white, size: 20.sp),
                  SizedBox(width: 4.w),
                  Text(
                    lp.translate('back'),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              lp.translate('terms_of_use'),
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            SizedBox(width: 80.w),
          ],
        ),
      );
    });
  }

  // ── helpers — UI unchanged, only strings swapped ──────────────────────────

  Widget _buildEmergencyNumbersCard(BuildContext context, LanguageProvider lp) {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.local_phone, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              lp.translate('emergency_numbers_title'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildEmergencyButton('SAMU', '15', Colors.blue[700]!),
                _buildEmergencyButton(lp.translate('police'), '17', Colors.green[700]!),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildEmergencyButton(lp.translate('fire_department'), '14', Colors.orange[700]!),
                _buildEmergencyButton(lp.translate('civil_protection'), '14', Colors.red[700]!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyButton(String label, String number, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildDisclaimerCard(BuildContext context, LanguageProvider lp) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber[800], size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    lp.translate('disclaimer_title'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.amber[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              lp.translate('disclaimer_body'),
              style: const TextStyle(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsibilitiesCard(BuildContext context, LanguageProvider lp) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lp.translate('responsibilities_title'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              lp.translate('responsibilities_body'),
              style: const TextStyle(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBbaFooter(BuildContext context, LanguageProvider lp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                child: Image.asset(
                  'assets/images/bba_logo.png',
                  height: 32,
                  width: 32,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.blue[600]!, Colors.blue[800]!]),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school, color: Colors.white, size: 16),
                    );
                  },
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lp.translate('footer_project'),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      lp.translate('footer_university'),
                      style: TextStyle(color: Colors.blueGrey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              lp.translate('footer_credits'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.blueGrey),
            ),
          ),
        ],
      ),
    );
  }
}