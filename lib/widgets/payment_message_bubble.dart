// import 'package:flutter/material.dart';
// import 'package:work_ledger/models/company_bill_payment.dart';

// class PaymentMessageBubble extends StatelessWidget {
//   final CompanyBillPayment payment;

//   const PaymentMessageBubble({required this.payment});

//   @override
//   Widget build(BuildContext context) {
//     final isSelf = payment.transactionType == 'bill';
//     final alignment =
//         isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start;
//     final bubbleColor = isSelf ? Colors.green[100] : Colors.grey[300];

//     return Container(
//       margin: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
//       child: Column(
//         crossAxisAlignment: alignment,
//         children: [
//           Container(
//             padding: EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: bubbleColor,
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Column(
//               crossAxisAlignment: alignment,
//               children: [
//                 Text(
//                   "${payment.amount} ₹",
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 Text(payment.remarks ?? ""),
//                 if (payment.pictureUrl != null)
//                   Image.network(payment.pictureUrl!, width: 100),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
