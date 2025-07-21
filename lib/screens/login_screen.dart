import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:work_ledger/app_constants.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/db_models/db_user_prefs.dart';
import 'package:work_ledger/screens/splash_screen.dart';
import 'package:work_ledger/services/unsecure_api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController _mobileController = TextEditingController();
  TextEditingController _otpController = TextEditingController();

  bool _otpSent = false;
  bool _isLoading = false;
  int _secondsRemaining = 60;
  Timer? _timer;

  void _startCountdown() {
    _secondsRemaining = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  Future<void> requestOtp() async {
    if (_mobileController.text.length != 10) {
      _showError("Enter valid 10-digit mobile number");
      return;
    }
    setState(() => _isLoading = true);
    bool isSent = await UnsecureApiService.OTPRequest({
      "mobile": _mobileController.text,
    });
    setState(() {
      _otpSent = isSent;
      _isLoading = false;
    });
    if (isSent) _startCountdown();
  }

  Future<void> verifyOtp() async {
    if (_otpController.text.length != 6) {
      _showError("Enter valid 6-digit OTP");
      return;
    }

    setState(() => _isLoading = true);

    final json = await UnsecureApiService.OTPVerify({
      "mobile": _mobileController.text,
      "otp": _otpController.text,
    });

    if (json != null && json['success'] == true) {
      final token = json['token'];
      if (token != null) {
        await DBUserPrefs().savePreference(TOKEN, token);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SplashScreen()),
        );
      }
    } else {
      _showError("OTP verification failed!");
    }

    setState(() => _isLoading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _resetToMobileInput() {
    _otpController.clear();
    _timer?.cancel();
    setState(() {
      _otpSent = false;
      _otpController = TextEditingController();
      _secondsRemaining = 60;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Image.asset(
              APP_ICON,
              height: 120,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Login",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      if (!_otpSent)
                        Column(
                          children: [
                            TextField(
                              controller: _mobileController,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              decoration: const InputDecoration(
                                labelText: "Mobile Number",
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _isLoading
                                ? const CircularProgressIndicator()
                                : ElevatedButton.icon(
                                    onPressed: requestOtp,
                                    icon: const Icon(Icons.send),
                                    label: const Text("Request OTP"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors
                                          .blue, // Set background color to blue
                                      foregroundColor: Colors
                                          .white, // Optional: sets icon/text color
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      minimumSize: Size(150, 48),
                                    ),
                                  ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            Text(
                              "OTP sent to +91 ${_mobileController.text}",
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            PinCodeTextField(
                              appContext: context,
                              controller: _otpController,
                              length: 6,
                              autoFocus: true,
                              keyboardType: TextInputType.number,
                              animationType: AnimationType.fade,
                              pinTheme: PinTheme(
                                shape: PinCodeFieldShape.box,
                                borderRadius: BorderRadius.circular(8),
                                fieldHeight: 50,
                                fieldWidth: 40,
                                activeColor: Colors.green,
                                selectedColor: Colors.blue,
                                inactiveColor: Colors.grey,
                              ),
                              onChanged: (_) {},
                            ),
                            const SizedBox(height: 8),
                            _secondsRemaining > 0
                                ? Text(
                                    "Resend OTP in $_secondsRemaining seconds",
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  )
                                : TextButton(
                                    onPressed: requestOtp,
                                    child: const Text("Resend OTP"),
                                  ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _resetToMobileInput,
                              child: const Text("Change mobile number?"),
                            ),
                            const SizedBox(height: 10),
                            _isLoading
                                ? const CircularProgressIndicator()
                                : ElevatedButton.icon(
                                    onPressed: verifyOtp,
                                    icon: const Icon(Icons.lock),
                                    label: const Text("Verify OTP"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors
                                          .blue, // Set background color to blue
                                      foregroundColor: Colors
                                          .white, // Optional: sets icon/text color
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      minimumSize: Size(150, 48),
                                    ),
                                  ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mobileController.dispose();
    _otpController = TextEditingController();
    _otpController.dispose();
    super.dispose();
  }
}
