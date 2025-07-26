import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:work_ledger/services/api_constant.dart';

class UnsecureApiService {
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
      };

  // ----------------------------
  // OTP REQUEST
  // ----------------------------
  static Future<bool> OTPRequest(Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('${API_PATH}auth/request_otp'),
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
      final response = await http.post(
        Uri.parse('${API_PATH}auth/verify_otp'),
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
      print('Update Company Error: $e');
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
}
