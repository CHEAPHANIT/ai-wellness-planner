import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'grocery_pdf_export_stub.dart'
    if (dart.library.html) 'grocery_pdf_export_web.dart'
    as grocery_pdf_export;

const _leaf = Color(0xFF0F8B5F);
const _leafDark = Color(0xFF0C3B2E);
const _mint = Color(0xFFE7F6EC);
const _amber = Color(0xFFF2A93B);
const _coral = Color(0xFFE76F51);
const _blue = Color(0xFF3178C6);

bool _isDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _appBackground(BuildContext context) =>
    _isDark(context) ? const Color(0xFF0F1513) : const Color(0xFFF5F7FA);

Color _appSurface(BuildContext context) =>
    _isDark(context) ? const Color(0xFF151D1A) : Colors.white;

Color _appSurfaceSoft(BuildContext context) =>
    _isDark(context) ? const Color(0xFF1B2521) : const Color(0xFFF0FAF5);

Color _appBorder(BuildContext context) =>
    _isDark(context) ? const Color(0xFF33413B) : const Color(0xFFD9E5DE);

Color _appText(BuildContext context) =>
    _isDark(context) ? const Color(0xFFF1F7F4) : const Color(0xFF111827);

Color _appMutedText(BuildContext context) =>
    _isDark(context) ? const Color(0xFFABBAB3) : const Color(0xFF667085);

String _titleCase(String value) {
  return value
      .trim()
      .split(RegExp(r'[\s_-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}

double _foodNumber(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _formatFoodNumber(double value) {
  if (value % 1 == 0) {
    return value.round().toString();
  }
  return value.toStringAsFixed(1);
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.apiClient,
    required this.onAuthenticated,
  });

  final ApiClient apiClient;
  final VoidCallback onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _register = false;
  bool _loading = false;
  bool _rememberMe = false;
  bool _showPassword = false;
  bool _showCreatePassword = false;
  bool _showConfirmPassword = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_register) {
        await widget.apiClient.register(
          email: _email.text.trim(),
          fullName: _name.text.trim(),
          password: _password.text,
          rememberMe: _rememberMe,
        );
      } else {
        await widget.apiClient.login(
          email: _email.text.trim(),
          password: _password.text,
          rememberMe: _rememberMe,
        );
      }
      widget.onAuthenticated();
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _setRegisterMode(bool value) {
    setState(() {
      _register = value;
      _error = null;
      if (value) {
        _name.clear();
        _email.clear();
        _password.clear();
        _confirmPassword.clear();
      } else if (_email.text.isEmpty && _password.text.isEmpty) {
        _name.text = 'Demo User';
        _email.text = 'demo@example.com';
        _password.text = 'password123';
        _confirmPassword.text = 'password123';
      }
    });
  }

  Future<void> _showPasswordResetDialog() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => _PasswordResetDialog(
        apiClient: widget.apiClient,
        initialEmail: _email.text.trim(),
      ),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Sign in again.')),
      );
      _password.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: _register ? const Color(0xFFF4F5F7) : const Color(0xFFF7FAF8),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 42),
              child: _register
                  ? _CreateAccountPage(
                      formKey: _formKey,
                      loading: _loading,
                      error: _error,
                      email: _email,
                      name: _name,
                      password: _password,
                      confirmPassword: _confirmPassword,
                      showPassword: _showCreatePassword,
                      showConfirmPassword: _showConfirmPassword,
                      onPasswordVisibilityChanged: () {
                        setState(
                          () => _showCreatePassword = !_showCreatePassword,
                        );
                      },
                      onConfirmPasswordVisibilityChanged: () {
                        setState(
                          () => _showConfirmPassword = !_showConfirmPassword,
                        );
                      },
                      onSignIn: () => _setRegisterMode(false),
                      onSubmit: _submit,
                    )
                  : _AuthForm(
                      formKey: _formKey,
                      register: _register,
                      loading: _loading,
                      rememberMe: _rememberMe,
                      showPassword: _showPassword,
                      error: _error,
                      email: _email,
                      name: _name,
                      password: _password,
                      onRememberChanged: (value) {
                        setState(() => _rememberMe = value ?? false);
                      },
                      onPasswordVisibilityChanged: () {
                        setState(() => _showPassword = !_showPassword);
                      },
                      onForgotPassword: _showPasswordResetDialog,
                      onRegisterChanged: (value) => _setRegisterMode(value),
                      onSubmit: _submit,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateAccountPage extends StatelessWidget {
  const _CreateAccountPage({
    required this.formKey,
    required this.loading,
    required this.error,
    required this.email,
    required this.name,
    required this.password,
    required this.confirmPassword,
    required this.showPassword,
    required this.showConfirmPassword,
    required this.onPasswordVisibilityChanged,
    required this.onConfirmPasswordVisibilityChanged,
    required this.onSignIn,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final bool loading;
  final String? error;
  final TextEditingController email;
  final TextEditingController name;
  final TextEditingController password;
  final TextEditingController confirmPassword;
  final bool showPassword;
  final bool showConfirmPassword;
  final VoidCallback onPasswordVisibilityChanged;
  final VoidCallback onConfirmPasswordVisibilityChanged;
  final VoidCallback onSignIn;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BrandMark(size: 46, flat: true),
          const SizedBox(height: 14),
          Text(
            'Join NutriAI',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: _leaf,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start your nutrition journey today!',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF667085)),
          ),
          const SizedBox(height: 22),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 26),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create Account',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF111827),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 22),
                    CreateAccountField(
                      controller: name,
                      label: 'Full Name',
                      hint: 'John Doe',
                      icon: Icons.person_outline,
                      validator: _required,
                    ),
                    const SizedBox(height: 16),
                    CreateAccountField(
                      controller: email,
                      label: 'Email Address',
                      hint: 'your.email@example.com',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      validator: _required,
                    ),
                    const SizedBox(height: 16),
                    CreateAccountField(
                      controller: password,
                      label: 'Password',
                      hint: 'Create a password',
                      icon: Icons.lock_outline,
                      obscureText: !showPassword,
                      suffixIcon: IconButton(
                        tooltip: showPassword
                            ? 'Hide password'
                            : 'Show password',
                        onPressed: onPasswordVisibilityChanged,
                        icon: Icon(
                          showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 8) {
                          return 'Use at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CreateAccountField(
                      controller: confirmPassword,
                      label: 'Confirm Password',
                      hint: 'Confirm your password',
                      icon: Icons.lock_outline,
                      obscureText: !showConfirmPassword,
                      suffixIcon: IconButton(
                        tooltip: showConfirmPassword
                            ? 'Hide password'
                            : 'Show password',
                        onPressed: onConfirmPasswordVisibilityChanged,
                        icon: Icon(
                          showConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (value != password.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 14),
                      ErrorBanner(message: error!),
                    ],
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: loading ? null : onSubmit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        backgroundColor: const Color(0xFF16A05D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Create Account',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF667085)),
              ),
              InkWell(
                onTap: onSignIn,
                borderRadius: BorderRadius.circular(4),
                child: Text(
                  'Sign in',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _leaf,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CreateAccountField extends StatelessWidget {
  const CreateAccountField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF8B95A1)),
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF98A2B3)),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: _leaf, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthForm extends StatelessWidget {
  const _AuthForm({
    required this.formKey,
    required this.register,
    required this.loading,
    required this.rememberMe,
    required this.showPassword,
    required this.error,
    required this.email,
    required this.name,
    required this.password,
    required this.onRememberChanged,
    required this.onPasswordVisibilityChanged,
    required this.onForgotPassword,
    required this.onRegisterChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final bool register;
  final bool loading;
  final bool rememberMe;
  final bool showPassword;
  final String? error;
  final TextEditingController email;
  final TextEditingController name;
  final TextEditingController password;
  final ValueChanged<bool?> onRememberChanged;
  final VoidCallback onPasswordVisibilityChanged;
  final VoidCallback onForgotPassword;
  final ValueChanged<bool> onRegisterChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BrandMark(size: 56, flat: true),
          const SizedBox(height: 16),
          Text(
            'Welcome to NutriAI',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF16A05D),
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your AI-powered nutrition companion',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF667085),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 38),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 20,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(38, 38, 38, 36),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Sign In',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF1F2937),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _LoginField(
                      controller: email,
                      icon: Icons.mail_outline,
                      label: 'Email Address',
                      hint: 'your.email@example.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: _required,
                    ),
                    const SizedBox(height: 24),
                    _LoginField(
                      controller: password,
                      icon: Icons.lock_open_outlined,
                      label: 'Password',
                      hint: 'Enter your password',
                      obscureText: !showPassword,
                      suffixIcon: IconButton(
                        tooltip: showPassword
                            ? 'Hide password'
                            : 'Show password',
                        onPressed: onPasswordVisibilityChanged,
                        icon: Icon(
                          showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 8) {
                          return 'Use at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: rememberMe,
                            onChanged: onRememberChanged,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: const BorderSide(
                              color: Color(0xFFCDD5DF),
                              width: 1.2,
                            ),
                            activeColor: const Color(0xFF16A05D),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Remember me',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF4B5563)),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: loading ? null : onForgotPassword,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF009A55),
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 14),
                      ErrorBanner(message: error!),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: loading ? null : onSubmit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(53),
                        backgroundColor: const Color(0xFF16A05D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                    const SizedBox(height: 36),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF667085)),
                        ),
                        InkWell(
                          onTap: () => onRegisterChanged(true),
                          borderRadius: BorderRadius.circular(4),
                          child: Text(
                            'Sign up',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: const Color(0xFF009A55),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: const Color(0xFF344054),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(fontSize: 16, color: Color(0xFF111827)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF98A2B3), fontSize: 16),
            prefixIcon: Icon(icon, size: 22, color: const Color(0xFF98A2B3)),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD9DEE7)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD9DEE7)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF16A05D),
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordResetDialog extends StatefulWidget {
  const _PasswordResetDialog({
    required this.apiClient,
    required this.initialEmail,
  });

  final ApiClient apiClient;
  final String initialEmail;

  @override
  State<_PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<_PasswordResetDialog> {
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _newPassword = TextEditingController();
  bool _loading = false;
  bool _otpVerified = false;
  String? _demoOtp;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email.text = widget.initialEmail;
  }

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (_email.text.trim().isEmpty) {
      setState(() => _error = 'Email is required');
      return;
    }
    await _run(() async {
      final result = await widget.apiClient.forgotPassword(_email.text.trim());
      _demoOtp = result['demo_otp']?.toString();
      _otpVerified = false;
      _message = _demoOtp == null
          ? result['message']?.toString()
          : 'Demo OTP: $_demoOtp';
    });
  }

  Future<void> _verifyOtp() async {
    if (_otp.text.trim().isEmpty) {
      setState(() => _error = 'OTP is required');
      return;
    }
    await _run(() async {
      await widget.apiClient.verifyOtp(
        email: _email.text.trim(),
        otp: _otp.text.trim(),
      );
      _otpVerified = true;
      _message = 'OTP verified. Enter a new password.';
    });
  }

  Future<void> _changePassword() async {
    if (!_otpVerified) {
      setState(() => _error = 'Verify the OTP first');
      return;
    }
    if (_newPassword.text.length < 8) {
      setState(() => _error = 'Use at least 8 characters');
      return;
    }
    await _run(() async {
      await widget.apiClient.changePassword(
        email: _email.text.trim(),
        otp: _otp.text.trim(),
        newPassword: _newPassword.text,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      await action();
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset password'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _otp,
                    decoration: const InputDecoration(labelText: 'OTP'),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: _loading ? null : _requestOtp,
                  child: const Text('Send OTP'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newPassword,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              SuccessBanner(message: _message!),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              ErrorBanner(message: _error!),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        OutlinedButton(
          onPressed: _loading ? null : _verifyOtp,
          child: const Text('Verify OTP'),
        ),
        FilledButton(
          onPressed: _loading ? null : _changePassword,
          child: Text(_loading ? 'Working...' : 'Change password'),
        ),
      ],
    );
  }
}

class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({super.key, required this.register});

  final bool register;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _mint,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: DefaultTextStyle(
          style: const TextStyle(color: _leafDark),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const BrandMark(size: 48),
                  const SizedBox(width: 12),
                  Text(
                    'NutriAI',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _leafDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      register
                          ? 'Healthy starts with your first plan'
                          : 'Planning healthy meals made simple',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: _leafDark,
                        fontWeight: FontWeight.w900,
                        height: 1.04,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'AI meal ideas, nutrition tracking, water goals, and groceries in one calm workspace.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF51655B),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 26),
                    const MealPreviewCard(),
                  ],
                ),
              ),
              const Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FeaturePill(
                    icon: Icons.restaurant_menu,
                    label: 'Smart meals',
                  ),
                  FeaturePill(
                    icon: Icons.water_drop_outlined,
                    label: 'Water goals',
                  ),
                  FeaturePill(
                    icon: Icons.monitor_heart_outlined,
                    label: 'Risk insights',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeaturePill extends StatelessWidget {
  const FeaturePill({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: _leaf),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: _leafDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 42, this.flat = false});

  final double size;
  final bool flat;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(flat ? 8 : 14),
        border: flat ? Border.all(color: const Color(0xFFD9DEE7)) : null,
        boxShadow: flat
            ? null
            : const [
                BoxShadow(
                  color: Color(0x220C3B2E),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(Icons.eco_rounded, color: _leaf, size: size * 0.58),
      ),
    );
  }
}

class AuthModeSwitch extends StatelessWidget {
  const AuthModeSwitch({
    super.key,
    required this.register,
    required this.onChanged,
  });

  final bool register;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: AuthModeButton(
                selected: !register,
                icon: Icons.login,
                label: 'Login',
                onTap: () => onChanged(false),
              ),
            ),
            Expanded(
              child: AuthModeButton(
                selected: register,
                icon: Icons.person_add_alt,
                label: 'Create',
                onTap: () => onChanged(true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthModeButton extends StatelessWidget {
  const AuthModeButton({
    super.key,
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _leafDark : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x220C3B2E),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : const Color(0xFF62716A),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF62716A),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.icon,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
  });

  final TextEditingController controller;
  final IconData icon;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFFAFCFA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE1E7E2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE1E7E2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _leaf, width: 1.4),
        ),
      ),
    );
  }
}

class MealPreviewCard extends StatelessWidget {
  const MealPreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _HoverLift(
      borderRadius: 22,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x180C3B2E),
              blurRadius: 24,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const MealBowlGraphic(),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today Plan',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF66746D),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Balanced bowl',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: _leafDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        MacroChip(color: _leaf, label: '420 kcal'),
                        SizedBox(width: 8),
                        MacroChip(color: _coral, label: '28g protein'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MealBowlGraphic extends StatelessWidget {
  const MealBowlGraphic({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 102,
            height: 102,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF1D7),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE8D9C0), width: 6),
            ),
          ),
          const Positioned(
            left: 23,
            top: 24,
            child: _FoodDot(color: _leaf, size: 32),
          ),
          const Positioned(
            right: 25,
            top: 27,
            child: _FoodDot(color: _amber, size: 28),
          ),
          const Positioned(
            left: 36,
            bottom: 25,
            child: _FoodDot(color: _coral, size: 26),
          ),
          const Positioned(
            right: 34,
            bottom: 30,
            child: _FoodDot(color: _blue, size: 20),
          ),
        ],
      ),
    );
  }
}

