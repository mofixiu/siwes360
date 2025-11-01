import 'package:flutter/material.dart';
import 'package:siwes360/auth/signup.dart';
import 'package:siwes360/themes/theme.dart';
import 'package:siwes360/widgets/customButton.dart';

class CreateNewPassword extends StatefulWidget {
  const CreateNewPassword({super.key});

  @override
  State<CreateNewPassword> createState() => _CreateNewPasswordState();
}

class _CreateNewPasswordState extends State<CreateNewPassword> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                  'Change Password?',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E232C),
                    height: 1.3,
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).size.height * 0.03),

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
                                hintText: "Enter Password",
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
                                      _isPasswordVisible = !_isPasswordVisible;
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
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
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
                 CustomButton(
                  ontap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignUp()),
                    );
                  },
                  data: "Confirm",
                  textcolor: Colors.white,
                  backgroundcolor: Color(0xFF0A3D62),
                  width: MediaQuery.of(context).size.width,
                  height: 50,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
