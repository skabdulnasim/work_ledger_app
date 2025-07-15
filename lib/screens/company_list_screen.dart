import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:work_ledger/db_models/db_company.dart';
import 'package:work_ledger/screens/company_screen.dart';
import 'package:work_ledger/widgets/bottom_nav.dart';
import 'package:work_ledger/models/company.dart';

class CompanyListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Company")),
      body: ValueListenableBuilder(
        valueListenable: DBCompany.getListenable(),
        builder: (context, Box<Company> box, _) {
          final companies = box.values.toList();

          if (companies.isEmpty) {
            return Center(child: Text("No companies found"));
          }

          return ListView.builder(
            itemCount: companies.length,
            itemBuilder: (context, index) {
              final company = companies[index];
              return ListTile(
                title: Text("${company.name.toString()}"),
                subtitle: Text(company.mobileNo),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CompanyScreen(company: company),
                    ),
                  );
                },
              );
            },
          );
        },
      ),

      /// ✅ FAB to Add New Company
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Create a blank company object (with a UUID)
          final newCompany = Company(
            id: "LOCAL-${DateTime.now().millisecondsSinceEpoch.toString()}", // or UUID
            name: '',
            mobileNo: '',
            address: '',
            gstin: '',
          );

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CompanyScreen(company: newCompany),
            ),
          );

          if (result == true) {
            (context as Element).reassemble(); // Refresh after adding
          }
        },
        child: Icon(Icons.add),
        tooltip: "Add Company",
      ),
    );
  }
}
