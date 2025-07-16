import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/models/company_bill_payment.dart';
import 'package:work_ledger/models/employee.dart';
import 'package:work_ledger/models/employee_attendance.dart';
import 'package:work_ledger/models/site.dart';
import 'package:work_ledger/models/site_payment_role.dart';
import 'package:work_ledger/models/skill.dart';
import 'package:work_ledger/screens/company_list_screen.dart';
import 'package:work_ledger/screens/employee_attendance_screen.dart';
import 'package:work_ledger/screens/employee_list_screen.dart';
import 'package:work_ledger/screens/site_list_screen.dart';
import 'package:work_ledger/screens/skill_list_screen.dart';
import 'package:work_ledger/screens/splash_screen.dart';
import 'package:work_ledger/services/helper.dart';
import 'models/company.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);
  Hive.registerAdapter(CompanyAdapter());
  Hive.registerAdapter(SkillAdapter());
  Hive.registerAdapter(SiteAdapter());
  Hive.registerAdapter(SitePaymentRoleAdapter());
  Hive.registerAdapter(CompanyBillPaymentAdapter());
  Hive.registerAdapter(EmployeeAdapter());
  Hive.registerAdapter(EmployeeAttendanceAdapter());

  await Hive.openBox<Company>(BOX_COMPANY);
  await Hive.openBox<Skill>(BOX_SKILL);
  await Hive.openBox<Site>(BOX_SITE);
  await Hive.openBox<CompanyBillPayment>(BOX_COMPANY_BILL_PAYMENT);
  await Hive.openBox<Employee>(BOX_EMPLOYEE);
  await Hive.openBox<EmployeeAttendance>(BOX_EMPLOYEE_ATTENDANCE);

  runApp(MyApp());
  Helper.listenForNetworkChanges();
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/company': (context) => CompanyListScreen(),
        '/sites': (context) => SiteListScreen(),
        '/employee': (context) => EmployeeListScreen(),
        '/skill': (context) => SkillListScreen(),
        '/login': (context) => LoginScreen(),
        // '/employee_attendance': (context) => EmployeeAttendanceScreen(),
      },
    );
  }
}
