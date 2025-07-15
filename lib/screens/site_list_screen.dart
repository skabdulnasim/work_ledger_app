import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/db_models/db_user_prefs.dart';
import 'package:work_ledger/models/site.dart';
import 'package:work_ledger/db_models/db_site.dart';
import 'package:work_ledger/screens/bill_payment_list_screen.dart';
import 'package:work_ledger/screens/login_screen.dart';
import 'package:work_ledger/screens/site_screen.dart';
import 'package:work_ledger/widgets/bottom_nav.dart';
import 'package:work_ledger/widgets/top_bar.dart';

class SiteListScreen extends StatelessWidget {
  const SiteListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(
        pageTitle: 'Sites',
        actions: [
          {'label': 'Company', 'value': 'company'},
          {'label': 'Logout', 'value': 'logout'},
        ],
        onSelected: (value) async {
          switch (value) {
            case 'company':
              Navigator.pushNamed(context, '/company');
              break;
            case 'logout':
              await DBUserPrefs().savePreference(TOKEN, null);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
              break;
          }
        },
      ),
      body: ValueListenableBuilder(
        valueListenable: DBSite.getListenable(),
        builder: (context, Box<Site> box, _) {
          final sites = box.values.toList();

          if (sites.isEmpty) {
            return const Center(child: Text("No sites found"));
          }

          return ListView.builder(
            itemCount: sites.length,
            itemBuilder: (context, index) {
              final site = sites[index];
              return ListTile(
                title: Text(site.name),
                subtitle: Text(site.address),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BillPaymentListScreen(site: site),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newSite = Site(
            id: "LOCAL-${DateTime.now().millisecondsSinceEpoch}",
            name: '',
            address: '',
            companyId: '', // Required, set in form
          );
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SiteScreen(site: newSite),
            ),
          );

          if (result == true) {
            (context as Element).reassemble();
          }
        },
        child: const Icon(Icons.add),
        tooltip: "Add Site",
      ),
      bottomNavigationBar: BottomNav(currentIndex: 1),
    );
  }
}
