import 'package:flutter/material.dart';
import 'package:work_ledger/services/helper.dart';
import 'package:work_ledger/services/unsecure_api_service.dart';

class ClientRegisterScreen extends StatefulWidget {
  @override
  _ClientRegisterScreenState createState() => _ClientRegisterScreenState();
}

class _ClientRegisterScreenState extends State<ClientRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '', mobile = '', address = '', subdomain = '';

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final responseBody = await UnsecureApiService.saveClient({
        "client": {
          "name": name,
          "mobile": mobile,
          "address": address,
          "subdomain": subdomain,
        }
      });

      if (responseBody != null && responseBody['success'] == true) {
        final client = responseBody['client'];
        if (client != null) {
          if (!mounted) return;
          Navigator.pushNamed(
            context,
            '/subscribe',
            arguments: client,
          );
        }
      } else {
        Helper.showMessage(
            context, "Registration failed! Try after sometime!", false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Organization Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Organization name"),
                onSaved: (val) => name = val ?? '',
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              SizedBox(
                height: 20,
              ),
              TextFormField(
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Valid WhatsApp Number"),
                onSaved: (val) => mobile = val ?? '',
                validator: (val) =>
                    val!.length != 10 ? "Enter valid 10-digit number" : null,
              ),
              SizedBox(
                height: 20,
              ),
              TextFormField(
                decoration: InputDecoration(
                    border: OutlineInputBorder(), labelText: "Address"),
                onSaved: (val) => address = val ?? '',
              ),
              SizedBox(
                height: 20,
              ),
              TextFormField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Subdomain",
                  errorMaxLines: 3, // Allow multi-line error
                ),
                onSaved: (val) => subdomain = val ?? '',
                validator: (val) {
                  final regex = RegExp(
                      r'^[a-z]{5,12}$'); // only lowercase letters, 5–12 chars

                  if (val == null || val.isEmpty) {
                    return "Subdomain is required.";
                  } else if (!regex.hasMatch(val)) {
                    return "Use only lowercase letters (5–15 characters).\nE.g., preetilata, In case of Organization: Preeti Lata Textile.";
                  }

                  return null; // valid
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(6), // small border radius
                  ),
                ),
                onPressed: _submit,
                child: Text(
                  "Register Now",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/license'),
                child: Text("I have already subscribed!"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
