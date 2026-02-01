import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _numPages = 3;

  final List<Map<String, String>> _onboardingPages = [
    {
      'title': 'Welcome to AutoGit!',
      'description':
          'Manage all your Git repos and GitHub projects on the go. Local or remote, we\'ve got you covered.',
      'image': 'assets/images/onboarding-1.png',
    },
    {
      'title': 'Built with Flutter',
      'description': 'Keeping ease of use and simplicity in mind.',
      'image': 'assets/images/onboarding-2.png',
    },
    {
      'title': 'Get Started',
      'description':
          'Visit our website at https://autogit.app for more information.',
      'image': 'assets/images/onboarding-3.png',
    },
  ];

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _onNextPressed() {
    if (_currentPage == _numPages - 1) {
      GoRouter.of(context).go("/home");
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _onboardingPages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            width: double.infinity,
                            height: 250,
                            child: Image.asset(
                              _onboardingPages[index]['image']!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.blue[100],
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 80,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _onboardingPages[index]['title']!,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _onboardingPages[index]['description']!,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(
                3, // Always show exactly 3 dots
                (index) => _buildPageIndicator(index),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onNextPressed,
                  child: Text(
                    _currentPage == _numPages - 1 ? 'Get Started' : 'Next',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    bool isCurrentPage = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isCurrentPage ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isCurrentPage ? 1.0 : 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
