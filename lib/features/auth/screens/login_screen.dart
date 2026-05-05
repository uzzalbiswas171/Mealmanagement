import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/services/auth_service.dart';
import '../widgets/auth_field.dart';
import 'auth_gate.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _loading = true);
    try {
      await AuthService.signIn(
        email: _emailCtrl.text,
        password: _passCtrl.text,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showError(AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      _showError('Enter your email first.');
      return;
    }
    try {
      await AuthService.sendPasswordReset(_emailCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Password reset email sent.',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white)),
        backgroundColor: AppColors.greenAccent,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!mounted) return;
      _showError(AuthService.friendlyError(e));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white)),
      backgroundColor: AppColors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // blue header
              Container(
                margin:EdgeInsets.only(top: 100),
                height: 240,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
                decoration: const BoxDecoration(
                  image: DecorationImage(image: AssetImage("assets/images/u_brand.png"),fit: BoxFit.fill),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryBlue,
                      AppColors.primaryBlueLight
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                // child: Column(
                //   children: [
                //     Container(
                //       width: 68,
                //       height: 68,
                //       decoration: BoxDecoration(
                //         color: Colors.white.withValues(alpha: 0.15),
                //         shape: BoxShape.circle,
                //       ),
                //       child: const Icon(Icons.restaurant_menu_rounded,
                //           color: Colors.white, size: 34),
                //     ),
                //     const SizedBox(height: 16),
                //     Text('Welcome Back',
                //         style: AppTextStyles.headingLarge.copyWith(
                //             color: Colors.white, fontSize: 24)),
                //     const SizedBox(height: 4),
                //     Text('Sign in to your mess account',
                //         style: AppTextStyles.bodyMedium
                //             .copyWith(color: Colors.white70)),
                //   ],
                // ),
              ),

              // form
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AuthField(
                        controller: _emailCtrl,
                        label: 'Email Address',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? 'Email is required'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      AuthField(
                        controller: _passCtrl,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscure,
                        suffix: IconButton(
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                        validator: (v) => (v?.isEmpty ?? true)
                            ? 'Password is required'
                            : null,
                      ),
                      // const SizedBox(height: 8),
                      // Align(
                      //   alignment: Alignment.centerRight,
                      //   child: TextButton(
                      //     onPressed: _forgotPassword,
                      //     child: Text('Forgot Password?',
                      //         style: AppTextStyles.bodySmall.copyWith(
                      //             color: AppColors.primaryBlue)),
                      //   ),
                      // ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : Text('Sign In',
                                  style: AppTextStyles.headingSmall
                                      .copyWith(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.center,
                      //   children: [
                      //     Text("Don't have an account?",
                      //         style: AppTextStyles.bodySmall),
                      //     TextButton(
                      //       onPressed: () => Navigator.pushReplacement(
                      //         context,
                      //         MaterialPageRoute(
                      //             builder: (_) => const RegisterScreen()),
                      //       ),
                      //       child: Text('Create Account',
                      //           style: AppTextStyles.headingSmall.copyWith(
                      //               color: AppColors.primaryBlue)),
                      //     ),
                      //   ],
                      // ),
                      // const SizedBox(height: 8),
                      // TextButton(
                      //   onPressed: () => Navigator.push(
                      //     context,
                      //     MaterialPageRoute(
                      //         builder: (_) => const DbCleanupScreen()),
                      //   ),
                      //   child: Text('Admin: Clear Database',
                      //       style: AppTextStyles.bodySmall.copyWith(
                      //           color: Colors.red.shade300)),
                      // ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
