import 'package:flutter/material.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/db_models/db_user_prefs.dart';
import 'package:work_ledger/screens/company_list_screen.dart';
import 'package:work_ledger/screens/splash_screen.dart';
import 'package:work_ledger/services/sync_manager.dart';
import 'package:work_ledger/services/unsecure_api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;

  Future<void> requestOtp() async {
    setState(() => _isLoading = true);
    bool isSent = await UnsecureApiService.OTPRequest({
      "mobile": _mobileController.text,
    });
    setState(() {
      _otpSent = isSent;
      _isLoading = false;
    });
  }

  Future<void> verifyOtp() async {
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
      print("OTP verification failed!");
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _mobileController,
              decoration: const InputDecoration(labelText: "Mobile"),
            ),
            if (_otpSent)
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(labelText: "OTP"),
              ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _otpSent ? verifyOtp : requestOtp,
                child: Text(_otpSent ? "Verify OTP" : "Request OTP"),
              ),
          ],
        ),
      ),
    );
  }
}
