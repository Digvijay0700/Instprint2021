import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  Future<void> _loadRememberedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? remember = prefs.getBool('remember_me');
    if (remember == true) {
      setState(() {
        rememberMe = true;
        emailController.text = prefs.getString('email') ?? '';
        passwordController.text = prefs.getString('password') ?? '';
      });

      // Auto-login
      if (emailController.text.isNotEmpty &&
          passwordController.text.isNotEmpty) {
        _loginUser();
      }
    }
  }

  Future<void> _saveCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('email', emailController.text.trim());
      await prefs.setString('password', passwordController.text.trim());
    } else {
      await prefs.setBool('remember_me', false);
      await prefs.remove('email');
      await prefs.remove('password');
    }
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      final user = await _authService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (user != null) {
        await _saveCredentials();
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          message = 'Email address is not valid.';
          break;
        case 'user-disabled':
          message = 'This user account has been disabled.';
          break;
        default:
          message = 'Login failed. Please check your credentials.';
      }
      _showErrorDialog(message);
    } catch (e) {
      _showErrorDialog("Something went wrong. Please try again.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    if (emailController.text.isEmpty) {
      _showErrorDialog("Please enter your email to reset password.");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          title: const Text("Password Reset"),
          content: Text(
            "A password reset link has been sent to ${emailController.text
                .trim()}. Please check your email.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                  "OK", style: TextStyle(color: Colors.indigo)),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = "No user found with this email.";
          break;
        case 'invalid-email':
          message = "Email address is not valid.";
          break;
        default:
          message = "Failed to send password reset email. Try again.";
      }
      _showErrorDialog(message);
    } catch (e) {
      _showErrorDialog("Something went wrong. Please try again.");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            backgroundColor: Colors.white,
            title: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text("Error", style: TextStyle(color: Colors.red)),
              ],
            ),
            content: Text(
                message, style: const TextStyle(color: Colors.black87)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK", style: TextStyle(color: Colors.indigo)),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // << fixes keyboard overflow
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 40),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFF8E1), Color(0xFFFFC107)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Center(
                child: SizedBox(
                  height: 150,
                  child: Image.asset('assets/logo.png'),
                ),
              ),
              const SizedBox(height: 25),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          "Login to your account",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Email & Password Fields
                        TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: "Email",
                            prefixIcon: const Icon(Icons.email),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) =>
                          value!.isEmpty ? "Enter your email" : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) =>
                          value!.isEmpty ? "Enter your password" : null,
                        ),
                        const SizedBox(height: 8),
                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordPage()),
                            ),
                            child: Text(
                              "Forgot Password?",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.indigo.shade800,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        // Remember Me
                        Row(
                          children: [
                            Checkbox(
                              value: rememberMe,
                              onChanged: (value) {
                                setState(() =>
                                rememberMe = value ?? false);
                              },
                            ),
                            const Text("Remember Me"),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Login button
                        isLoading
                            ? Lottie.asset(
                            'assets/lottie/login_printer.json',
                            height: 100)
                            : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _loginUser,
                            child: Text(
                              "Login",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/register'),
                          child: Text(
                            "Don't have an account? Register",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.indigo.shade800,
                              decoration: TextDecoration.underline,
                            ),
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
}
