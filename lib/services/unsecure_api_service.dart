import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/db_models/db_user_prefs.dart';
import 'package:work_ledger/models/subscription_plan.dart';
import 'package:work_ledger/services/api_constant.dart';

class UnsecureApiService {
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
      };

  static Future<String> api_base_url() async {
    String _apiBaseUrl = await DBUserPrefs().getPreference(API_BASE_URL);
    return _apiBaseUrl;
  }

  // ----------------------------
  // OTP REQUEST
  // ----------------------------
  static Future<bool> OTPRequest(Map<String, dynamic> body) async {
    try {
      final apiBaseUrl = await api_base_url();
      print(apiBaseUrl);
      final response = await http.post(
        Uri.parse('${apiBaseUrl}auth/request_otp'),
        headers: headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("POST failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Request OTP Error: $e");
      return false;
    }
  }

  // ----------------------------
  // OTP VERIFICATION
  // ----------------------------
  static Future<Map<String, dynamic>?> OTPVerify(
    Map<String, dynamic> body,
  ) async {
    try {
      final apiBaseUrl = await api_base_url();
      final response = await http.post(
        Uri.parse('${apiBaseUrl}auth/verify_otp'),
        headers: headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print("POST failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print('Verify OTP Error: $e');
      return null;
    }
  }

  Future<String> downloadFile(String url, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    final response = await http.get(Uri.parse(url));
    await file.writeAsBytes(response.bodyBytes);
    return file.path;
  }

  static Future<Map<String, dynamic>?> saveClient(
      Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('${API_PATH}clients'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print(response.body);
      final data = jsonDecode(response.body);
      return data;
    } else {
      print("Error: ${response.body}");
      return null;
    }
  }

  // FETCH SUBSCRIPTION PLANS
  static Future<List<SubscriptionPlan>> fetchSubscriptionPlans() async {
    try {
      final res = await http.get(Uri.parse('${API_PATH}subscription_plans'));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => SubscriptionPlan.fromJson(e)).toList();
      } else {
        print('Failed to load plans: ${res.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching plans: $e');
      return [];
    }
  }

  // FETCH RAZORPAY KEY ID
  static Future<String?> fetchRazorpayKeyId() async {
    try {
      final res = await http.get(Uri.parse('${API_PATH}razorpay_settings'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['razorpay_key_id'];
      } else {
        print('Failed to fetch key: ${res.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching Razorpay key: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> verifyLicense(
      Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('${API_PATH}tenants/verify'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print(response.body);
      final data = jsonDecode(response.body);
      return data;
    } else {
      print("Error: ${response.body}");
      return null;
    }
  }

  // CONFIRM PAYMENT
  static Future<Map<String, dynamic>?> createPayment(
      Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('${API_PATH}subscription_payments'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print(response.body);
      final data = jsonDecode(response.body);
      return data;
    } else {
      print("Error: ${response.body}");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> createSubscriptionOrder(
      Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('${API_PATH}subscription_orders'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print(response.body);
        final data = jsonDecode(response.body);
        return data;
      } else {
        print("Error: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error creating subscription order: $e");
      return null;
    }
  }
}
