import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/app_colors.dart';

class MicButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onTap;

  const MicButton({
    super.key,
    required this.isListening,
    required this.onTap,
  });

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    if (widget.isListening) {
      _pulseController.repeat();
      _glowController.repeat();
    }
  }

  @override
  void didUpdateWidget(MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening != oldWidget.isListening) {
      if (widget.isListening) {
        _pulseController.repeat();
        _glowController.repeat();
      } else {
        _pulseController.stop();
        _glowController.stop();
        _pulseController.reset();
        _glowController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _glowController]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow rings
              if (widget.isListening) ...[
                _buildGlowRing(0.7, 0.1),
                _buildGlowRing(0.85, 0.15),
              ],
              
              // Main button container with gradient
              Container(
                width: 180.w,
                height: 180.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: AppColors.micButtonGradient,
                    center: Alignment.center,
                    radius: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryRed.withOpacity(
                        widget.isListening ? 0.6 : 0.3,
                      ),
                      blurRadius: widget.isListening ? 60 : 30,
                      spreadRadius: widget.isListening ? 20 : 10,
                    ),
                    BoxShadow(
                      color: AppColors.primaryRed.withOpacity(0.2),
                      blurRadius: 80,
                      spreadRadius: 40,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: 70.sp,
                  ),
                ),
              )
              .animate(target: widget.isListening ? 1 : 0)
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
                duration: 300.ms,
                curve: Curves.easeInOut,
              ),
              
              // Inner glow effect
              if (widget.isListening)
                Container(
                  width: 100.w,
                  height: 100.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGlowRing(double scale, double opacity) {
    final pulseValue = _pulseController.value;
    final animatedScale = scale + (pulseValue * 0.15);
    final animatedOpacity = opacity * (1 - pulseValue);
    
    return Container(
      width: 180.w * animatedScale,
      height: 180.w * animatedScale,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primaryRed.withOpacity(animatedOpacity),
          width: 2,
        ),
      ),
    );
  }
}
