import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/db_models/db_site.dart';
import 'package:work_ledger/db_models/db_user_prefs.dart';
import 'package:work_ledger/models/company.dart';
import 'package:work_ledger/models/company_bill_payment.dart';
import 'package:work_ledger/models/site.dart';
import 'package:work_ledger/models/skill.dart';
import 'package:work_ledger/services/api_constant.dart';

class SecureApiService {
  /////////////// HEADER
  static Future<Map<String, String>> getHeaders() async {
    final authToken = await DBUserPrefs().getPreference(TOKEN);

    if (authToken != null && authToken.isNotEmpty) {
      return {
        'Authorization': 'Token $authToken',
        'Content-Type': 'application/json',
      };
    } else {
      return {
        'Content-Type': 'application/json',
      };
    }
  }

  // ----------------------------
  // CREATE COMPANY
  // ----------------------------
  static Future<Map<String, dynamic>?> createCompany(Company company) async {
    try {
      String apiURL = '${API_PATH}companies';

      final response = await http.post(
        Uri.parse(apiURL),
        headers: await getHeaders(),
        body: jsonEncode(company.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print("POST failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Create Company Error: $e");
      return null;
    }
  }

  // ----------------------------
  // UPDATE COMPANY
  // ----------------------------
  static Future<Map<String, dynamic>?> updateCompany(Company company) async {
    try {
      final response = await http.put(
        Uri.parse('${API_PATH}companies/${company.serverId}'),
        headers: await getHeaders(),
        body: jsonEncode(company.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print("PUT failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print('Update Company Error: $e');
      return null;
    }
  }

  // ----------------------------
  // FETCH COMPANIES (INDEX)
  // ----------------------------
  static Future<List<Company>> fetchCompaniesFromServer() async {
    try {
      String apiURL = '${API_PATH}companies?ANY_FIXED_PARAMS=0';
      String lastSyncedAt = await DBUserPrefs().getPreference(
        COMPANY_SYNCED_AT,
      );
      if (lastSyncedAt.isNotEmpty) {
        apiURL = '$apiURL&updated_after=$lastSyncedAt';
      }
      final res =
          await http.get(Uri.parse(apiURL), headers: await getHeaders());
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        return data.map((e) => Company.fromJson(e)).toList();
      } else {
        print('Fetch Error: ${res.statusCode}');
        return [];
      }
    } catch (e) {
      print('Fetch Companies Error: $e');
      return [];
    }
  }

  // ----------------------------
  // DELETE COMPANY
  // ----------------------------
  static Future<bool> deleteCompany(int companyId) async {
    try {
      final response = await http.delete(
        Uri.parse('${API_PATH}companies/$companyId'),
        headers: await getHeaders(),
      );
      return response.statusCode == 204;
    } catch (e) {
      print('Delete Company Error: $e');
      return false;
    }
  }

  // ----------------------------
  // FETCH SINGLE COMPANY (OPTIONAL)
  // ----------------------------
  static Future<Company?> getCompanyById(int id) async {
    try {
      final res = await http.get(
        Uri.parse('${API_PATH}companies/$id'),
        headers: await getHeaders(),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return Company.fromJson(data);
      } else {
        print('Get Company Failed: ${res.statusCode}');
        return null;
      }
    } catch (e) {
      print('Get Company Error: $e');
      return null;
    }
  }

  // ----------------------------
  // CREATE SKILL
  // ----------------------------
  static Future<Map<String, dynamic>?> createSkill(Skill skill) async {
    try {
      final response = await http.post(
        Uri.parse('${API_PATH}employee_roles'),
        headers: await getHeaders(),
        body: jsonEncode(skill.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print("POST failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Create Skill Error: $e");
      return null;
    }
  }

  // ----------------------------
  // UPDATE SKILL
  // ----------------------------
  static Future<Map<String, dynamic>?> updateSkill(Skill skill) async {
    try {
      final response = await http.put(
        Uri.parse('${API_PATH}employee_roles/${skill.serverId}'),
        headers: await getHeaders(),
        body: jsonEncode(skill.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print("PUT failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print('Update Skill Error: $e');
      return null;
    }
  }

  // ----------------------------
  // FETCH SKILLS (INDEX)
  // ----------------------------
  static Future<List<Skill>> fetchSkillsFromServer() async {
    try {
      String apiURL = '${API_PATH}employee_roles?ANY_FIXED_PARAMS=0';
      String lastSyncedAt = await DBUserPrefs().getPreference(
        EMPLOYEE_ROLE_SYNCED_AT,
      );
      if (lastSyncedAt.isNotEmpty) {
        apiURL = '$apiURL&updated_after=$lastSyncedAt';
      }

      final res =
          await http.get(Uri.parse(apiURL), headers: await getHeaders());
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        return data.map((e) => Skill.fromJson(e)).toList();
      } else {
        print('Fetch Error: ${res.statusCode}');
        return [];
      }
    } catch (e) {
      print('Fetch Skills Error: $e');
      return [];
    }
  }

  // ----------------------------
  // FETCH SINGLE SKILL (OPTIONAL)
  // ----------------------------
  static Future<Skill?> getSkillById(int id) async {
    try {
      final res = await http.get(
        Uri.parse('${API_PATH}employee_roles/$id'),
        headers: await getHeaders(),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return Skill.fromJson(data);
      } else {
        print('Get Skill Failed: ${res.statusCode}');
        return null;
      }
    } catch (e) {
      print('Get Skill Error: $e');
      return null;
    }
  }

  // ----------------------------
  // FETCH SITES (INDEX)
  // ----------------------------
  static Future<List<Map<String, dynamic>>> fetchSitesFromServer() async {
    try {
      String apiURL = '${API_PATH}sites?ANY_FIXED_PARAMS=0';
      String lastSyncedAt = await DBUserPrefs().getPreference(
        SITE_SYNCED_AT,
      );
      if (lastSyncedAt.isNotEmpty) {
        apiURL = '$apiURL&updated_after=$lastSyncedAt';
      }

      final res =
          await http.get(Uri.parse(apiURL), headers: await getHeaders());
      if (res.statusCode == 200) {
        final jaonRes = json.decode(res.body);
        final List data = jaonRes['sites'];
        List<Map<String, dynamic>> sSites = [];
        for (var e in data) {
          sSites.add(e);
        }
        return sSites;
      } else {
        print('Fetch Error: ${res.statusCode}');
        return [];
      }
    } catch (e) {
      print('Fetch Sites Error: $e');
      return [];
    }
  }

  // ----------------------------
  // CREATE COMPANY
  // ----------------------------
  static Future<Map<String, dynamic>?> createSite(
      Map<String, dynamic> payload) async {
    try {
      String apiURL = '${API_PATH}sites';

      final response = await http.post(
        Uri.parse(apiURL),
        headers: await getHeaders(),
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print("POST failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Create site Error: $e");
      return null;
    }
  }

  // ----------------------------
  // UPDATE COMPANY
  // ----------------------------
  static Future<Map<String, dynamic>?> updateSite(
      Map<String, dynamic> payload, String serverId) async {
    try {
      final response = await http.put(
        Uri.parse('${API_PATH}sites/$serverId'),
        headers: await getHeaders(),
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print("PUT failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print('Update site Error: $e');
      return null;
    }
  }

  /// COMPANY BILL PAYMENT ////
  static Future<Map<String, dynamic>?> createCompanyBillPayment(
      CompanyBillPayment payment) async {
    try {
      Site? site = DBSite.find(payment.siteId);
      if (site != null) {
        final uri = Uri.parse('${API_PATH}company_bill_payments');

        final request = http.MultipartRequest('POST', uri);
        request.headers.addAll(await getHeaders());

        // Add nested fields
        request.fields['company_bill_payment[transaction_at]'] =
            payment.transactionAt.toIso8601String();
        request.fields['company_bill_payment[bill_no]'] = payment.billNo;
        request.fields['company_bill_payment[amount]'] =
            payment.amount.toString();
        request.fields['company_bill_payment[payment_mode]'] =
            payment.paymentMode;
        request.fields['company_bill_payment[transaction_type]'] =
            payment.transactionType;
        request.fields['company_bill_payment[site_id]'] = site.serverId!;

        // Attach files
        for (final filePath in payment.attachmentPaths) {
          final file = File(filePath);
          if (await file.exists()) {
            request.files.add(await http.MultipartFile.fromPath(
              'attachments[]',
              filePath,
            ));
          }
        }

        final response = await request.send();
        final body = await response.stream.bytesToString();

        if (response.statusCode == 200 || response.statusCode == 201) {
          return json.decode(body);
        } else {
          print('CompanyBillPayment POST failed: $body');
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      print("Create CompanyBillPayment Error: $e");
      return null;
    }
  }

  // ----------------------------
  // FETCH COMPANY BILL PAYMENTS (INDEX)
  // ----------------------------
  static Future<List<Map<String, dynamic>>>
      fetchCompanyBillPaymentsFromServer() async {
    try {
      String apiURL = '${API_PATH}company_bill_payments?ANY_FIXED_PARAMS=0';
      String lastSyncedAt = await DBUserPrefs().getPreference(
        COMPANY_BILL_PAY_SYNCED_AT,
      );
      if (lastSyncedAt.isNotEmpty) {
        apiURL = '$apiURL&updated_after=$lastSyncedAt';
      }

      final res =
          await http.get(Uri.parse(apiURL), headers: await getHeaders());
      if (res.statusCode == 200) {
        final jaonRes = json.decode(res.body);
        final List data = jaonRes;
        List<Map<String, dynamic>> sComBillPay = [];
        for (var e in data) {
          sComBillPay.add(e);
        }
        return sComBillPay;
      } else {
        print('Fetch Error: ${res.statusCode}');
        return [];
      }
    } catch (e) {
      print('Fetch Company Bill Payment Error: $e');
      return [];
    }
  }

  // ----------------------------
  // FETCH EMPLOYEES (INDEX)
  // ----------------------------
  static Future<List<Map<String, dynamic>>> fetchEmployeeFromServer() async {
    try {
      String apiURL = '${API_PATH}employees?ANY_FIXED_PARAMS=0';
      String lastSyncedAt = await DBUserPrefs().getPreference(
        EMPLOYEE_SYNCED_AT,
      );
      if (lastSyncedAt.isNotEmpty) {
        apiURL = '$apiURL&updated_after=$lastSyncedAt';
      }

      final res =
          await http.get(Uri.parse(apiURL), headers: await getHeaders());
      if (res.statusCode == 200) {
        final jaonRes = json.decode(res.body);
        final List data = jaonRes;
        List<Map<String, dynamic>> sEmployees = [];
        for (var e in data) {
          sEmployees.add(e);
        }
        return sEmployees;
      } else {
        print('Fetch Error: ${res.statusCode}');
        return [];
      }
    } catch (e) {
      print('Fetch Sites Error: $e');
      return [];
    }
  }

  // ----------------------------
  // CREATE EMPLOYEE
  // ----------------------------
  static Future<Map<String, dynamic>?> createEmployee(
      Map<String, dynamic> payload) async {
    try {
      String apiURL = '${API_PATH}employees';

      final response = await http.post(
        Uri.parse(apiURL),
        headers: await getHeaders(),
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print("POST failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Create employee Error: $e");
      return null;
    }
  }

  // ----------------------------
  // UPDATE EMPLOYEE
  // ----------------------------
  static Future<Map<String, dynamic>?> updateEmployee(
      Map<String, dynamic> payload, String serverId) async {
    try {
      final response = await http.put(
        Uri.parse('${API_PATH}employees/$serverId'),
        headers: await getHeaders(),
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print("PUT failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print('Update employee Error: $e');
      return null;
    }
  }

  // ----------------------------
  // FETCH EMPLOYEE ATTENDANCE (INDEX)
  // ----------------------------
  static Future<List<Map<String, dynamic>>>
      fetchEmployeeAttendanceFromServer() async {
    try {
      String apiURL = '${API_PATH}employee_attendances?ANY_FIXED_PARAMS=0';
      String lastSyncedAt = await DBUserPrefs().getPreference(
        EMPLOYEE_ATTENDANCE_SYNCED_AT,
      );
      if (lastSyncedAt.isNotEmpty) {
        apiURL = '$apiURL&updated_after=$lastSyncedAt';
      }

      final res =
          await http.get(Uri.parse(apiURL), headers: await getHeaders());
      if (res.statusCode == 200) {
        final jaonRes = json.decode(res.body);
        final List data = jaonRes;
        List<Map<String, dynamic>> sAttendances = [];
        for (var e in data) {
          sAttendances.add(e);
        }
        return sAttendances;
      } else {
        print('Fetch Error: ${res.statusCode}');
        return [];
      }
    } catch (e) {
      print('Fetch Attendances Error: $e');
      return [];
    }
  }

  // ----------------------------
  // CREATE EMPLOYEE ATTENDANCE
  // ----------------------------
  static Future<Map<String, dynamic>?> createEmployeeAttendance(
      Map<String, dynamic> payload) async {
    try {
      String apiURL = '${API_PATH}employee_attendances';

      final response = await http.post(
        Uri.parse(apiURL),
        headers: await getHeaders(),
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print("POST failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Create employee attendance Error: $e");
      return null;
    }
  }

  // ----------------------------
  // UPDATE EMPLOYEE ATTENDANCE
  // ----------------------------
  static Future<Map<String, dynamic>?> updateEmployeeAttendance(
      Map<String, dynamic> payload, String serverId) async {
    try {
      final response = await http.put(
        Uri.parse('${API_PATH}employee_attendances/$serverId'),
        headers: await getHeaders(),
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print("PUT failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print('Update employee attendance Error: $e');
      return null;
    }
  }

  // ----------------------------
  // LIST EMPLOYEE SALARY GENERATEs (INDEX)
  // ----------------------------
  static Future<List<Map<String, dynamic>>>
      fetchEmployeeSalaryGenerateFromServer() async {
    try {
      String apiURL = '${API_PATH}employee_salary_generates?ANY_FIXED_PARAMS=0';
      String lastSyncedAt = await DBUserPrefs().getPreference(
        EMPLOYEE_SALARY_GRNERATE_SYNCED_AT,
      );
      if (lastSyncedAt.isNotEmpty) {
        apiURL = '$apiURL&updated_after=$lastSyncedAt';
      }
      final res =
          await http.get(Uri.parse(apiURL), headers: await getHeaders());
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print("Failed to fetch salary generates");
        return [];
      }
    } catch (e) {
      print("Fetch error: $e");
      return [];
    }
  }

  // ----------------------------
  // CREATE EMPLOYEE SALARY GENERATE
  // ----------------------------
  static Future<Map<String, dynamic>?> createEmployeeSalaryGenerate(
      Map<String, dynamic> payload) async {
    try {
      final url = '${API_PATH}employee_salary_generates/generate';
      final res = await http.post(Uri.parse(url),
          headers: await getHeaders(), body: jsonEncode(payload));
      if (res.statusCode == 200 || res.statusCode == 201) {
        return json.decode(res.body);
      } else {
        print("Create failed: ${res.body}");
        return null;
      }
    } catch (e) {
      print("Create error: $e");
      return null;
    }
  }
}
