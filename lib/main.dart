import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/models/attach_file.dart';
import 'package:work_ledger/models/company_bill_payment.dart';
import 'package:work_ledger/models/employee.dart';
import 'package:work_ledger/models/employee_attendance.dart';
import 'package:work_ledger/models/employee_hold_transaction.dart';
import 'package:work_ledger/models/employee_salary_generate.dart';
import 'package:work_ledger/models/employee_wallet_transaction.dart';
import 'package:work_ledger/models/expense.dart';
import 'package:work_ledger/models/hold_amount.dart';
import 'package:work_ledger/models/my_client.dart';
import 'package:work_ledger/models/site.dart';
import 'package:work_ledger/models/site_payment_role.dart';
import 'package:work_ledger/models/skill.dart';
import 'package:work_ledger/screens/bill_payment_list_screen.dart';
import 'package:work_ledger/screens/client_register_screen.dart';
import 'package:work_ledger/screens/company_list_screen.dart';
import 'package:work_ledger/screens/company_screen.dart';
import 'package:work_ledger/screens/attendance_screen.dart';
import 'package:work_ledger/screens/employee_list_screen.dart';
import 'package:work_ledger/screens/employee_salary_generate_list_screen.dart';
import 'package:work_ledger/screens/employee_screen.dart';
import 'package:work_ledger/screens/expense_trans_screen.dart';
import 'package:work_ledger/screens/intro_screen.dart';
import 'package:work_ledger/screens/license_verification_screen.dart';
import 'package:work_ledger/screens/site_list_screen.dart';
import 'package:work_ledger/screens/site_screen.dart';
import 'package:work_ledger/screens/skill_list_screen.dart';
import 'package:work_ledger/screens/skill_screen.dart';
import 'package:work_ledger/screens/splash_screen.dart';
import 'package:work_ledger/screens/subscription_screen.dart';
import 'package:work_ledger/services/helper.dart';
import 'models/company.dart';
import 'screens/login_screen.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  HttpOverrides.global = MyHttpOverrides();

  WidgetsFlutterBinding.ensureInitialized();

  await setupHiveDirectory();
  Hive.registerAdapter(CompanyAdapter());
  Hive.registerAdapter(SkillAdapter());
  Hive.registerAdapter(SiteAdapter());
  Hive.registerAdapter(SitePaymentRoleAdapter());
  Hive.registerAdapter(CompanyBillPaymentAdapter());
  Hive.registerAdapter(EmployeeAdapter());
  Hive.registerAdapter(EmployeeAttendanceAdapter());
  Hive.registerAdapter(EmployeeSalaryGenerateAdapter());
  Hive.registerAdapter(EmployeeWalletTransactionAdapter());
  Hive.registerAdapter(AttachFileAdapter());
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(HoldAmountAdapter());
  Hive.registerAdapter(EmployeeHoldTransactionAdapter());
  Hive.registerAdapter(MyClientAdapter());

  await Hive.openBox<Company>(BOX_COMPANY);
  await Hive.openBox<Skill>(BOX_SKILL);
  await Hive.openBox<Site>(BOX_SITE);
  await Hive.openBox<CompanyBillPayment>(BOX_COMPANY_BILL_PAYMENT);
  await Hive.openBox<Employee>(BOX_EMPLOYEE);
  await Hive.openBox<EmployeeAttendance>(BOX_EMPLOYEE_ATTENDANCE);
  await Hive.openBox<EmployeeSalaryGenerate>(BOX_EMPLOYEE_SALARY_GENERATE);
  await Hive.openBox<EmployeeWalletTransaction>(
      BOX_EMPLOYEE_WALLET_TRANSACTION);
  await Hive.openBox<AttachFile>(BOX_ATTACH_FILE);
  await Hive.openBox<Expense>(BOX_EXPENSE);
  await Hive.openBox<HoldAmount>(BOX_HOLD_AMOUNT);
  await Hive.openBox<EmployeeHoldTransaction>(BOX_EMPLOYEE_HOLD_TRANSACTION);
  await Hive.openBox<MyClient>(BOX_CLIENT);

  runApp(MyApp());
  Helper.listenForNetworkChanges();
}

Future<void> setupHiveDirectory() async {
  Directory appDir;

  if (Platform.isWindows) {
    // Custom directory for Windows
    appDir =
        Directory('${Platform.environment['LOCALAPPDATA']}\\work_ledger\\db');
    if (!appDir.existsSync()) {
      appDir.createSync(recursive: true);
    }
  } else if (Platform.isAndroid) {
    // App-specific directory for Android
    appDir = await getApplicationDocumentsDirectory();
  } else {
    throw UnsupportedError('Unsupported platform');
  }

  // Initialize Hive with the determined directory
  Hive.init(appDir.path);
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/intro',
      routes: {
        '/intro': (context) => IntroScreen(),
        '/register': (context) => ClientRegisterScreen(),
        '/license': (context) => LicenseVerificationScreen(),
        '/splash': (context) => const SplashScreen(),
        '/companies': (context) => CompanyListScreen(),
        '/sites': (context) => SiteListScreen(),
        '/employees': (context) => EmployeeListScreen(),
        '/skills': (context) => SkillListScreen(),
        '/login': (context) => LoginScreen(),
        '/salaries': (context) => EmployeeSalaryGenerateListScreen(),
      },
      onGenerateRoute: (routePath) {
        if (routePath.name == '/bill_payments') {
          final site = routePath.arguments as Site;
          return MaterialPageRoute(
            builder: (context) => BillPaymentListScreen(site: site),
          );
        }
        if (routePath.name == '/site') {
          final site = routePath.arguments as Site;
          return MaterialPageRoute(
            builder: (context) => SiteScreen(site: site),
          );
        }
        if (routePath.name == '/company') {
          final company = routePath.arguments as Company;
          return MaterialPageRoute(
            builder: (context) => CompanyScreen(company: company),
          );
        }
        if (routePath.name == '/skill') {
          final skill = routePath.arguments as Skill;
          return MaterialPageRoute(
            builder: (context) => SkillScreen(skill: skill),
          );
        }
        if (routePath.name == '/employee') {
          final employee = routePath.arguments as Employee;
          return MaterialPageRoute(
            builder: (context) => EmployeeScreen(employee: employee),
          );
        }
        if (routePath.name == '/attendance') {
          final site = routePath.arguments as Site;
          return MaterialPageRoute(
            builder: (context) => AttendanceScreen(site: site),
          );
        }
        if (routePath.name == '/expense_trans') {
          final employee = routePath.arguments as Employee;
          return MaterialPageRoute(
            builder: (context) => ExpenseTransScreen(employee: employee),
          );
        }
        if (routePath.name == '/subscribe') {
          final client = routePath.arguments as Map;
          return MaterialPageRoute(
            builder: (context) => SubscriptionScreen(client: client),
          );
        }
        return null;
      },
    );
  }
}
