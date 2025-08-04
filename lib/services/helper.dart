import 'dart:async';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
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

        final String? token = await DBUserPrefs().getPreference(TOKEN);
        print(token != null);
        print(token!.isNotEmpty);
        print(token);
        if (token != null && token.isNotEmpty) {
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

          await SyncManager().syncEmployeeAttendancesFromServer();
          await SyncManager().syncPendingEmployeeAttendances();

          await SyncManager().syncEmployeeSalaryGeneratesFromServer();
          await SyncManager().syncPendingEmployeeSalaryGenerates();

          await SyncManager().syncHoldAmountFromServer();
          await SyncManager().syncPendingHoldAmounts();

          await SyncManager().syncExpensesFromServer();
          await SyncManager().syncPendingExpenses();

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

  static DateTime beginningOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day, 0, 0, 0);
  }

  static DateTime endOfDay(DateTime dateTime) {
    return DateTime(
        dateTime.year, dateTime.month, dateTime.day, 23, 59, 59, 999);
  }

  static String getCurrentDateTime() {
    return DateFormat("yyyy-MM-dd HH:mm").format(DateTime.now());
  }

  static String getFullDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  static String getAMPMDateTime(DateTime dateTime) {
    return DateFormat('dd-MM-yyyy hh:mm:ss a').format(dateTime);
  }

  static String getJustDate(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  static String getJustTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  static String getTextDate(DateTime dateTime) {
    return DateFormat('d MMMM, yyyy').format(dateTime);
  }

  static DateTime setDateTime(String dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateTime);
  }

  static DateTime setAMPMToDateTime(String formattedDateTimeString) {
    return DateFormat('dd-MM-yyyy HH:mm a').parse(formattedDateTimeString);
  }

  static DateTime setStringToDateTime(String formattedDateTimeString) {
    return DateFormat(
      "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
    ).parse(formattedDateTimeString);
  }

  static String getAvatarText(String str) {
    // Split the string by spaces to separate words
    List<String> words = str.trim().split(' ');

    if (words.length >= 2) {
      // If there are two or more words, get the first letter of each and capitalize
      return words[0][0].toUpperCase() + words[1][0].toUpperCase();
    } else if (words.isNotEmpty) {
      // If there's only one word, get the first two letters and capitalize them
      return str.substring(0, 2).toUpperCase();
    }

    return '';
  }

  // Generate avatar text color (darker)
  static Color getAvatarColor() {
    String timestamp =
        DateFormat('yyyy-MM-dd HH:mm:ss.SSSSSS').format(DateTime.now());
    final int hash = _hashCode(timestamp);
    final hue = hash % 360;
    return HSVColor.fromAHSV(1.0, hue.toDouble(), 0.7, 0.8).toColor();
  }

  // Generate avatar background fill color (lighter)
  static Color getAvatarFillColor() {
    String timestamp =
        DateFormat('yyyy-MM-dd HH:mm:ss.SSSSSS').format(DateTime.now());
    final int hash = _hashCode(timestamp + "_fill");
    final hue = hash % 360;
    return HSVColor.fromAHSV(1.0, hue.toDouble(), 0.3, 0.95).toColor();
  }

  // Simple hash function from string
  static int _hashCode(String input) {
    return input.codeUnits.fold(0, (prev, e) => prev + e * 37) & 0xFFFFFF;
  }

  static void showMessage(
      BuildContext context, String message, bool isSuccess) {
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 40, // Adjust this value to position it below the screen top
        right: 20, // Adjust this value to position it from the right edge
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSuccess
                    ? [Colors.green, const Color.fromARGB(255, 113, 242, 117)]
                    : [Colors.red, const Color.fromARGB(255, 231, 105, 96)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.warning,
                  color: Colors.white,
                ),
                SizedBox(width: 8.0),
                Text(
                  message,
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    // Remove the overlay after a delay
    Future.delayed(Duration(seconds: 3)).then((_) => overlayEntry.remove());
  }
}
