import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/db_models/db_user_prefs.dart';
import 'package:work_ledger/services/sync_manager.dart';

class Helper {
  static late StreamSubscription<List<ConnectivityResult>> _subscription;
  static final Connectivity _connectivity = Connectivity();

  static void listenForNetworkChanges() {
    _subscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) async {
      print("Connectivity changed: $results");

      // Check if at least one of the results is a connected type
      bool isConnected = results.any(
        (result) =>
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet,
      );

      bool isOnline = await isRealNetworkAvailable();

      if (isConnected && isOnline) {
        print("Hello Network");

        final String token = await DBUserPrefs().getPreference(TOKEN);
        if (token.isNotEmpty) {
          print("SYNCING START...");

          await SyncManager().syncCompaniesFromServer();
          await SyncManager().syncPendingCompanies();

          await SyncManager().syncSkillsFromServer();
          await SyncManager().syncPendingSkills();

          await SyncManager().syncSitesFromServer();
          await SyncManager().syncPendingSites();

          await SyncManager().syncComBillPayFromServer();
          await SyncManager().syncPendingCompanyBillPayments();

          await SyncManager().syncEmployeesFromServer();
          await SyncManager().syncPendingEmployees();

          print("SYNCING END...");
        }
      }
    }, onError: (e) => print('Connectivity error: $e'));
  }

  /// Function to execute when network becomes available.
  static Future<bool> isRealNetworkAvailable() async {
    try {
      final response = await http
          .get(Uri.parse('http://google.com'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static void dispose() {
    _subscription.cancel();
  }

  static String getCurrentDateTime() {
    return DateFormat("yyyy-MM-dd HH:mm").format(DateTime.now());
  }

  static String getFullDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  static DateTime getDateTime(String dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateTime);
  }

  static DateTime getAMPMToDateTime(String formattedDateTimeString) {
    return DateFormat('dd-MM-yyyy HH:mm a').parse(formattedDateTimeString);
  }

  static DateTime getStringToDateTime(String formattedDateTimeString) {
    return DateFormat(
      "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
    ).parse(formattedDateTimeString);
  }

  static DateTime beginningOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day, 0, 0, 0);
  }

  static DateTime endOfDay(DateTime dateTime) {
    return DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      23,
      59,
      59,
      999,
    );
  }
}
