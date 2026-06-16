import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_textfield.dart';
import 'package:finalyearproject/core/styles/app_theme_extensions.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  /// Extracts the wait duration (in seconds) from a Supabase rate-limit message.
  /// Supabase typically returns: "...you can only request this after 60 seconds."
  int? _parseRateLimitSeconds(String message) {
    final match = RegExp(r'after (\d+) second').firstMatch(message);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
        redirectTo: 'io.supabase.sewasiswa://login-callback/',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailSent = true;
        });
        _animationController.reset();
        _animationController.forward();
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final seconds = e.statusCode == '429' ? _parseRateLimitSeconds(e.message) : null;
        final message = seconds != null
            ? 'Too many requests. Please wait $seconds seconds before trying again.'
            : e.message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: context.appColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('An unexpected error occurred. Please try again.'),
            backgroundColor: context.appColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: context.appColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: _emailSent ? _buildSuccessState() : _buildEmailForm(),
          ),
        ),
      ),
    );
  }

  /// ── Step 1: Email Entry Form ──────────────────────────────────────────────
  Widget _buildEmailForm() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon badge
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: context.appColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: context.appColors.primary.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                'Forgot Password?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: context.appColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle
              Text(
                "No worries! Enter your registered email and we'll send you a link to reset your password.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: context.appColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),

              // Email field
              CustomTextField(
                label: 'Email Address',
                hintText: 'e.g. yourname@student.utem.edu.my',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email address';
                  }
                  if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Send reset link button
              CustomButton(
                text: 'Send Reset Link',
                onPressed: _sendResetLink,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),

              // Back to login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Remember your password? ',
                    style: TextStyle(color: context.appColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: context.appColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ── Step 2: Success Confirmation ─────────────────────────────────────────
  Widget _buildSuccessState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Animated success icon
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: context.appColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.appColors.success.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.mark_email_read_rounded,
                    color: context.appColors.success,
                    size: 46,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Title
            Text(
              'Check Your Inbox',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Email sent to
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 15,
                  color: context.appColors.textSecondary,
                  height: 1.55,
                ),
                children: [
                  const TextSpan(text: 'A password reset link has been sent to\n'),
                  TextSpan(
                    text: _emailController.text.trim(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.appColors.primary,
                    ),
                  ),
                  const TextSpan(text: '\n\nPlease check your inbox and follow the link to reset your password.'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Spam notice
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: context.appColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.appColors.outlineVariant,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: context.appColors.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Don't see the email? Check your spam or junk folder.",
                      style: TextStyle(
                        fontSize: 13,
                        color: context.appColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Back to login button
            CustomButton(
              text: 'Back to Sign In',
              onPressed: () => context.go('/login'),
            ),
            const SizedBox(height: 16),

            // Resend option
            CustomButton(
              text: 'Resend Email',
              onPressed: () {
                setState(() => _emailSent = false);
                _animationController.reset();
                _animationController.forward();
              },
              isOutlined: true,
            ),
          ],
        ),
      ),
    );
  }
}
