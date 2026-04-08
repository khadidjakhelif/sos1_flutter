import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'emergency_mode_viewmodel.dart';
import '../../../services/ai_emergency_assistant.dart';

class EmergencyModeView extends StackedView<EmergencyModeViewModel> {
  final String emergencyType;
  final String? emergencyDescription;
  final String? location;


   const EmergencyModeView({
    super.key,
    required this.emergencyType,
    this.emergencyDescription,
    this.location,
  });


  @override
  Widget builder(
    BuildContext context,
    EmergencyModeViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(0, 0, 0, 1),
      body: SafeArea(
        child: Column(
          children: [
            // Emergency Header
            _buildEmergencyHeader(viewModel),

            // Chat Messages
            Expanded(
              child: _buildChatArea(viewModel),
            ),

            // Quick Actions
            _buildQuickActions(viewModel),

            // Input Area
            _buildInputArea(viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyHeader(EmergencyModeViewModel viewModel) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            const Color.fromRGBO(0, 0, 0, 1),
            const Color(0xFFB71C1C),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row
          Row(
            children: [
              // Emergency Icon
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.emergency,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),

              // Emergency Type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MODE URGENCE',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      viewModel.emergencyType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Timer
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      viewModel.formattedElapsedTime,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Progress Indicator
          if (viewModel.isEmergencyActive)
            LinearProgressIndicator(
              value: viewModel.currentStepIndex / 6, // Approximate total steps
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 4.h,
            ),
        ],
      ),
    );
  }

  Widget _buildChatArea(EmergencyModeViewModel viewModel) {
    return Container(
      color: const Color.fromRGBO(0, 0, 0, 1),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        reverse: true,
        itemCount: viewModel.messages.length,
        itemBuilder: (context, index) {
          final message = viewModel.messages[viewModel.messages.length - 1 - index];
          return _buildMessageBubble(message);
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12.h,
          left: isUser ? 60.w : 0,
          right: isUser ? 0 : 60.w,
        ),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.white.withOpacity(0.9)
              : Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
            bottomLeft: Radius.circular(isUser ? 20.r : 4.r),
            bottomRight: Radius.circular(isUser ? 4.r : 20.r),
          ),
          border: message.isImportant
              ? Border.all(color: Colors.white, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isStep)
              Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'ÉTAPE ${message.stepNumber}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            Text(
              message.text,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: isUser ? const Color(0xFFB71C1C) : Colors.white,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 300.ms)
      .slideX(
        begin: isUser ? 0.2 : -0.2,
        end: 0,
      );
  }

  Widget _buildQuickActions(EmergencyModeViewModel viewModel) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFF8B0000),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickActionButton(
            icon: Icons.phone,
            label: 'APPEL SECOURS',
            onTap: viewModel.callEmergencyServices,
          ),
          _buildQuickActionButton(
            icon: Icons.location_on,
            label: 'PARTAGER POS',
            onTap: viewModel.shareLocation,
          ),

          SizedBox(width: 8,),

          _buildMicButton(viewModel),

          SizedBox(width: 8,),

          _buildQuickActionButton(
            icon: Icons.skip_next,
            label: 'ÉTAPE SUIVANTE',
            onTap: viewModel.nextStep,
          ),
          _buildQuickActionButton(
            icon: Icons.repeat,
            label: 'RÉPÉTER',
            onTap: viewModel.repeatStep,
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton(EmergencyModeViewModel viewModel) {
    final isListening = viewModel.isListening;

    return GestureDetector(
      onTap: viewModel.toggleListening,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulse ring when active
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isListening ? 56.w : 48.w,
            height: isListening ? 56.w : 48.w,
            decoration: BoxDecoration(
              color: isListening
                  ? Colors.white
                  : Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(isListening ? 28.r : 12.r),
              boxShadow: isListening
                  ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 4,
                ),
              ]
                  : [],
            ),
            child: Icon(
              isListening ? Icons.mic : Icons.mic_none,
              color: isListening
                  ? const Color(0xFFB71C1C)
                  : Colors.white,
              size: 24.sp,
            ),
          )
              .animate(
            onPlay: (controller) =>
            isListening ? controller.repeat() : controller.reset(),
          )
              .scaleXY(
            begin: 1.0,
            end: isListening ? 1.08 : 1.0,
            duration: 600.ms,
            curve: Curves.easeInOut,
          )
              .then()
              .scaleXY(
            begin: 1.08,
            end: 1.0,
            duration: 600.ms,
            curve: Curves.easeInOut,
          ),
          SizedBox(height: 6.h),
          Text(
            isListening ? 'ÉCOUTE...' : 'MICRO',
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              color: isListening
                  ? Colors.white
                  : Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(EmergencyModeViewModel viewModel) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF8B0000),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // End Emergency Button
          GestureDetector(
            onTap: viewModel.endEmergency,
            child: Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // Text Input
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: TextField(
                controller: viewModel.textController,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'Répondez ou dites "suivant"...',
                  hintStyle: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                ),
                onSubmitted: (text) {
                  final trimmed = text.trim();
                  if (trimmed.isNotEmpty) {
                    viewModel.sendMessage(trimmed);
                    viewModel.textController.clear();
                  }
                },
                textInputAction: TextInputAction.send,
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // Send Button
          GestureDetector(
            onTap: () {
              print('🔘 SEND BUTTON TAPPED');
              final text = viewModel.textController.text.trim();
              print('📝 Text: "$text"');
              if (text.isNotEmpty) {
                print('✅ Sending...');
                viewModel.sendMessage(text);
                viewModel.textController.clear();
              } else {
                print('❌ Empty text');
              }
            },
            child: Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.send,
                color: const Color(0xFFB71C1C),
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  EmergencyModeViewModel viewModelBuilder(BuildContext context) => EmergencyModeViewModel();

  @override
  void onViewModelReady(EmergencyModeViewModel viewModel) {
    viewModel.initialize(
      emergencyType: emergencyType,
      emergencyDescription: emergencyDescription,
      location: location,
    );
  }
}
