import 'package:flutter/material.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/db_models/db_my_client.dart';
import 'package:work_ledger/db_models/db_user_prefs.dart';
import 'package:work_ledger/models/my_client.dart';
import 'package:work_ledger/services/helper.dart';
import 'package:work_ledger/services/unsecure_api_service.dart';

class LicenseVerificationScreen extends StatefulWidget {
  @override
  _LicenseVerificationScreenState createState() =>
      _LicenseVerificationScreenState();
}

class _LicenseVerificationScreenState extends State<LicenseVerificationScreen> {
  final TextEditingController _controller = TextEditingController();

  Future<void> _verifyLicense() async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Provide valid license code!")));
      return;
    }
    final json = await UnsecureApiService.verifyLicense({
      "license_code": key,
    });

    if (json != null && json['success'] == true) {
      MyClient c = MyClient(
        serverId: json['tenant']['client']['id'].toString(),
        name: json['tenant']['client']['name'],
        mobile: json['tenant']['client']['mobile'],
        subdomain: json['tenant']['subdomain'],
      );
      DBMyClient.upsert(c);
      final subdomain = json['tenant']['subdomain'];
      await DBUserPrefs().savePreference(SUBDOAMIN, subdomain);
      await DBUserPrefs().savePreference(
          BASE_URL, 'http://${subdomain}.highsales.store:4010/');
      await DBUserPrefs().savePreference(
          API_BASE_URL, 'http://${subdomain}.highsales.store:4010/api/v1/');
      List l = json['tenant']['client']['subscription_payments'];
      print('VALIDITY:   ');
      if (l.isNotEmpty) {
        final data = l.first;
        print(data['valid_till']);
        await DBUserPrefs().savePreference(VALIDITY, data['valid_till']);
      } else {
        await DBUserPrefs().savePreference(
          VALIDITY,
          Helper.getJustDate(DateTime.now().add(Duration(days: 365))),
        );
        print(Helper.getJustDate(DateTime.now().add(Duration(days: 365))));
      }
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (Route<dynamic> route) => false,
      );
    } else {
      Helper.showMessage(context, "License verification failed!", false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("License Verification")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(child: Text("")),
            Text("License Code", style: TextStyle(fontSize: 18)),
            SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                  border: OutlineInputBorder(), hintText: "e.g. X-XXXX"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6), // small border radius
                ),
              ),
              child: Text(
                "VERIFY NOW",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              onPressed: () => _verifyLicense(),
            ),
            Expanded(child: Text("")),
          ],
        ),
      ),
    );
  }
}
