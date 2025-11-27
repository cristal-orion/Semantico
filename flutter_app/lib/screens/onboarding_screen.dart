import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/pop_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Benvenuto in Semantico!',
      description: 'Il gioco dove indovini la parola segreta usando la vicinanza semantica.',
      icon: Icons.waving_hand_rounded,
      color: PopTheme.yellow,
    ),
    OnboardingPage(
      title: 'Come funziona?',
      description: 'Scrivi una parola e scopri quanto è vicina alla soluzione. Più il numero è basso, più sei vicino!',
      icon: Icons.lightbulb_outline_rounded,
      color: PopTheme.cyan,
    ),
    OnboardingPage(
      title: 'Temperature',
      description: 'I colori ti aiutano:\n🧊 Blu = Freddo\n🌡️ Giallo = Tiepido\n🔥 Arancio = Caldo\n💥 Viola = Fuoco!',
      icon: Icons.thermostat_rounded,
      color: PopTheme.orange,
    ),
    OnboardingPage(
      title: 'Suggerimenti',
      description: 'Bloccato? Tocca la lampadina 💡 per ricevere un suggerimento con una parola vicina alla soluzione.',
      icon: Icons.tips_and_updates_rounded,
      color: PopTheme.magenta,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pages[_currentPage].color,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  'Salta',
                  style: PopTheme.bodyStyle.copyWith(
                    color: PopTheme.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? PopTheme.black
                          : PopTheme.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Next/Start button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PopTheme.black,
                    foregroundColor: PopTheme.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'INIZIA A GIOCARE!' : 'AVANTI',
                    style: PopTheme.bodyStyle.copyWith(
                      color: PopTheme.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: PopTheme.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: PopTheme.black, width: 3),
              boxShadow: [
                BoxShadow(
                  color: PopTheme.black,
                  offset: const Offset(4, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: 60,
              color: PopTheme.black,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: PopTheme.headingStyle.copyWith(fontSize: 28),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: PopTheme.bodyStyle.copyWith(fontSize: 16, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
