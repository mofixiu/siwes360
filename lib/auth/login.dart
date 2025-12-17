import 'package:flutter/material.dart';
import 'package:siwes360/auth/forgotPassword.dart';
import 'package:siwes360/auth/signup.dart';
import 'package:siwes360/screens/student/firstLoginSetup.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/utils/role_router.dart';
import 'package:siwes360/themes/theme.dart';
import 'package:siwes360/widgets/customButton.dart';
import 'package:siwes360/utils/custom_page_route.dart'; // Add this import

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize RequestService
    if (!RequestService.isInitialized) {
      RequestService.initialize();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await RequestService.login(
        emailController.text.trim(),
        passwordController.text,
      );

      if (!mounted) return;

      if (result != null && result['status'] == 'success') {
        // Save token
        final token = result['data']['token'];
        await RequestService.saveAuthToken(token);

        // Get user and role data from response
        final userData = Map<String, dynamic>.from(result['data']['user']);
        final roleData = result['data']['role_data'] != null
            ? Map<String, dynamic>.from(result['data']['role_data'])
            : null;

        // Merge user data with role data
        final fullUserData = <String, dynamic>{
          ...userData,
          'role_data': roleData,
        };

        // Save to local storage
        await RequestService.saveUserData(fullUserData);

        if (!mounted) return;

        // Check if student and first login
        if (userData['role'] == 'student' && roleData != null) {
          final isFirstLogin = roleData['is_first_login'];

          // Check if it's the first login (handle boolean, int, and string values)
          if (isFirstLogin == true ||
              isFirstLogin == 1 ||
              isFirstLogin == '1') {
            // Navigate to first login setup with fade transition
            await context.pushReplacementFade(
              FirstLoginSetup(userData: fullUserData),
            );
            return;
          }
        }

        // Show success message for returning users
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, ${userData['full_name']}!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate to role-based dashboard
        final role = userData['role'];
        RoleRouter.navigateToRoleBasedHome(context, role);
      } else {
        // Show error message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result?['message'] ?? 'Login failed'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(245, 245, 247, 1),

        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Image.asset(
                  "assets/images/siwes360 logo.png",
                  width: MediaQuery.of(context).size.width,
                  height: 300,
                  fit: BoxFit.cover,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                const Text(
                  "Simplifying the SIWES Experience",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: SIWES360.lightBorderColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: SIWES360.darkBorderColor,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "Log in",
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w500,
                            color: SIWES360.darkBorderColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: SIWES360.darkBorderColor,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),

                // Email Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(252, 242, 232, 1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: emailController,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                hintText: "Enter Email Address",
                                hintStyle: TextStyle(
                                  color: SIWES360.darkBorderColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                errorStyle: TextStyle(fontSize: 0),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(
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

                // Password Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(252, 242, 232, 1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: passwordController,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                hintText: "Enter Password",
                                hintStyle: const TextStyle(
                                  color: SIWES360.darkBorderColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                errorStyle: const TextStyle(fontSize: 0),
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
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              style: const TextStyle(
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
                GestureDetector(
                  onTap: () {
                    context.pushFade(const ForgotPassword());
                  },
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0A3D62),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),

                // Login Button
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: CustomButton(
                    ontap: _isLoading ? () {} : _handleLogin,
                    data: _isLoading ? "Logging in..." : "Login",
                    textcolor: Colors.white,
                    backgroundcolor: _isLoading
                        ? Colors.grey
                        : const Color(0xFF0A3D62),
                    width: MediaQuery.of(context).size.width,
                    height: 50,
                  ),
                ),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: CircularProgressIndicator(color: Color(0xFF0A3D62)),
                  ),

                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: SIWES360.darkBorderColor,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "or",
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w500,
                            color: SIWES360.darkBorderColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: SIWES360.darkBorderColor,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: CustomButton(
                    ontap: () {
                      context.pushFade(const SignUp());
                    },
                    data: "Create An Account",
                    textcolor: Colors.white,
                    backgroundcolor: const Color(0xFF0A3D62),
                    width: MediaQuery.of(context).size.width,
                    height: 50,
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                const Text(
                  "By Continuing, you agree to our",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Terms of Service",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0A3D62),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      " and ",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Privacy Policy",
                      style: TextStyle(
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.black,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
