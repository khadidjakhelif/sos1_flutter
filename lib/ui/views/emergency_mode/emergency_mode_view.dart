import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart'; // NEW — for timestamp formatting
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

            // Dispatch failure banner (shown after all retries fail)
            if (viewModel.reportStatus == EmergencyReportStatus.failed)
              _buildDispatchFailureBanner(),

            // Auto-call countdown (shown only while countdown is running)
            if (viewModel.countdownSeconds != null)
              _buildAutoCallCountdown(viewModel),

            // Resolution banner — shown when officer resolves from dashboard
            if (viewModel.resolution != null)
              _buildResolutionBanner(viewModel),

            // NEW: "Are you OK?" ping prompt from the officer
            if (viewModel.pendingPing != null)
              _buildPingPrompt(viewModel),

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

  // ── Dispatch failure banner ─────────────────────────────────────────────
  Widget _buildDispatchFailureBanner() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFF3E1A00),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFFF6D00), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off, color: const Color(0xFFFF6D00), size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DISPATCH INJOIGNABLE',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFFF6D00),
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "Serveur non joignable après 3 tentatives. "
                  "Suivez les instructions de l'assistant. "
                  "Appel des secours automatique en cours...",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.orange.shade200,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .slideY(begin: -0.3, end: 0, duration: 350.ms, curve: Curves.easeOut)
        .fadeIn(duration: 300.ms);
  }

  // ── Auto-call countdown widget ─────────────────────────────────────────
  Widget _buildAutoCallCountdown(EmergencyModeViewModel viewModel) {
    final seconds = viewModel.countdownSeconds!;
    final number = viewModel.pendingCallNumber ?? '14';

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0000),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE53935), width: 1.5),
      ),
      child: Row(
        children: [
          // Countdown circle
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE53935), width: 2),
            ),
            child: Center(
              child: Text(
                '$seconds',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFE53935),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Appel du $number dans $seconds s...',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          // Cancel button
          GestureDetector(
            onTap: viewModel.cancelCountdown,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Colors.white30),
              ),
              child: Text(
                'ANNULER',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1000.ms, color: Colors.red.withOpacity(0.15));
  }

  // NEW: resolution banner displayed when the safety officer resolves the emergency
  Widget _buildResolutionBanner(EmergencyModeViewModel viewModel) {
    final resolution = viewModel.resolution!;

    // Format the resolved timestamp if available
    String timeLabel = '';
    if (resolution.resolvedAt != null) {
      timeLabel = DateFormat('HH:mm').format(resolution.resolvedAt!.toLocal());
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF4CAF50), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status row
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 18.sp,
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .scaleXY(begin: 1.0, end: 1.12, duration: 900.ms, curve: Curves.easeInOut)
                  .then()
                  .scaleXY(begin: 1.12, end: 1.0, duration: 900.ms, curve: Curves.easeInOut),
              SizedBox(width: 10.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'URGENCE RÉSOLUE',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withOpacity(0.8),
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    resolution.responderLabel,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // ETA chip
              if (resolution.etaMinutes != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'ETA ${resolution.etaMinutes} min',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),

          // Timestamp row
          if (timeLabel.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.white54, size: 12.sp),
                SizedBox(width: 4.w),
                Text(
                  'Résolu à $timeLabel',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ],

          // Notes row
          if (resolution.notes != null && resolution.notes!.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              resolution.notes!,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    )
        .animate()
        .slideY(begin: -0.3, end: 0, duration: 400.ms, curve: Curves.easeOut)
        .fadeIn(duration: 300.ms);
  }

  // NEW: "Are you OK?" ping prompt shown when the officer sends a check-in ping
  Widget _buildPingPrompt(EmergencyModeViewModel viewModel) {
    return _PingPromptBanner(
      ping: viewModel.pendingPing!,
      onAcknowledge: viewModel.acknowledgePing,
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
          final message =
              viewModel.messages[viewModel.messages.length - 1 - index];
          return _buildMessageBubble(message, viewModel, index == 0);
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, EmergencyModeViewModel viewModel, bool isLatest) {
    final isWorker = message.senderRole == 'worker';
    final isOfficer = message.senderRole == 'safety_officer';
    final isSystem = message.senderRole == 'system';
    final isUser = isWorker; // Aliased for distant code compat

    if (isSystem) {
      return Align(
        alignment: Alignment.center,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 20.w),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            message.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ).animate().fadeIn(duration: 300.ms);
    }

    Color bgColor = isWorker
        ? Colors.white.withOpacity(0.9)
        : isOfficer
            ? const Color(0xFF1565C0) // Officer blue
            : Colors.grey.withOpacity(0.3); // AI dark grey

    Color textColor = isWorker ? const Color(0xFFB71C1C) : Colors.white;

    return Align(
      alignment: isWorker ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12.h,
          left: isWorker ? 60.w : 0,
          right: isWorker ? 0 : 60.w,
        ),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
            bottomLeft: Radius.circular(isWorker ? 20.r : 4.r),
            bottomRight: Radius.circular(isWorker ? 4.r : 20.r),
          ),
          border: message.isImportant
              ? Border.all(color: Colors.white, width: 2)
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isOfficer)
                    Container(
                      margin: EdgeInsets.only(bottom: 6.h),
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.security, color: Colors.white, size: 12.sp),
                          SizedBox(width: 4.w),
                          Text(
                            'OFFICIER SÉCURITÉ',
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                      color: textColor,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            if (!isUser && isLatest)
              Padding(
                padding: EdgeInsets.only(left: 12.w),
                child: GestureDetector(
                  onTap: viewModel.isSpeaking ? viewModel.stopSpeaking : null,
                  child: viewModel.isSpeaking
                      ? Icon(
                          Icons.volume_up_rounded,
                          color: Colors.white.withOpacity(0.9),
                          size: 22.sp,
                        )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .fade(begin: 0.5, end: 1.0, duration: 800.ms)
                      : Icon(
                          Icons.volume_off_rounded,
                          color: Colors.white.withOpacity(0.5),
                          size: 22.sp,
                        ),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(
          begin: isWorker ? 0.2 : -0.2,
          end: 0,
        );
  }

  Widget _buildQuickActions(BuildContext context, EmergencyModeViewModel viewModel) {
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
          SizedBox(
            width: 8,
          ),
          _buildMicButton(viewModel),
          SizedBox(
            width: 8,
          ),
          // Officer button removed because chat is unified
          _buildQuickActionButton(
            icon: Icons.skip_next,
            label: 'ÉTAPE SUIV',
            onTap: viewModel.nextStep,
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
              color:
                  isListening ? Colors.white : Colors.white.withOpacity(0.15),
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
              color: isListening ? const Color(0xFFB71C1C) : Colors.white,
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
              color: isListening ? Colors.white : Colors.white.withOpacity(0.8),
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
  EmergencyModeViewModel viewModelBuilder(BuildContext context) =>
      EmergencyModeViewModel();

  @override
  void onViewModelReady(EmergencyModeViewModel viewModel) {
    viewModel.initialize(
      emergencyType: emergencyType,
      emergencyDescription: emergencyDescription,
      location: location,
    );
  }
}

// ─── Ping Prompt Banner ────────────────────────────────────────────────────────

/// Stateful widget that shows a 60-second countdown for the officer's
/// "are you OK?" ping. Tapping the acknowledge button calls [onAcknowledge].
/// When the countdown expires the banner auto-dismisses (the backend already
/// logged the unanswered ping — the viewmodel clears pendingPing via the timer
/// expiry so the conditional in the view removes this widget).
class _PingPromptBanner extends StatefulWidget {
  final dynamic ping; // PingEvent
  final Future<void> Function() onAcknowledge;

  const _PingPromptBanner({
    required this.ping,
    required this.onAcknowledge,
  });

  @override
  State<_PingPromptBanner> createState() => _PingPromptBannerState();
}

class _PingPromptBannerState extends State<_PingPromptBanner> {
  late int _secondsLeft;
  Timer? _countdown;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.ping.windowSeconds as int? ?? 60;
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          t.cancel();
          // The viewmodel will clear pendingPing when it detects the window
          // expired — no forced rebuild needed here.
        }
      });
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A2C00), Color(0xFF7B4500)],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFFFB300), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withOpacity(0.35),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Pulsing bell icon
              Icon(Icons.notifications_active, color: const Color(0xFFFFB300), size: 22.sp)
                  .animate(onPlay: (c) => c.repeat())
                  .scaleXY(begin: 1.0, end: 1.15, duration: 600.ms)
                  .then()
                  .scaleXY(begin: 1.15, end: 1.0, duration: 600.ms),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'L\'officier demande: Êtes-vous OK?',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              // Countdown circle
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFB300), width: 2),
                ),
                child: Center(
                  child: Text(
                    '$_secondsLeft',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFFFB300),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: () async {
              _countdown?.cancel();
              await widget.onAcknowledge();
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Text(
                  '✅  JE SUIS OK',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .slideY(begin: -0.3, end: 0, duration: 350.ms, curve: Curves.easeOut)
        .fadeIn(duration: 300.ms);
  }
}
