import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wissal_app/controller/auth_controller/signup_controller.dart';

import '../../../widgets/custome_button.dart';

class SignupForm extends StatefulWidget {
  const SignupForm({super.key});

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final SignupController signupController = Get.put(SignupController());
  bool _obscurePassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person_outline),
              filled: true,
              hintText: 'Full Name',
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.alternate_email_outlined),
              filled: true,
              hintText: 'Email',
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleSignup(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              filled: true,
              hintText: 'Password',
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 25),
          Obx(
            () => signupController.isLoading.value
                ? const CircularProgressIndicator()
                : CustomeButton(
                    mytext: 'Sign Up',
                    myicon: Icons.person_add,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    onPressed: _handleSignup,
                  ),
          ),
        ],
      ),
    );
  }

  void _handleSignup() {
    FocusScope.of(context).unfocus();
    signupController.signUp(
      emailController.text.trim(),
      passwordController.text,
      nameController.text.trim(),
    );
  }
}
