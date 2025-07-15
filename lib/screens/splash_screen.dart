import 'package:flutter/material.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/db_models/db_user_prefs.dart';
import 'package:work_ledger/services/sync_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double progress = 0.0;
  final List<Future<void> Function()> syncSteps = [];

  @override
  void initState() {
    super.initState();
    _startInitialization();
  }

  void _startInitialization() async {
    final token = await DBUserPrefs().getPreference(TOKEN);
    if (token != null && token.toString().isNotEmpty) {
      syncSteps.addAll([
        () => SyncManager().syncCompaniesFromServer(),
        () => SyncManager().syncPendingCompanies(),
        () => SyncManager().syncSkillsFromServer(),
        () => SyncManager().syncPendingSkills(),
        () => SyncManager().syncSitesFromServer(),
        () => SyncManager().syncComBillPayFromServer(),
        () => SyncManager().syncEmployeesFromServer(),
        () => SyncManager().syncEmployeeAttendancesFromServer(),
      ]);

      await _runSyncSteps();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/sites');
    } else {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<void> _runSyncSteps() async {
    for (int i = 0; i < syncSteps.length; i++) {
      try {
        await syncSteps[i]();
      } catch (e) {
        print("Sync step $i failed: $e");
      }
      setState(() {
        progress = (i + 1) / syncSteps.length;
      });
      await Future.delayed(
          const Duration(milliseconds: 200)); // optional animation buffer
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return SweepGradient(
                          startAngle: 0.0,
                          endAngle: 3.14 * 2,
                          colors: <Color>[
                            const Color.fromARGB(255, 39, 176, 96),
                            const Color.fromARGB(255, 180, 33, 243),
                            Colors.blue,
                            const Color.fromARGB(255, 76, 175, 147),
                            const Color.fromARGB(255, 243, 33, 89),
                            const Color.fromARGB(255, 240, 243, 33),
                            const Color.fromARGB(255, 200, 100, 0),
                            Colors.green,
                          ],
                        ).createShader(bounds);
                      },
                      child: Padding(
                        padding: EdgeInsets.all(65),
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 65,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white), // This color gets masked
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    "${(progress * 100).toStringAsFixed(0)}%",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 1
                        ..color = Colors.black, // Stroke color

                      shadows: [
                        Shadow(
                          blurRadius: 4.0,
                          color: const Color.fromARGB(115, 51, 50, 50),
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "${(progress * 100).toStringAsFixed(0)}%",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
