import 'package:flutter/material.dart';
import 'package:wissal_app/pages/Auth/widgets/loginform.dart';
import 'package:wissal_app/pages/Auth/widgets/signupform.dart';

class AuthPageBody extends StatefulWidget {
  const AuthPageBody({super.key});

  @override
  State<AuthPageBody> createState() => _AuthPageBodyState();
}

class _AuthPageBodyState extends State<AuthPageBody> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 335,
        height: _currentPage == 0 ? 320 : 420,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tabs (Login / Signup)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTab(
                  title: "Login",
                  selected: _currentPage == 0,
                  onTap: () => _goToPage(0),
                ),
                _buildTab(
                  title: "Signup",
                  selected: _currentPage == 1,
                  onTap: () => _goToPage(1),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // PageView for smooth swipe animation
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                physics: const BouncingScrollPhysics(),
                children: const [
                  LoginForm(key: ValueKey("login")),
                  SignupForm(key: ValueKey("signup")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: selected ? 100 : 0,
            height: 5,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}
