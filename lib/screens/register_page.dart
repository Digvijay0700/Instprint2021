import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? selectedYear;
  bool _isLoading = false;

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate() || selectedYear == null) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final uid = userCred.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'year': selectedYear,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful!')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Registration failed')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.amber[800]),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                color: Colors.white,
                elevation: 12,
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[800],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Name
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                          value!.isEmpty ? 'Enter your name' : null,
                        ),
                        const SizedBox(height: 16),

                        // Phone
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) => value!.length < 10
                              ? 'Enter a valid phone number'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) =>
                          value!.isEmpty ? 'Enter your email' : null,
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value!.length < 6
                              ? 'Minimum 6 characters'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                          value!.isEmpty ? 'Re-enter your password' : null,
                        ),
                        const SizedBox(height: 16),

                        // Year Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedYear,
                          items: ['1st', '2nd', '3rd'].map((year) {
                            return DropdownMenuItem<String>(
                              value: year,
                              child: Text(year),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => selectedYear = value);
                          },
                          validator: (value) =>
                          value == null ? "Select your year" : null,
                          decoration: InputDecoration(
                            labelText: "Year",
                            prefixIcon: const Icon(Icons.school),
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit Button or Animation
                        _isLoading
                            ? SizedBox(
                          height: 80,
                          child: Lottie.asset(
                            'assets/lottie/login_printer.json',
                            fit: BoxFit.contain,
                          ),
                        )
                            : ElevatedButton(
                          onPressed: _registerUser,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.amber[800],
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Register",
                              style: TextStyle(fontSize: 18)),
                        ),

                        const SizedBox(height: 16),

                        // ✅ Consent with clickable links
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                                color: Colors.black87, fontSize: 14),
                            children: [
                              const TextSpan(
                                  text: "By registering, you agree to our "),
                              TextSpan(
                                text: "Terms & Conditions",
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    _showPolicyDialog(
                                      context,
                                      "Terms & Conditions",
                                      """Welcome to INSTPRINT! 

By using our app, you agree not to upload illegal or offensive content. 
Prices are shown per shopkeeper. INSTPRINT is not responsible for misprints or delays. 
Refunds/cancellations depend on shopkeeper policy.  

Thank you for using INSTPRINT!""",
                                    );
                                  },
                              ),
                              const TextSpan(text: " and "),
                              TextSpan(
                                text: "Privacy Policy",
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    _showPolicyDialog(
                                      context,
                                      "Privacy Policy",
                                      """We collect name, email, phone, and uploaded documents 
to process print requests. Your data is stored securely in Firebase 
and only shared with the chosen shopkeeper.  

Uploaded files are deleted after order completion.  
We never sell your data to third parties.""",
                                    );
                                  },
                              ),
                              const TextSpan(text: "."),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Already have account
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Navigate back to login page
                },
                child: const Text(
                  "Already have an account? Log In",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// 🔹 Helper function for policy popup
void _showPolicyDialog(BuildContext context, String title, String content) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.amber[800],
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Text(
          content,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text(
            "Close",
            style: TextStyle(color: Colors.black87),
          ),
        ),
      ],
    ),
  );
}
