import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/session_service.dart';
import '../../services/controller/login_controller.dart';

/// Self-contained design tokens for this screen — clean, minimal,
/// mint/teal "wellness" style with an organic blob header.
class _T {
  static const blobStart = Color(0xFF6BD9B4);
  static const blobEnd = Color(0xFF3EBE93);
  static const bg = Colors.white;
  static const textPrimary = Color(0xFF1F2A24);
  static const textSecondary = Color(0xFF8B9892);
  static const underline = Color(0xFFE1E5E3);
  static const underlineFocus = Color(0xFF3EBE93);
  static const buttonFill = Color(0xFFE9E6F4);
  static const buttonFillPressed = Color(0xFFDCD8ED);
  static const buttonText = Color(0xFF241F33);
  static const link = Color(0xFF3EBE93);
  static const error = Color(0xFFDC2626);
  static const errorBg = Color(0xFFFEF2F2);
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  late final LoginController controller;

  late final AnimationController _entrance;
  late final AnimationController _pulse;
  late final AnimationController _shake;

  late final Animation<double> _blobFade;
  late final Animation<double> _blobScale;
  late final Animation<Offset> _headingSlide;
  late final Animation<double> _headingFade;
  late final Animation<Offset> _fieldsSlide;
  late final Animation<double> _fieldsFade;
  late final Animation<double> _buttonFade;
  late final Animation<double> _buttonScale;

  final FocusNode _staffIdFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _staffIdHasFocus = false;
  bool _passwordHasFocus = false;
  bool _buttonPressed = false;

  Worker? _errorWorker;

