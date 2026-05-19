import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_language_provider.dart';
import '../../../services/api_service.dart';
import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _employeeIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyCodeController = TextEditingController();
  final _apiService = locator<ApiService>();
  final _navigationService = locator<NavigationService>();

  bool _isLoading = false;
  bool _showPassword = false;
  String? _errorMessage;
  bool _isLoginMode = true; // toggle login/register

  // Extra fields for registration
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  Future<void> _submit() async {
    if (_employeeIdController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _companyCodeController.text.isEmpty) {
      setState(() => _errorMessage = 'Veuillez remplir tous les champs obligatoires.');
      return;
    }

    if (!_isLoginMode && _fullNameController.text.isEmpty) {
      setState(() => _errorMessage = 'Veuillez entrer votre nom complet.');
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = 'Le mot de passe doit contenir au moins 6 caractères.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLoginMode) {
        await _apiService.login(
          employeeId: _employeeIdController.text.trim(),
          password: _passwordController.text,
          companyCode: _companyCodeController.text.trim(),
        );
      } else {
        await _apiService.register(
          fullName: _fullNameController.text.trim(),
          employeeId: _employeeIdController.text.trim(),
          password: _passwordController.text,
          phone: _phoneController.text.trim(),
          companyCode: _companyCodeController.text.trim(),
        );
      }
      // Navigate to main app
      _navigationService.navigateTo(Routes.voiceAssistantView);
    } on DioException catch (e) {
      setState(() {
        final data = e.response?.data;
        if (data is Map) {
          if (data['detail'] is List) {
            final firstError = data['detail'][0];
            _errorMessage = 'Erreur de saisie: ${firstError['loc'].last} - ${firstError['msg']}';
          } else {
            _errorMessage = data['message'] ?? data['detail']?.toString() ?? 'Erreur de connexion.';
          }
        } else {
          _errorMessage = 'Erreur de connexion. Vérifiez votre réseau.';
        }
      });
    } catch (e) {
      print('Unexpected error during registration/login: $e');
      setState(() => _errorMessage = 'Erreur inattendue: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, lp, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 28.w),
            child: Column(
              children: [
                SizedBox(height: 60.h),

                // Logo
                Icon(Icons.emergency, color: AppColors.primaryRed, size: 64.sp),
                SizedBox(height: 16.h),
                Text('SOS ALGÉRIE',
                    style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryRed,
                        letterSpacing: 3)),
                SizedBox(height: 8.h),
                Text('Système de gestion des urgences',
                    style:
                        TextStyle(fontSize: 13.sp, color: AppColors.textMuted)),

                SizedBox(height: 48.h),

                // Toggle Login/Register
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      _buildToggleButton('Connexion', _isLoginMode, () {
                        setState(() {
                          _isLoginMode = true;
                          _errorMessage = null;
                        });
                      }),
                      _buildToggleButton('Inscription', !_isLoginMode, () {
                        setState(() {
                          _isLoginMode = false;
                          _errorMessage = null;
                        });
                      }),
                    ],
                  ),
                ),

                SizedBox(height: 32.h),

                // Register-only fields
                if (!_isLoginMode) ...[
                  _buildField(_fullNameController, 'Nom complet', Icons.person),
                  SizedBox(height: 16.h),
                  _buildField(_phoneController, 'Téléphone', Icons.phone,
                      keyboardType: TextInputType.phone),
                  SizedBox(height: 16.h),
                ],

                // Common fields
                _buildField(
                    _employeeIdController, 'Matricule employé', Icons.badge),
                SizedBox(height: 16.h),
                _buildField(
                    _companyCodeController, 'Code entreprise', Icons.business,
                    hint: 'Ex: SONATRACH-2024'),
                SizedBox(height: 16.h),
                _buildPasswordField(),

                // Error message
                if (_errorMessage != null) ...[
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border:
                          Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: AppColors.error, size: 18.sp),
                        SizedBox(width: 8.w),
                        Expanded(
                            child: Text(_errorMessage!,
                                style: TextStyle(
                                    color: AppColors.error, fontSize: 13.sp))),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 32.h),

                // Submit button
                GestureDetector(
                  onTap: _isLoading ? null : _submit,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 18.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: AppColors.redGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primaryRed.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(
                              _isLoginMode
                                  ? 'Se connecter'
                                  : 'Créer mon compte',
                              style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                    ),
                  ),
                ),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryRed : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : AppColors.textMuted)),
        ),
      ),
    );
  }

  Widget _buildField(
      TextEditingController controller, String label, IconData icon,
      {String? hint, TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primaryRed.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 15.sp, color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20.sp),
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 14.sp),
          hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primaryRed.withOpacity(0.2)),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: !_showPassword,
        style: TextStyle(fontSize: 15.sp, color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.lock, color: AppColors.textMuted, size: 20.sp),
          labelText: 'Mot de passe',
          labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 14.sp),
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _showPassword = !_showPassword),
            child: Icon(_showPassword ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textMuted, size: 20.sp),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _passwordController.dispose();
    _companyCodeController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
