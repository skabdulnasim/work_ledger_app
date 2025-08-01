import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/db_models/db_my_client.dart';
import 'package:work_ledger/db_models/db_user_prefs.dart';
import 'package:work_ledger/models/my_client.dart';
import 'package:work_ledger/models/subscription_plan.dart';
import 'package:work_ledger/services/unsecure_api_service.dart';

class SubscriptionScreen extends StatefulWidget {
  Map<dynamic, dynamic> client;

  SubscriptionScreen({super.key, required this.client});

  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late Map<dynamic, dynamic> client;
  Razorpay? _razorpay;
  List<SubscriptionPlan> _plans = [];

  @override
  void initState() {
    super.initState();
    client = widget.client;
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    loadPlans();
  }

  Future<void> loadPlans() async {
    _plans = await UnsecureApiService.fetchSubscriptionPlans();
    setState(() {});
  }

  void subscribeNow(SubscriptionPlan plan) async {
    final keyId = await UnsecureApiService.fetchRazorpayKeyId();
    if (keyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch Razorpay credentials")));
      return;
    }

    final orderData = await UnsecureApiService.createSubscriptionOrder({
      "client_id": client['id'],
      "subscription_plan_id": plan.id,
      "quantity": 1,
      "discount_amount": 0,
    });

    if (orderData != null && orderData['success'] == true) {
      var options = {
        'key': keyId,
        'amount':
            (double.tryParse(orderData['subscription_order']['amount'])! * 100)
                .toInt(),
        'name': 'Work Ledger',
        'description': plan.title,
        'order_id': orderData['subscription_order']['razorpay_order_id'],
        'prefill': {
          'contact': client['mobile'],
          'email': '${client['mobile']}@workledger.com',
        },
        'notes': {
          'client_id': '1',
          'plan_id': plan.id.toString(),
          'order_id': orderData['subscription_order']['id'].toString(),
        }
      };

      print(options);

      _razorpay!.open(options);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to place order! Try after sometime.")));
      return;
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final data = response.data ?? {};
      final notes = data['notes'] ?? {};
      final planId = int.tryParse(notes['plan_id'].toString());

      final plan = _plans.firstWhere(
        (e) => e.id == planId,
        orElse: () => _plans.first,
      );

      final responseBody = await UnsecureApiService.createPayment({
        "subscription_payment": {
          "client_id": client['id'],
          "subscription_plan_id": plan.id,
          "razorpay_payment_id": response.paymentId!,
          "is_activated": true,
          "valid_till": DateTime.now()
              .add(Duration(days: plan.durationInDays))
              .toIso8601String(),
          "price": plan.price,
        }
      });

      if (responseBody != null && responseBody['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment Successful")),
        );

        // Navigator.pushNamed(context, '/license');
        checkAppFlow(DateTime.now()
            .add(Duration(days: plan.durationInDays))
            .toIso8601String());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment save failed")),
        );
      }
    } catch (e) {
      print("Error handling payment success: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong!")),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment failed")),
    );
  }

  void _handleExternalWallet(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("External wallet!")),
    );
  }

  Future<void> checkAppFlow(String validity) async {
    final subdomain = await DBUserPrefs().getPreference(SUBDOAMIN);
    final apiBaseUrl = await DBUserPrefs().getPreference(API_BASE_URL);
    await DBUserPrefs().savePreference(VALIDITY, validity);
    final token = await DBUserPrefs().getPreference(TOKEN);

    final now = DateTime.now();
    final validTill = DateTime.parse(validity);

    if (subdomain != null && apiBaseUrl != null) {
      if (validTill.isAfter(now)) {
        if (token != null) {
          // ALL DATA AVAILABLE
          Navigator.pushReplacementNamed(context, '/splash');
        } else {
          // ONLY LICENSE DATA AVAILABLE
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        Navigator.pushNamed(
          context,
          '/subscribe',
          arguments: client,
        );
      }
    } else {
      // DATA MISSING
      Navigator.pushReplacementNamed(context, '/license');
    }
  }

  @override
  void dispose() {
    _razorpay!.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Subscribtion Plans")),
      body: ListView.builder(
        itemCount: _plans.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (ctx, i) {
          final plan = _plans[i];
          return Center(
            child: subscriptionCard(
              plan.title,
              plan.price > 0 ? "₹${plan.price.toStringAsFixed(0)}" : "FREE",
              [
                {'icon': '⏳', 'text': '${plan.durationInDays} days'},
              ],
              () {
                subscribeNow(plan);
              },
            ),
          );
        },
      ),
    );
  }

  Widget subscriptionCard(String title, String price,
      List<Map<String, String>> features, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.all(12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Title and Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              RichText(
                text: TextSpan(
                  text: price,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                  children: [
                    TextSpan(
                      text: '',
                      style: TextStyle(fontSize: 12, color: Colors.black),
                    ),
                  ],
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            "For individuals & small teams",
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          SizedBox(height: 16),

          // Features
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(feature['icon']!, style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature['text']!,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),

          SizedBox(height: 20),

          // Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text("SUBSCRIBE NOW",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
