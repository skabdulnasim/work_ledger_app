import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/db_models/db_user_prefs.dart';
import 'package:work_ledger/models/site.dart';
import 'package:work_ledger/db_models/db_site.dart';
import 'package:work_ledger/screens/login_screen.dart';
import 'package:work_ledger/services/helper.dart';
import 'package:work_ledger/widgets/bottom_nav.dart';
import 'package:work_ledger/widgets/top_bar.dart';

class SiteListScreen extends StatelessWidget {
  const SiteListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(
        pageTitle: 'Sites',
        fixedAction: [],
        menuActions: [
          {'label': 'Company', 'value': 'company'},
          {'label': 'Logout', 'value': 'logout'},
        ],
        onSelected: (value) async {
          switch (value) {
            case 'company':
              Navigator.pushNamed(context, '/companies');
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
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          Helper.getAvatarFillColor(), // Customize color
                      child: Text(
                        Helper.getAvatarText(
                            site.name), // Replace with dynamic initials
                        style: TextStyle(
                          color: Helper.getAvatarColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            site.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(site.address)
                        ],
                      ),
                    ),
                  ],
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  '/bill_payments',
                  arguments: site, // Pass the site object here
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
          final result = Navigator.pushNamed(
            context,
            '/site',
            arguments: newSite,
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
