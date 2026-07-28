import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_grow_code/auth/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialMessage});

  final String? initialMessage;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final message = widget.initialMessage;
    if (message != null && message.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showMessage(message, isError: true);
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (_isLoading) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Enter your email and password.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.signIn(email: email, password: password);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (error) {
      _showMessage(_authErrorMessage(error), isError: true);
    } on AuthStatusException catch (error) {
      _showMessage(error.message, isError: true);
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      _showMessage(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Enter your email first, then tap Forgot Password.');
      return;
    }

    try {
      await AuthService.sendPublicPasswordReset(email);
      _showMessage('Password reset email sent if the account exists.');
    } on FirebaseAuthException catch (error) {
      _showMessage(_authErrorMessage(error), isError: true);
    } catch (_) {
      _showMessage('Unable to send a password reset email right now.');
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst('Exception: ', '')),
        backgroundColor: isError ? Colors.redAccent : null,
      ),
    );
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact an administrator.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: screen.width * 0.08,
          vertical: screen.height * 0.05,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFB68C63).withOpacity(0.7),
              const Color(0xFFF5EFE6),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: (screen.width * 0.12).clamp(44.0, 68.0).toDouble(),
                    backgroundImage: const AssetImage(
                      'assets/images/adhika_logo.jpg',
                    ),
                  ),
                  SizedBox(height: screen.height * 0.015),
                  Text(
                    'Smart Grow',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: (screen.width * 0.07)
                          .clamp(28.0, 38.0)
                          .toDouble(),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'IoT Mushroom Monitoring',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: (screen.width * 0.035)
                          .clamp(14.0, 18.0)
                          .toDouble(),
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: screen.height * 0.04),
                  buildInputField(
                    icon: Icons.email,
                    label: 'Email',
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: screen.height * 0.02),
                  buildInputField(
                    icon: Icons.lock,
                    label: 'Password',
                    isPassword: true,
                    controller: passwordController,
                    onSubmitted: (_) => login(),
                  ),
                  SizedBox(height: screen.height * 0.015),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _sendPasswordReset,
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: Color(0xFF5D4037)),
                      ),
                    ),
                  ),
                  SizedBox(height: screen.height * 0.02),
                  buildButton(
                    text: _isLoading ? 'LOGGING IN...' : 'LOGIN',
                    color: const Color(0xFFB68C63),
                    textColor: Colors.white,
                    onPressed: _isLoading ? null : login,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInputField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    bool isPassword = false,
    TextInputType? keyboardType,
    ValueChanged<String>? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? !_isPasswordVisible : false,
        keyboardType: keyboardType,
        textInputAction: isPassword
            ? TextInputAction.done
            : TextInputAction.next,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFFB68C63)),
          labelText: label,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget buildButton({
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        child: Text(text, style: TextStyle(fontSize: 16, color: textColor)),
      ),
    );
  }
}