  @override
  void initState() {
    super.initState();

    Get.put(SessionService(), permanent: true);
    controller = Get.put(LoginController(Get.find<SessionService>()));

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _blobFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _blobScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _headingFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
    );
    _headingSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _fieldsFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
    );
    _fieldsSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _buttonFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );
    _buttonScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _staffIdFocus.addListener(() {
      setState(() => _staffIdHasFocus = _staffIdFocus.hasFocus);
    });
    _passwordFocus.addListener(() {
      setState(() => _passwordHasFocus = _passwordFocus.hasFocus);
    });

    _errorWorker = ever<String>(controller.errorMessage, (msg) {
      if (msg.isNotEmpty) {
        _shake
          ..reset()
          ..forward();
      }
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    _shake.dispose();
    _staffIdFocus.dispose();
    _passwordFocus.dispose();
    _errorWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBlobHeader(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildField(
                      label: 'Staff ID',
                      controllerField: controller.staffIdController,
                      focusNode: _staffIdFocus,
                      hasFocus: _staffIdHasFocus,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_passwordFocus),
                    ),
                    const SizedBox(height: 26),
                    _buildPasswordField(),
                    const SizedBox(height: 34),
                    _buildLoginButton(),
                    const SizedBox(height: 16),
                    _buildForgotPassword(),
                    _buildErrorMessage(),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildFooter(),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlobHeader(BuildContext context) {
    return FadeTransition(
      opacity: _blobFade,
      child: ScaleTransition(
        scale: _blobScale,
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: 250,
          width: double.infinity,
          child: Stack(
            children: [
              ClipPath(
                clipper: _BlobClipper(),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_T.blobStart, _T.blobEnd],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 20,
                child: const Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              Positioned(
                top: 12,
                right: 20,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1.08).animate(
                    CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.22),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                bottom: 46,
                right: 24,
                child: SlideTransition(
                  position: _headingSlide,
                  child: FadeTransition(
                    opacity: _headingFade,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Welcome,',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'login to continue',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controllerField,
    required FocusNode focusNode,
    required bool hasFocus,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return SlideTransition(
      position: _fieldsSlide,
      child: FadeTransition(
        opacity: _fieldsFade,
        child: TextField(
          controller: controllerField,
          focusNode: focusNode,
          obscureText: obscureText,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: const TextStyle(fontSize: 15, color: _T.textPrimary),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: hasFocus ? _T.underlineFocus : _T.textSecondary,
            ),
            suffixIcon: suffixIcon,
            isDense: true,
            contentPadding: const EdgeInsets.only(bottom: 8),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: _T.underline, width: 1),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: _T.underlineFocus, width: 1.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Obx(
      () => _buildField(
        label: 'Password',
        controllerField: controller.passwordController,
        focusNode: _passwordFocus,
        hasFocus: _passwordHasFocus,
        obscureText: !controller.isPasswordVisible.value,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => controller.login(),
        suffixIcon: IconButton(
          icon: Icon(
            controller.isPasswordVisible.value
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: _T.textSecondary,
            size: 19,
          ),
          onPressed: controller.togglePasswordVisibility,
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return FadeTransition(
      opacity: _buttonFade,
      child: ScaleTransition(
        scale: _buttonScale,
        child: Center(
          child: Obx(
            () {
              final loading = controller.isLoading.value;
              return GestureDetector(
                onTapDown: loading
                    ? null
                    : (_) => setState(() => _buttonPressed = true),
                onTapUp: loading
                    ? null
                    : (_) => setState(() => _buttonPressed = false),
                onTapCancel: loading
                    ? null
                    : () => setState(() => _buttonPressed = false),
                onTap: loading ? null : controller.login,
                child: AnimatedScale(
                  scale: _buttonPressed ? 0.96 : 1.0,
                  duration: const Duration(milliseconds: 110),
                  curve: Curves.easeOut,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 190,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _buttonPressed
                          ? _T.buttonFillPressed
                          : _T.buttonFill,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: loading
                          ? const SizedBox(
                              key: ValueKey('loading'),
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _T.buttonText,
                                ),
                              ),
                            )
                          : const Text(
                              'Login',
                              key: ValueKey('label'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _T.buttonText,
                              ),
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return FadeTransition(
      opacity: _buttonFade,
      child: Center(
        child: TextButton(
          onPressed: controller.forgotPassword,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Forgot password?',
            style: TextStyle(
              color: _T.link,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
              decorationColor: _T.link,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Obx(() {
      final message = controller.errorMessage.value;
      return AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: message.isEmpty
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: const EdgeInsets.only(top: 18),
                child: AnimatedBuilder(
                  animation: _shake,
                  builder: (context, child) {
                    final offset = _shakeOffset(_shake.value) * 8;
                    return Transform.translate(
                      offset: Offset(offset, 0),
                      child: child,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _T.errorBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: _T.error,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(
                              color: _T.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      );
    });
  }

  Widget _buildFooter() {
    return FadeTransition(
      opacity: _buttonFade,
      child: Column(
        children: [
          SizedBox(
            height: 26,
            width: double.infinity,
            child: CustomPaint(
              painter: _PulseLinePainter(),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 90,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDE3E0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Version 1.0.0',
            style: TextStyle(
              color: _T.textSecondary.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Damped sine wave used to drive the error-card shake.
  double _shakeOffset(double t) {
    if (t <= 0 || t >= 1) return 0;
    final damping = 1 - t;
    return damping * math.sin(t * 4 * math.pi * 2.5);
  }
}

/// Organic blob silhouette for the header, echoing the reference
/// wellness-app design language.
class _BlobClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.78);
    path.quadraticBezierTo(
      size.width * 0.22,
      size.height,
      size.width * 0.52,
      size.height * 0.86,
    );
    path.quadraticBezierTo(
      size.width * 0.78,
      size.height * 0.72,
      size.width,
      size.height * 0.92,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// A faint decorative heartbeat / ECG line used at the bottom of the
/// screen, matching the pulse motif in the reference design.
class _PulseLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDCE8E2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final midY = size.height / 2;
    final path = Path()..moveTo(0, midY);

    final segment = size.width / 6;
    path.lineTo(segment * 1.4, midY);
    path.lineTo(segment * 1.7, midY - size.height * 0.35);
    path.lineTo(segment * 2.0, midY + size.height * 0.45);
    path.lineTo(segment * 2.3, midY - size.height * 0.6);
    path.lineTo(segment * 2.6, midY);
    path.lineTo(size.width, midY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}