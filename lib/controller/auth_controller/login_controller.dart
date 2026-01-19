import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginController extends GetxController {
  var isLoading = false.obs;
  var loginError = ''.obs;

  Future<void> Login(String email, String password) async {
    // Validate empty fields
    if (email.isEmpty && password.isEmpty) {
      _showError("Empty Fields", "Please enter your email and password");
      return;
    }
    if (email.isEmpty) {
      _showError("Email Required", "Please enter your email address");
      return;
    }
    if (password.isEmpty) {
      _showError("Password Required", "Please enter your password");
      return;
    }

    // Validate email format
    if (!GetUtils.isEmail(email)) {
      _showError("Invalid Email", "Please enter a valid email address");
      return;
    }

    final supabase = Supabase.instance.client;
    isLoading.value = true;
    loginError.value = '';

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        debugPrint("✅ Login successful: ${response.user!.email}");
        Get.offAllNamed('/homepage');
        _showSuccess("Welcome Back!", "Logged in successfully");
      } else {
        _showError("Login Failed", "Please check your credentials");
      }
    } on AuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      _showError("Error", "An unexpected error occurred. Please try again.");
    } finally {
      isLoading.value = false;
    }
  }

  void _handleAuthError(AuthException e) {
    String title = "Login Failed";
    String message;

    if (e.message.toLowerCase().contains("invalid login credentials")) {
      message = "Incorrect email or password. Please try again.";
    } else if (e.message.toLowerCase().contains("email not confirmed")) {
      title = "Email Not Verified";
      message = "Please check your inbox and verify your email first.";
    } else if (e.message.toLowerCase().contains("user not found")) {
      title = "Account Not Found";
      message = "No account exists with this email. Please sign up first.";
    } else if (e.message.toLowerCase().contains("too many requests")) {
      title = "Too Many Attempts";
      message = "Please wait a moment before trying again.";
    } else if (e.message.toLowerCase().contains("network")) {
      title = "Connection Error";
      message = "Please check your internet connection.";
    } else {
      message = e.message;
    }

    loginError.value = message;
    _showError(title, message);
  }

  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      icon: const Icon(Icons.error_outline, color: Colors.white),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(10),
      borderRadius: 10,
    );
  }

  void _showSuccess(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade600,
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(10),
      borderRadius: 10,
    );
  }
}
