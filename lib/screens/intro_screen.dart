import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/db_models/db_my_client.dart';
import 'package:work_ledger/db_models/db_user_prefs.dart';

class IntroScreen extends StatefulWidget {
  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final List<String> images = [
    'assets/images/slide1.png',
    'assets/images/slide2.png',
    'assets/images/slide3.png',
    'assets/images/slide4.png',
    'assets/images/slide5.png',
    'assets/images/slide6.png',
    'assets/images/slide7.png',
    'assets/images/slide8.png',
    'assets/images/slide9.png',
  ];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // checkAppFlow(); // DIRECT
  }

  Future<void> checkAppFlow() async {
    /// ON BELLOW LINE TEST PERPOUS ONLY
    // await DBUserPrefs().savePreference(VALIDITY, '2025-07-30 13:00');

    final myClient = DBMyClient.getMyClient();
    final subdomain = await DBUserPrefs().getPreference(SUBDOAMIN);
    final apiBaseUrl = await DBUserPrefs().getPreference(API_BASE_URL);
    final validity = await DBUserPrefs().getPreference(VALIDITY);
    final token = await DBUserPrefs().getPreference(TOKEN);

    final now = DateTime.now();
    print('VALIDITY: ${validity}');
    final validTill = (validity != '') ? DateTime.parse(validity) : null;

    if (subdomain != null &&
        apiBaseUrl != null &&
        validTill != null &&
        myClient != null) {
      if (validTill.isAfter(now)) {
        if (token != null) {
          // ALL DATA AVAILABLE
          Navigator.pushReplacementNamed(context, '/splash');
        } else {
          // ONLY LICENSE DATA AVAILABLE
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        final client = {
          'id': myClient.serverId,
          'name': myClient.name,
          'mobile': myClient.mobile,
          'address': myClient.address,
          'subdomain': myClient.subdomain,
        };

        if (!mounted) return;
        Navigator.pushNamed(
          context,
          '/subscribe',
          arguments: client,
        );
      }
    } else {
      // DATA MISSING
      Navigator.pushNamed(context, '/register');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: Text("")),
            SizedBox(
              height: screenHeight * 0.53,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Slider
                  CarouselSlider(
                    options: CarouselOptions(
                      autoPlay: true,
                      viewportFraction: 1.0,
                      height: double.infinity,
                      onPageChanged: (index, reason) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                    ),
                    items: images.map((imagePath) {
                      return Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 40, vertical: 22),
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                          width: double.infinity,
                        ),
                      );
                    }).toList(),
                  ),

                  // Transparent Mobile Frame
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/mobile_frame.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    ),
                  ),
                ],
              ),
            ),

            // Slider Indicator Outside the Frame
            SizedBox(height: 10), // spacing between frame and dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (index) {
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 6),
                  width: _currentIndex == index ? 10 : 8,
                  height: _currentIndex == index ? 10 : 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index ? Colors.black : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
            SizedBox(height: 10),
            Text(
              "Welcome to Work Ledger",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Effortlessly manage employees, attendance, salary, expenses, and payments — all in one place.\n\nStay organized, track site activities, and maintain ledgers with ease.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6), // small border radius
                ),
              ),
              child: Text(
                "Let’s get to work!",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              onPressed: () => checkAppFlow(),
            ),
            Expanded(child: Text("")),
          ],
        ),
      ),
    );
  }
}
