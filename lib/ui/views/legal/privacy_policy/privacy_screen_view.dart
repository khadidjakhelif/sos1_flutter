import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';
import '../../../../utils/app_language_provider.dart';
import 'privacy_policy_viewmodel.dart';
import 'package:provider/provider.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<PrivacyPolicyViewModel>.reactive(
      viewModelBuilder: () => PrivacyPolicyViewModel(),
      builder: (context, viewModel, child) =>
          Scaffold(
            body: Column(
              children: [
                SizedBox(height: 30,),
                _buildHeader(viewModel),

                Expanded(
                  child: Consumer<LanguageProvider>(
                    builder: (context, lp, child) => SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Colors.black, Colors.red[700]!]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.security, size: 64, color: Colors.white),
                                const SizedBox(height: 12),
                                Text(
                                  lp.translate('app_name'),
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  lp.translate('privacy_subtitle'),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Data collected
                          _buildSection(
                            context,
                            lp.translate('data_collected'),
                            [
                              _buildDataRow(Icons.mic,          lp.translate('data_voice'),      lp.translate('data_voice_sub')),
                              _buildDataRow(Icons.location_on,  lp.translate('data_location'),   lp.translate('data_location_sub')),
                              _buildDataRow(Icons.history,      lp.translate('data_history'),    lp.translate('data_history_sub')),
                              _buildDataRow(Icons.close,        lp.translate('data_name_phone'), lp.translate('data_name_phone_sub')),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // What we DON'T do
                          _buildWarningCard(context, [
                            lp.translate('no_ads'),
                            lp.translate('no_data_sale'),
                            lp.translate('no_tracking'),
                            lp.translate('local_storage'),
                          ]),

                          const SizedBox(height: 20),

                          // Rights
                          _buildSection(
                            context,
                            lp.translate('your_rights'),
                            [
                              _buildRightRow(Icons.delete,           lp.translate('right_delete')),
                              _buildRightRow(Icons.download,         lp.translate('right_export')),
                              _buildRightRow(Icons.location_disabled, lp.translate('right_location_off')),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Contact
                          _buildContactCard(context, lp),

                          const SizedBox(height: 32),

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

  Widget _buildHeader(PrivacyPolicyViewModel viewModel) {
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
              lp.translate('privacy_policy'),
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

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w100)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard(BuildContext context, List<String> warnings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: warnings.map((warning) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(Icons.block, color: Colors.red[400], size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(warning)),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildRightRow(IconData icon, String right) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green[600]),
          const SizedBox(width: 12),
          Text(right, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, LanguageProvider lp) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lp.translate('contact_us'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('support@sosalgerie.app'),
            const SizedBox(height: 8),
            Text(
              lp.translate('contact_project'),
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              lp.translate('last_updated'),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
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