class _FoodDot extends StatelessWidget {
  const _FoodDot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class MacroChip extends StatelessWidget {
  const MacroChip({super.key, required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.apiClient,
    required this.onLogout,
    required this.darkMode,
    required this.onDarkModeChanged,
  });

  final ApiClient apiClient;
  final VoidCallback onLogout;
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        apiClient: widget.apiClient,
        onNavigate: (index) => setState(() => _selectedIndex = index),
      ),
      ProfileScreen(apiClient: widget.apiClient),
      FoodDatabaseScreen(apiClient: widget.apiClient),
      FoodLogScreen(apiClient: widget.apiClient),
      PlannerScreen(apiClient: widget.apiClient),
      GroceryScreen(apiClient: widget.apiClient),
      ProgressScreen(apiClient: widget.apiClient),
      AllergiesScreen(apiClient: widget.apiClient),
      AssistantScreen(apiClient: widget.apiClient),
      SettingsScreen(
        apiClient: widget.apiClient,
        onLogout: widget.onLogout,
        darkMode: widget.darkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return Scaffold(
          drawer: compact
              ? Drawer(
                  child: SafeArea(
                    child: NavigationDrawer(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (value) {
                        setState(() => _selectedIndex = value);
                        Navigator.of(context).pop();
                      },
                      children: const [
                        Padding(
                          padding: EdgeInsets.fromLTRB(24, 20, 16, 12),
                          child: Text(
                            'NutriAI',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        NavigationDrawerDestination(
                          icon: Icon(Icons.dashboard_outlined),
                          label: Text('Dashboard'),
                        ),
                        NavigationDrawerDestination(
                          icon: Icon(Icons.person_outline),
                          label: Text('Profile'),
                        ),
                        NavigationDrawerDestination(
                          icon: Icon(Icons.restaurant_menu),
                          label: Text('Foods'),
                        ),
                        NavigationDrawerDestination(
                          icon: Icon(Icons.fact_check_outlined),
                          label: Text('Log Food'),
                        ),
                        NavigationDrawerDestination(
                          icon: Icon(Icons.calendar_today_outlined),
                          label: Text('Meal Planner'),
                        ),
                        NavigationDrawerDestination(
                          icon: Icon(Icons.shopping_cart_outlined),
                          label: Text('Grocery'),
                        ),
                        NavigationDrawerDestination(
                          icon: Icon(Icons.show_chart),
                          label: Text('Progress'),
                        ),
                        NavigationDrawerDestination(
                          icon: Icon(Icons.health_and_safety_outlined),
                          label: Text('Allergies'),
                        ),
                        NavigationDrawerDestination(
                          icon: Icon(Icons.smart_toy_outlined),
                          label: Text('AI Assistant'),
                        ),
                        NavigationDrawerDestination(
                          icon: Icon(Icons.settings_outlined),
                          label: Text('Settings'),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
          appBar: compact
              ? AppBar(
                  title: const Row(
                    children: [
                      Icon(Icons.eco_rounded),
                      SizedBox(width: 10),
                      Text('NutriAI'),
                    ],
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Sign out',
                      onPressed: widget.onLogout,
                      icon: const Icon(Icons.logout),
                    ),
                  ],
                )
              : null,
          body: Row(
            children: [
              if (!compact)
                SizedBox(
                  width: 190,
                  child: _DesktopSidebar(
                    selectedIndex: _selectedIndex,
                    onSelected: (value) =>
                        setState(() => _selectedIndex = value),
                    onLogout: widget.onLogout,
                  ),
                ),
              Expanded(
                child: Container(
                  color: _appBackground(context),
                  padding: EdgeInsets.all(
                    compact ? 12 : (_selectedIndex == 0 ? 0 : 24),
                  ),
                  child: pages[_selectedIndex],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.apiClient,
    required this.onNavigate,
  });

  final ApiClient apiClient;
  final ValueChanged<int> onNavigate;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashboardData> _load() async {
    final profile = await widget.apiClient.profile();
    final goal = await widget.apiClient.goal() ?? <String, dynamic>{};
    if (_foodNumber(goal['daily_calorie_target']) <= 0 &&
        profile['age'] != null &&
        profile['height_cm'] != null &&
        profile['weight_kg'] != null) {
      final prediction = await widget.apiClient.predictCalories({
        'age': profile['age'],
        'gender': profile['gender'] ?? 'male',
        'height_cm': profile['height_cm'],
        'weight_kg': profile['weight_kg'],
        'activity_level': profile['activity_level'] ?? 'moderate',
        'goal': goal['goal_type'] ?? 'maintain',
      });
      goal['daily_calorie_target'] = prediction['recommended_daily_calories'];
    }
    final foods = await widget.apiClient.foods();
    final summary = await widget.apiClient.nutritionSummary(todayIsoDate());
    final logs = await _withFallback(
      widget.apiClient.foodLogs(),
      <Map<String, dynamic>>[],
    );
    final progress = await _withFallback(
      widget.apiClient.weightProgress(),
      <String, dynamic>{},
    );
    final water = await _withFallback(
      widget.apiClient.waterLog(todayIsoDate()),
      <String, dynamic>{},
    );
    final now = DateTime.now();
    final weeklySummaries = await Future.wait(
      List.generate(7, (index) {
        final day = now.subtract(Duration(days: 6 - index));
        return _withFallback(
          widget.apiClient.nutritionSummary(_isoDate(day)),
          <String, dynamic>{'calories': 0},
        );
      }),
    );
    return _DashboardData(
      profile: profile,
      goal: goal,
      foods: foods,
      summary: summary,
      logs: logs,
      progress: progress,
      water: water,
      weeklySummaries: weeklySummaries,
    );
  }

  Future<T> _withFallback<T>(Future<T> future, T fallback) async {
    try {
      return await future;
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ErrorView(
            message: snapshot.error.toString(),
            onRetry: () => setState(() => _future = _load()),
          );
        }
        final data = snapshot.data!;
        final summary = data.summary;
        final calories = _numValue(summary['calories']);
        final protein = _numValue(summary['protein_g']);
        final carbs = _numValue(summary['carbs_g']);
        final fats = _numValue(summary['fat_g']);
        final water = _numValue(data.water['amount_ml']);
        final calorieTarget = _numOrNull(data.goal['daily_calorie_target']);
        final proteinTarget = _numOrNull(data.goal['protein_target_g']);
        final waterTarget = _numOrNull(data.water['recommended_ml']);
        final currentWeight = _numOrNull(
          data.progress['current_weight'] ?? data.profile['weight_kg'],
        );
        final targetWeight = _numOrNull(
          data.progress['target_weight'] ?? data.profile['target_weight_kg'],
        );
        final weekly = data.weeklySummaries
            .map((item) => _numValue(item['calories']))
            .toList();
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 26, 32, 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: _appText(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Welcome back! Here's your nutrition overview",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _appMutedText(context),
                  ),
                ),
                const SizedBox(height: 28),
                _DashboardMetricGrid(
                  children: [
                    DashboardMetricCard(
                      icon: Icons.local_fire_department_outlined,
                      iconColor: const Color(0xFF16A05D),
                      value: calorieTarget == null
                          ? '${calories.round()} / Set profile'
                          : '${calories.round()} / ${calorieTarget.round()}',
                      label: 'Calories',
                      progress: calorieTarget == null || calorieTarget <= 0
                          ? 0
                          : (calories / calorieTarget).clamp(0, 1),
                    ),
                    DashboardMetricCard(
                      icon: Icons.monitor_heart_outlined,
                      iconColor: const Color(0xFF2EB8F0),
                      value: proteinTarget == null
                          ? '${protein.round()}g / Set profile'
                          : '${protein.round()}g / ${proteinTarget.round()}g',
                      label: 'Protein',
                      progress: proteinTarget == null || proteinTarget <= 0
                          ? 0
                          : (protein / proteinTarget).clamp(0, 1),
                    ),
                    DashboardMetricCard(
                      icon: Icons.water_drop_outlined,
                      iconColor: const Color(0xFF2EB8F0),
                      value: waterTarget == null
                          ? '${water.round()}ml / Set profile'
                          : '${water.round()}ml / ${waterTarget.round()}ml',
                      label: 'Water Intake',
                      progress: waterTarget == null || waterTarget <= 0
                          ? 0
                          : (water / waterTarget).clamp(0, 1),
                    ),
                    DashboardWeightCard(
                      value: currentWeight == null
                          ? 'No weight yet'
                          : '${currentWeight.toStringAsFixed(1)} kg',
                      target: targetWeight == null
                          ? 'Set a profile target'
                          : 'Target: ${targetWeight.toStringAsFixed(0)} kg',
                      delta: currentWeight == null || targetWeight == null
                          ? null
                          : targetWeight - currentWeight,
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 820;
                    final chart = DashboardPanel(
                      title: 'Weekly Calories',
                      child: SizedBox(
                        height: 245,
                        child: WeeklyCaloriesChart(values: weekly),
                      ),
                    );
                    final macros = DashboardPanel(
                      title: "Today's Macros",
                      child: MacrosPanel(
                        protein: protein,
                        carbs: carbs,
                        fats: fats,
                      ),
                    );
                    if (stacked) {
                      return Column(
                        children: [chart, const SizedBox(height: 16), macros],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: chart),
                        const SizedBox(width: 16),
                        Expanded(flex: 3, child: macros),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 26),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 820;
                    final quickActions = DashboardPanel(
                      title: 'Quick Actions',
                      child: QuickActionsGrid(onNavigate: widget.onNavigate),
                    );
                    final recent = DashboardPanel(
                      title: 'Recent Food Logged',
                      child: RecentFoodLogged(
                        logs: data.logs,
                        foods: data.foods,
                      ),
                    );
                    if (stacked) {
                      return Column(
                        children: [
                          quickActions,
                          const SizedBox(height: 16),
                          recent,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: quickActions),
                        const SizedBox(width: 16),
                        Expanded(flex: 5, child: recent),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _numValue(dynamic value, {double fallback = 0}) {
    return _numOrNull(value) ?? fallback;
  }

  double? _numOrNull(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }
}

class FoodDatabaseScreen extends StatefulWidget {
  const FoodDatabaseScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<FoodDatabaseScreen> createState() => _FoodDatabaseScreenState();
}

class _FoodDatabaseScreenState extends State<FoodDatabaseScreen> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _foods = [];
  String _category = 'All Categories';
  bool _loading = true;
  bool _favoritesOnly = false;
  String? _error;
  final Set<int> _favorites = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final foods = await widget.apiClient.foods();
      final favorites = await widget.apiClient.favoriteFoodIds();
      setState(() {
        _foods = foods;
        _favorites
          ..clear()
          ..addAll(favorites);
        _error = null;
      });
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _showAddFoodDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: _AddFoodDialog(apiClient: widget.apiClient),
      ),
    );
    if (created == true) {
      await _load();
    }
  }

  Future<void> _showSubstitutes(String foodName) async {
    await showDialog<void>(
      context: context,
      builder: (context) =>
          _SubstitutesDialog(apiClient: widget.apiClient, foodName: foodName),
    );
  }

  Future<void> _toggleFavorite(int id, String name) async {
    final wasFavorite = _favorites.contains(id);
    setState(() {
      if (wasFavorite) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
    });
    try {
      final updated = wasFavorite
          ? await widget.apiClient.removeFavoriteFood(id)
          : await widget.apiClient.addFavoriteFood(id);
      setState(() {
        _favorites
          ..clear()
          ..addAll(updated);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              wasFavorite
                  ? '$name removed from favorites'
                  : '$name added to favorites',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      setState(() {
        if (wasFavorite) {
          _favorites.add(id);
        } else {
          _favorites.remove(id);
        }
        _error = error.toString();
      });
    }
  }

  void _showAllFoods() {
    setState(() {
      _favoritesOnly = false;
      _category = 'All Categories';
      _search.clear();
    });
  }

  List<String> get _categories {
    final values =
        _foods
            .map((food) => food['category']?.toString().trim() ?? '')
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return ['All Categories', ...values];
  }

  List<Map<String, dynamic>> get _visibleFoods {
    final query = _search.text.trim().toLowerCase();
    return _foods.where((food) {
      final name = food['name']?.toString().toLowerCase() ?? '';
      final category = food['category']?.toString().toLowerCase() ?? '';
      final matchesSearch =
          query.isEmpty || name.contains(query) || category.contains(query);
      final matchesCategory =
          _category == 'All Categories' ||
          food['category']?.toString() == _category;
      final id = food['id'];
      final matchesFavorite =
          !_favoritesOnly || (id is int && _favorites.contains(id));
      return matchesSearch && matchesCategory && matchesFavorite;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            compact ? 4 : 0,
            compact ? 2 : 0,
            compact ? 4 : 0,
            24,
          ),
          children: [
            _FoodDatabaseHeader(
              search: _search,
              categories: _categories,
              selectedCategory: _category,
              compact: compact,
              favoritesOnly: _favoritesOnly,
              favoritesCount: _favorites.length,
              onSearchChanged: (_) => setState(() {}),
              onCategoryChanged: (value) =>
                  setState(() => _category = value ?? 'All Categories'),
              onFavoritesOnlyChanged: () {
                if (_favoritesOnly) {
                  _showAllFoods();
                } else {
                  setState(() => _favoritesOnly = true);
                }
              },
              onAddFood: _showAddFoodDialog,
            ),
            if (_favoritesOnly ||
                _category != 'All Categories' ||
                _search.text.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _FoodFilterStatusBar(
                favoritesOnly: _favoritesOnly,
                category: _category,
                searchText: _search.text.trim(),
                visibleCount: _visibleFoods.length,
                onShowAll: _showAllFoods,
              ),
            ],
            const SizedBox(height: 24),
            if (_loading)
              const SizedBox(
                height: 240,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              ErrorView(message: _error!, onRetry: _load)
            else if (_visibleFoods.isEmpty)
              const _EmptyFoodsView()
            else
              _FoodDatabaseGrid(
                foods: _visibleFoods,
                favorites: _favorites,
                onSubstitutes: _showSubstitutes,
                onFavorite: (id) {
                  final food = _foods.firstWhere(
                    (item) => item['id'] == id,
                    orElse: () => {'name': 'Food'},
                  );
                  _toggleFavorite(id, food['name']?.toString() ?? 'Food');
                },
              ),
          ],
        );
      },
    );
  }
}

class _FoodDatabaseHeader extends StatelessWidget {
  const _FoodDatabaseHeader({
    required this.search,
    required this.categories,
    required this.selectedCategory,
    required this.compact,
    required this.favoritesOnly,
    required this.favoritesCount,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onFavoritesOnlyChanged,
    required this.onAddFood,
  });

  final TextEditingController search;
  final List<String> categories;
  final String selectedCategory;
  final bool compact;
  final bool favoritesOnly;
  final int favoritesCount;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onFavoritesOnlyChanged;
  final VoidCallback onAddFood;

  @override
  Widget build(BuildContext context) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Food Database',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _appText(context),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Browse and search nutrition information for foods',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: _appMutedText(context),
            height: 1.25,
          ),
        ),
      ],
    );
    final searchBox = SizedBox(
      width: compact ? double.infinity : null,
      height: 44,
      child: TextField(
        controller: search,
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search foods...',
          prefixIcon: const Icon(Icons.search, size: 20),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFC9D5CF)),
          ),
        ),
      ),
    );
    final categoryBox = SizedBox(
      width: compact ? double.infinity : 132,
      height: 44,
      child: DropdownButtonFormField<String>(
        initialValue: categories.contains(selectedCategory)
            ? selectedCategory
            : 'All Categories',
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        dropdownColor: _appSurface(context),
        style: TextStyle(
          color: _appText(context),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
        items: categories
            .map(
              (category) => DropdownMenuItem<String>(
                value: category,
                child: Text(
                  _categoryLabel(category),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: onCategoryChanged,
      ),
    );
    final addButton = SizedBox(
      width: compact ? double.infinity : 142,
      height: 50,
      child: FilledButton.icon(
        onPressed: onAddFood,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Add Food'),
      ),
    );
    final favoritesButton = SizedBox(
      width: compact ? double.infinity : 146,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onFavoritesOnlyChanged,
        icon: Icon(
          favoritesOnly ? Icons.close : Icons.favorite_border,
          size: 18,
        ),
        label: Text(
          favoritesOnly
              ? 'Show All'
              : favoritesCount > 0
              ? 'Favorites ($favoritesCount)'
              : 'Favorites',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: favoritesOnly
              ? const Color(0xFFFFEDF2)
              : Colors.white,
          foregroundColor: favoritesOnly
              ? const Color(0xFFE11D48)
              : const Color(0xFF344054),
          side: BorderSide(
            color: favoritesOnly
                ? const Color(0xFFFFB5C8)
                : const Color(0xFFC9D5CF),
          ),
        ),
      ),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 16),
          searchBox,
          const SizedBox(height: 12),
          categoryBox,
          const SizedBox(height: 12),
          favoritesButton,
          const SizedBox(height: 12),
          addButton,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 290, child: title),
        const SizedBox(width: 20),
        Flexible(flex: 7, child: searchBox),
        const SizedBox(width: 14),
        categoryBox,
        const SizedBox(width: 14),
        favoritesButton,
        const SizedBox(width: 22),
        addButton,
      ],
    );
  }

  static String _categoryLabel(String value) {
    if (value == 'All Categories') {
      return 'All\nCategories';
    }
    return _titleCase(value);
  }
}

class _FoodFilterStatusBar extends StatelessWidget {
  const _FoodFilterStatusBar({
    required this.favoritesOnly,
    required this.category,
    required this.searchText,
    required this.visibleCount,
    required this.onShowAll,
  });

  final bool favoritesOnly;
  final String category;
  final String searchText;
  final int visibleCount;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final filters = <String>[
      if (favoritesOnly) 'Favorites',
      if (category != 'All Categories') _titleCase(category),
      if (searchText.isNotEmpty) '"$searchText"',
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8F3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCFE4D6)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(
              favoritesOnly ? Icons.favorite : Icons.filter_alt_outlined,
              color: favoritesOnly ? const Color(0xFFE11D48) : _leaf,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Showing $visibleCount food${visibleCount == 1 ? '' : 's'} for ${filters.join(' + ')}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF344054),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onShowAll,
              icon: const Icon(Icons.list_alt, size: 16),
              label: const Text('Show all foods'),
              style: TextButton.styleFrom(
                foregroundColor: _leaf,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodDatabaseGrid extends StatelessWidget {
  const _FoodDatabaseGrid({
    required this.foods,
    required this.favorites,
    required this.onFavorite,
    required this.onSubstitutes,
  });

  final List<Map<String, dynamic>> foods;
  final Set<int> favorites;
  final ValueChanged<int> onFavorite;
  final ValueChanged<String> onSubstitutes;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 20.0;
        final columns = constraints.maxWidth < 680
            ? 1
            : constraints.maxWidth < 1040
            ? 2
            : 3;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: foods.map((food) {
            final id = food['id'] is int ? food['id'] as int : food.hashCode;
            return SizedBox(
              width: width,
              height: 210,
              child: _FoodDatabaseCard(
                food: food,
                favorite: favorites.contains(id),
                onFavorite: () => onFavorite(id),
                onSubstitutes: () =>
                    onSubstitutes(food['name']?.toString() ?? 'food'),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _FoodDatabaseCard extends StatelessWidget {
  const _FoodDatabaseCard({
    required this.food,
    required this.favorite,
    required this.onFavorite,
    required this.onSubstitutes,
  });

  final Map<String, dynamic> food;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onSubstitutes;

  @override
  Widget build(BuildContext context) {
    final name = food['name']?.toString() ?? 'Food';
    final category = _titleCase(food['category']?.toString() ?? 'Food');
    final calories = _foodNumber(food['calories']);
    final protein = _foodNumber(food['protein_g']);
    final carbs = _foodNumber(food['carbs_g']);
    final fat = _foodNumber(food['fat_g']);
    return _HoverLift(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: favorite ? const Color(0xFFFFFBFC) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: favorite ? const Color(0xFFFFAFC3) : const Color(0xFFD9E5DE),
            width: favorite ? 1.4 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120C3B2E),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FoodCategoryIcon(category: category),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF111827),
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_formatFoodNumber(calories)} kcal',
                        style: const TextStyle(
                          color: Color(0xFF087443),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'CALORIES',
                        style: TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 8,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MacroMiniTile(
                      label: 'Protein',
                      value: '${_formatFoodNumber(protein)}g',
                      progress: protein / 40,
                      color: _leaf,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MacroMiniTile(
                      label: 'Carbs',
                      value: '${_formatFoodNumber(carbs)}g',
                      progress: carbs / 70,
                      color: const Color(0xFF1FBF8F),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MacroMiniTile(
                      label: 'Fat',
                      value: '${_formatFoodNumber(fat)}g',
                      progress: fat / 25,
                      color: const Color(0xFFE11D48),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFE4E7EC)),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Serving size: ${food['serving_size'] ?? '1 serving'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Find substitutes',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 28,
                      height: 28,
                    ),
                    onPressed: onSubstitutes,
                    icon: const Icon(
                      Icons.swap_horiz,
                      color: Color(0xFF62716A),
                      size: 20,
                    ),
                  ),
                  IconButton(
                    tooltip: favorite ? 'Remove favorite' : 'Add favorite',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 28,
                      height: 28,
                    ),
                    onPressed: onFavorite,
                    icon: Icon(
                      favorite ? Icons.favorite : Icons.favorite_border,
                      color: favorite
                          ? const Color(0xFFE11D48)
                          : const Color(0xFF62716A),
                      size: 20,
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
}

class _FoodCategoryIcon extends StatelessWidget {
  const _FoodCategoryIcon({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFD7F5E1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(_iconForCategory(category), color: _leaf, size: 23),
      ),
    );
  }

  IconData _iconForCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('rice') || lower.contains('carb')) {
      return Icons.grain;
    }
    if (lower.contains('fish') || lower.contains('protein')) {
      return Icons.set_meal_outlined;
    }
    if (lower.contains('vegetable')) {
      return Icons.eco_outlined;
    }
    if (lower.contains('fruit')) {
      return Icons.spa_outlined;
    }
    if (lower.contains('snack')) {
      return Icons.cookie_outlined;
    }
    if (lower.contains('breakfast')) {
      return Icons.breakfast_dining_outlined;
    }
    return Icons.restaurant_menu;
  }
}

class _MacroMiniTile extends StatelessWidget {
  const _MacroMiniTile({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  final String label;
  final String value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3FF),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 4,
                backgroundColor: const Color(0xFFD2D8D4),
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFoodsView extends StatelessWidget {
  const _EmptyFoodsView();

  @override
  Widget build(BuildContext context) {
    return const _DashboardCard(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No foods match your search.')),
      ),
    );
  }
}

class _SubstitutesDialog extends StatefulWidget {
  const _SubstitutesDialog({required this.apiClient, required this.foodName});

  final ApiClient apiClient;
  final String foodName;

  @override
  State<_SubstitutesDialog> createState() => _SubstitutesDialogState();
}

class _SubstitutesDialogState extends State<_SubstitutesDialog> {
  bool _loading = true;
  String? _error;
  List<String> _alternatives = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.apiClient.substitutes(widget.foodName);
      final alternatives = result['alternatives'] as List<dynamic>? ?? [];
      setState(() {
        _alternatives = alternatives.map((item) => item.toString()).toList();
      });
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Substitutes for ${widget.foodName}'),
      content: SizedBox(
        width: 360,
        child: _loading
            ? const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              )
            : _error != null
            ? ErrorBanner(message: _error!)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: _alternatives
                    .map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.check_circle_outline),
                        title: Text(item),
                      ),
                    )
                    .toList(),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _AddFoodDialog extends StatefulWidget {
  const _AddFoodDialog({required this.apiClient});

  final ApiClient apiClient;

  @override
  State<_AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<_AddFoodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _servingSize = TextEditingController();
  final _calories = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  String _category = 'meal';
  String? _imageName;
  bool _saving = false;
  bool _recognizing = false;
  Map<String, dynamic>? _recognition;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _servingSize.dispose();
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.apiClient.createFood(
        name: _name.text.trim(),
        category: _category,
        servingSize: _servingSize.text.trim(),
        calories: double.tryParse(_calories.text.trim()) ?? 0,
        proteinG: double.tryParse(_protein.text.trim()) ?? 0,
        carbsG: double.tryParse(_carbs.text.trim()) ?? 0,
        fatG: double.tryParse(_fat.text.trim()) ?? 0,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null) {
      return;
    }
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      setState(() {
        _imageName = file.name;
        _error = 'Could not read image bytes';
      });
      return;
    }
    setState(() {
      _imageName = file.name;
      _recognizing = true;
      _recognition = null;
      _error = null;
    });
    try {
      final result = await widget.apiClient.recognizeFoodImage(
        bytes: bytes,
        filename: file.name,
      );
      final predictedName = result['food_name']?.toString() ?? '';
      final calories = _foodNumber(result['estimated_calories']);
      setState(() {
        _recognition = result;
        if (_name.text.trim().isEmpty && predictedName.isNotEmpty) {
          _name.text = predictedName;
        }
        if (_calories.text.trim().isEmpty && calories > 0) {
          _calories.text = _formatFoodNumber(calories);
        }
      });
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _recognizing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.of(context).size.height - 56,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ColoredBox(
            color: _appSurface(context),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AddFoodDialogHeader(
                    saving: _saving,
                    onClose: () => Navigator.of(context).pop(false),
                  ),
                  Divider(height: 1, color: _appBorder(context)),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(26, 22, 26, 26),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _FoodDialogPrimaryFields(
                            name: _name,
                            calories: _calories,
                            servingSize: _servingSize,
                            category: _category,
                            onCategoryChanged: (value) {
                              if (value != null) {
                                setState(() => _category = value);
                              }
                            },
                            requiredValidator: _required,
                            numberValidator: _numberRequired,
                          ),
                          const SizedBox(height: 22),
                          _MacroBreakdownPanel(
                            protein: _protein,
                            carbs: _carbs,
                            fat: _fat,
                            validator: _numberRequired,
                          ),
                          const SizedBox(height: 24),
                          _UploadFoodImageBox(
                            imageName: _recognizing
                                ? 'Recognizing image...'
                                : _imageName,
                            onTap: _saving || _recognizing ? null : _pickImage,
                          ),
                          if (_recognition != null) ...[
                            const SizedBox(height: 12),
                            _ImageRecognitionResult(data: _recognition!),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            ErrorBanner(message: _error!),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1, color: _appBorder(context)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(26, 18, 26, 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 22),
                        SizedBox(
                          height: 44,
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: const Icon(Icons.save_outlined, size: 16),
                            label: Text(_saving ? 'Saving...' : 'Save Food'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  String? _numberRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    if (double.tryParse(value.trim()) == null) {
      return 'Use a number';
    }
    return null;
  }
}

class _AddFoodDialogHeader extends StatelessWidget {
  const _AddFoodDialogHeader({required this.saving, required this.onClose});

  final bool saving;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 22, 18, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF18C878),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.restaurant, color: Colors.white, size: 21),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Food',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _appText(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Enter nutritional details to expand the database',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _appMutedText(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: saving ? null : onClose,
            icon: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }
}

class _FoodDialogPrimaryFields extends StatelessWidget {
  const _FoodDialogPrimaryFields({
    required this.name,
    required this.calories,
    required this.servingSize,
    required this.category,
    required this.onCategoryChanged,
    required this.requiredValidator,
    required this.numberValidator,
  });

  final TextEditingController name;
  final TextEditingController calories;
  final TextEditingController servingSize;
  final String category;
  final ValueChanged<String?> onCategoryChanged;
  final FormFieldValidator<String> requiredValidator;
  final FormFieldValidator<String> numberValidator;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 460;
        final first = _FoodDialogTextField(
          controller: name,
          label: 'Food Name',
          hintText: 'e.g. Avocado Toast',
          validator: requiredValidator,
        );
        final second = _FoodDialogCategoryField(
          value: category,
          onChanged: onCategoryChanged,
        );
        final third = _FoodDialogTextField(
          controller: calories,
          label: 'Calories (kcal)',
          hintText: '0',
          suffixText: 'kcal',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: numberValidator,
        );
        final fourth = _FoodDialogTextField(
          controller: servingSize,
          label: 'Serving Size',
          hintText: 'e.g. 100g, 1 slice',
          validator: requiredValidator,
        );
        if (stacked) {
          return Column(
            children: [
              first,
              const SizedBox(height: 16),
              second,
              const SizedBox(height: 16),
              third,
              const SizedBox(height: 16),
              fourth,
            ],
          );
        }
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: first),
                const SizedBox(width: 22),
                Expanded(child: second),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: third),
                const SizedBox(width: 22),
                Expanded(child: fourth),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _FoodDialogTextField extends StatelessWidget {
  const _FoodDialogTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.suffixText,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final String? suffixText;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FoodDialogLabel(label),
        const SizedBox(height: 8),
        SizedBox(
          height: 46,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: TextStyle(fontSize: 13, color: _appText(context)),
            decoration: InputDecoration(
              hintText: hintText,
              suffixText: suffixText,
              suffixStyle: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              hintStyle: const TextStyle(
                color: Color(0xFF98A2B3),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: _appSurfaceSoft(context),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: _appBorder(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: _appBorder(context)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FoodDialogCategoryField extends StatelessWidget {
  const _FoodDialogCategoryField({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String?> onChanged;

  static const _categories = [
    'meal',
    'breakfast',
    'protein',
    'carbohydrate',
    'vegetable',
    'fruit',
    'snack',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FoodDialogLabel('Category'),
        const SizedBox(height: 8),
        SizedBox(
          height: 46,
          child: DropdownButtonFormField<String>(
            key: const ValueKey('add-food-category'),
            initialValue: value,
            isExpanded: true,
            dropdownColor: _appSurface(context),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
            decoration: InputDecoration(
              filled: true,
              fillColor: _appSurfaceSoft(context),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: _appBorder(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: _appBorder(context)),
              ),
            ),
            style: TextStyle(
              color: _appText(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            items: _categories
                .map(
                  (category) => DropdownMenuItem<String>(
                    value: category,
                    child: Text(
                      _titleCase(category),
                      style: TextStyle(color: _appText(context)),
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _MacroBreakdownPanel extends StatelessWidget {
  const _MacroBreakdownPanel({
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.validator,
  });

  final TextEditingController protein;
  final TextEditingController carbs;
  final TextEditingController fat;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _appSurfaceSoft(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD0D5DD)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 13,
                  color: _appText(context),
                ),
                const SizedBox(width: 5),
                Text(
                  'Macro Breakdown',
                  style: TextStyle(
                    color: _appText(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 420;
                final inputs = [
                  _MacroDialogInput(
                    controller: protein,
                    label: 'PROTEIN',
                    validator: validator,
                  ),
                  _MacroDialogInput(
                    controller: carbs,
                    label: 'CARBS',
                    validator: validator,
                  ),
                  _MacroDialogInput(
                    controller: fat,
                    label: 'FAT',
                    validator: validator,
                  ),
                ];
                if (stacked) {
                  return Column(
                    children: inputs
                        .expand((input) => [input, const SizedBox(height: 10)])
                        .take(inputs.length * 2 - 1)
                        .toList(),
                  );
                }
                return Row(
                  children: inputs
                      .expand(
                        (input) => [
                          Expanded(child: input),
                          const SizedBox(width: 14),
                        ],
                      )
                      .take(inputs.length * 2 - 1)
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroDialogInput extends StatelessWidget {
  const _MacroDialogInput({
    required this.controller,
    required this.label,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _leaf,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 36,
          child: TextFormField(
            controller: controller,
            validator: validator,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              color: _appText(context),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: '0',
              suffixText: 'g',
              suffixStyle: const TextStyle(
                color: Color(0xFF98A2B3),
                fontSize: 9,
              ),
              filled: true,
              fillColor: _appSurface(context),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFCFE4D6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFCFE4D6)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UploadFoodImageBox extends StatelessWidget {
  const _UploadFoodImageBox({required this.imageName, required this.onTap});

  final String? imageName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 132,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _appSurfaceSoft(context),
              _leaf.withValues(alpha: _isDark(context) ? 0.16 : 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _appBorder(context)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              color: _appText(context),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              imageName ?? 'Upload Food Image (Optional)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _appText(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageRecognitionResult extends StatelessWidget {
  const _ImageRecognitionResult({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final foodName = data['food_name']?.toString() ?? 'Food';
    final calories = _foodNumber(data['estimated_calories']);
    final confidence = _foodNumber(data['confidence']);
    final method = data['method']?.toString() ?? 'fallback';
    final unknown = confidence <= 0 || foodName == 'Unknown Food';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE7F5EA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCFE4D6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.image_search, color: _leaf),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                unknown
                    ? 'No reliable food match. Enter the food manually.'
                    : '$foodName • ${_formatFoodNumber(calories)} kcal per saved serving • ${_formatFoodNumber(confidence * 100)}% • $method',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1B4C3A),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodDialogLabel extends StatelessWidget {
  const _FoodDialogLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: _appText(context),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _DashboardMetricGrid extends StatelessWidget {
  const _DashboardMetricGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 620
            ? 1
            : constraints.maxWidth < 920
            ? 2
            : 4;
        const gap = 14.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children
              .map((child) => SizedBox(width: width, height: 154, child: child))
              .toList(),
        );
      },
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.selectedIndex,
    required this.onSelected,
    required this.onLogout,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    const items = [
      _SidebarItem(Icons.home_outlined, 'Dashboard', 0),
      _SidebarItem(Icons.person_outline, 'Profile', 1),
      _SidebarItem(Icons.restaurant_menu, 'Foods', 2),
      _SidebarItem(Icons.fact_check_outlined, 'Log Food', 3),
      _SidebarItem(Icons.calendar_today_outlined, 'Meal Planner', 4),
      _SidebarItem(Icons.shopping_cart_outlined, 'Grocery', 5),
      _SidebarItem(Icons.show_chart, 'Progress', 6),
      _SidebarItem(Icons.health_and_safety_outlined, 'Allergies', 7),
      _SidebarItem(Icons.smart_toy_outlined, 'AI Assistant', 8),
      _SidebarItem(Icons.settings_outlined, 'Settings', 9),
    ];
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE4E7EC))),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 12, 22),
              child: Row(
                children: [
                  const BrandMark(size: 24, flat: true),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NutriAI',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: const Color(0xFF16A05D),
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const Text(
                          'AI NUTRITION PLANNER',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF98A2B3),
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ...items.map(
              (item) => _SidebarButton(
                item: item,
                selected: selectedIndex == item.index,
                onTap: item.index == null
                    ? null
                    : () => onSelected(item.index!),
              ),
            ),
            const Spacer(),
            const Divider(height: 1, color: Color(0xFFE4E7EC)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              child: InkWell(
                onTap: onLogout,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 16, color: Color(0xFF344054)),
                      SizedBox(width: 10),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Color(0xFF344054),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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
    );
  }
}

class _SidebarItem {
  const _SidebarItem(this.icon, this.label, this.index);

  final IconData icon;
  final String label;
  final int? index;
}

class _SidebarButton extends StatelessWidget {
  const _SidebarButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _SidebarItem item;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF16A05D) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 15,
                color: selected ? Colors.white : const Color(0xFF344054),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF344054),
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
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

class DashboardMetricCard extends StatelessWidget {
  const DashboardMetricCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.progress,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SoftIcon(icon: icon, color: iconColor),
                const Spacer(),
                Text(
                  'Today',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _appMutedText(context),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _appText(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: _appMutedText(context)),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: const Color(0xFFE5F3EE),
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardWeightCard extends StatelessWidget {
  const DashboardWeightCard({
    super.key,
    required this.value,
    required this.target,
    required this.delta,
  });

  final String value;
  final String target;
  final double? delta;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _SoftIcon(
                  icon: Icons.show_chart,
                  color: Color(0xFFFFA12B),
                ),
                const Spacer(),
                if (delta != null)
                  Text(
                    '${delta! >= 0 ? '+' : ''}${delta!.toStringAsFixed(1)}kg',
                    style: const TextStyle(
                      color: Color(0xFF16A05D),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _appText(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Current Weight',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: _appMutedText(context)),
            ),
            Text(
              target,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: _appMutedText(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardPanel extends StatelessWidget {
  const DashboardPanel({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _appText(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _HoverLift(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _appSurface(context),
          border: Border.all(color: _appBorder(context)),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _SoftIcon extends StatelessWidget {
  const _SoftIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class WeeklyCaloriesChart extends StatefulWidget {
  const WeeklyCaloriesChart({super.key, required this.values});

  final List<double> values;

  @override
  State<WeeklyCaloriesChart> createState() => _WeeklyCaloriesChartState();
}

class _WeeklyCaloriesChartState extends State<WeeklyCaloriesChart> {
  int? _hoveredIndex;

  static const _labels = ['Mon', 'Tues', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _chartLeft = 34.0;
  static const _chartRight = 8.0;
  static const _chartTop = 8.0;
  static const _chartBottom = 28.0;
  static const _maxValue = 2400.0;

  void _handleHover(PointerHoverEvent event, Size size) {
    final index = _barIndexAt(event.localPosition, size);
    if (index != _hoveredIndex) {
      setState(() => _hoveredIndex = index);
    }
  }

  int? _barIndexAt(Offset position, Size size) {
    final chart = _chartRect(size);
    if (!chart.inflate(6).contains(position)) {
      return null;
    }
    final slot = chart.width / widget.values.length;
    final barWidth = math.min(58.0, slot * 0.68);
    for (var i = 0; i < widget.values.length; i++) {
      final value = widget.values[i].clamp(0, _maxValue).toDouble();
      final barHeight = chart.height * (value / _maxValue);
      final x = chart.left + slot * i + (slot - barWidth) / 2;
      final rect = Rect.fromLTWH(
        x,
        chart.bottom - barHeight,
        barWidth,
        barHeight,
      ).inflate(8);
      if (rect.contains(position)) {
        return i;
      }
    }
    return null;
  }

  Rect _chartRect(Size size) {
    return Rect.fromLTWH(
      _chartLeft,
      _chartTop,
      size.width - _chartLeft - _chartRight,
      size.height - _chartTop - _chartBottom,
    );
  }

  Offset _tooltipOffset(Size size, int index) {
    final chart = _chartRect(size);
    final slot = chart.width / widget.values.length;
    final value = widget.values[index].clamp(0, _maxValue).toDouble();
    final barHeight = chart.height * (value / _maxValue);
    final barCenterX = chart.left + slot * index + slot / 2;
    const tooltipWidth = 116.0;
    const tooltipHeight = 64.0;
    final left = (barCenterX - tooltipWidth / 2).clamp(
      chart.left,
      chart.right - tooltipWidth,
    );
    final top = (chart.bottom - barHeight + 12).clamp(
      chart.top + 8,
      chart.bottom - tooltipHeight - 8,
    );
    return Offset(left.toDouble(), top.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final tooltipOffset = _hoveredIndex == null
            ? null
            : _tooltipOffset(size, _hoveredIndex!);
        return MouseRegion(
          onHover: (event) => _handleHover(event, size),
          onExit: (_) => setState(() => _hoveredIndex = null),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                painter: _WeeklyCaloriesPainter(
                  widget.values,
                  hoveredIndex: _hoveredIndex,
                ),
                child: const SizedBox.expand(),
              ),
              if (_hoveredIndex != null && tooltipOffset != null)
                Positioned(
                  left: tooltipOffset.dx,
                  top: tooltipOffset.dy,
                  child: WeeklyCaloriesTooltip(
                    day: _labels[_hoveredIndex!],
                    calories: widget.values[_hoveredIndex!].round(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _WeeklyCaloriesPainter extends CustomPainter {
  _WeeklyCaloriesPainter(this.values, {this.hoveredIndex});

  final List<double> values;
  final int? hoveredIndex;
  final _labels = const ['Mon', 'Tues', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void paint(Canvas canvas, Size size) {
    const left = 34.0;
    const right = 8.0;
    const top = 8.0;
    const bottom = 28.0;
    final chart = Rect.fromLTWH(
      left,
      top,
      size.width - left - right,
      size.height - top - bottom,
    );
    final gridPaint = Paint()
      ..color = const Color(0xFFE7ECEF)
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = const Color(0xFFC7D0D7)
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    const maxValue = 2400.0;
    const ticks = [0, 600, 1200, 1800, 2400];

    for (final tick in ticks) {
      final y = chart.bottom - chart.height * (tick / maxValue);
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      textPainter.text = TextSpan(
        text: '$tick',
        style: const TextStyle(color: Color(0xFF667085), fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }
    canvas.drawLine(chart.bottomLeft, chart.bottomRight, axisPaint);
    canvas.drawLine(chart.bottomLeft, chart.topLeft, axisPaint);

    final slot = chart.width / values.length;
    final barWidth = math.min(58.0, slot * 0.68);
    final barPaint = Paint();
    for (var i = 0; i < values.length; i++) {
      final value = values[i].clamp(0, maxValue);
      final barHeight = chart.height * (value / maxValue);
      final x = chart.left + slot * i + (slot - barWidth) / 2;
      barPaint.color = i == hoveredIndex
          ? const Color(0xFF0F8B5F)
          : const Color(0xFF16A05D);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, chart.bottom - barHeight, barWidth, barHeight),
        const Radius.circular(8),
      );
      canvas.drawRRect(rect, barPaint);
      textPainter.text = TextSpan(
        text: _labels[i],
        style: const TextStyle(color: Color(0xFF667085), fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + barWidth / 2 - textPainter.width / 2, chart.bottom + 11),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyCaloriesPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.hoveredIndex != hoveredIndex;
  }
}

class WeeklyCaloriesTooltip extends StatelessWidget {
  const WeeklyCaloriesTooltip({
    super.key,
    required this.day,
    required this.calories,
  });

  final String day;
  final int calories;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24000000),
              blurRadius: 14,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: SizedBox(
          width: 116,
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    color: Color(0xFF344054),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'calories : $calories',
                  style: const TextStyle(
                    color: Color(0xFF16A05D),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MacrosPanel extends StatefulWidget {
  const MacrosPanel({
    super.key,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  final double protein;
  final double carbs;
  final double fats;

  @override
  State<MacrosPanel> createState() => _MacrosPanelState();
}

class _MacrosPanelState extends State<MacrosPanel> {
  int? _hoveredIndex;

  static const _labels = ['Protein', 'Carbs', 'Fats'];
  static const _colors = [_leaf, _blue, _amber];

  List<double> get _values => [widget.protein, widget.carbs, widget.fats];

  void _handleHover(PointerHoverEvent event, Size size) {
    final index = _segmentIndexAt(event.localPosition, size);
    if (index != _hoveredIndex) {
      setState(() => _hoveredIndex = index);
    }
  }

  int? _segmentIndexAt(Offset position, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final distance = (position - center).distance;
    final stroke = size.shortestSide * 0.16;
    final radius = size.shortestSide / 2 - stroke / 2;
    if (distance < radius - stroke / 1.2 || distance > radius + stroke / 1.2) {
      return null;
    }

    var angle = math.atan2(position.dy - center.dy, position.dx - center.dx);
    angle = (angle + math.pi / 2) % (math.pi * 2);
    if (angle < 0) {
      angle += math.pi * 2;
    }

    final total = _values
        .fold<double>(0, (sum, value) => sum + value)
        .clamp(1, double.infinity);
    var start = 0.0;
    for (var i = 0; i < _values.length; i++) {
      final sweep = math.pi * 2 * (_values[i] / total);
      if (angle >= start && angle <= start + sweep) {
        return i;
      }
      start += sweep;
    }
    return null;
  }

  Offset _tooltipOffset(Size size, int index) {
    final total = _values
        .fold<double>(0, (sum, value) => sum + value)
        .clamp(1, double.infinity);
    var start = -math.pi / 2;
    for (var i = 0; i < index; i++) {
      start += math.pi * 2 * (_values[i] / total);
    }
    final sweep = math.pi * 2 * (_values[index] / total);
    final angle = start + sweep / 2;
    final radius = size.shortestSide * 0.27;
    const tooltipWidth = 116.0;
    const tooltipHeight = 64.0;
    final center = Offset(size.width / 2, size.height / 2);
    final raw = Offset(
      center.dx + math.cos(angle) * radius - tooltipWidth / 2,
      center.dy + math.sin(angle) * radius - tooltipHeight / 2,
    );
    return Offset(
      raw.dx.clamp(-10, size.width - tooltipWidth + 10).toDouble(),
      raw.dy.clamp(-8, size.height - tooltipHeight + 8).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              final tooltipOffset = _hoveredIndex == null
                  ? null
                  : _tooltipOffset(size, _hoveredIndex!);
              return MouseRegion(
                onHover: (event) => _handleHover(event, size),
                onExit: (_) => setState(() => _hoveredIndex = null),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(
                      painter: _DonutPainter(
                        values: _values,
                        hoveredIndex: _hoveredIndex,
                      ),
                      child: const SizedBox.expand(),
                    ),
                    if (_hoveredIndex != null && tooltipOffset != null)
                      Positioned(
                        left: tooltipOffset.dx,
                        top: tooltipOffset.dy,
                        child: MacroTooltip(
                          label: _labels[_hoveredIndex!],
                          value: '${_values[_hoveredIndex!].round()}g',
                          color: _colors[_hoveredIndex!],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        MacroLegendRow(
          color: _leaf,
          label: 'Protein',
          value: '${widget.protein.round()}g',
          highlighted: _hoveredIndex == 0,
        ),
        const SizedBox(height: 12),
        MacroLegendRow(
          color: _blue,
          label: 'Carbs',
          value: '${widget.carbs.round()}g',
          highlighted: _hoveredIndex == 1,
        ),
        const SizedBox(height: 12),
        MacroLegendRow(
          color: _amber,
          label: 'Fats',
          value: '${widget.fats.round()}g',
          highlighted: _hoveredIndex == 2,
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.values, this.hoveredIndex});

  final List<double> values;
  final int? hoveredIndex;
  final colors = const [_leaf, _blue, _amber];

  @override
  void paint(Canvas canvas, Size size) {
    final total = values
        .fold<double>(0, (sum, value) => sum + value)
        .clamp(1, double.infinity);
    final rect = Offset.zero & size;
    final stroke = size.shortestSide * 0.16;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = math.pi * 2 * (values[i] / total);
      paint
        ..color = colors[i].withValues(
          alpha: hoveredIndex == null || hoveredIndex == i ? 1 : 0.45,
        )
        ..strokeWidth = hoveredIndex == i ? stroke + 5 : stroke;
      canvas.drawArc(rect.deflate(stroke / 2), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.hoveredIndex != hoveredIndex;
  }
}

class MacroTooltip extends StatelessWidget {
  const MacroTooltip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24000000),
              blurRadius: 14,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: SizedBox(
          width: 116,
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF344054),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'grams : $value',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MacroLegendRow extends StatelessWidget {
  const MacroLegendRow({
    super.key,
    required this.color,
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final Color color;
  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: highlighted ? color.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: _appMutedText(context),
                fontSize: 12,
                fontWeight: highlighted ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: _appText(context),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    const actions = [
      _QuickAction(
        Icons.restaurant_menu,
        'Log Food',
        Color(0xFFEFFAF4),
        _leaf,
        3,
      ),
      _QuickAction(
        Icons.calendar_today_outlined,
        'Meal Plan',
        Color(0xFFF0FAFF),
        _blue,
        4,
      ),
      _QuickAction(
        Icons.trending_up,
        'Track Progress',
        Color(0xFFFFF8EF),
        _amber,
        6,
      ),
      _QuickAction(
        Icons.spa_outlined,
        'AI Assistant',
        Color(0xFFEFFAF4),
        _leaf,
        8,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 420 ? 1 : 2;
        const gap = 14.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: actions
              .map(
                (action) => SizedBox(
                  width: width,
                  height: 100,
                  child: Semantics(
                    key: ValueKey('quick-action-${action.destination}'),
                    button: true,
                    label: 'Open ${action.label}',
                    child: Material(
                      color: action.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: action.color.withValues(alpha: 0.22),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => onNavigate(action.destination),
                        mouseCursor: SystemMouseCursors.click,
                        hoverColor: action.color.withValues(alpha: 0.12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(action.icon, color: action.color, size: 21),
                            const SizedBox(height: 10),
                            Text(
                              action.label,
                              style: const TextStyle(
                                color: Color(0xFF17231F),
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _QuickAction {
  const _QuickAction(
    this.icon,
    this.label,
    this.background,
    this.color,
    this.destination,
  );

  final IconData icon;
  final String label;
  final Color background;
  final Color color;
  final int destination;
}

class RecentFoodLogged extends StatelessWidget {
  const RecentFoodLogged({super.key, required this.logs, required this.foods});

  final List<Map<String, dynamic>> logs;
  final List<Map<String, dynamic>> foods;

  @override
  Widget build(BuildContext context) {
    final displayLogs = logs.isEmpty ? _sampleLogs : logs.take(4).toList();
    return Column(
      children: displayLogs.map((log) {
        final food = _foodForLog(log);
        final meal = _mealLabel(log['meal_type']?.toString() ?? 'Meal');
        final calories = _caloriesForLog(log, food);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF3FBF6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const _SoftIcon(
                    icon: Icons.local_dining_outlined,
                    color: Color(0xFF16A05D),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food['name']?.toString() ?? 'Logged food',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$meal   -   ${_timeLabel(log)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        calories.round().toString(),
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'cal',
                        style: TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Map<String, dynamic> _foodForLog(Map<String, dynamic> log) {
    if (log['food'] is Map) {
      return Map<String, dynamic>.from(log['food'] as Map);
    }
    final id = log['food_id'];
    return foods.firstWhere(
      (food) => food['id'] == id,
      orElse: () => {'name': log['food_name'] ?? 'Logged food', 'calories': 0},
    );
  }

  double _caloriesForLog(Map<String, dynamic> log, Map<String, dynamic> food) {
    final direct = double.tryParse(log['calories']?.toString() ?? '');
    if (direct != null) {
      return direct;
    }
    final calories = double.tryParse(food['calories']?.toString() ?? '') ?? 0;
    final quantity = double.tryParse(log['quantity']?.toString() ?? '') ?? 1;
    return calories * quantity;
  }

  String _mealLabel(String value) {
    if (value.isEmpty) {
      return 'Meal';
    }
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  String _timeLabel(Map<String, dynamic> log) {
    final raw = log['created_at']?.toString() ?? log['logged_at']?.toString();
    if (raw == null || raw.isEmpty) {
      return 'Today';
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    final hour = parsed.hour == 0
        ? 12
        : parsed.hour > 12
        ? parsed.hour - 12
        : parsed.hour;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final suffix = parsed.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  static final _sampleLogs = [
    {
      'food': {'name': 'Bai Sach Chrouk', 'calories': 450},
      'meal_type': 'Breakfast',
    },
    {
      'food': {'name': 'Kuy Teav', 'calories': 550},
      'meal_type': 'Lunch',
    },
    {
      'food': {'name': 'Grilled Fish', 'calories': 350},
      'meal_type': 'Dinner',
    },
    {
      'food': {'name': 'Mixed Fruits', 'calories': 120},
      'meal_type': 'Snack',
    },
  ];
}

class FoodChip extends StatelessWidget {
  const FoodChip({super.key, required this.food});

  final Map<String, dynamic> food;

  @override
  Widget build(BuildContext context) {
    final category = food['category']?.toString() ?? 'food';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _foodColor(category).withValues(alpha: 0.12),
        border: Border.all(color: _foodColor(category).withValues(alpha: 0.32)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_foodIcon(category), size: 17, color: _foodColor(category)),
            const SizedBox(width: 8),
            Text(
              food['name'].toString(),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Color _foodColor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('protein') || lower.contains('meal')) {
      return _coral;
    }
    if (lower.contains('fruit') || lower.contains('snack')) {
      return _amber;
    }
    if (lower.contains('carbohydrate') || lower.contains('breakfast')) {
      return _blue;
    }
    return _leaf;
  }

  IconData _foodIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('protein') || lower.contains('meal')) {
      return Icons.restaurant;
    }
    if (lower.contains('fruit') || lower.contains('snack')) {
      return Icons.local_dining;
    }
    if (lower.contains('carbohydrate') || lower.contains('breakfast')) {
      return Icons.rice_bowl_outlined;
    }
    return Icons.eco_outlined;
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _targetWeight = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  final _conditions = TextEditingController();
  String _gender = 'male';
  String _activity = 'moderate';
  String _goal = 'maintain';
  String _preference = 'high-protein';
  String _exercise = '3 days per week';
  String _habits = 'balanced';
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _targetWeight.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    _conditions.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await widget.apiClient.profile();
      final goal = await widget.apiClient.goal();
      _setNumberText(_age, profile['age']);
      _setNumberText(_height, profile['height_cm']);
      _setNumberText(_weight, profile['weight_kg']);
      _conditions.text = profile['health_conditions']?.toString() ?? '';
      _gender = profile['gender']?.toString() ?? _gender;
      _activity = profile['activity_level']?.toString() ?? _activity;
      _preference = profile['food_preference']?.toString() ?? _preference;
      _exercise = profile['exercise_frequency']?.toString() ?? _exercise;
      _habits = profile['eating_habits']?.toString() ?? _habits;
      if (goal != null) {
        _goal = goal['goal_type']?.toString() ?? _goal;
        _setNumberText(_targetWeight, goal['target_weight_kg']);
        _setNumberText(_protein, goal['protein_target_g']);
        _setNumberText(_carbs, goal['carbs_target_g']);
        _setNumberText(_fat, goal['fat_target_g']);
      }
    } catch (error) {
      _error = error.toString();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _save() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.apiClient.saveProfile(
        profile: {
          'age': int.tryParse(_age.text) ?? 28,
          'gender': _gender,
          'height_cm': double.tryParse(_height.text) ?? 175,
          'weight_kg': double.tryParse(_weight.text) ?? 72.5,
          'activity_level': _activity,
          'food_preference': _preference,
          'dietary_preference': _preference,
          'health_conditions': _conditions.text.trim().isEmpty
              ? null
              : _conditions.text.trim(),
          'exercise_frequency': _exercise,
          'eating_habits': _habits,
        },
        goal: {
          'goal_type': _goal,
          'target_weight_kg': double.tryParse(_targetWeight.text),
          'daily_calorie_target': _targetCalories.round(),
          'protein_target_g': double.tryParse(_protein.text) ?? 120,
          'carbs_target_g': double.tryParse(_carbs.text) ?? 200,
          'fat_target_g': double.tryParse(_fat.text) ?? 65,
        },
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
      });
      await showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.42),
        builder: (context) => BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: const ProfileSavedDialog(),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  void _setNumberText(TextEditingController controller, dynamic value) {
    final number = _foodNumber(value);
    if (number > 0) {
      controller.text = _formatFoodNumber(number);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bmi = _bmi;
    final bmr = _bmr;
    final targetCalories = _targetCalories;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 26, 32, 34),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Health Profile',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _appText(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your body information and health goals',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: _appMutedText(context)),
            ),
            const SizedBox(height: 28),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 860;
                final form = ProfileFormCard(
                  loading: _loading,
                  age: _age,
                  height: _height,
                  weight: _weight,
                  targetWeight: _targetWeight,
                  conditions: _conditions,
                  gender: _gender,
                  activity: _activity,
                  goal: _goal,
                  preference: _preference,
                  exercise: _exercise,
                  habits: _habits,
                  onGenderChanged: (value) => setState(() => _gender = value),
                  onActivityChanged: (value) =>
                      setState(() => _activity = value),
                  onGoalChanged: (value) => setState(() => _goal = value),
                  onPreferenceChanged: (value) =>
                      setState(() => _preference = value),
                  onExerciseChanged: (value) =>
                      setState(() => _exercise = value),
                  onHabitsChanged: (value) => setState(() => _habits = value),
                  onMetricsChanged: () => setState(() {}),
                  onSave: _save,
                );
                final insights = ProfileInsightColumn(
                  bmi: bmi,
                  bmr: bmr,
                  targetCalories: targetCalories,
                );
                if (stacked) {
                  return Column(
                    children: [form, const SizedBox(height: 18), insights],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: form),
                    const SizedBox(width: 28),
                    Expanded(flex: 3, child: insights),
                  ],
                );
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              ErrorBanner(message: _error!),
            ],
          ],
        ),
      ),
    );
  }

  double get _heightValue => double.tryParse(_height.text) ?? 175;
  double get _weightValue => double.tryParse(_weight.text) ?? 72.5;
  int get _ageValue => int.tryParse(_age.text) ?? 28;

  double get _bmi {
    final meters = _heightValue / 100;
    if (meters <= 0) {
      return 0;
    }
    return _weightValue / (meters * meters);
  }

  double get _bmr {
    final base = 10 * _weightValue + 6.25 * _heightValue - 5 * _ageValue;
    return _gender == 'female' ? base - 161 : base + 5;
  }

  double get _targetCalories {
    final multiplier = switch (_activity) {
      'sedentary' => 1.2,
      'light' => 1.375,
      'moderate' => 1.55,
      'active' => 1.725,
      'very_active' => 1.9,
      _ => 1.55,
    };
    final maintenance = _bmr * multiplier;
    return switch (_goal) {
      'lose_weight' => maintenance - 400,
      'gain_muscle' => maintenance + 250,
      'gain_weight' => maintenance + 400,
      _ => maintenance,
    };
  }
}

class ProfileFormCard extends StatelessWidget {
  const ProfileFormCard({
    super.key,
    required this.loading,
    required this.age,
    required this.height,
    required this.weight,
    required this.targetWeight,
    required this.conditions,
    required this.gender,
    required this.activity,
    required this.goal,
    required this.preference,
    required this.exercise,
    required this.habits,
    required this.onGenderChanged,
    required this.onActivityChanged,
    required this.onGoalChanged,
    required this.onPreferenceChanged,
    required this.onExerciseChanged,
    required this.onHabitsChanged,
    required this.onMetricsChanged,
    required this.onSave,
  });

  final bool loading;
  final TextEditingController age;
  final TextEditingController height;
  final TextEditingController weight;
  final TextEditingController targetWeight;
  final TextEditingController conditions;
  final String gender;
  final String activity;
  final String goal;
  final String preference;
  final String exercise;
  final String habits;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<String> onActivityChanged;
  final ValueChanged<String> onGoalChanged;
  final ValueChanged<String> onPreferenceChanged;
  final ValueChanged<String> onExerciseChanged;
  final ValueChanged<String> onHabitsChanged;
  final VoidCallback onMetricsChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 28, 30, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ProfileSectionTitle(
              icon: Icons.person_outline,
              title: 'Body Information',
            ),
            const SizedBox(height: 18),
            ProfileFieldGrid(
              children: [
                ProfileTextField(
                  controller: age,
                  label: 'Age',
                  hint: '28',
                  onChanged: onMetricsChanged,
                ),
                ProfileSelectField(
                  label: 'Gender',
                  value: gender,
                  values: const ['male', 'female'],
                  labels: const {'male': 'Male', 'female': 'Female'},
                  onChanged: onGenderChanged,
                ),
                ProfileTextField(
                  controller: height,
                  label: 'Height (cm)',
                  hint: '175',
                  onChanged: onMetricsChanged,
                ),
                ProfileTextField(
                  controller: weight,
                  label: 'Weight (kg)',
                  hint: '72.5',
                  onChanged: onMetricsChanged,
                ),
                ProfileTextField(
                  controller: targetWeight,
                  label: 'Target Weight (kg)',
                  hint: '67.5',
                ),
              ],
            ),
            const SizedBox(height: 34),
            const ProfileSectionTitle(
              icon: Icons.bolt_outlined,
              title: 'Activity & Lifestyle',
            ),
            const SizedBox(height: 18),
            ProfileFieldGrid(
              children: [
                ProfileSelectField(
                  label: 'Activity Level',
                  value: activity,
                  values: const [
                    'sedentary',
                    'light',
                    'moderate',
                    'active',
                    'very_active',
                  ],
                  labels: const {
                    'sedentary': 'Sedentary',
                    'light': 'Light (1-3 days/week)',
                    'moderate': 'Moderate (3-5 days/week)',
                    'active': 'Active (6-7 days/week)',
                    'very_active': 'Very Active',
                  },
                  onChanged: onActivityChanged,
                ),
                ProfileSelectField(
                  label: 'Exercise Frequency',
                  value: exercise,
                  values: const [
                    'none',
                    '1-2 times/week',
                    '3-5 times/week',
                    '3 days per week',
                    'daily',
                  ],
                  labels: const {
                    'none': 'None',
                    '1-2 times/week': '1-2 times/week',
                    '3-5 times/week': '3-5 times/week',
                    '3 days per week': '3-5 times/week',
                    'daily': 'Daily',
                  },
                  onChanged: onExerciseChanged,
                ),
                ProfileSelectField(
                  label: 'Goal',
                  value: goal,
                  values: const [
                    'lose_weight',
                    'maintain',
                    'gain_muscle',
                    'gain_weight',
                  ],
                  labels: const {
                    'lose_weight': 'Lose Weight',
                    'maintain': 'Maintain',
                    'gain_muscle': 'Gain Muscle',
                    'gain_weight': 'Gain Weight',
                  },
                  onChanged: onGoalChanged,
                ),
                ProfileSelectField(
                  label: 'Dietary Preference',
                  value: preference,
                  values: const [
                    'balanced',
                    'high-protein',
                    'low-carb',
                    'vegetarian',
                  ],
                  labels: const {
                    'balanced': 'Balanced',
                    'high-protein': 'High Protein',
                    'low-carb': 'Low Carb',
                    'vegetarian': 'Vegetarian',
                  },
                  onChanged: onPreferenceChanged,
                ),
              ],
            ),
            const SizedBox(height: 34),
            const ProfileSectionTitle(
              icon: Icons.health_and_safety_outlined,
              title: 'Health Information',
            ),
            const SizedBox(height: 18),
            ProfileSelectField(
              label: 'Eating Habits',
              value: habits,
              values: const ['balanced', 'regular', 'irregular', 'snacking'],
              labels: const {
                'balanced': 'Regular (3 meals/day)',
                'regular': 'Regular (3 meals/day)',
                'irregular': 'Irregular',
                'snacking': 'Frequent snacking',
              },
              onChanged: onHabitsChanged,
            ),
            const SizedBox(height: 18),
            ProfileTextField(
              controller: conditions,
              label: 'Health Conditions (Optional)',
              hint: 'e.g., diabetes, hypertension, etc.',
              minLines: 3,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: loading ? null : onSave,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: const Color(0xFF16A05D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: const Text(
                'Save Profile',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileFieldGrid extends StatelessWidget {
  const ProfileFieldGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 520 ? 1 : 2;
        const gap = 18.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: 18,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }
}

class ProfileSectionTitle extends StatelessWidget {
  const ProfileSectionTitle({
    super.key,
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF16A05D), size: 18),
        const SizedBox(width: 9),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: _appText(context),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class ProfileTextField extends StatelessWidget {
  const ProfileTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.minLines = 1,
    this.keyboardType = TextInputType.number,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int minLines;
  final TextInputType keyboardType;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileFieldLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          minLines: minLines,
          maxLines: minLines == 1 ? 1 : minLines,
          onChanged: (_) => onChanged?.call(),
          style: TextStyle(color: _appText(context), fontSize: 14),
          decoration: _profileInputDecoration(context, hint),
        ),
      ],
    );
  }
}

class ProfileSelectField extends StatelessWidget {
  const ProfileSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.values,
    required this.labels,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final Map<String, String> labels;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = values.contains(value) ? values : [...values, value];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileFieldLabel(label),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: _profileInputDecoration(context, null),
          dropdownColor: _appSurface(context),
          style: TextStyle(color: _appText(context), fontSize: 14),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFF98A2B3),
            size: 18,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(labels[item] ?? _prettyLabel(item)),
                ),
              )
              .toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ],
    );
  }

  String _prettyLabel(String value) {
    return value
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .map(
          (part) =>
              part.isEmpty ? part : part[0].toUpperCase() + part.substring(1),
        )
        .join(' ');
  }
}

class ProfileFieldLabel extends StatelessWidget {
  const ProfileFieldLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: _appMutedText(context),
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

InputDecoration _profileInputDecoration(BuildContext context, String? hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: _appMutedText(context), fontSize: 14),
    filled: true,
    fillColor: _appSurfaceSoft(context),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: _appBorder(context)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: _appBorder(context)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF16A05D), width: 1.4),
    ),
  );
}

class ProfileInsightColumn extends StatelessWidget {
  const ProfileInsightColumn({
    super.key,
    required this.bmi,
    required this.bmr,
    required this.targetCalories,
  });

  final double bmi;
  final double bmr;
  final double targetCalories;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BmiInsightCard(bmi: bmi),
        const SizedBox(height: 22),
        ProfileNumberCard(
          title: 'Basal Metabolic Rate',
          value: bmr.round().toString(),
          unit: 'calories/day',
          color: const Color(0xFF4C8DF6),
          note: 'This is the number of calories your body burns at rest',
        ),
        const SizedBox(height: 22),
        ProfileNumberCard(
          title: 'Target Daily Calories',
          value: targetCalories.round().toString(),
          unit: 'calories/day',
          color: const Color(0xFFFF7417),
          note: 'Based on your activity level and selected health goal',
        ),
      ],
    );
  }
}

class ProfileSavedDialog extends StatelessWidget {
  const ProfileSavedDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _appSurface(context),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x24000000),
                  blurRadius: 28,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Color(0xFFDDF8E8),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.check_circle_outline,
                        color: _leaf,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Success!',
                    style: TextStyle(
                      color: _appText(context),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Profile saved successfully',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _appMutedText(context),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(38),
                      backgroundColor: const Color(0xFF087A3D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text(
                      'Dismiss',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BmiInsightCard extends StatelessWidget {
  const BmiInsightCard({super.key, required this.bmi});

  final double bmi;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Body Mass Index (BMI)',
              style: TextStyle(
                color: _appText(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Text(
                    bmi.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Color(0xFF16B978),
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      height: 0.95,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _bmiCategory(bmi),
                    style: const TextStyle(
                      color: Color(0xFF16B978),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const BmiRangeRow(label: 'Underweight', value: '< 18.5'),
            const SizedBox(height: 10),
            const BmiRangeRow(
              label: 'Normal',
              value: '18.5 - 24.9',
              highlighted: true,
            ),
            const SizedBox(height: 10),
            const BmiRangeRow(label: 'Overweight', value: '25 - 29.9'),
            const SizedBox(height: 10),
            const BmiRangeRow(label: 'Obese', value: '>= 30'),
          ],
        ),
      ),
    );
  }

  String _bmiCategory(double value) {
    if (value < 18.5) return 'Underweight';
    if (value < 25) return 'Normal';
    if (value < 30) return 'Overweight';
    return 'Obese';
  }
}

class BmiRangeRow extends StatelessWidget {
  const BmiRangeRow({
    super.key,
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFE0F7EF) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: highlighted
                      ? const Color(0xFF16A05D)
                      : _appMutedText(context),
                  fontSize: 12,
                  fontWeight: highlighted ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: highlighted
                    ? const Color(0xFF16A05D)
                    : _appMutedText(context),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileNumberCard extends StatelessWidget {
  const ProfileNumberCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
    required this.note,
  });

  final String title;
  final String value;
  final String unit;
  final Color color;
  final String note;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 26),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: TextStyle(
                  color: _appText(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 40,
                fontWeight: FontWeight.w900,
                height: 0.95,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              unit,
              style: TextStyle(color: _appMutedText(context), fontSize: 13),
            ),
            const SizedBox(height: 26),
            Text(
              note,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _appMutedText(context),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final _calories = TextEditingController(text: '2200');
  final _protein = TextEditingController(text: '140');
  final _carbs = TextEditingController(text: '240');
  final _fat = TextEditingController(text: '70');
  final _allergies = TextEditingController();
  final _budget = TextEditingController(text: '35');
  String _goal = 'maintain';
  String _preference = 'high-protein';
  bool _loading = false;
  bool _weeklyPlan = false;
  String? _error;
  DateTime _selectedDate = _dateOnly(DateTime.now());
  List<Map<String, dynamic>> _savedPlans = [];
  Map<String, dynamic>? _groceryList;

  @override
  void initState() {
    super.initState();
    _loadPlannerContext();
  }

  @override
  void dispose() {
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    _allergies.dispose();
    _budget.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _payload => {
    'daily_calorie_target': int.tryParse(_calories.text) ?? 2200,
    'health_goal': _goal,
    'food_preference': _preference,
    'allergies': _allergies.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(),
    'budget': double.tryParse(_budget.text),
    'protein_requirement_g': double.tryParse(_protein.text),
    'carbohydrate_requirement_g': double.tryParse(_carbs.text),
    'fat_requirement_g': double.tryParse(_fat.text),
  };

  Map<String, Map<String, dynamic>> get _plansByDate => {
    for (final plan in _savedPlans.reversed)
      if (plan['plan_date'] != null) plan['plan_date'].toString(): plan,
  };

  Future<void> _loadPlannerContext() async {
    try {
      final plans = await widget.apiClient.mealPlans();
      final profile = await widget.apiClient.profile();
      final goal = await widget.apiClient.goal() ?? <String, dynamic>{};
      final allergies = await widget.apiClient.allergies();
      var calories = _foodNumber(goal['daily_calorie_target']);
      if (calories <= 0 &&
          profile['age'] != null &&
          profile['height_cm'] != null &&
          profile['weight_kg'] != null) {
        final prediction = await widget.apiClient.predictCalories({
          'age': profile['age'],
          'gender': profile['gender'] ?? 'male',
          'height_cm': profile['height_cm'],
          'weight_kg': profile['weight_kg'],
          'activity_level': profile['activity_level'] ?? 'moderate',
          'goal': goal['goal_type'] ?? 'maintain',
        });
        calories = _foodNumber(prediction['recommended_daily_calories']);
      }
      if (!mounted) return;
      setState(() {
        _savedPlans = plans;
        if (calories > 0) _calories.text = calories.round().toString();
        if (goal['protein_target_g'] != null) {
          _protein.text = _formatFoodNumber(
            _foodNumber(goal['protein_target_g']),
          );
        }
        if (goal['carbs_target_g'] != null) {
          _carbs.text = _formatFoodNumber(_foodNumber(goal['carbs_target_g']));
        }
        if (goal['fat_target_g'] != null) {
          _fat.text = _formatFoodNumber(_foodNumber(goal['fat_target_g']));
        }
        _goal = goal['goal_type']?.toString() ?? _goal;
        _preference = profile['food_preference']?.toString() ?? _preference;
        _allergies.text = allergies
            .map((item) => item['ingredient']?.toString() ?? '')
            .where((item) => item.isNotEmpty)
            .join(', ');
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _generatePlan() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_weeklyPlan) {
        await _generateWeek(_selectedDate);
      } else {
        await _generateDay(_selectedDate);
      }
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _generateGroceries() async {
    final plansByDate = _plansByDate;
    final exportDays = _weeklyPlan
        ? _weeklyPlannerDays(_weekStartDate(_selectedDate), plansByDate)
        : [
            _PlannerWeekDay(
              name: _plannerDateLabel(_selectedDate, false),
              date: _selectedDate,
              planId: plansByDate[_isoDate(_selectedDate)]?['id'] as int?,
              meals: _plannerMealsFromPlan(
                plansByDate[_isoDate(_selectedDate)],
              ),
            ),
          ];
    final selectedIds = await showDialog<List<int>>(
      context: context,
      builder: (context) => _GroceryExportDialog(days: exportDays),
    );
    if (selectedIds == null || selectedIds.isEmpty) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.apiClient.generateGroceryList(
        mealPlanIds: selectedIds,
        budget: (double.tryParse(_budget.text) ?? 0) * selectedIds.length,
      );
      setState(() => _groceryList = result);
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => _GroceryExportResultDialog(data: result),
        );
      }
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _generateDay(DateTime date) async {
    final result = await widget.apiClient.generateMealPlan(
      _payload,
      planDate: _isoDate(date),
    );
    if (mounted) {
      setState(() => _mergeSavedPlans([result]));
    }
  }

  Future<void> _generateWeek(DateTime date) async {
    final weekStart = _weekStartDate(date);
    final results = await widget.apiClient.generateWeeklyMealPlan(
      _payload,
      planDate: _isoDate(weekStart),
    );
    if (mounted) {
      setState(() {
        _mergeSavedPlans(results);
        _selectedDate = weekStart;
      });
    }
  }

  void _mergeSavedPlans(List<Map<String, dynamic>> plans) {
    final merged = _plansByDate;
    for (final plan in plans) {
      final date = plan['plan_date']?.toString();
      if (date != null) {
        merged[date] = plan;
      }
    }
    _savedPlans = merged.values.toList()
      ..sort((a, b) {
        final dateCompare = b['plan_date'].toString().compareTo(
          a['plan_date'].toString(),
        );
        if (dateCompare != 0) {
          return dateCompare;
        }
        return b['created_at'].toString().compareTo(a['created_at'].toString());
      });
  }

  Future<void> _moveDate(int amount) async {
    setState(() {
      _selectedDate = _dateOnly(_selectedDate.add(Duration(days: amount)));
    });
  }

  Future<void> _setPlanMode(bool weeklyPlan) async {
    setState(() => _weeklyPlan = weeklyPlan);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = _dateOnly(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final plansByDate = _plansByDate;
    final selectedPlan = plansByDate[_isoDate(_selectedDate)];
    final meals = _plannerMealsFromPlan(selectedPlan);
    final weekStart = _weekStartDate(_selectedDate);
    final weekDays = _weeklyPlannerDays(weekStart, plansByDate);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            compact ? 4 : 0,
            compact ? 2 : 0,
            compact ? 4 : 0,
            32,
          ),
          children: [
            _MealPlannerHeader(
              loading: _loading,
              onExportGrocery: _generateGroceries,
              onGeneratePlan: _generatePlan,
            ),
            const SizedBox(height: 18),
            _MealPlannerControls(
              compact: compact,
              weeklyPlan: _weeklyPlan,
              onPlanChanged: _setPlanMode,
              dateLabel: _plannerDateLabel(_selectedDate, _weeklyPlan),
              onPrevious: () => _moveDate(_weeklyPlan ? -7 : -1),
              onNext: () => _moveDate(_weeklyPlan ? 7 : 1),
              onPickDate: _pickDate,
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Plan settings',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, settingsConstraints) {
                      final width = settingsConstraints.maxWidth < 700
                          ? settingsConstraints.maxWidth
                          : (settingsConstraints.maxWidth - 24) / 3;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: width,
                            child: NumberField(
                              controller: _calories,
                              label: 'Daily calories',
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: NumberField(
                              controller: _protein,
                              label: 'Protein (g)',
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: NumberField(
                              controller: _carbs,
                              label: 'Carbohydrates (g)',
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: NumberField(
                              controller: _fat,
                              label: 'Fat (g)',
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: NumberField(
                              controller: _budget,
                              label: 'Daily grocery budget estimate',
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: TextFormField(
                              controller: _allergies,
                              decoration: const InputDecoration(
                                labelText: 'Allergies (comma separated)',
                              ),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: SelectField(
                              label: 'Goal',
                              value: _goal,
                              values: const [
                                'lose_weight',
                                'maintain',
                                'gain_muscle',
                                'gain_weight',
                              ],
                              onChanged: (value) =>
                                  setState(() => _goal = value),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: SelectField(
                              label: 'Preference',
                              value: _preference,
                              values: const [
                                'balanced',
                                'high-protein',
                                'low-carb',
                                'vegetarian',
                                'vegan',
                                'halal',
                                'cambodian',
                              ],
                              onChanged: (value) =>
                                  setState(() => _preference = value),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Budget is checked against estimated grocery costs after the plan is generated.',
                    style: TextStyle(color: Color(0xFF667085), fontSize: 11),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              ErrorBanner(message: _error!),
            ],
            if (_groceryList != null) ...[
              const SizedBox(height: 14),
              const SuccessBanner(message: 'Grocery list generated'),
            ],
            const SizedBox(height: 24),
            if (_weeklyPlan) ...[
              _WeeklyPlannerGrid(days: weekDays),
              const SizedBox(height: 28),
              _WeeklyOverviewCard(days: weekDays),
              const SizedBox(height: 28),
              _DailyTotalNutritionCard(meals: meals),
            ] else ...[
              _MealPlannerGrid(meals: meals),
              const SizedBox(height: 26),
              _DailyTotalCard(meals: meals),
            ],
          ],
        );
      },
    );
  }
}

class _GroceryExportDialog extends StatefulWidget {
  const _GroceryExportDialog({required this.days});

  final List<_PlannerWeekDay> days;

  @override
  State<_GroceryExportDialog> createState() => _GroceryExportDialogState();
}

class _GroceryExportDialogState extends State<_GroceryExportDialog> {
  late final Set<int> _selectedPlanIds;

  List<_PlannerWeekDay> get _exportableDays =>
      widget.days.where((day) => day.planId != null).toList();

  @override
  void initState() {
    super.initState();
    _selectedPlanIds = _exportableDays
        .map((day) => day.planId)
        .whereType<int>()
        .toSet();
  }

  void _setAll(bool selected) {
    setState(() {
      _selectedPlanIds.clear();
      if (selected) {
        _selectedPlanIds.addAll(_exportableDays.map((day) => day.planId!));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final exportableDays = _exportableDays;
    final allSelected =
        exportableDays.isNotEmpty &&
        _selectedPlanIds.length == exportableDays.length;
    return AlertDialog(
      title: const Text('Export to grocery'),
      content: SizedBox(
        width: 560,
        child: exportableDays.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'Generate a meal plan first, then export it to grocery.',
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          value: allSelected,
                          onChanged: (value) => _setAll(value ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Select all visible meal plans'),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _setAll(false),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 420),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: exportableDays.length,
                      separatorBuilder: (_, _) => const Divider(height: 12),
                      itemBuilder: (context, index) {
                        final day = exportableDays[index];
                        final planId = day.planId!;
                        return CheckboxListTile(
                          value: _selectedPlanIds.contains(planId),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedPlanIds.add(planId);
                              } else {
                                _selectedPlanIds.remove(planId);
                              }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            day.name,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            _exportFoodPreview(day),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          secondary: Text(
                            '${_formatFoodNumber(day.calories)} cal',
                            style: const TextStyle(
                              color: Color(0xFF12A05C),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _selectedPlanIds.isEmpty
              ? null
              : () => Navigator.of(context).pop(_selectedPlanIds.toList()),
          icon: const Icon(Icons.shopping_cart_outlined, size: 16),
          label: Text('Export ${_selectedPlanIds.length} selected'),
        ),
      ],
    );
  }

  String _exportFoodPreview(_PlannerWeekDay day) {
    final foods = day.meals
        .expand((meal) => meal.items.map((item) => item.name))
        .toSet()
        .toList();
    if (foods.isEmpty) {
      return 'No foods in this plan';
    }
    return foods.join(', ');
  }
}

class _GroceryExportResultDialog extends StatelessWidget {
  const _GroceryExportResultDialog({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final items = data['items'] as List<dynamic>? ?? [];
    return AlertDialog(
      title: const Text('Grocery list exported'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SuccessBanner(
              message:
                  '${items.length} grocery item${items.length == 1 ? '' : 's'} created. Estimated total: ${data['estimated_total_cost']}',
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = Map<String, dynamic>.from(items[index] as Map);
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.shopping_basket_outlined),
                    title: Text(item['food_item']?.toString() ?? 'Item'),
                    subtitle: Text(item['quantity']?.toString() ?? ''),
                    trailing: Text('${item['estimated_cost']}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: () => grocery_pdf_export.printGroceryListPdf(data),
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
          label: const Text('Print / Save PDF'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _MealPlannerHeader extends StatelessWidget {
  const _MealPlannerHeader({
    required this.loading,
    required this.onExportGrocery,
    required this.onGeneratePlan,
  });

  final bool loading;
  final VoidCallback onExportGrocery;
  final VoidCallback onGeneratePlan;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meal Planner',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _appText(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Generate and manage your meal plans',
              style: TextStyle(
                color: _appMutedText(context),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
        final actions = Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: compact ? WrapAlignment.start : WrapAlignment.end,
          children: [
            SizedBox(
              height: 38,
              child: OutlinedButton.icon(
                onPressed: loading ? null : onExportGrocery,
                icon: const Icon(Icons.shopping_cart_outlined, size: 15),
                label: const Text('Export to Grocery'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _appText(context),
                  side: const BorderSide(color: Color(0xFFD0D5DD)),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 38,
              child: FilledButton.icon(
                onPressed: loading ? null : onGeneratePlan,
                icon: const Icon(Icons.bolt_outlined, size: 15),
                label: Text(loading ? 'Generating...' : 'Generate Plan'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF12B76A),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 14), actions],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            const SizedBox(width: 18),
            actions,
          ],
        );
      },
    );
  }
}

class _MealPlannerControls extends StatelessWidget {
  const _MealPlannerControls({
    required this.compact,
    required this.weeklyPlan,
    required this.onPlanChanged,
    required this.dateLabel,
    required this.onPrevious,
    required this.onNext,
    required this.onPickDate,
  });

  final bool compact;
  final bool weeklyPlan;
  final ValueChanged<bool> onPlanChanged;
  final String dateLabel;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final tabs = DecoratedBox(
      decoration: BoxDecoration(
        color: _appSurfaceSoft(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PlannerTab(
              label: 'Daily Plan',
              selected: !weeklyPlan,
              onTap: () => onPlanChanged(false),
            ),
            _PlannerTab(
              label: 'Weekly Plan',
              selected: weeklyPlan,
              onTap: () => onPlanChanged(true),
            ),
          ],
        ),
      ),
    );
    final date = SizedBox(
      height: 40,
      width: compact ? double.infinity : 286,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _appSurface(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _appBorder(context)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 4),
            IconButton(
              tooltip: weeklyPlan ? 'Previous week' : 'Previous day',
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
              iconSize: 18,
              color: const Color(0xFF98A2B3),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: onPickDate,
                icon: const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Color(0xFF12B76A),
                ),
                label: Text(
                  dateLabel,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _appText(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  foregroundColor: _appText(context),
                ),
              ),
            ),
            IconButton(
              tooltip: weeklyPlan ? 'Next week' : 'Next day',
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
              iconSize: 18,
              color: const Color(0xFF98A2B3),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [tabs, const SizedBox(height: 12), date],
      );
    }
    return Row(children: [tabs, const Spacer(), date]);
  }
}

class _PlannerTab extends StatelessWidget {
  const _PlannerTab({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? _appSurface(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? _appText(context) : _appMutedText(context),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _MealPlannerGrid extends StatelessWidget {
  const _MealPlannerGrid({required this.meals});

  final List<_PlannerMeal> meals;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 20.0;
        final columns = constraints.maxWidth < 760 ? 1 : 2;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: meals
              .map(
                (meal) => SizedBox(
                  width: width,
                  child: _MealPlannerCard(meal: meal),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MealPlannerCard extends StatelessWidget {
  const _MealPlannerCard({required this.meal});

  final _PlannerMeal meal;

  @override
  Widget build(BuildContext context) {
    return _FoodLogPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${meal.icon} ${meal.name}',
                    style: TextStyle(
                      color: _appText(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${_formatFoodNumber(meal.calories)} cal',
                  style: const TextStyle(
                    color: Color(0xFF12A05C),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...meal.items.map((item) => _PlannerFoodRow(item: item)),
            const SizedBox(height: 18),
            const Divider(height: 1, color: Color(0xFFE4E7EC)),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _PlannerMacroStat(
                    label: 'PROTEIN',
                    value: '${_formatFoodNumber(meal.protein)}g',
                  ),
                ),
                Expanded(
                  child: _PlannerMacroStat(
                    label: 'CARBS',
                    value: '${_formatFoodNumber(meal.carbs)}g',
                  ),
                ),
                Expanded(
                  child: _PlannerMacroStat(
                    label: 'FAT',
                    value: '${_formatFoodNumber(meal.fat)}g',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlannerFoodRow extends StatelessWidget {
  const _PlannerFoodRow({required this.item});

  final _PlannerFood item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'P: ${_formatFoodNumber(item.protein)}g • C: ${_formatFoodNumber(item.carbs)}g • F: ${_formatFoodNumber(item.fat)}g',
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_formatFoodNumber(item.calories)} cal',
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlannerMacroStat extends StatelessWidget {
  const _PlannerMacroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: _appMutedText(context),
            fontSize: 8,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          value,
          style: TextStyle(
            color: _appText(context),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _DailyTotalCard extends StatelessWidget {
  const _DailyTotalCard({required this.meals});

  final List<_PlannerMeal> meals;

  @override
  Widget build(BuildContext context) {
    final calories = meals.fold<double>(0, (sum, meal) => sum + meal.calories);
    final protein = meals.fold<double>(0, (sum, meal) => sum + meal.protein);
    final carbs = meals.fold<double>(0, (sum, meal) => sum + meal.carbs);
    final fat = meals.fold<double>(0, (sum, meal) => sum + meal.fat);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Total',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 620;
                final stats = [
                  _DailyCaloriesRing(value: calories),
                  _DailyTotalStat(
                    value: '${_formatFoodNumber(protein)}g',
                    label: 'PROTEIN',
                    color: const Color(0xFF3178C6),
                  ),
                  _DailyTotalStat(
                    value: '${_formatFoodNumber(carbs)}g',
                    label: 'CARBS',
                    color: const Color(0xFFFF7417),
                  ),
                  _DailyTotalStat(
                    value: '${_formatFoodNumber(fat)}g',
                    label: 'FAT',
                    color: const Color(0xFFFF3B5C),
                  ),
                ];
                if (compact) {
                  return Wrap(spacing: 16, runSpacing: 16, children: stats);
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: stats,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyPlannerGrid extends StatelessWidget {
  const _WeeklyPlannerGrid({required this.days});

  final List<_PlannerWeekDay> days;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 20.0;
        final columns = constraints.maxWidth < 620
            ? 1
            : constraints.maxWidth < 980
            ? 2
            : 3;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: days
              .map(
                (day) => SizedBox(
                  width: width,
                  child: _WeeklyPlannerDayCard(day: day),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _WeeklyPlannerDayCard extends StatelessWidget {
  const _WeeklyPlannerDayCard({required this.day});

  final _PlannerWeekDay day;

  @override
  Widget build(BuildContext context) {
    return _FoodLogPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    day.name,
                    style: TextStyle(
                      color: _appText(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${_formatFoodNumber(day.calories)} cal',
                  style: const TextStyle(
                    color: Color(0xFF12A05C),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...day.meals.map(
              (meal) => Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meal.icon, style: const TextStyle(fontSize: 11)),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '${meal.name}: ${_weeklyMealPreview(meal)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _appMutedText(context),
                          fontSize: 10,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyOverviewCard extends StatelessWidget {
  const _WeeklyOverviewCard({required this.days});

  final List<_PlannerWeekDay> days;

  @override
  Widget build(BuildContext context) {
    final totalCalories = days.fold<double>(
      0,
      (sum, day) => sum + day.calories,
    );
    final totalProtein = days.fold<double>(0, (sum, day) => sum + day.protein);
    final averageCalories = days.isEmpty ? 0.0 : totalCalories / days.length;
    return _FoodLogPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Overview',
              style: TextStyle(
                color: _appText(context),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 26),
            LayoutBuilder(
              builder: (context, constraints) {
                final stats = [
                  _WeeklyOverviewStat(
                    value: _formatFoodNumber(totalCalories),
                    label: 'Total Calories',
                    color: const Color(0xFF12A05C),
                  ),
                  _WeeklyOverviewStat(
                    value: '${_formatFoodNumber(totalProtein)}g',
                    label: 'Total Protein',
                    color: const Color(0xFF3178C6),
                  ),
                  _WeeklyOverviewStat(
                    value: _formatFoodNumber(averageCalories),
                    label: 'Avg Calories/Day',
                    color: const Color(0xFFFF7417),
                  ),
                  const _WeeklyOverviewStat(
                    value: '100%',
                    label: 'Compliance',
                    color: Color(0xFF12A05C),
                  ),
                ];
                return Wrap(
                  spacing: 24,
                  runSpacing: 20,
                  alignment: WrapAlignment.spaceBetween,
                  children: stats
                      .map(
                        (stat) => SizedBox(
                          width: constraints.maxWidth < 520 ? 120 : 132,
                          child: stat,
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyOverviewStat extends StatelessWidget {
  const _WeeklyOverviewStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF667085),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DailyTotalNutritionCard extends StatelessWidget {
  const _DailyTotalNutritionCard({required this.meals});

  final List<_PlannerMeal> meals;

  @override
  Widget build(BuildContext context) {
    final calories = meals.fold<double>(0, (sum, meal) => sum + meal.calories);
    final protein = meals.fold<double>(0, (sum, meal) => sum + meal.protein);
    final carbs = meals.fold<double>(0, (sum, meal) => sum + meal.carbs);
    final fat = meals.fold<double>(0, (sum, meal) => sum + meal.fat);
    return _FoodLogPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Total Nutrition',
              style: TextStyle(
                color: _appText(context),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 28),
            LayoutBuilder(
              builder: (context, constraints) {
                final tiles = [
                  _DailyCaloriesRing(value: calories),
                  _DailyNutritionReachCard(
                    label: 'Protein',
                    value: '${_formatFoodNumber(protein)}g',
                    color: const Color(0xFF3178C6),
                    background: const Color(0xFFF0F6FF),
                    icon: Icons.fitness_center,
                  ),
                  _DailyNutritionReachCard(
                    label: 'Carbs',
                    value: '${_formatFoodNumber(carbs)}g',
                    color: const Color(0xFFFF7417),
                    background: const Color(0xFFFFF4E8),
                    icon: Icons.rice_bowl_outlined,
                  ),
                  _DailyNutritionReachCard(
                    label: 'Fat',
                    value: '${_formatFoodNumber(fat)}g',
                    color: const Color(0xFF8B5CF6),
                    background: const Color(0xFFF6F0FF),
                    icon: Icons.blur_circular_outlined,
                  ),
                ];
                return Wrap(
                  spacing: 24,
                  runSpacing: 18,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: tiles,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyNutritionReachCard extends StatelessWidget {
  const _DailyNutritionReachCard({
    required this.label,
    required this.value,
    required this.color,
    required this.background,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final Color background;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: SizedBox(
        width: 126,
        height: 116,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Icon(icon, color: color, size: 15),
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  color: _appText(context),
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: 1,
                  minHeight: 6,
                  backgroundColor: Colors.white,
                  color: color.withValues(alpha: 0.35),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Daily Target\nReached',
                style: TextStyle(
                  color: color,
                  fontSize: 8,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyCaloriesRing extends StatelessWidget {
  const _DailyCaloriesRing({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: (value / 2000).clamp(0, 1),
              strokeWidth: 8,
              backgroundColor: Colors.white,
              color: const Color(0xFF16A05D),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatFoodNumber(value),
                style: const TextStyle(
                  color: Color(0xFF16A05D),
                  fontSize: 22,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'CALORIES',
                style: TextStyle(
                  color: Color(0xFF16A05D),
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyTotalStat extends StatelessWidget {
  const _DailyTotalStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        width: 150,
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlannerMeal {
  const _PlannerMeal({
    required this.name,
    required this.icon,
    required this.items,
  });

  final String name;
  final String icon;
  final List<_PlannerFood> items;

  double get calories => items.fold(0, (sum, item) => sum + item.calories);
  double get protein => items.fold(0, (sum, item) => sum + item.protein);
  double get carbs => items.fold(0, (sum, item) => sum + item.carbs);
  double get fat => items.fold(0, (sum, item) => sum + item.fat);
}

class _PlannerWeekDay {
  const _PlannerWeekDay({
    required this.name,
    required this.date,
    required this.planId,
    required this.meals,
  });

  final String name;
  final DateTime date;
  final int? planId;
  final List<_PlannerMeal> meals;

  double get calories => meals.fold(0, (sum, meal) => sum + meal.calories);
  double get protein => meals.fold(0, (sum, meal) => sum + meal.protein);
}

class _PlannerFood {
  const _PlannerFood({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
}

const _defaultPlannerMeals = [
  _PlannerMeal(
    name: 'Breakfast',
    icon: '🌅',
    items: [
      _PlannerFood(
        name: 'Bai Sach Chrouk',
        calories: 450,
        protein: 25,
        carbs: 55,
        fat: 12,
      ),
      _PlannerFood(
        name: 'Fried Egg',
        calories: 90,
        protein: 6,
        carbs: 0.5,
        fat: 7,
      ),
    ],
  ),
  _PlannerMeal(
    name: 'Lunch',
    icon: '☀️',
    items: [
      _PlannerFood(
        name: 'Grilled Chicken Breast',
        calories: 165,
        protein: 31,
        carbs: 0,
        fat: 3.6,
      ),
      _PlannerFood(
        name: 'Brown Rice',
        calories: 215,
        protein: 5,
        carbs: 45,
        fat: 2,
      ),
      _PlannerFood(
        name: 'Mixed Vegetables',
        calories: 80,
        protein: 3,
        carbs: 15,
        fat: 1,
      ),
    ],
  ),
  _PlannerMeal(
    name: 'Dinner',
    icon: '🌙',
    items: [
      _PlannerFood(
        name: 'Grilled Fish',
        calories: 250,
        protein: 35,
        carbs: 0,
        fat: 12,
      ),
      _PlannerFood(
        name: 'White Rice',
        calories: 200,
        protein: 4,
        carbs: 45,
        fat: 0.5,
      ),
    ],
  ),
  _PlannerMeal(
    name: 'Snacks',
    icon: '🍎',
    items: [
      _PlannerFood(
        name: 'Banana',
        calories: 105,
        protein: 1.3,
        carbs: 27,
        fat: 0.4,
      ),
      _PlannerFood(
        name: 'Mango',
        calories: 99,
        protein: 1.4,
        carbs: 25,
        fat: 0.6,
      ),
    ],
  ),
];

List<_PlannerWeekDay> _weeklyPlannerDays(
  DateTime weekStart,
  Map<String, Map<String, dynamic>> plansByDate,
) {
  return List.generate(7, (offset) {
    final date = _dateOnly(weekStart.add(Duration(days: offset)));
    final plan = plansByDate[_isoDate(date)];
    return _PlannerWeekDay(
      name: '${_weekdayName(date)} ${date.day}',
      date: date,
      planId: plan?['id'] as int?,
      meals: _plannerMealsFromPlan(plan),
    );
  });
}

List<_PlannerMeal> _plannerMealsFromPlan(Map<String, dynamic>? plan) {
  final planJson = plan?['plan_json'];
  if (planJson is Map) {
    return _plannerMealsFromRecommendation(Map<String, dynamic>.from(planJson));
  }
  return _defaultPlannerMeals;
}

String _weeklyMealPreview(_PlannerMeal meal) {
  if (meal.items.isEmpty) {
    return 'No foods selected';
  }
  return meal.items.take(2).map((item) => item.name).join(', ');
}

List<_PlannerMeal> _plannerMealsFromRecommendation(Map<String, dynamic> data) {
  final meals = data['meals'];
  if (meals is! List || meals.isEmpty) {
    return _defaultPlannerMeals;
  }
  return meals.map((mealData) {
    final meal = Map<String, dynamic>.from(mealData as Map);
    final type = meal['meal_type']?.toString() ?? 'meal';
    final items = meal['items'];
    final foods = items is List
        ? items.map((itemData) {
            final item = Map<String, dynamic>.from(itemData as Map);
            return _PlannerFood(
              name: item['name']?.toString() ?? 'Food',
              calories: _foodNumber(item['calories']),
              protein: _foodNumber(item['protein_g']),
              carbs: _foodNumber(item['carbs_g']),
              fat: _foodNumber(item['fat_g']),
            );
          }).toList()
        : <_PlannerFood>[];
    return _PlannerMeal(
      name: _mealTitle(type),
      icon: _plannerMealIcon(type),
      items: foods,
    );
  }).toList();
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

DateTime _weekStartDate(DateTime value) {
  final date = _dateOnly(value);
  return date.subtract(Duration(days: date.weekday - DateTime.monday));
}

String _isoDate(DateTime value) {
  final date = _dateOnly(value);
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _plannerDateLabel(DateTime selectedDate, bool weeklyPlan) {
  if (weeklyPlan) {
    final start = _weekStartDate(selectedDate);
    final end = start.add(const Duration(days: 6));
    return '${_shortMonthName(start)} ${start.day} - ${_shortMonthName(end)} ${end.day}';
  }
  final today = _dateOnly(DateTime.now());
  final selected = _dateOnly(selectedDate);
  final offset = selected.difference(today).inDays;
  final prefix = switch (offset) {
    0 => 'Today',
    1 => 'Tomorrow',
    -1 => 'Yesterday',
    _ => '${_shortMonthName(selected)} ${selected.day}',
  };
  return '$prefix - ${_weekdayName(selected)}';
}

String _weekdayName(DateTime value) {
  return const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][value.weekday - 1];
}

String _shortMonthName(DateTime value) {
  return const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][value.month - 1];
}

String _plannerMealIcon(String value) {
  return switch (value.toLowerCase()) {
    'breakfast' => '🌅',
    'lunch' => '☀️',
    'dinner' => '🌙',
    'snack' || 'snacks' => '🍎',
    _ => '🍽',
  };
}

class FoodLogScreen extends StatefulWidget {
  const FoodLogScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends State<FoodLogScreen> {
  final _quantity = TextEditingController(text: '1');
  final _notes = TextEditingController();
  List<Map<String, dynamic>> _foods = [];
  List<Map<String, dynamic>> _logs = [];
  Map<String, dynamic>? _summary;
  int? _selectedFoodId;
  String _mealType = 'breakfast';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _quantity.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final foods = await widget.apiClient.foods();
      final logs = await widget.apiClient.foodLogs();
      final summary = await widget.apiClient.nutritionSummary(todayIsoDate());
      final todayLogs = logs.where((log) {
        final parsed = DateTime.tryParse(log['logged_at']?.toString() ?? '');
        return parsed != null && _isoDate(parsed.toLocal()) == todayIsoDate();
      }).toList();
      setState(() {
        _foods = foods;
        _logs = todayLogs;
        _summary = summary;
        _selectedFoodId ??= foods.isEmpty ? null : foods.first['id'] as int;
        _error = null;
      });
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _logFood() async {
    if (_selectedFoodId == null) {
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.apiClient.logFood(
        foodId: _selectedFoodId!,
        mealType: _mealType,
        quantity: double.tryParse(_quantity.text) ?? 1,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        logDate: todayIsoDate(),
      );
      _notes.clear();
      await _load();
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _deleteFoodLog(int logId) async {
    setState(() => _loading = true);
    try {
      await widget.apiClient.deleteFoodLog(logId);
      await _load();
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        final content = [
          _FoodLoggingHeader(),
          const SizedBox(height: 24),
          if (_error != null) ...[
            ErrorBanner(message: _error!),
            const SizedBox(height: 16),
          ],
          if (_loading && _summary == null)
            const SizedBox(
              height: 320,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (compact)
            Column(
              children: [
                _FoodLogMainColumn(
                  foods: _foods,
                  logs: _logs,
                  selectedFoodId: _selectedFoodId,
                  mealType: _mealType,
                  quantity: _quantity,
                  notes: _notes,
                  loading: _loading,
                  onMealChanged: (value) => setState(() => _mealType = value),
                  onFoodChanged: (value) =>
                      setState(() => _selectedFoodId = value),
                  onLogFood: _logFood,
                  onDeleteLog: _deleteFoodLog,
                ),
                const SizedBox(height: 18),
                _FoodLogSidebar(summary: _summary),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: _FoodLogMainColumn(
                    foods: _foods,
                    logs: _logs,
                    selectedFoodId: _selectedFoodId,
                    mealType: _mealType,
                    quantity: _quantity,
                    notes: _notes,
                    loading: _loading,
                    onMealChanged: (value) => setState(() => _mealType = value),
                    onFoodChanged: (value) =>
                        setState(() => _selectedFoodId = value),
                    onLogFood: _logFood,
                    onDeleteLog: _deleteFoodLog,
                  ),
                ),
                const SizedBox(width: 22),
                SizedBox(width: 280, child: _FoodLogSidebar(summary: _summary)),
              ],
            ),
        ];
        return ListView(
          padding: EdgeInsets.fromLTRB(
            compact ? 4 : 0,
            compact ? 2 : 0,
            compact ? 4 : 0,
            28,
          ),
          children: content,
        );
      },
    );
  }
}

class _FoodLoggingHeader extends StatelessWidget {
  const _FoodLoggingHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Food Logging',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _appText(context),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Track your daily meals and nutrition',
          style: TextStyle(
            color: _appMutedText(context),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _FoodLogMainColumn extends StatelessWidget {
  const _FoodLogMainColumn({
    required this.foods,
    required this.logs,
    required this.selectedFoodId,
    required this.mealType,
    required this.quantity,
    required this.notes,
    required this.loading,
    required this.onMealChanged,
    required this.onFoodChanged,
    required this.onLogFood,
    required this.onDeleteLog,
  });

  final List<Map<String, dynamic>> foods;
  final List<Map<String, dynamic>> logs;
  final int? selectedFoodId;
  final String mealType;
  final TextEditingController quantity;
  final TextEditingController notes;
  final bool loading;
  final ValueChanged<String> onMealChanged;
  final ValueChanged<int?> onFoodChanged;
  final VoidCallback onLogFood;
  final ValueChanged<int> onDeleteLog;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LogFoodFormCard(
          foods: foods,
          selectedFoodId: selectedFoodId,
          mealType: mealType,
          quantity: quantity,
          notes: notes,
          loading: loading,
          onMealChanged: onMealChanged,
          onFoodChanged: onFoodChanged,
          onLogFood: onLogFood,
        ),
        const SizedBox(height: 20),
        _TodaysFoodLogCard(logs: logs, onDeleteLog: onDeleteLog),
      ],
    );
  }
}

class _LogFoodFormCard extends StatelessWidget {
  const _LogFoodFormCard({
    required this.foods,
    required this.selectedFoodId,
    required this.mealType,
    required this.quantity,
    required this.notes,
    required this.loading,
    required this.onMealChanged,
    required this.onFoodChanged,
    required this.onLogFood,
  });

  final List<Map<String, dynamic>> foods;
  final int? selectedFoodId;
  final String mealType;
  final TextEditingController quantity;
  final TextEditingController notes;
  final bool loading;
  final ValueChanged<String> onMealChanged;
  final ValueChanged<int?> onFoodChanged;
  final VoidCallback onLogFood;

  @override
  Widget build(BuildContext context) {
    return _FoodLogPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Log Food',
              style: TextStyle(
                color: _appText(context),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 520;
                final meal = _FoodLogDropdown<String>(
                  label: 'Meal Type',
                  value: mealType,
                  items: const ['breakfast', 'lunch', 'dinner', 'snack'],
                  itemLabel: _mealTitle,
                  onChanged: (value) {
                    if (value != null) {
                      onMealChanged(value);
                    }
                  },
                );
                final food = _FoodLogDropdown<int>(
                  label: 'Food Item',
                  value: selectedFoodId,
                  items: foods
                      .map((food) => food['id'])
                      .whereType<int>()
                      .toList(),
                  itemLabel: (id) {
                    final food = foods.firstWhere(
                      (item) => item['id'] == id,
                      orElse: () => {'name': 'Select a food...'},
                    );
                    return food['name'].toString();
                  },
                  hint: 'Select a food...',
                  onChanged: onFoodChanged,
                );
                if (stacked) {
                  return Column(
                    children: [meal, const SizedBox(height: 18), food],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: meal),
                    const SizedBox(width: 22),
                    Expanded(child: food),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            _FoodLogTextField(
              controller: quantity,
              label: 'Quantity',
              hintText: '1',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 20),
            _FoodLogTextField(
              controller: notes,
              label: 'Notes (Optional)',
              hintText: 'e.g., homemade, restaurant, snack',
              minLines: 3,
              maxLines: 4,
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: loading ? null : onLogFood,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add to Log'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF087A3D),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodaysFoodLogCard extends StatelessWidget {
  const _TodaysFoodLogCard({required this.logs, required this.onDeleteLog});

  final List<Map<String, dynamic>> logs;
  final ValueChanged<int> onDeleteLog;

  static const _mealOrder = ['breakfast', 'lunch', 'dinner', 'snack'];

  @override
  Widget build(BuildContext context) {
    final visibleLogs = logs.take(12).toList();
    return _FoodLogPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Food Log",
              style: TextStyle(
                color: _appText(context),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 22),
            if (visibleLogs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'No food logs yet',
                  style: TextStyle(color: _appMutedText(context)),
                ),
              )
            else
              ..._mealOrder.expand((meal) {
                final mealLogs = visibleLogs
                    .where((log) => log['meal_type']?.toString() == meal)
                    .toList();
                if (mealLogs.isEmpty) {
                  return <Widget>[];
                }
                return [
                  _FoodLogMealLabel(meal: meal),
                  const SizedBox(height: 12),
                  ...mealLogs.map(
                    (log) => _FoodLogEntryTile(
                      log: log,
                      onDelete: () {
                        final id = log['id'];
                        if (id is int) {
                          onDeleteLog(id);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                ];
              }),
          ],
        ),
      ),
    );
  }
}

class _FoodLogMealLabel extends StatelessWidget {
  const _FoodLogMealLabel({required this.meal});

  final String meal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(_mealEmoji(meal), style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 6),
        Text(
          meal.toUpperCase(),
          style: TextStyle(
            color: _appMutedText(context),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _FoodLogEntryTile extends StatelessWidget {
  const _FoodLogEntryTile({required this.log, required this.onDelete});

  final Map<String, dynamic> log;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final food = Map<String, dynamic>.from(log['food'] as Map);
    final calories =
        _foodNumber(food['calories']) * _foodNumber(log['quantity']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFAFFFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDDE8E1)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: Row(
            children: [
              const _FoodLogReceiptIcon(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food['name'].toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Qty: ${_formatFoodNumber(_foodNumber(log['quantity']))} • ${_formatLogTime(log['logged_at'])}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF344054),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatFoodNumber(calories),
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'CAL',
                    style: TextStyle(
                      color: Color(0xFF344054),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 22),
              IconButton(
                tooltip: 'Delete log',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFFF3B5C),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodLogSidebar extends StatelessWidget {
  const _FoodLogSidebar({required this.summary});

  final Map<String, dynamic>? summary;

  @override
  Widget build(BuildContext context) {
    final calories = _foodNumber(summary?['calories']);
    final protein = _foodNumber(summary?['protein_g']);
    final carbs = _foodNumber(summary?['carbs_g']);
    final fat = _foodNumber(summary?['fat_g']);
    final score = summary?['nutrition_score'] is num
        ? (summary!['nutrition_score'] as num).round()
        : calories > 0
        ? 82
        : 0;
    return Column(
      children: [
        _TodaysNutritionCard(
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
        ),
        const SizedBox(height: 20),
        _NutritionScoreCard(score: score),
        const SizedBox(height: 20),
        const _NutritionTipCard(),
      ],
    );
  }
}

class _TodaysNutritionCard extends StatelessWidget {
  const _TodaysNutritionCard({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  @override
  Widget build(BuildContext context) {
    return _FoodLogPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Nutrition",
              style: TextStyle(
                color: _appText(context),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 22),
            _NutritionProgressRow(
              label: 'Calories',
              value: calories,
              target: 2000,
              unit: '',
              color: const Color(0xFF087A3D),
            ),
            _NutritionProgressRow(
              label: 'Protein',
              value: protein,
              target: 120,
              unit: 'g',
              color: const Color(0xFF08A7D8),
            ),
            _NutritionProgressRow(
              label: 'Carbohydrates',
              value: carbs,
              target: 220,
              unit: 'g',
              color: const Color(0xFFFFA12B),
            ),
            _NutritionProgressRow(
              label: 'Fat',
              value: fat,
              target: 65,
              unit: 'g',
              color: const Color(0xFFFF223F),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionProgressRow extends StatelessWidget {
  const _NutritionProgressRow({
    required this.label,
    required this.value,
    required this.target,
    required this.unit,
    required this.color,
  });

  final String label;
  final double value;
  final double target;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: _appText(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${_formatFoodNumber(value)}$unit / ${_formatFoodNumber(target)}$unit',
                style: TextStyle(
                  color: _appText(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (value / target).clamp(0, 1),
              minHeight: 7,
              backgroundColor: const Color(0xFFE4E7EC),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionScoreCard extends StatelessWidget {
  const _NutritionScoreCard({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE9F7F1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
          child: Column(
            children: [
              const Text(
                'Nutrition Score',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                score.toString(),
                style: const TextStyle(
                  color: Color(0xFF087A3D),
                  fontSize: 52,
                  height: 0.95,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Great progress today!',
                style: TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NutritionTipCard extends StatelessWidget {
  const _NutritionTipCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5F7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 34,
                height: 34,
                child: Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFF16A05D),
                  size: 18,
                ),
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nutrition Tip',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Fiber intake can help regulate blood sugar levels. Try adding more leafy greens to your next meal.',
                    style: TextStyle(
                      color: Color(0xFF344054),
                      fontSize: 10,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodLogDropdown<T> extends StatelessWidget {
  const _FoodLogDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FoodLogFieldLabel(label),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: DropdownButtonFormField<T>(
            initialValue: value,
            isExpanded: true,
            hint: hint == null ? null : Text(hint!),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
            decoration: _foodLogInputDecoration(context),
            style: TextStyle(
              color: _appText(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            items: items
                .map(
                  (item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(
                      itemLabel(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _FoodLogTextField extends StatelessWidget {
  const _FoodLogTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FoodLogFieldLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          minLines: minLines,
          maxLines: maxLines,
          style: TextStyle(
            color: _appText(context),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          decoration: _foodLogInputDecoration(context, hintText: hintText),
        ),
      ],
    );
  }
}

class _FoodLogFieldLabel extends StatelessWidget {
  const _FoodLogFieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: _appText(context),
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _FoodLogPanel extends StatelessWidget {
  const _FoodLogPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _HoverLift(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _appSurface(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _appBorder(context)),
        ),
        child: child,
      ),
    );
  }
}

class _FoodLogReceiptIcon extends StatelessWidget {
  const _FoodLogReceiptIcon();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5F7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD0D5DD)),
      ),
      child: SizedBox(
        width: 44,
        height: 44,
        child: CustomPaint(painter: _ReceiptIconPainter()),
      ),
    );
  }
}

InputDecoration _foodLogInputDecoration(
  BuildContext context, {
  String? hintText,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(
      color: _appMutedText(context),
      fontSize: 11,
      fontWeight: FontWeight.w500,
    ),
    filled: true,
    fillColor: _appSurfaceSoft(context),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: BorderSide(color: _appBorder(context)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: BorderSide(color: _appBorder(context)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Color(0xFF16A05D), width: 1.2),
    ),
  );
}

String _mealTitle(String value) {
  if (value.isEmpty) {
    return 'Meal';
  }
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

String _mealEmoji(String value) {
  return switch (value) {
    'breakfast' => '🌅',
    'lunch' => '☀️',
    'dinner' => '🌙',
    'snack' => '🍎',
    _ => '🍽',
  };
}

String _formatLogTime(dynamic value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (parsed == null) {
    return '';
  }
  final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
  final minute = parsed.minute.toString().padLeft(2, '0');
  final period = parsed.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

String _shortDateTime(dynamic value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (parsed == null) {
    return 'Grocery list';
  }
  return '${_shortMonthName(parsed)} ${parsed.day}, ${_formatLogTime(value)}';
}

class _ReceiptIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = const Color(0xFFD0D5DD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final green = Paint()
      ..color = const Color(0xFF16A05D)
      ..strokeWidth = 2;
    final muted = Paint()
      ..color = const Color(0xFFE4E7EC)
      ..strokeWidth = 1.2;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, 8, size.width - 20, size.height - 16),
      const Radius.circular(2),
    );
    canvas.drawRRect(rect, border);
    canvas.drawLine(const Offset(15, 14), Offset(size.width - 15, 14), green);
    for (var i = 0; i < 4; i++) {
      final y = 20.0 + i * 5;
      canvas.drawLine(Offset(15, y), Offset(size.width - 18, y), muted);
    }
    canvas.drawLine(
      Offset(15, size.height - 11),
      Offset(size.width - 15, size.height - 11),
      green,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GroceryScreen extends StatefulWidget {
  const GroceryScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> {
  final _budget = TextEditingController(text: '35');
  List<Map<String, dynamic>> _lists = [];
  int? _selectedListId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _budget.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lists = await widget.apiClient.groceryLists();
      if (mounted) {
        setState(() {
          _lists = lists;
          if (lists.isEmpty) {
            _selectedListId = null;
          } else if (_selectedListId == null ||
              !lists.any((list) => list['id'] == _selectedListId)) {
            _selectedListId = lists.first['id'] as int?;
          }
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.apiClient.generateGroceryList(
        budget: double.tryParse(_budget.text),
      );
      if (mounted) {
        setState(() {
          _lists = [
            list,
            ..._lists.where((existing) => existing['id'] != list['id']),
          ];
          _selectedListId = list['id'] as int?;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _toggleItem(int itemId, bool purchased) async {
    try {
      final updated = await widget.apiClient.updateGroceryItem(
        itemId: itemId,
        purchased: purchased,
      );
      if (mounted) {
        setState(() {
          _lists = _lists
              .map((list) => list['id'] == updated['id'] ? updated : list)
              .toList();
          _selectedListId = updated['id'] as int?;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    }
  }

  Future<void> _setItemStatus(int itemId, String status) async {
    try {
      final updated = await widget.apiClient.updateGroceryItem(
        itemId: itemId,
        status: status,
      );
      if (mounted) {
        setState(() {
          _lists = _lists
              .map((list) => list['id'] == updated['id'] ? updated : list)
              .toList();
          _selectedListId = updated['id'] as int?;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    }
  }

  Future<void> _setAllPurchased(
    List<Map<String, dynamic>> items,
    bool purchased,
  ) async {
    final changedItems = items
        .where((item) => (_groceryItemStatus(item) == 'bought') != purchased)
        .toList();
    if (changedItems.isEmpty) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      Map<String, dynamic>? updatedList;
      for (final item in changedItems) {
        updatedList = await widget.apiClient.updateGroceryItem(
          itemId: item['id'] as int,
          status: purchased ? 'bought' : 'need_to_buy',
        );
      }
      if (mounted && updatedList != null) {
        final latestList = updatedList;
        setState(() {
          _lists = _lists
              .map((list) => list['id'] == latestList['id'] ? latestList : list)
              .toList();
          _selectedListId = latestList['id'] as int?;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedList();
    final items = selected?['items'] is List
        ? List<Map<String, dynamic>>.from(
            (selected!['items'] as List).map(
              (item) => Map<String, dynamic>.from(item as Map),
            ),
          )
        : <Map<String, dynamic>>[];
    final purchased = items
        .where((item) => _groceryItemStatus(item) == 'bought')
        .length;
    final alreadyHave = items
        .where((item) => _groceryItemStatus(item) == 'have')
        .length;
    final planToBuyTotal = items
        .where((item) => _groceryItemStatus(item) != 'have')
        .fold<double>(
          0,
          (sum, item) => sum + _foodNumber(item['estimated_cost']),
        );
    final remainingTotal = items
        .where((item) => _groceryItemStatus(item) == 'need_to_buy')
        .fold<double>(
          0,
          (sum, item) => sum + _foodNumber(item['estimated_cost']),
        );
    final purchasedTotal = items
        .where((item) => _groceryItemStatus(item) == 'bought')
        .fold<double>(
          0,
          (sum, item) => sum + _foodNumber(item['estimated_cost']),
        );
    final alreadyHaveTotal = items
        .where((item) => _groceryItemStatus(item) == 'have')
        .fold<double>(
          0,
          (sum, item) => sum + _foodNumber(item['estimated_cost']),
        );
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _SystemPageHeader(
          title: 'Grocery',
          subtitle: 'Generate and check off ingredients from meal plans',
          icon: Icons.shopping_cart_outlined,
          action: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh, size: 15),
                label: const Text('Refresh'),
              ),
              FilledButton.icon(
                onPressed: _loading ? null : _generate,
                icon: const Icon(Icons.auto_awesome, size: 15),
                label: Text(_loading ? 'Loading...' : 'Generate List'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_error != null) ...[
          ErrorBanner(message: _error!),
          const SizedBox(height: 14),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 840;
            final summary = _SystemInfoPanel(
              children: [
                _SystemStatTile(
                  label: 'Plan to Buy',
                  value: '\$${_formatFoodNumber(planToBuyTotal)}',
                  icon: Icons.payments_outlined,
                ),
                _SystemStatTile(
                  label: 'Still Need',
                  value: '\$${_formatFoodNumber(remainingTotal)}',
                  icon: Icons.receipt_long_outlined,
                ),
                _SystemStatTile(
                  label: 'Bought Cost',
                  value: '\$${_formatFoodNumber(purchasedTotal)}',
                  icon: Icons.shopping_bag_outlined,
                ),
                _SystemStatTile(
                  label: 'Already Have',
                  value:
                      '$alreadyHave item${alreadyHave == 1 ? '' : 's'} • \$${_formatFoodNumber(alreadyHaveTotal)}',
                  icon: Icons.kitchen_outlined,
                ),
                _SystemStatTile(
                  label: 'Items Checked',
                  value: '$purchased / ${items.length}',
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(height: 14),
                _FoodLogTextField(
                  controller: _budget,
                  label: 'Budget',
                  hintText: '35',
                  keyboardType: TextInputType.number,
                ),
                if (_lists.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _GroceryListPicker(
                    lists: _lists,
                    selectedListId: _selectedListId,
                    onChanged: (value) =>
                        setState(() => _selectedListId = value),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: selected == null
                          ? null
                          : () => grocery_pdf_export.printGroceryListPdf(
                              selected,
                            ),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                      label: const Text('Print / Save PDF'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _loading || items.isEmpty
                              ? null
                              : () => _setAllPurchased(items, true),
                          child: const Text('Mark all bought'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _loading || items.isEmpty
                              ? null
                              : () => _setAllPurchased(items, false),
                          child: const Text('Clear checks'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
            final list = _FoodLogPanel(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selected?['name']?.toString() ?? 'Shopping List',
                            style: TextStyle(
                              color: _appText(context),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (selected?['created_at'] != null)
                          Text(
                            _formatLogTime(selected?['created_at']),
                            style: TextStyle(
                              color: _appMutedText(context),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      items.isEmpty
                          ? 'Ingredients will appear here after generating a list from meal plans.'
                          : 'Ingredients generated from meal plans with quantity, estimated cost, and kitchen status.',
                      style: TextStyle(
                        color: _appMutedText(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_loading && items.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(28),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (items.isEmpty)
                      const _SystemEmptyState(
                        icon: Icons.shopping_bag_outlined,
                        title: 'No grocery list yet',
                        message:
                            'Generate a meal plan, then create a grocery list.',
                      )
                    else
                      Column(
                        children: [
                          const _GroceryTableHeader(),
                          const SizedBox(height: 8),
                          ...items.map(
                            (item) => _GroceryItemRow(
                              item: item,
                              onChanged: (value) => _toggleItem(
                                item['id'] as int,
                                value ?? false,
                              ),
                              onStatusChanged: (value) {
                                if (value != null) {
                                  _setItemStatus(item['id'] as int, value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
            if (compact) {
              return Column(
                children: [summary, const SizedBox(height: 18), list],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: list),
                const SizedBox(width: 20),
                SizedBox(width: 300, child: summary),
              ],
            );
          },
        ),
      ],
    );
  }

  Map<String, dynamic>? _selectedList() {
    if (_lists.isEmpty) {
      return null;
    }
    return _lists.firstWhere(
      (list) => list['id'] == _selectedListId,
      orElse: () => _lists.first,
    );
  }
}

class _GroceryListPicker extends StatelessWidget {
  const _GroceryListPicker({
    required this.lists,
    required this.selectedListId,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> lists;
  final int? selectedListId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: lists.any((list) => list['id'] == selectedListId)
          ? selectedListId
          : lists.first['id'] as int?,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Grocery list'),
      items: lists.map((list) {
        final id = list['id'] as int;
        final itemCount = (list['items'] as List<dynamic>? ?? []).length;
        final created = _shortDateTime(list['created_at']);
        return DropdownMenuItem<int>(
          value: id,
          child: Text(
            '$created • $itemCount item${itemCount == 1 ? '' : 's'}',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class _GroceryTableHeader extends StatelessWidget {
  const _GroceryTableHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          SizedBox(width: 48),
          Expanded(flex: 3, child: _GroceryHeaderLabel('Ingredient')),
          Expanded(flex: 2, child: _GroceryHeaderLabel('Quantity')),
          Expanded(flex: 2, child: _GroceryHeaderLabel('Est. cost')),
          SizedBox(width: 142, child: _GroceryHeaderLabel('Status')),
        ],
      ),
    );
  }
}

class _GroceryHeaderLabel extends StatelessWidget {
  const _GroceryHeaderLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF667085),
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

String _groceryItemStatus(Map<String, dynamic> item) {
  final status = item['status']?.toString();
  if (status == 'need_to_buy' || status == 'have' || status == 'bought') {
    return status!;
  }
  return item['purchased'] == true ? 'bought' : 'need_to_buy';
}

class _GroceryItemRow extends StatelessWidget {
  const _GroceryItemRow({
    required this.item,
    required this.onChanged,
    required this.onStatusChanged,
  });

  final Map<String, dynamic> item;
  final ValueChanged<bool?> onChanged;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final status = _groceryItemStatus(item);
    final purchased = status == 'bought';
    final have = status == 'have';
    final cost = _formatFoodNumber(_foodNumber(item['estimated_cost']));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: purchased
              ? const Color(0xFFEAF7F1)
              : have
              ? const Color(0xFFEFF6FF)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE4E7EC)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 14, 12),
          child: Row(
            children: [
              SizedBox(
                width: 42,
                child: Checkbox(
                  value: purchased,
                  onChanged: onChanged,
                  activeColor: const Color(0xFF16A05D),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  item['food_item']?.toString() ?? 'Ingredient',
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: _GroceryValueText(item['quantity']?.toString() ?? '-'),
              ),
              Expanded(flex: 2, child: _GroceryValueText('\$$cost')),
              SizedBox(
                width: 142,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: status,
                    isExpanded: true,
                    iconSize: 16,
                    style: const TextStyle(
                      color: Color(0xFF344054),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'need_to_buy',
                        child: Text('Need to buy'),
                      ),
                      DropdownMenuItem(
                        value: 'have',
                        child: Text('Already have'),
                      ),
                      DropdownMenuItem(value: 'bought', child: Text('Bought')),
                    ],
                    onChanged: onStatusChanged,
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

class _GroceryValueText extends StatelessWidget {
  const _GroceryValueText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFF344054),
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class AllergiesScreen extends StatefulWidget {
  const AllergiesScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<AllergiesScreen> createState() => _AllergiesScreenState();
}

class _AllergiesScreenState extends State<AllergiesScreen> {
  final _ingredient = TextEditingController();
  String _severity = 'medium';
  List<Map<String, dynamic>> _allergies = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ingredient.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final allergies = await widget.apiClient.allergies();
      if (mounted) {
        setState(() => _allergies = allergies);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _add() async {
    final ingredient = _ingredient.text.trim();
    if (ingredient.isEmpty) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final allergy = await widget.apiClient.addAllergy(
        ingredient,
        severity: _severity,
      );
      if (mounted) {
        setState(() {
          _allergies = [..._allergies, allergy]
            ..sort(
              (a, b) => a['ingredient'].toString().compareTo(
                b['ingredient'].toString(),
              ),
            );
          _ingredient.clear();
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _delete(int id) async {
    try {
      await widget.apiClient.deleteAllergy(id);
      if (mounted) {
        setState(() => _allergies.removeWhere((item) => item['id'] == id));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const _SystemPageHeader(
          title: 'Allergies',
          subtitle: 'Keep unsafe ingredients out of AI recommendations',
          icon: Icons.health_and_safety_outlined,
        ),
        const SizedBox(height: 18),
        if (_error != null) ...[
          ErrorBanner(message: _error!),
          const SizedBox(height: 14),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 840;
            final form = _FoodLogPanel(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Add Allergy',
                      style: TextStyle(
                        color: _appText(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FoodLogTextField(
                      controller: _ingredient,
                      label: 'Ingredient',
                      hintText: 'Peanuts',
                    ),
                    const SizedBox(height: 14),
                    _FoodLogDropdown<String>(
                      label: 'Severity',
                      value: _severity,
                      items: const ['low', 'medium', 'high'],
                      itemLabel: _titleCase,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _severity = value);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _loading ? null : _add,
                      icon: const Icon(Icons.add),
                      label: Text(_loading ? 'Saving...' : 'Add Allergy'),
                    ),
                  ],
                ),
              ),
            );
            final list = _FoodLogPanel(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tracked Allergies',
                      style: TextStyle(
                        color: _appText(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_loading && _allergies.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(28),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_allergies.isEmpty)
                      const _SystemEmptyState(
                        icon: Icons.verified_user_outlined,
                        title: 'No allergies added',
                        message:
                            'Add ingredients that recommendations should avoid.',
                      )
                    else
                      ..._allergies.map(
                        (allergy) => _AllergyRow(
                          allergy: allergy,
                          onDelete: () => _delete(allergy['id'] as int),
                        ),
                      ),
                  ],
                ),
              ),
            );
            if (compact) {
              return Column(children: [form, const SizedBox(height: 18), list]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 320, child: form),
                const SizedBox(width: 20),
                Expanded(child: list),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AllergyRow extends StatelessWidget {
  const _AllergyRow({required this.allergy, required this.onDelete});

  final Map<String, dynamic> allergy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE4E7EC)),
        ),
        child: ListTile(
          leading: const CircleAvatar(
            radius: 17,
            backgroundColor: Color(0xFFFFF1F0),
            child: Icon(
              Icons.priority_high,
              size: 16,
              color: Color(0xFFE76F51),
            ),
          ),
          title: Text(
            _titleCase(allergy['ingredient']?.toString() ?? 'Ingredient'),
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            'Severity: ${_titleCase(allergy['severity']?.toString() ?? 'Not set')}',
            style: const TextStyle(color: Color(0xFF667085), fontSize: 11),
          ),
          trailing: IconButton(
            tooltip: 'Remove allergy',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Color(0xFFE76F51)),
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.apiClient,
    required this.onLogout,
    required this.darkMode,
    required this.onDarkModeChanged,
  });

  final ApiClient apiClient;
  final VoidCallback onLogout;
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _name = TextEditingController(text: 'John Doe');
  final _email = TextEditingController(text: 'johndoe@example.com');
  String? _settingsMessage;
  String? _settingsError;
  bool _loadingAccount = true;
  bool _mealReminders = true;
  bool _waterReminders = true;
  bool _weeklySummary = true;
  bool _marketingUpdates = false;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _darkMode = widget.darkMode;
    _loadAccount();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _loadAccount() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final user = await widget.apiClient.me();
      if (mounted) {
        setState(() {
          _name.text = user['full_name']?.toString() ?? _name.text;
          _email.text = user['email']?.toString() ?? _email.text;
          _mealReminders =
              preferences.getBool('meal_reminders') ?? _mealReminders;
          _waterReminders =
              preferences.getBool('water_reminders') ?? _waterReminders;
          _weeklySummary =
              preferences.getBool('weekly_summary') ?? _weeklySummary;
          _marketingUpdates =
              preferences.getBool('marketing_updates') ?? _marketingUpdates;
          _loadingAccount = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _settingsError = error.toString();
          _loadingAccount = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      final updated = await widget.apiClient.updateAccount(
        email: _email.text.trim(),
        fullName: _name.text.trim(),
      );
      final preferences = await SharedPreferences.getInstance();
      await Future.wait([
        preferences.setBool('meal_reminders', _mealReminders),
        preferences.setBool('water_reminders', _waterReminders),
        preferences.setBool('weekly_summary', _weeklySummary),
        preferences.setBool('marketing_updates', _marketingUpdates),
      ]);
      _name.text = updated['full_name']?.toString() ?? _name.text;
      _email.text = updated['email']?.toString() ?? _email.text;
      _showMessage('Account and preferences saved.');
    } catch (error) {
      setState(() => _settingsError = error.toString());
    }
  }

  void _showMessage(String message) {
    setState(() {
      _settingsMessage = message;
      _settingsError = null;
    });
  }

  Future<void> _showChangePasswordDialog() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => _SettingsChangePasswordDialog(
        apiClient: widget.apiClient,
        email: _email.text.trim(),
      ),
    );
    if (changed == true && mounted) {
      _showMessage('Password changed successfully.');
    }
  }

  Future<void> _exportData() async {
    try {
      final data = await Future.wait<dynamic>([
        widget.apiClient.me(),
        widget.apiClient.profile(),
        widget.apiClient.foodLogs(),
        widget.apiClient.mealPlans(),
        widget.apiClient.groceryLists(),
        widget.apiClient.weightProgress(),
        widget.apiClient.waterLog(todayIsoDate()),
        widget.apiClient.allergies(),
      ]);
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => _SettingsExportDialog(
          data: {
            'user': data[0],
            'profile': data[1],
            'food_logs': data[2],
            'meal_plans': data[3],
            'grocery_lists': data[4],
            'weight_progress': data[5],
            'water_today': data[6],
            'allergies': data[7],
          },
        ),
      );
    } catch (error) {
      setState(() => _settingsError = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 34),
      children: [
        const _SettingsHeader(),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 820;
            final mainColumn = Column(
              children: [
                _SettingsPanel(
                  title: 'Account Information',
                  icon: Icons.person_outline,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_loadingAccount) ...[
                        const LinearProgressIndicator(minHeight: 3),
                        const SizedBox(height: 14),
                      ],
                      _SettingsTextField(label: 'Full Name', controller: _name),
                      const SizedBox(height: 14),
                      _SettingsTextField(label: 'Email', controller: _email),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _saveSettings,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(86, 30),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          backgroundColor: const Color(0xFF149B60),
                          textStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        child: const Text('Save Changes'),
                      ),
                      if (_settingsMessage != null) ...[
                        const SizedBox(height: 12),
                        SuccessBanner(message: _settingsMessage!),
                      ],
                      if (_settingsError != null) ...[
                        const SizedBox(height: 12),
                        ErrorBanner(message: _settingsError!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SettingsPanel(
                  title: 'Notifications',
                  titleIndent: 26,
                  child: Column(
                    children: [
                      _SettingsToggleRow(
                        title: 'Meal Reminders',
                        subtitle: 'Get reminded to log your meals',
                        value: _mealReminders,
                        onChanged: (value) =>
                            setState(() => _mealReminders = value),
                      ),
                      _SettingsToggleRow(
                        title: 'Water Reminders',
                        subtitle: 'Get reminded to log your water',
                        value: _waterReminders,
                        onChanged: (value) =>
                            setState(() => _waterReminders = value),
                      ),
                      _SettingsToggleRow(
                        title: 'Weekly Summary',
                        subtitle: 'Review your nutrition progress',
                        value: _weeklySummary,
                        onChanged: (value) =>
                            setState(() => _weeklySummary = value),
                      ),
                      _SettingsToggleRow(
                        title: 'Product Updates',
                        subtitle: 'Receive nutrition feature updates',
                        value: _marketingUpdates,
                        onChanged: (value) =>
                            setState(() => _marketingUpdates = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SettingsPanel(
                  title: 'Preferences',
                  icon: Icons.language,
                  child: Column(
                    children: [
                      _SettingsToggleRow(
                        title: 'Dark Mode',
                        subtitle: 'Toggle dark theme',
                        value: _darkMode,
                        leading: Icons.wb_sunny_outlined,
                        onChanged: (value) {
                          setState(() => _darkMode = value);
                          widget.onDarkModeChanged(value);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SettingsPanel(
                  title: 'Security',
                  icon: Icons.lock_outline,
                  child: Column(
                    children: [
                      _SettingsActionRow(
                        title: 'Change Password',
                        subtitle: 'Update your account password',
                        onTap: _showChangePasswordDialog,
                      ),
                      const SizedBox(height: 12),
                      _SettingsActionRow(
                        title: 'Two-Factor Authentication',
                        subtitle: 'Demo project uses OTP reset instead',
                        onTap: () => _showMessage(
                          'Two-factor authentication is not enabled in this demo.',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
            final sideColumn = Column(
              children: [
                _SettingsProfileCard(name: _name.text, email: _email.text),
                const SizedBox(height: 14),
                const _SettingsAboutCard(),
                const SizedBox(height: 14),
                _SettingsDangerCard(
                  onExport: _exportData,
                  onLogout: widget.onLogout,
                ),
              ],
            );

            if (stack) {
              return Column(
                children: [mainColumn, const SizedBox(height: 18), sideColumn],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 13, child: mainColumn),
                const SizedBox(width: 14),
                SizedBox(width: 246, child: sideColumn),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Settings',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          'Manage your account and preferences',
          style: TextStyle(
            color: _appMutedText(context),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.title,
    required this.child,
    this.icon,
    this.titleIndent = 0,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final double titleIndent;

  @override
  Widget build(BuildContext context) {
    return _FoodLogPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: titleIndent),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 17, color: const Color(0xFF12A76A)),
                    const SizedBox(width: 18),
                  ],
                  Text(
                    title,
                    style: TextStyle(
                      color: _appText(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _SettingsTextField extends StatelessWidget {
  const _SettingsTextField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: _appText(context), fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: TextStyle(
          color: _appMutedText(context),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: _appSurfaceSoft(context),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: BorderSide(color: _appBorder(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: BorderSide(color: _appBorder(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: Color(0xFF149B60), width: 1.2),
        ),
      ),
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  const _SettingsToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.leading,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? leading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _appSurfaceSoft(context),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Row(
            children: [
              if (leading != null) ...[
                Icon(leading, color: const Color(0xFF12A76A), size: 17),
                const SizedBox(width: 18),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: _appText(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: _appMutedText(context),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.76,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF12A76A),
                  inactiveThumbColor: const Color(0xFFE6F8EF),
                  inactiveTrackColor: const Color(0xFFEFF8F3),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsActionRow extends StatelessWidget {
  const _SettingsActionRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _appSurfaceSoft(context),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: _appText(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: _appMutedText(context),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF667085),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsProfileCard extends StatelessWidget {
  const _SettingsProfileCard({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _appSurfaceSoft(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC9E2DD)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
        child: Column(
          children: [
            CircleAvatar(
              radius: 41,
              backgroundColor: const Color(0xFF0EA561),
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              name,
              style: TextStyle(
                color: _appText(context),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              email,
              style: TextStyle(color: _appMutedText(context), fontSize: 11),
            ),
            const SizedBox(height: 24),
            const _SettingsMiniStat(label: 'Member since', value: 'Jan, 2026'),
            const SizedBox(height: 13),
            const _SettingsMiniStat(label: 'Days active', value: '42 days'),
            const SizedBox(height: 13),
            const _SettingsMiniStat(label: 'Meal logged', value: '156'),
          ],
        ),
      ),
    );
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'NA';
    }
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}

class _SettingsMiniStat extends StatelessWidget {
  const _SettingsMiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: _appMutedText(context),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: _appText(context),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _SettingsAboutCard extends StatelessWidget {
  const _SettingsAboutCard();

  @override
  Widget build(BuildContext context) {
    return _FoodLogPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 24, 30, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About NutriAI',
              style: TextStyle(
                color: _appText(context),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 24),
            const _SettingsMiniStat(label: 'Version', value: '1.0.0'),
            const SizedBox(height: 14),
            const _SettingsMiniStat(label: 'Build', value: '2026.02.15'),
            const SizedBox(height: 28),
            const _SettingsLink('Privacy Policy'),
            const SizedBox(height: 16),
            const _SettingsLink('Terms of Service'),
            const SizedBox(height: 16),
            const _SettingsLink('Help & Support'),
          ],
        ),
      ),
    );
  }
}

class _SettingsLink extends StatelessWidget {
  const _SettingsLink(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: _appText(context),
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SettingsDangerCard extends StatelessWidget {
  const _SettingsDangerCard({required this.onExport, required this.onLogout});

  final VoidCallback onExport;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _isDark(context)
            ? const Color(0xFF2B1B1B)
            : const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE9B7B7)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 24, 30, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Actions',
              style: TextStyle(
                color: Color(0xFFFF2525),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: onExport,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF2525),
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Export All Data'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onLogout,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF2525),
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsChangePasswordDialog extends StatefulWidget {
  const _SettingsChangePasswordDialog({
    required this.apiClient,
    required this.email,
  });

  final ApiClient apiClient;
  final String email;

  @override
  State<_SettingsChangePasswordDialog> createState() =>
      _SettingsChangePasswordDialogState();
}

class _SettingsChangePasswordDialogState
    extends State<_SettingsChangePasswordDialog> {
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _oldPassword.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_oldPassword.text.isEmpty) {
      setState(() => _error = 'Current password is required');
      return;
    }
    if (_newPassword.text.length < 8) {
      setState(() => _error = 'Use at least 8 characters');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.apiClient.changePassword(
        email: widget.email,
        oldPassword: _oldPassword.text,
        newPassword: _newPassword.text,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _oldPassword,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newPassword,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              ErrorBanner(message: _error!),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: Text(_loading ? 'Saving...' : 'Save password'),
        ),
      ],
    );
  }
}

class _SettingsExportDialog extends StatelessWidget {
  const _SettingsExportDialog({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    const encoder = JsonEncoder.withIndent('  ');
    final text = encoder.convert(data);
    return AlertDialog(
      title: const Text('Exported data'),
      content: SizedBox(
        width: 560,
        height: 420,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _appSurfaceSoft(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDDE8E1)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: SelectableText(
              text,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: _appText(context),
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _SystemPageHeader extends StatelessWidget {
  const _SystemPageHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.action,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final titleBlock = Row(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: const Color(0xFFEAF7F1),
              child: Icon(icon, color: const Color(0xFF16A05D), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: _appText(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _appMutedText(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        if (compact || action == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              if (action != null) ...[const SizedBox(height: 14), action!],
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 16),
            action!,
          ],
        );
      },
    );
  }
}

class _SystemInfoPanel extends StatelessWidget {
  const _SystemInfoPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _FoodLogPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(children: children),
      ),
    );
  }
}

class _SystemStatTile extends StatelessWidget {
  const _SystemStatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE4E7EC)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFFEAF7F1),
                child: Icon(icon, size: 16, color: const Color(0xFF16A05D)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SystemEmptyState extends StatelessWidget {
  const _SystemEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 34),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFFEAF7F1),
              child: Icon(icon, color: const Color(0xFF16A05D)),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _question = TextEditingController();
  final _weight = TextEditingController(text: '80');
  final _height = TextEditingController(text: '170');
  final String _habits = 'balanced';
  final String _exercise = '3 days per week';
  final String _goal = 'lose_weight';
  bool _loading = false;
  bool _recognizing = false;
  String? _error;
  Map<String, dynamic>? _risk;
  final List<_AssistantChatMessage> _messages = [
    const _AssistantChatMessage(
      role: _AssistantRole.assistant,
      text:
          'Hi, I am your nutrition assistant. Ask me about meals, calories, dieting, hydration, allergies, or healthier swaps.',
    ),
  ];

  @override
  void dispose() {
    _question.dispose();
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  Future<void> _ask([String? prompt]) async {
    final question = (prompt ?? _question.text).trim();
    if (question.isEmpty) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _messages.add(
        _AssistantChatMessage(role: _AssistantRole.user, text: question),
      );
      _question.clear();
    });
    try {
      final result = await widget.apiClient.askNutritionQuestion(question);
      setState(
        () => _messages.add(
          _AssistantChatMessage(
            role: _AssistantRole.assistant,
            text: result['answer']?.toString() ?? 'I could not answer that.',
            source: result['source']?.toString(),
          ),
        ),
      );
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _predictRisk() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.apiClient.predictHealthRisk({
        'eating_habits': _habits,
        'exercise_frequency': _exercise,
        'weight_kg': double.tryParse(_weight.text),
        'height_cm': double.tryParse(_height.text),
        'goal': _goal,
      });
      setState(() => _risk = result);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _recognizeFoodPhoto() async {
    setState(() {
      _recognizing = true;
      _error = null;
    });
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );
      final file = result?.files.single;
      final bytes = file?.bytes;
      if (file == null || bytes == null) {
        return;
      }
      final recognized = await widget.apiClient.recognizeFoodImage(
        bytes: bytes,
        filename: file.name,
      );
      final name = recognized['food_name']?.toString() ?? 'food';
      final calories = recognized['estimated_calories']?.toString() ?? '-';
      final confidence = _foodNumber(recognized['confidence']);
      setState(() {
        _messages.add(
          _AssistantChatMessage(
            role: _AssistantRole.user,
            text: 'Uploaded food photo: ${file.name}',
          ),
        );
        _messages.add(
          _AssistantChatMessage(
            role: _AssistantRole.assistant,
            text: confidence <= 0 || name == 'Unknown Food'
                ? 'I could not identify that photo reliably. Please enter the food name and serving size manually.'
                : 'The filename suggests $name ($calories kcal per saved serving), but this is a low-confidence match—not visual recognition.',
            source: 'food recognition',
          ),
        );
      });
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _recognizing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1220;
        final medium = constraints.maxWidth >= 920;
        final chat = _AssistantChatPanel(
          messages: _messages,
          controller: _question,
          loading: _loading,
          onAsk: () => _ask(),
          onPrompt: _ask,
        );
        final side = _AssistantCapabilitiesPanel(
          recognizing: _recognizing,
          onPrompt: _ask,
          onUploadPhoto: _recognizeFoodPhoto,
          risk: _risk,
          onPredictRisk: _predictRisk,
        );
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (_error != null) ...[
              ErrorBanner(message: _error!),
              const SizedBox(height: 12),
            ],
            if (wide)
              SizedBox(
                height: 760,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 270,
                      child: _AssistantConversationsPanel(onPrompt: _ask),
                    ),
                    const SizedBox(width: 0),
                    Expanded(child: chat),
                    const SizedBox(width: 0),
                    SizedBox(width: 290, child: side),
                  ],
                ),
              )
            else if (medium)
              SizedBox(
                height: 760,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: chat),
                    SizedBox(width: 290, child: side),
                  ],
                ),
              )
            else
              Column(
                children: [
                  SizedBox(height: 680, child: chat),
                  const SizedBox(height: 16),
                  side,
                ],
              ),
          ],
        );
      },
    );
  }
}

enum _AssistantRole { user, assistant }

class _AssistantChatMessage {
  const _AssistantChatMessage({
    required this.role,
    required this.text,
    this.source,
  });

  final _AssistantRole role;
  final String text;
  final String? source;
}

class _AssistantConversationsPanel extends StatelessWidget {
  const _AssistantConversationsPanel({required this.onPrompt});

  final ValueChanged<String> onPrompt;

  @override
  Widget build(BuildContext context) {
    final conversations = [
      (
        'Breakfast Protein Sources',
        'What are good protein...',
        '9:01 AM',
        'What are good protein sources for breakfast?',
      ),
      (
        'Weekly Meal Plan',
        'Can you create a 7-day...',
        'Yesterday',
        'Can you create a 7-day weekly meal plan?',
      ),
      (
        'Cambodian Food Calories',
        'How many calories in Lok Lak?',
        'Mon',
        'How many calories are in Cambodian beef lok lak?',
      ),
      (
        'Allergy-safe Recipes',
        'I am allergic to nuts...',
        'Sun',
        'Suggest allergy-safe recipes without nuts.',
      ),
      (
        'Weight Loss Tips',
        'What deficit should I aim for?',
        'Last week',
        'What calorie deficit should I aim for?',
      ),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _appSurface(context),
        border: Border(
          top: BorderSide(color: _appBorder(context)),
          left: BorderSide(color: _appBorder(context)),
          bottom: BorderSide(color: _appBorder(context)),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Conversations',
                    style: TextStyle(
                      color: _appText(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => onPrompt('Start a new nutrition chat.'),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('New'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(74, 32),
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextFormField(
              decoration: InputDecoration(
                hintText: 'Search chats...',
                prefixIcon: const Icon(Icons.search, size: 16),
                filled: true,
                fillColor: const Color(0xFFEAF7F1),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: conversations.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                final active = index == 0;
                return InkWell(
                  onTap: () => onPrompt(conversation.$4),
                  borderRadius: BorderRadius.circular(8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFFE7F8F1) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: active
                            ? const Color(0xFF9CDEC5)
                            : Colors.transparent,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  conversation.$1,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: active
                                        ? const Color(0xFF007A4D)
                                        : const Color(0xFF111827),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  conversation.$2,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF667085),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            conversation.$3,
                            style: const TextStyle(
                              color: Color(0xFF8A9791),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFCFE0D6))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOPICS',
                  style: TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.7,
                  children: const [
                    _AssistantTopicTile(
                      icon: Icons.lightbulb_outline,
                      label: 'Nutrition Facts',
                      color: Color(0xFFEAF7F1),
                    ),
                    _AssistantTopicTile(
                      icon: Icons.calendar_month_outlined,
                      label: 'Meal Planning',
                      color: Color(0xFFEFFAF6),
                    ),
                    _AssistantTopicTile(
                      icon: Icons.local_fire_department_outlined,
                      label: 'Calories Tracking',
                      color: Color(0xFFFFF4E5),
                    ),
                    _AssistantTopicTile(
                      icon: Icons.fitness_center,
                      label: 'Fitness & Diet',
                      color: Color(0xFFEFF6FF),
                    ),
                    _AssistantTopicTile(
                      icon: Icons.favorite_border,
                      label: 'Health Goals',
                      color: Color(0xFFFFEDF2),
                    ),
                    _AssistantTopicTile(
                      icon: Icons.error_outline,
                      label: 'Allergies',
                      color: Color(0xFFFFF8E5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantTopicTile extends StatelessWidget {
  const _AssistantTopicTile({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF12C48B)),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantChatPanel extends StatelessWidget {
  const _AssistantChatPanel({
    required this.messages,
    required this.controller,
    required this.loading,
    required this.onAsk,
    required this.onPrompt,
  });

  final List<_AssistantChatMessage> messages;
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onAsk;
  final ValueChanged<String> onPrompt;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _appSurface(context),
        border: Border.all(color: _appBorder(context)),
      ),
      child: Column(
        children: [
          Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: _appBorder(context))),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFF50615A),
                  size: 22,
                ),
                const SizedBox(width: 12),
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFF12C48B),
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NutriAI Assistant',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _appText(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Online · Powered by AI',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF16A05D),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const _AssistantMiniMetric(
                  icon: Icons.local_fire_department_outlined,
                  label: '1,850 kcal goal',
                  color: Color(0xFFFF8A00),
                ),
                const SizedBox(width: 8),
                const _AssistantMiniMetric(
                  icon: Icons.water_drop_outlined,
                  label: '2.0L water',
                  color: Color(0xFF36BFFA),
                ),
                const SizedBox(width: 8),
                const _AssistantMiniMetric(
                  icon: Icons.directions_run,
                  label: 'Active',
                  color: Color(0xFF16A05D),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(42, 18, 42, 18),
              itemCount: messages.length + (loading ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index >= messages.length) {
                  return const _AssistantTypingBubble();
                }
                return _AssistantBubble(message: messages[index]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _AssistantPromptChip(
                    label: 'Plan my meals for this week',
                    onTap: () => onPrompt('Plan my meals for this week.'),
                  ),
                  _AssistantPromptChip(
                    label: 'Analyze my diet',
                    onTap: () => onPrompt('Analyze my diet today.'),
                  ),
                  _AssistantPromptChip(
                    label: 'Find high-protein foods',
                    onTap: () => onPrompt('Find high-protein foods for me.'),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(28, 12, 28, 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: _appBorder(context))),
            ),
            child: Column(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCFE0D6)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Icon(
                          Icons.image_outlined,
                          color: Color(0xFF667085),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: controller,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText:
                                  'Ask about nutrition, meal plans, Cambodian foods...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onFieldSubmitted: (_) {
                              if (!loading) {
                                onAsk();
                              }
                            },
                          ),
                        ),
                        IconButton(
                          tooltip: 'Voice input',
                          onPressed: null,
                          icon: const Icon(Icons.mic_none, size: 20),
                        ),
                        FilledButton(
                          onPressed: loading ? null : onAsk,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(42, 42),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Icon(Icons.send_outlined, size: 19),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'NutriAI may make mistakes. Consult a dietitian for medical nutrition advice.',
                  style: TextStyle(
                    color: Color(0xFF8A9791),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantMiniMetric extends StatelessWidget {
  const _AssistantMiniMetric({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF3FAF6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssistantPromptChip extends StatelessWidget {
  const _AssistantPromptChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      avatar: const Icon(Icons.auto_awesome, size: 15),
      onPressed: onTap,
      backgroundColor: const Color(0xFFEAF7F1),
      side: const BorderSide(color: Color(0xFFCFE4D6)),
      labelStyle: const TextStyle(
        color: Color(0xFF0C3B2E),
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.message});

  final _AssistantChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == _AssistantRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isUser ? const Color(0xFF16A05D) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isUser ? const Color(0xFF16A05D) : const Color(0xFFE4E7EC),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    color: isUser ? Colors.white : const Color(0xFF111827),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!isUser && message.source != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Source: ${message.source}',
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistantTypingBubble extends StatelessWidget {
  const _AssistantTypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(8)),
          border: Border.fromBorderSide(BorderSide(color: Color(0xFFE4E7EC))),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            'NutriAI is thinking...',
            style: TextStyle(
              color: Color(0xFF667085),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistantCapabilitiesPanel extends StatelessWidget {
  const _AssistantCapabilitiesPanel({
    required this.recognizing,
    required this.onPrompt,
    required this.onUploadPhoto,
    required this.risk,
    required this.onPredictRisk,
  });

  final bool recognizing;
  final ValueChanged<String> onPrompt;
  final VoidCallback onUploadPhoto;
  final Map<String, dynamic>? risk;
  final VoidCallback onPredictRisk;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _appSurfaceSoft(context),
        border: Border(
          top: BorderSide(color: _appBorder(context)),
          right: BorderSide(color: _appBorder(context)),
          bottom: BorderSide(color: _appBorder(context)),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        children: [
          const _AssistantSideTitle('AI Capabilities'),
          const SizedBox(height: 14),
          _AssistantCapabilityCard(
            icon: Icons.chat_outlined,
            title: 'Nutrition Q&A',
            subtitle: 'Calories, macros, vitamins, minerals',
            onTap: () => onPrompt('Answer a nutrition question for me.'),
          ),
          const SizedBox(height: 10),
          _AssistantCapabilityCard(
            icon: Icons.camera_alt_outlined,
            title: 'Food Recognition',
            subtitle: 'Upload a photo to identify foods',
            onTap: onUploadPhoto,
          ),
          const SizedBox(height: 10),
          _AssistantCapabilityCard(
            icon: Icons.menu_book_outlined,
            title: 'Meal Planning',
            subtitle: 'Personalized weekly meal plans',
            onTap: () => onPrompt('Create a personalized weekly meal plan.'),
          ),
          const SizedBox(height: 20),
          _AssistantContextCard(risk: risk, onPredictRisk: onPredictRisk),
          const SizedBox(height: 20),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFEFF8F3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCFE0D6)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        color: Color(0xFF12C48B),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Calorie Estimator',
                          style: TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Take a photo of your meal and get instant nutrition estimates.',
                    style: TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 11,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: recognizing ? null : onUploadPhoto,
                      icon: Icon(
                        recognizing
                            ? Icons.hourglass_empty
                            : Icons.upload_outlined,
                        size: 15,
                      ),
                      label: Text(
                        recognizing ? 'Analyzing...' : 'Upload Food Photo',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const _AssistantSideTitle('Tips', small: true),
          const SizedBox(height: 10),
          _AssistantTipTile(
            icon: Icons.schedule,
            text: 'Ask about meal timing for better energy',
            onTap: () =>
                onPrompt('What is the best meal timing for better energy?'),
          ),
          _AssistantTipTile(
            icon: Icons.fitness_center,
            text: 'Mention your workout for tailored macros',
            onTap: () => onPrompt('Tailor my macros for my workout routine.'),
          ),
          _AssistantTipTile(
            icon: Icons.favorite_border,
            text: 'Share health goals for personalized plans',
            onTap: () => onPrompt('Help me plan based on my health goals.'),
          ),
        ],
      ),
    );
  }
}

class _AssistantSideTitle extends StatelessWidget {
  const _AssistantSideTitle(this.title, {this.small = false});

  final String title;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          small ? Icons.lightbulb_outline : Icons.bolt,
          size: small ? 14 : 16,
          color: const Color(0xFF007A4D),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: _appText(context),
            fontSize: small ? 12 : 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _AssistantCapabilityCard extends StatelessWidget {
  const _AssistantCapabilityCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFC9DCD3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF7EA),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(icon, size: 20, color: const Color(0xFF00865A)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssistantContextCard extends StatelessWidget {
  const _AssistantContextCard({
    required this.risk,
    required this.onPredictRisk,
  });

  final Map<String, dynamic>? risk;
  final VoidCallback onPredictRisk;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC9DCD3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Today's Context",
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            const _AssistantMacroRow(
              label: 'Calories',
              value: '1,240 / 1,850',
              progress: .67,
              color: Color(0xFFFF8A00),
            ),
            const _AssistantMacroRow(
              label: 'Protein',
              value: '58g / 120g',
              progress: .48,
              color: Color(0xFF4C9AFF),
            ),
            const _AssistantMacroRow(
              label: 'Carbs',
              value: '142g / 230g',
              progress: .62,
              color: Color(0xFFFFB000),
            ),
            const _AssistantMacroRow(
              label: 'Fat',
              value: '34g / 60g',
              progress: .57,
              color: Color(0xFFFF5D7A),
            ),
            const SizedBox(height: 8),
            Text(
              risk == null
                  ? 'AI uses this context to give you personalized advice.'
                  : 'Latest risk: ${risk!['risk_level']} · BMI ${risk!['bmi']}',
              style: const TextStyle(
                color: Color(0xFF8A9791),
                fontSize: 9,
                height: 1.35,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onPredictRisk,
              icon: const Icon(Icons.health_and_safety_outlined, size: 14),
              label: const Text('Check health risk'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF007A4D),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssistantMacroRow extends StatelessWidget {
  const _AssistantMacroRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  final String label;
  final String value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE9EEF0),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantTipTile extends StatelessWidget {
  const _AssistantTipTile({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE4E7EC)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 15, color: const Color(0xFF007A4D)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _weight = TextEditingController();
  final _date = TextEditingController(text: todayIsoDate());
  final _water = TextEditingController(text: '250');
  Map<String, dynamic>? _progress;
  Map<String, dynamic>? _waterLog;
  List<Map<String, dynamic>> _waterHistory = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _weight.dispose();
    _date.dispose();
    _water.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final progress = await widget.apiClient.weightProgress();
      final water = await widget.apiClient.waterLog(todayIsoDate());
      final waterHistory = await widget.apiClient.waterLogs(days: 7);
      setState(() {
        _progress = progress;
        _waterLog = water;
        _waterHistory = waterHistory;
        _error = null;
        if (_weight.text.trim().isEmpty) {
          final currentWeight = _foodNumber(progress['current_weight']);
          if (currentWeight > 0) {
            _weight.text = _formatFoodNumber(currentWeight);
          }
        }
      });
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _recordWeight() async {
    await widget.apiClient.recordWeight(
      double.tryParse(_weight.text) ?? 75,
      recordedDate: _date.text.trim().isEmpty ? null : _date.text.trim(),
    );
    await _load();
  }

  Future<void> _recordWater() async {
    final addAmount = double.tryParse(_water.text) ?? 0;
    final currentAmount = _foodNumber(_waterLog?['amount_ml']);
    await widget.apiClient.logWater(currentAmount + addAmount);
    await _load();
  }

  void _setWaterPreset(double value) {
    setState(() => _water.text = _formatFoodNumber(value));
  }

  @override
  Widget build(BuildContext context) {
    final history = _weightHistory(_progress);
    final currentWeight = _foodNumber(_progress?['current_weight']);
    final targetWeight = _foodNumber(_progress?['target_weight']);
    final startWeight = _foodNumber(_progress?['start_weight']);
    final progress = _foodNumber(_progress?['progress_percentage']);
    final waterAmount = _foodNumber(_waterLog?['amount_ml']);
    final recommendedWater = _foodNumber(_waterLog?['recommended_ml']);
    final waterRemaining = math.max(0.0, recommendedWater - waterAmount);
    final waterPercent = recommendedWater <= 0
        ? 0.0
        : ((waterAmount / recommendedWater) * 100).clamp(0, 100).toDouble();
    final lost = startWeight == 0 || currentWeight == 0
        ? 0.0
        : startWeight - currentWeight;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const _ProgressHeader(),
        const SizedBox(height: 16),
        if (_error != null) ...[
          ErrorBanner(message: _error!),
          const SizedBox(height: 14),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 900;
            final metrics = [
              _ProgressMetricCard(
                title: 'Current Weight',
                value: currentWeight == 0
                    ? '- kg'
                    : '${_formatFoodNumber(currentWeight)} kg',
                icon: Icons.trending_up,
                background: const Color(0xFFE8F6EE),
                iconBackground: const Color(0xFFCFF0DD),
                footer: Row(
                  children: [
                    Expanded(
                      child: _ProgressMiniLabel(
                        label: 'Target',
                        value: targetWeight == 0
                            ? '-'
                            : '${_formatFoodNumber(targetWeight)} kg',
                      ),
                    ),
                    _ProgressMiniLabel(
                      label: 'Lost',
                      value:
                          '${lost >= 0 ? '-' : '+'}${_formatFoodNumber(lost.abs())} kg',
                      alignEnd: true,
                      valueColor: const Color(0xFF16A05D),
                    ),
                  ],
                ),
              ),
              _ProgressMetricCard(
                title: 'Progress',
                value: '${_formatFoodNumber(progress)}%',
                icon: Icons.track_changes,
                background: Colors.white,
                iconBackground: const Color(0xFFE8F6EE),
                footer: _ProgressBar(
                  value: progress / 100,
                  caption:
                  '${_formatFoodNumber((currentWeight - targetWeight).abs())} kg to goal',
                  color: const Color(0xFF16A05D),
                ),
              ),
              _ProgressMetricCard(
                title: "Today's Water",
                value: '${_formatFoodNumber(waterAmount)} ml',
                icon: Icons.water_drop,
                background: const Color(0xFFEAF7FF),
                iconBackground: const Color(0xFFCFEFFF),
                valueColor: const Color(0xFF36BFFA),
                footer: _ProgressBar(
                  value: recommendedWater == 0
                      ? 0.0
                      : waterAmount / recommendedWater,
                  caption:
                      '${_formatFoodNumber(waterRemaining)} ml remaining • ${_formatFoodNumber(waterPercent)}%',
                  color: const Color(0xFF36BFFA),
                ),
              ),
            ];
            final metricRow = compact
                ? Wrap(spacing: 16, runSpacing: 16, children: metrics)
                : Row(
                    children: metrics
                        .map(
                          (card) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: card,
                            ),
                          ),
                        )
                        .toList(),
                  );
            final left = Column(
              children: [
                _ProgressPanel(
                  title: 'Weight Progress',
                  child: Column(
                    children: [
                      _WeightProgressChart(
                        history: history,
                        startWeight: startWeight,
                        currentWeight: currentWeight,
                        targetWeight: targetWeight,
                      ),
                      const SizedBox(height: 18),
                      _RecentWeightEntries(history: history),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _ProgressPanel(
                  title: 'Weekly Water Intake',
                  child: _WeeklyWaterChart(
                    logs: _waterHistory,
                    todayAmount: waterAmount,
                    recommendedAmount: recommendedWater,
                  ),
                ),
              ],
            );
            final right = Column(
              children: [
                _ProgressPanel(
                  title: 'Log Weight',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FoodLogTextField(
                        controller: _weight,
                        label: 'Weight (kg)',
                        hintText: '72.5',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      _FoodLogTextField(
                        controller: _date,
                        label: 'Date',
                        hintText: 'yyyy-mm-dd',
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: _loading ? null : _recordWeight,
                        icon: const Icon(Icons.add, size: 15),
                        label: const Text('Log Weight'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _ProgressPanel(
                  title: 'Log Water Intake',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FoodLogTextField(
                        controller: _water,
                        label: 'Amount (ml)',
                        hintText: '250',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _WaterPresetButton(
                            label: '250ml',
                            onTap: () => _setWaterPreset(250),
                          ),
                          _WaterPresetButton(
                            label: '500ml',
                            onTap: () => _setWaterPreset(500),
                          ),
                          _WaterPresetButton(
                            label: '750ml',
                            onTap: () => _setWaterPreset(750),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _loading ? null : _recordWater,
                        icon: const Icon(Icons.water_drop, size: 15),
                        label: const Text('Add Water'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF36BFFA),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _MilestonesCard(lost: lost, progress: progress),
              ],
            );
            return Column(
              children: [
                metricRow,
                const SizedBox(height: 20),
                if (compact)
                  Column(children: [left, const SizedBox(height: 20), right])
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: left),
                      const SizedBox(width: 20),
                      SizedBox(width: 300, child: right),
                    ],
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

List<Map<String, dynamic>> _weightHistory(Map<String, dynamic>? progress) {
  final history = progress?['history'];
  if (history is! List) {
    return <Map<String, dynamic>>[];
  }
  return history.map((item) => Map<String, dynamic>.from(item as Map)).toList();
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress Tracking',
          style: TextStyle(
            color: _appText(context),
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Monitor your weight and hydration progress',
          style: TextStyle(
            color: _appMutedText(context),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ProgressMetricCard extends StatelessWidget {
  const _ProgressMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.background,
    required this.iconBackground,
    required this.footer,
    this.valueColor = const Color(0xFF111827),
  });

  final String title;
  final String value;
  final IconData icon;
  final Color background;
  final Color iconBackground;
  final Widget footer;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDDE8E1)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: Icon(
                        icon,
                        size: 17,
                        color: const Color(0xFF16A05D),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: valueColor,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              footer,
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressMiniLabel extends StatelessWidget {
  const _ProgressMiniLabel({
    required this.label,
    required this.value,
    this.alignEnd = false,
    this.valueColor = const Color(0xFF111827),
  });

  final String label;
  final String value;
  final bool alignEnd;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF667085),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.value,
    required this.caption,
    required this.color,
  });

  final double value;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 7,
            backgroundColor: const Color(0xFFF2F4F7),
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          caption,
          style: const TextStyle(
            color: Color(0xFF667085),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _FoodLogPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: _appText(context),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _WeightProgressChart extends StatelessWidget {
  const _WeightProgressChart({
    required this.history,
    required this.startWeight,
    required this.currentWeight,
    required this.targetWeight,
  });

  final List<Map<String, dynamic>> history;
  final double startWeight;
  final double currentWeight;
  final double targetWeight;

  @override
  Widget build(BuildContext context) {
    final values = history.isEmpty
        ? <double>[startWeight, currentWeight]
        : history.map((item) => _foodNumber(item['weight_kg'])).toList();
    return Column(
      children: [
        SizedBox(
          height: 235,
          width: double.infinity,
          child: CustomPaint(
            painter: _WeightChartPainter(
              history: history,
              values: values,
              targetWeight: targetWeight,
            ),
          ),
        ),
        if (history.length < 2) ...[
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Log weight on another date to draw a trend line.',
              style: TextStyle(
                color: Color(0xFF667085),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _WeightSummaryBox(
                label: 'Start',
                value: '${_formatFoodNumber(startWeight)} kg',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _WeightSummaryBox(
                label: 'Current',
                value: '${_formatFoodNumber(currentWeight)} kg',
                highlighted: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _WeightSummaryBox(
                label: 'Target',
                value: targetWeight == 0
                    ? '-'
                    : '${_formatFoodNumber(targetWeight)} kg',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WeightSummaryBox extends StatelessWidget {
  const _WeightSummaryBox({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFE8F6EE) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlighted
              ? const Color(0xFFCFE0D6)
              : const Color(0xFFE4E7EC),
        ),
      ),
      child: SizedBox(
        height: 62,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF98A2B3),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: highlighted
                    ? const Color(0xFF16A05D)
                    : const Color(0xFF111827),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentWeightEntries extends StatelessWidget {
  const _RecentWeightEntries({required this.history});

  final List<Map<String, dynamic>> history;

  @override
  Widget build(BuildContext context) {
    final recent = history.reversed.take(5).toList();
    if (recent.isEmpty) {
      return const _SystemEmptyState(
        icon: Icons.monitor_weight_outlined,
        title: 'No weight logs yet',
        message: 'Log your weight to start building a trend.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Recent entries',
            style: TextStyle(
              color: Color(0xFF667085),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...recent.map((entry) {
          final weight = _formatFoodNumber(_foodNumber(entry['weight_kg']));
          final date = entry['recorded_date']?.toString() ?? '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE4E7EC)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.monitor_weight_outlined,
                      size: 16,
                      color: Color(0xFF16A05D),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        date,
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '$weight kg',
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  const _WeightChartPainter({
    required this.history,
    required this.values,
    required this.targetWeight,
  });

  final List<Map<String, dynamic>> history;
  final List<double> values;
  final double targetWeight;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFEFF2F5)
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = const Color(0xFF16A05D)
      ..strokeWidth = 2.3
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()..color = const Color(0xFF16A05D);
    final targetPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final left = 46.0;
    final right = size.width - 18;
    final top = 10.0;
    final bottom = size.height - 28;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i < 5; i++) {
      final y = top + (bottom - top) * i / 4;
      canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
    }

    final cleanValues = values.where((value) => value > 0).toList();
    if (cleanValues.isEmpty) {
      return;
    }
    final scaleValues = [...cleanValues, if (targetWeight > 0) targetWeight];
    final rawMin = scaleValues.reduce(math.min);
    final rawMax = scaleValues.reduce(math.max);
    final padding = math.max(1.0, (rawMax - rawMin).abs() * 0.15);
    final minValue = rawMin - padding;
    final maxValue = rawMax + padding;
    final range = math.max(1, maxValue - minValue);

    double yForValue(double value) {
      return bottom - ((value - minValue) / range) * (bottom - top);
    }

    for (var i = 0; i < 5; i++) {
      final value = maxValue - range * i / 4;
      final y = top + (bottom - top) * i / 4;
      textPainter.text = TextSpan(
        text: '${_formatFoodNumber(value)} kg',
        style: const TextStyle(color: Color(0xFF667085), fontSize: 9),
      );
      textPainter.layout(maxWidth: left - 8);
      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }

    if (targetWeight > 0) {
      final targetY = yForValue(targetWeight);
      _drawDashedLine(
        canvas,
        Offset(left, targetY),
        Offset(right, targetY),
        targetPaint,
      );
      textPainter.text = const TextSpan(
        text: 'Target',
        style: TextStyle(color: Color(0xFF64748B), fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(right - textPainter.width, targetY - 14),
      );
    }

    final points = <Offset>[];
    for (var i = 0; i < cleanValues.length; i++) {
      final x = cleanValues.length == 1
          ? right
          : left + (right - left) * i / (cleanValues.length - 1);
      final y = yForValue(cleanValues[i]);
      points.add(Offset(x, y));
    }
    if (points.length > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, linePaint);
    }
    for (final point in points) {
      canvas.drawCircle(point, 3.5, dotPaint);
    }

    final labels = _dateLabels(cleanValues.length);
    for (var i = 0; i < labels.length; i++) {
      final x = labels.length == 1
          ? right
          : left + (right - left) * i / (labels.length - 1);
      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(color: Color(0xFF667085), fontSize: 9),
      );
      textPainter.layout();
      final labelX = (x - textPainter.width / 2).clamp(
        0.0,
        size.width - textPainter.width,
      );
      textPainter.paint(canvas, Offset(labelX, bottom + 14));
    }
  }

  List<String> _dateLabels(int count) {
    if (history.isEmpty) {
      return count <= 1 ? ['Today'] : ['Start', 'Today'];
    }
    return history.map((entry) {
      final raw = entry['recorded_date']?.toString() ?? '';
      final parsed = DateTime.tryParse(raw);
      if (parsed == null) {
        return raw;
      }
      return '${_monthLabel(parsed.month)} ${parsed.day}';
    }).toList();
  }

  String _monthLabel(int month) {
    const labels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return labels[(month - 1).clamp(0, labels.length - 1)];
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 6.0;
    const dashSpace = 5.0;
    var distance = 0.0;
    final total = (end - start).distance;
    final direction = (end - start) / total;
    while (distance < total) {
      final next = math.min(distance + dashWidth, total);
      canvas.drawLine(
        start + direction * distance,
        start + direction * next,
        paint,
      );
      distance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.history != history ||
        oldDelegate.targetWeight != targetWeight;
  }
}

class _WeeklyWaterChart extends StatelessWidget {
  const _WeeklyWaterChart({
    required this.logs,
    required this.todayAmount,
    required this.recommendedAmount,
  });

  final List<Map<String, dynamic>> logs;
  final double todayAmount;
  final double recommendedAmount;

  @override
  Widget build(BuildContext context) {
    final valuesByDate = {
      for (final log in logs)
        if (log['log_date'] != null)
          log['log_date'].toString(): _foodNumber(log['amount_ml']),
    };
    final today = DateTime.now();
    final days = List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      final key =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      return _WaterDay(
        label: _weekdayLabel(date.weekday),
        amount: key == todayIsoDate()
            ? math.max(todayAmount, valuesByDate[key] ?? 0)
            : valuesByDate[key] ?? 0,
      );
    });
    final maxAmount = math.max(
      recommendedAmount,
      days.map((day) => day.amount).fold<double>(0, math.max),
    );
    final average = days.isEmpty
        ? 0.0
        : days.fold<double>(0, (sum, day) => sum + day.amount) / days.length;
    final goalDays = recommendedAmount <= 0
        ? 0
        : days.where((day) => day.amount >= recommendedAmount).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 190,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: days.map((day) {
              final percent = maxAmount <= 0 ? 0.0 : day.amount / maxAmount;
              final height = day.amount <= 0 ? 8.0 : 24 + percent * 110;
              final hitGoal =
                  recommendedAmount > 0 && day.amount >= recommendedAmount;
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _formatFoodNumber(day.amount),
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: hitGoal
                            ? const Color(0xFF36BFFA)
                            : const Color(0xFFBFEAFF),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: SizedBox(width: 34, height: height),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      day.label,
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _WeightSummaryBox(
                label: '7-day avg',
                value: '${_formatFoodNumber(average)} ml',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _WeightSummaryBox(
                label: 'Goal days',
                value: '$goalDays / 7',
                highlighted: goalDays > 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _WeightSummaryBox(
                label: 'Daily goal',
                value: recommendedAmount <= 0
                    ? '-'
                    : '${_formatFoodNumber(recommendedAmount)} ml',
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _weekdayLabel(int weekday) {
    const labels = {
      DateTime.monday: 'Mon',
      DateTime.tuesday: 'Tue',
      DateTime.wednesday: 'Wed',
      DateTime.thursday: 'Thu',
      DateTime.friday: 'Fri',
      DateTime.saturday: 'Sat',
      DateTime.sunday: 'Sun',
    };
    return labels[weekday] ?? '';
  }
}

class _WaterDay {
  const _WaterDay({required this.label, required this.amount});

  final String label;
  final double amount;
}

class _WaterPresetButton extends StatelessWidget {
  const _WaterPresetButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFEAF3FF),
          side: const BorderSide(color: Color(0xFFD7E7FF)),
          foregroundColor: const Color(0xFF2563EB),
          textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
          padding: const EdgeInsets.symmetric(horizontal: 13),
        ),
        child: Text(label),
      ),
    );
  }
}

class _MilestonesCard extends StatelessWidget {
  const _MilestonesCard({required this.lost, required this.progress});

  final double lost;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE8F6EE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCFE0D6)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Milestones',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            _MilestoneRow(
              active: lost > 0,
              text: lost > 0
                  ? 'Lost ${_formatFoodNumber(lost)} kg so far!'
                  : 'Start logging weight',
            ),
            const _MilestoneRow(active: true, text: '7 days hydration streak'),
            _MilestoneRow(active: progress >= 100, text: 'Reach target weight'),
          ],
        ),
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({required this.active, required this.text});

  final bool active;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 7,
            color: active ? const Color(0xFF16A05D) : const Color(0xFFC9D2DC),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: active
                    ? const Color(0xFF344054)
                    : const Color(0xFF98A2B3),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MealRecommendationView extends StatelessWidget {
  const MealRecommendationView({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final meals = data['meals'] as List<dynamic>;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: 'Recommended plan'),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 14.0;
              final columns = (constraints.maxWidth / 280).floor().clamp(1, 4);
              final tileWidth =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: meals.map((meal) {
                  return SizedBox(
                    width: tileWidth,
                    child: MealPlanTile(
                      data: Map<String, dynamic>.from(meal as Map),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class MealPlanTile extends StatelessWidget {
  const MealPlanTile({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final items = data['items'] as List<dynamic>? ?? [];
    final mealType = _mealTitle(data['meal_type'].toString());
    final calories = data['calories'];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFB),
        border: Border.all(color: const Color(0xFFDDE5E1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    mealType,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '$calories kcal',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text(
                'No foods selected',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              ...items.map((item) {
                final food = Map<String, dynamic>.from(item as Map);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 7),
                        child: SizedBox(
                          width: 5,
                          height: 5,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(0xFF6B7A73),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          '${food['name']} • ${food['serving_size']}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  String _mealTitle(String value) {
    if (value.isEmpty) {
      return 'Meal';
    }
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }
}

class GroceryListView extends StatelessWidget {
  const GroceryListView({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final items = data['items'] as List<dynamic>? ?? [];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: data['name'].toString()),
          const SizedBox(height: 8),
          Text('Estimated total: ${data['estimated_total_cost']}'),
          const SizedBox(height: 12),
          ...items.map((item) {
            final grocery = Map<String, dynamic>.from(item as Map);
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: grocery['purchased'] == true,
              onChanged: null,
              title: Text(grocery['food_item'].toString()),
              subtitle: Text(
                '${grocery['quantity']} • ${grocery['estimated_cost']}',
              ),
            );
          }),
        ],
      ),
    );
  }
}

class PageScaffold extends StatelessWidget {
  const PageScaffold({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        PageHeader(title: title),
        const SizedBox(height: 16),
        ...children.expand((child) => [child, const SizedBox(height: 16)]),
      ],
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_leafDark, _leaf, Color(0xFF7FCB8D)],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F0C3B2E),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.eco_rounded, color: Colors.white),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _pageSubtitle(title),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFE7F5EA),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _pageSubtitle(String title) {
    return switch (title) {
      'Dashboard' => 'Today at a glance',
      'Profile' => 'Personalize your nutrition targets',
      'Meal planner' => 'Generate meals and shopping ideas',
      'Food log' => 'Record what you eat and track macros',
      'AI assistant' => 'Ask questions and check basic risks',
      'Progress' => 'Monitor weight and hydration',
      _ => 'NutriAI workspace',
    };
  }
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minTileWidth = 180,
  });

  final List<Widget> children;
  final double minTileWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / minTileWidth).floor().clamp(1, 4);
        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.8,
          children: children,
        );
      },
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return _HoverLift(
      child: Card(
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _HoverLift(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFDDE8E1)),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120C3B2E),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: _metricColor(label).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(icon, color: _metricColor(label), size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF62716A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _metricColor(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('calorie') || lower.contains('risk')) {
      return _coral;
    }
    if (lower.contains('water') || lower.contains('carb')) {
      return _blue;
    }
    if (lower.contains('protein') || lower.contains('weight')) {
      return _leaf;
    }
    return _amber;
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: _leaf,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class SelectField extends StatelessWidget {
  const SelectField({
    super.key,
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey(value),
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: values
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class NumberField extends StatelessWidget {
  const NumberField({super.key, required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return BannerBox(
      message: message,
      color: const Color(0xFFFFE9E5),
      icon: Icons.error_outline,
    );
  }
}

class SuccessBanner extends StatelessWidget {
  const SuccessBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return BannerBox(
      message: message,
      color: const Color(0xFFE7F5EA),
      icon: Icons.check_circle_outline,
    );
  }
}

class BannerBox extends StatelessWidget {
  const BannerBox({
    super.key,
    required this.message,
    required this.color,
    required this.icon,
  });

  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _HoverLift extends StatefulWidget {
  const _HoverLift({required this.child, this.borderRadius = 8});

  final Widget child;
  final double borderRadius;

  @override
  State<_HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<_HoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.18),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ]
              : const [],
        ),
        child: widget.child,
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ErrorBanner(message: message),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardData {
  _DashboardData({
    required this.profile,
    required this.goal,
    required this.foods,
    required this.summary,
    required this.logs,
    required this.progress,
    required this.water,
    required this.weeklySummaries,
  });

  final Map<String, dynamic> profile;
  final Map<String, dynamic> goal;
  final List<Map<String, dynamic>> foods;
  final Map<String, dynamic> summary;
  final List<Map<String, dynamic>> logs;
  final Map<String, dynamic> progress;
  final Map<String, dynamic> water;
  final List<Map<String, dynamic>> weeklySummaries;
}

String? _required(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Required';
  }
  return null;
}

String todayIsoDate() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}
