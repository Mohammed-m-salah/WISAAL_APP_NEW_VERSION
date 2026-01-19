import 'package:flutter/material.dart';
import 'package:wissal_app/widgets/welcome_body.dart';
import 'package:wissal_app/widgets/welcome_footer.dart';
import 'package:wissal_app/widgets/welcome_heading.dart';

class WelcomPage extends StatelessWidget {
  const WelcomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              SizedBox(
                height: 50,
              ),
              WelcomHeading(),
              SizedBox(height: 30),
              WelcomeBody(),
              Spacer(),
              WelcomeFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
