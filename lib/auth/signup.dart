import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:siwes360/auth/login.dart';
import 'package:siwes360/auth/otpsignup.dart';
import 'package:siwes360/themes/theme.dart';
import 'package:siwes360/widgets/customButton.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Back button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: () => Navigator.pop(context),
                      color: Colors.black,
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),

                  Text(
                    'Hello! Register to get\nstarted',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E232C),
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 32),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline, // Changed icon
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: usernameController,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter a username';
                                  }
                                  if (value.trim().length < 3) {
                                    return 'Username must be at least 3 characters';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: "Username",
                                  hintStyle: TextStyle(
                                    color: SIWES360.darkBorderColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  border: InputBorder.none,
                                  errorStyle: TextStyle(
                                    fontSize: 12,
                                    height: 0.5,
                                  ),
                                ),
                                keyboardType: TextInputType.text,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),

                  // Email Field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: emailController,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@stu.cu.edu.ng')) {
                                    return 'Please enter a valid CU student email';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: "Email",
                                  hintStyle: TextStyle(
                                    color: SIWES360.darkBorderColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  border: InputBorder.none,
                                  errorStyle: TextStyle(
                                    fontSize: 12,
                                    height: 0.5,
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock, color: Colors.grey[600], size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: passwordController,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (value.length < 8) {
                                    return 'Password must be at least 8 characters';
                                  }
                                  if (!RegExp(r'[A-Z]').hasMatch(value)) {
                                    return 'Password must contain an uppercase letter';
                                  }
                                  if (!RegExp(r'[0-9]').hasMatch(value)) {
                                    return 'Password must contain a number';
                                  }
                                  return null;
                                },
                                obscureText: !_isPasswordVisible,
                                decoration: InputDecoration(
                                  hintText: "Password",
                                  hintStyle: TextStyle(
                                    color: SIWES360.darkBorderColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  border: InputBorder.none,
                                  errorStyle: TextStyle(
                                    fontSize: 12,
                                    height: 0.5,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.grey[600],
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible =
                                            !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock, color: Colors.grey[600], size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: confirmPasswordController,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (value != passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                                obscureText: !_isConfirmPasswordVisible,
                                decoration: InputDecoration(
                                  hintText: "Confirm password",
                                  hintStyle: TextStyle(
                                    color: SIWES360.darkBorderColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  border: InputBorder.none,
                                  errorStyle: TextStyle(
                                    fontSize: 12,
                                    height: 0.5,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isConfirmPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.grey[600],
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isConfirmPasswordVisible =
                                            !_isConfirmPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),

                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: CustomButton(
                      ontap: () {
                        if (_formKey.currentState!.validate()) {
                          _handleRegister();
                        }
                      },
                      data: _isLoading ? "Registering..." : "Register",
                      textcolor: Colors.white,
                      backgroundcolor: _isLoading
                          ? Colors.grey
                          : Color(0xFF0A3D62),
                      width: MediaQuery.of(context).size.width,
                      height: 50,
                    ),
                  ),

                  if (_isLoading)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: CircularProgressIndicator(
                          color: Color(0xFF0A3D62),
                        ),
                      ),
                    ),
                  const SizedBox(height: 35),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFE8ECF4),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Or Register with',
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFF6A707C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFE8ECF4),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialButton(
                        icon: Icons.facebook,
                        color: const Color(0xFF1877F2),
                        onTap: () {},
                      ),

                      const SizedBox(width: 12),

                      _buildSocialButton(
                        icon: FontAwesomeIcons.google,
                        color: const Color.fromARGB(255, 164, 4, 4),
                        onTap: () {},
                      ),

                      const SizedBox(width: 12),

                      _buildSocialButton(
                        icon: Icons.apple,
                        color: Colors.black,
                        onTap: () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),

                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            fontSize: 15,
                            color: const Color(0xFF1E232C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Login(),
                              ),
                            );
                          },
                          child: Text(
                            'Login Now',
                            style: TextStyle(
                              fontSize: 15,
                              color: const Color(0xFF35C2C1),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    IconData? icon,
    String? imagePath,
    Color? color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 88,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE8ECF4), width: 1),
        ),
        child: Center(
          child: imagePath != null
              ? Image.asset(imagePath, width: 24, height: 24)
              : Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }

  void _handleRegister() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    // Debug print
    print('Username: ${usernameController.text}');
    print('Email: ${emailController.text}');
    print('Password: ${passwordController.text}');

    // Navigate to OTP screen
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const OTPSignup()),
      );
    }
  }
}
