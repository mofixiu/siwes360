import 'package:flutter/material.dart';
import 'package:siwes360/auth/otpforgotpassword.dart';
import 'package:siwes360/themes/theme.dart';
import 'package:siwes360/widgets/customButton.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController emailController = TextEditingController();

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
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E232C),
                    height: 1.3,
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Text(
                  "Don't worry! It occurs. Please enter the email address linked with your account.",
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF6A707C),
                    fontWeight: FontWeight.w600,
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
                                  return 'Please enter a valid CU email';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: "Enter your email",
                                hintStyle: TextStyle(
                                  color: SIWES360.darkBorderColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                errorStyle: TextStyle(fontSize: 0),
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
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),

                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: CustomButton(
                    ontap: () {
                      if (emailController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter your email'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (!emailController.text.contains('@stu.cu.edu.ng')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid CU email'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // Navigate if validation passes
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OTPForgotPassword(),
                        ),
                      );
                    },
                    data: "Send Code",
                    textcolor: Colors.white,
                    backgroundcolor: const Color(0xFF0A3D62),
                    width: MediaQuery.of(context).size.width,
                    height: 50,
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
