import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/app_colors.dart';

/// A premium 3D orb with sound wave ripple animations.
/// Tapping toggles listening mode with animated ripples expanding outward.
class SosOrb extends StatefulWidget {
  final bool isListening;
  final bool isProcessing;
  final VoidCallback onTap;

  const SosOrb({
    super.key,
    required this.isListening,
    required this.onTap,
    this.isProcessing = false,
  });

  @override
  State<SosOrb> createState() => _SosOrbState();
}

class _SosOrbState extends State<SosOrb> with TickerProviderStateMixin {
  late AnimationController _ripple1;
  late AnimationController _ripple2;
  late AnimationController _ripple3;
  late AnimationController _breathe;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();

    _ripple1 = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _ripple2 = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _ripple3 = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));

    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (widget.isListening) {
      _startRipples();
    }
  }

  void _startRipples() {
    _ripple1.repeat();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && widget.isListening) _ripple2.repeat();
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && widget.isListening) _ripple3.repeat();
    });
    _waveController.repeat();
  }

  void _stopRipples() {
    _ripple1.stop();
    _ripple2.stop();
    _ripple3.stop();
    _ripple1.reset();
    _ripple2.reset();
    _ripple3.reset();
    _waveController.stop();
    _waveController.reset();
  }

  @override
  void didUpdateWidget(SosOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening != oldWidget.isListening) {
      if (widget.isListening) {
        _startRipples();
      } else {
        _stopRipples();
      }
    }
  }

  @override
  void dispose() {
    _ripple1.dispose();
    _ripple2.dispose();
    _ripple3.dispose();
    _breathe.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orbSize = 200.w;

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: orbSize * 1.8,
        height: orbSize * 1.8,
        child: AnimatedBuilder(
          animation: Listenable.merge([_ripple1, _ripple2, _ripple3, _breathe, _waveController]),
          builder: (context, _) {
            final breatheScale = 1.0 + (_breathe.value * 0.03);

            return Stack(
              alignment: Alignment.center,
              children: [
                // ── Sound wave ripples (only when listening) ──
                if (widget.isListening) ...[
                  _buildRippleRing(_ripple1.value, orbSize, 0),
                  _buildRippleRing(_ripple2.value, orbSize, 1),
                  _buildRippleRing(_ripple3.value, orbSize, 2),
                ],

                // ── Ambient glow ──
                Container(
                  width: orbSize * 1.4,
                  height: orbSize * 1.4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (widget.isListening
                                ? AppColors.primaryRed
                                : AppColors.primaryRed.withOpacity(0.4))
                            .withOpacity(widget.isListening ? 0.35 : 0.15),
                        blurRadius: widget.isListening ? 80 : 50,
                        spreadRadius: widget.isListening ? 20 : 10,
                      ),
                    ],
                  ),
                ),

                // ── Sound wave bars (circular, around the orb) ──
                if (widget.isListening)
                  CustomPaint(
                    size: Size(orbSize * 1.35, orbSize * 1.35),
                    painter: _SoundWavePainter(
                      progress: _waveController.value,
                      color: AppColors.primaryRed,
                    ),
                  ),

                // ── Main 3D orb ──
                Transform.scale(
                  scale: breatheScale,
                  child: Container(
                    width: orbSize,
                    height: orbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.3, -0.4),
                        radius: 0.9,
                        colors: widget.isListening
                            ? [
                                const Color(0xFFFF6B6B),
                                const Color(0xFFE53935),
                                const Color(0xFFB71C1C),
                                const Color(0xFF7F0000),
                              ]
                            : [
                                const Color(0xFFEF5350),
                                const Color(0xFFD32F2F),
                                const Color(0xFFB71C1C),
                                const Color(0xFF880E0E),
                              ],
                        stops: const [0.0, 0.3, 0.7, 1.0],
                      ),
                      boxShadow: [
                        // Top-left highlight (3D illusion)
                        BoxShadow(
                          color: Colors.white.withOpacity(0.08),
                          blurRadius: 30,
                          offset: const Offset(-10, -10),
                        ),
                        // Bottom shadow (3D depth)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 40,
                          offset: const Offset(8, 16),
                        ),
                        // Red glow
                        BoxShadow(
                          color: AppColors.primaryRed.withOpacity(
                            widget.isListening ? 0.5 : 0.25,
                          ),
                          blurRadius: widget.isListening ? 60 : 30,
                          spreadRadius: widget.isListening ? 8 : 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Specular highlight (3D glass effect)
                        Positioned(
                          top: orbSize * 0.12,
                          left: orbSize * 0.18,
                          child: Container(
                            width: orbSize * 0.35,
                            height: orbSize * 0.2,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withOpacity(0.25),
                                  Colors.white.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Mic icon
                        Icon(
                          widget.isListening ? Icons.mic : Icons.mic_none_rounded,
                          color: Colors.white.withOpacity(0.95),
                          size: 56.sp,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Status text below orb ──
                Positioned(
                  bottom: orbSize * 0.15,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      widget.isProcessing
                          ? 'Analyse en cours...'
                          : widget.isListening
                              ? 'Je vous écoute...'
                              : 'Appuyez pour parler',
                      key: ValueKey(widget.isListening.toString() + widget.isProcessing.toString()),
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: widget.isListening
                            ? AppColors.primaryRed.withOpacity(0.9)
                            : AppColors.textMuted,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRippleRing(double value, double orbSize, int index) {
    final scale = 1.0 + (value * 0.6);
    final opacity = (1.0 - value) * 0.4;

    return Container(
      width: orbSize * scale,
      height: orbSize * scale,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primaryRed.withOpacity(opacity),
          width: 2.0 - (value * 1.2),
        ),
      ),
    );
  }
}

/// Custom painter that draws circular sound wave bars around the orb
class _SoundWavePainter extends CustomPainter {
  final double progress;
  final Color color;

  _SoundWavePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const barCount = 48;
    const barWidth = 2.5;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = barWidth
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < barCount; i++) {
      final angle = (2 * pi * i) / barCount;
      // Create a wave pattern that moves with progress
      final wavePhase = (progress * 2 * pi) + (i * 0.3);
      final amplitude = (sin(wavePhase) * 0.5 + 0.5) * 12.w;

      final innerPoint = Offset(
        center.dx + (radius - 8.w) * cos(angle),
        center.dy + (radius - 8.w) * sin(angle),
      );
      final outerPoint = Offset(
        center.dx + (radius - 8.w + amplitude) * cos(angle),
        center.dy + (radius - 8.w + amplitude) * sin(angle),
      );

      final barOpacity = (sin(wavePhase) * 0.3 + 0.5).clamp(0.15, 0.7);
      paint.color = color.withOpacity(barOpacity);

      canvas.drawLine(innerPoint, outerPoint, paint);
    }
  }

  @override
  bool shouldRepaint(_SoundWavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
