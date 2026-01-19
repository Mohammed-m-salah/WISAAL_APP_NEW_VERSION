import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wissal_app/controller/auth_controller/login_controller.dart';

import '../../../widgets/custome_button.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final LoginController loginController = Get.put(LoginController());
  bool _obscurePassword = true;

  @override
  void dispose() {
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
            onSubmitted: (_) => _handleLogin(),
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
            () => loginController.isLoading.value
                ? const CircularProgressIndicator()
                : CustomeButton(
                    mytext: 'Login',
                    myicon: Icons.login,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    onPressed: _handleLogin,
                  ),
          ),
        ],
      ),
    );
  }

  void _handleLogin() {
    FocusScope.of(context).unfocus();
    loginController.Login(
      emailController.text.trim(),
      passwordController.text,
    );
  }
}
