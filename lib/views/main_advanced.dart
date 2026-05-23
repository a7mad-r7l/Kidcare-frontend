import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PediatricClinicScreen extends StatefulWidget {
  final bool hasToken;
  const PediatricClinicScreen({Key? key, this.hasToken= false}) : super(key: key);

  @override
  State<PediatricClinicScreen> createState() => _PediatricClinicScreenState();
}

class _PediatricClinicScreenState extends State<PediatricClinicScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _doctorController;
  late AnimationController _floatingController;
  late AnimationController _textController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _logoRotationAnimation;

  late Animation<Offset> _doctorSlideAnimation;
  late Animation<double> _doctorOpacityAnimation;

  late Animation<Offset> _floatingAnimation;

  late Animation<double> _textOpacityAnimation;
  late Animation<double> _textScaleAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    _logoRotationAnimation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _textController,
          curve: const Interval(0.4, 1.0, curve: Curves.easeIn)),
    );

    _textScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
          parent: _textController,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack)),
    );

    _doctorController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _doctorSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _doctorController, curve: Curves.easeOutCubic),
    );

    _doctorOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _doctorController, curve: Curves.easeIn),
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnimation =
        Tween<Offset>(
                begin: const Offset(0, -0.015), end: const Offset(0, 0.015))
            .animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _logoController.forward().then((_) => _textController.forward());

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _doctorController.forward();
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        widget.hasToken
            ? Get.offAllNamed('/home')   // ✅ يوجه لـ home إذا يوجد Token
            : Get.offAllNamed('/login'); // ✅ يوجه لـ login إذا لا يوجد Token
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _doctorController.dispose();
    _floatingController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade100,
                    Colors.white,
                    Colors.blue.shade50,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -50,
            right: -50,
            child: _buildBackgroundCircle(150, Colors.blue.withOpacity(0.1)),
          ),
          Positioned(
            bottom: 100,
            left: -30,
            child: _buildBackgroundCircle(100, Colors.pink.withOpacity(0.05)),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Center(
                    child: FadeTransition(
                      opacity: _logoOpacityAnimation,
                      child: ScaleTransition(
                        scale: _logoScaleAnimation,
                        child: RotationTransition(
                          turns: _logoRotationAnimation,
                          child: SlideTransition(
                            position: _floatingAnimation,
                            child: Hero(
                              tag: 'logo',
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.1),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/images/pediatric_clinic_logo.png',
                                  width: 140,
                                  height: 140,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: FadeTransition(
                      opacity: _textOpacityAnimation,
                      child: ScaleTransition(
                        scale: _textScaleAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Kidcare',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: Colors.blue.shade800,
                                shadows: [
                                  Shadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    offset: const Offset(2, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Premium Pediatric Care',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue.shade400,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Center(
                    child: FadeTransition(
                      opacity: _doctorOpacityAnimation,
                      child: SlideTransition(
                        position: _doctorSlideAnimation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Image.asset(
                            'assets/images/doctor_and_children.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
