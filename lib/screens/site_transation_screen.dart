// import 'package:flutter/material.dart';
// import 'package:work_ledger/models/site.dart';
// import 'package:work_ledger/models/company_bill_payment.dart';
// import 'package:work_ledger/services/api_service.dart';
// import 'package:work_ledger/widgets/payment_message_bubble.dart';

// class SiteTransationScreen extends StatelessWidget {
//   final Site site;

//   SiteTransationScreen({required this.site});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(site.name),
//         actions: [
//           PopupMenuButton(
//             itemBuilder: (_) => [PopupMenuItem(child: Text('Option 1'))],
//           ),
//         ],
//       ),
//       body: FutureBuilder<List<CompanyBillPayment>>(
//         future: ApiService.fetchPayments(site.id),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData)
//             return Center(child: CircularProgressIndicator());
//           final payments = snapshot.data!;
//           return ListView.builder(
//             reverse: true,
//             itemCount: payments.length,
//             itemBuilder: (context, index) =>
//                 PaymentMessageBubble(payment: payments[index]),
//           );
//         },
//       ),
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: ElevatedButton.icon(
//           icon: Icon(Icons.add),
//           label: Text("Add Payment"),
//           onPressed: () {
//             // Add Payment Screen or Dialog
//           },
//         ),
//       ),
//     );
//   }
// }
