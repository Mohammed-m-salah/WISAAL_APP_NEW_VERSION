import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WelcomeMessageWidget extends StatefulWidget {
  final VoidCallback onTap;
  final String userName;

  const WelcomeMessageWidget({
    super.key,
    required this.onTap,
    required this.userName,
  });

  @override
  State<WelcomeMessageWidget> createState() => _WelcomeMessageWidgetState();
}

class _WelcomeMessageWidgetState extends State<WelcomeMessageWidget>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _pulseController;
  late AnimationController _dropController;
  late AnimationController _floatController;

  late Animation<double> _waveAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _dropAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _opacityAnimation;

  bool _isDropping = false;

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _waveAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
    _waveController.repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Float animation (up and down)
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _floatController.repeat(reverse: true);

    // Drop animation
    _dropController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _dropAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _dropController, curve: Curves.easeInBack),
    );
    _opacityAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _dropController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    _dropController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _handleTap() async {
    if (_isDropping) return;

    setState(() => _isDropping = true);

    _waveController.stop();
    _pulseController.stop();
    _floatController.stop();

    await _dropController.forward();

    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final isMediumScreen = size.width < 600;

    final emojiSize = isSmallScreen ? 50.0 : (isMediumScreen ? 65.0 : 80.0);
    final containerPadding =
        isSmallScreen ? 16.0 : (isMediumScreen ? 24.0 : 32.0);
    final titleSize = isSmallScreen ? 18.0 : (isMediumScreen ? 22.0 : 26.0);
    final subtitleSize = isSmallScreen ? 13.0 : (isMediumScreen ? 15.0 : 17.0);
    final buttonPaddingH =
        isSmallScreen ? 20.0 : (isMediumScreen ? 28.0 : 36.0);
    final buttonPaddingV =
        isSmallScreen ? 10.0 : (isMediumScreen ? 14.0 : 16.0);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _waveAnimation,
        _pulseAnimation,
        _dropAnimation,
        _floatAnimation,
      ]),
      builder: (context, child) {
        final dropOffset = _dropAnimation.value * size.height * 0.5;
        final rotation = _dropAnimation.value * math.pi * 0.5;
        final scale = 1 - (_dropAnimation.value * 0.3);
        final opacity = _opacityAnimation.value;

        return Transform.translate(
          offset: Offset(0, _isDropping ? dropOffset : _floatAnimation.value),
          child: Transform.rotate(
            angle: _isDropping ? rotation : 0,
            child: Transform.scale(
              scale: _isDropping ? scale : 1,
              child: Opacity(
                opacity: opacity,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.08,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _handleTap,
                          child: ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              padding: EdgeInsets.all(containerPadding),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    theme.colorScheme.primary.withOpacity(0.2),
                                    theme.colorScheme.secondary
                                        .withOpacity(0.15),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.2),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                  BoxShadow(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                    blurRadius: 60,
                                    spreadRadius: 20,
                                  ),
                                ],
                              ),
                              child: Transform.rotate(
                                angle: _waveAnimation.value,
                                child: Text(
                                  '👋',
                                  style: TextStyle(fontSize: emojiSize),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: size.height * 0.03),
                        Text(
                          'say_hello_to'.trParams({'name': widget.userName}),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: size.height * 0.01),
                        Text(
                          'start_conversation'.tr,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: subtitleSize,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: size.height * 0.04),
                        GestureDetector(
                          onTap: _handleTap,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(
                              horizontal: buttonPaddingH,
                              vertical: buttonPaddingV,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primary.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.waving_hand_rounded,
                                  color: Colors.white,
                                  size: isSmallScreen ? 18 : 22,
                                ),
                                SizedBox(width: isSmallScreen ? 6 : 10),
                                Text(
                                  'tap_to_wave'.tr,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: size.height * 0.02),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.touch_app_rounded,
                              size: isSmallScreen ? 14 : 16,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.4),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'or_tap_emoji'.tr,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 13,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
