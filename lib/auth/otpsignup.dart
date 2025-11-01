import 'package:flutter/material.dart';
import 'package:siwes360/screens/student/studentDashboard.dart';
import 'package:siwes360/themes/theme.dart';

class OTPSignup extends StatefulWidget {
  const OTPSignup({super.key});

  @override
  State<OTPSignup> createState() => _OTPSignupState();
}

class _OTPSignupState extends State<OTPSignup> {
  List<TextEditingController> controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var focusNode in focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verify Email',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: SIWES360.darkCardBackground,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),

              Text(
                "A verification code has been sent to your email",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 50,
                    height: 60,
                    child: TextField(
                      controller: controllers[index],
                      focusNode: focusNodes[index],
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      decoration: InputDecoration(
                        counterText: "",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: SIWES360.lightButtonBackground,
                            width: 2,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              Text(
                "Resend OTP in 30 secs",
                style: TextStyle(
                  color: SIWES360.lightBorderColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    String otp = controllers.map((c) => c.text).join();
                    if (otp.length == 6) {
                      print("OTP entered: $otp");
                      // Navigate to next screen or verify OTP
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("OTP Verified Successfully!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Please enter complete 6-digit OTP"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StudentDashboard(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SIWES360.lightButtonBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Verify OTP",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
