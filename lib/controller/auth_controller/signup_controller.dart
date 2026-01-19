import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wissal_app/model/user_model.dart';

class SignupController extends GetxController {
  var isLoading = false.obs;

  Future<void> signUp(String email, String password, String name) async {
    // Validate empty fields
    if (name.isEmpty && email.isEmpty && password.isEmpty) {
      _showError("Empty Fields", "Please fill in all fields");
      return;
    }
    if (name.isEmpty) {
      _showError("Name Required", "Please enter your full name");
      return;
    }
    if (email.isEmpty) {
      _showError("Email Required", "Please enter your email address");
      return;
    }
    if (password.isEmpty) {
      _showError("Password Required", "Please enter a password");
      return;
    }

    // Validate email format
    if (!GetUtils.isEmail(email)) {
      _showError("Invalid Email", "Please enter a valid email address");
      return;
    }

    // Validate password strength
    if (password.length < 6) {
      _showError("Weak Password", "Password must be at least 6 characters");
      return;
    }

    final supabase = Supabase.instance.client;
    isLoading.value = true;

    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
        emailRedirectTo: 'com.example.wissal_app://login-callback/',
      );

      if (response.user != null) {
        final userId = response.user!.id;

        await initUser(email, name, userId);

        if (response.user!.emailConfirmedAt == null) {
          _showSuccess(
            "Account Created!",
            "Please check your email to verify your account.",
          );
          print("📧 Confirmation email sent to: ${response.user!.email}");
        } else {
          await saveSession(userId);
          _showSuccess("Welcome!", "Account created successfully");
          print("✅ signup successful: ${response.user!.email}");
          Get.offNamed('/homepage');
        }
      } else {
        _showError("Signup Failed", "Could not create account. Please try again.");
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
    String title = "Signup Failed";
    String message;

    if (e.message.toLowerCase().contains("already registered") ||
        e.message.toLowerCase().contains("already exists")) {
      title = "Email Already Registered";
      message = "This email is already in use. Please login or use a different email.";
    } else if (e.message.toLowerCase().contains("invalid email")) {
      title = "Invalid Email";
      message = "Please enter a valid email address.";
    } else if (e.message.toLowerCase().contains("weak password") ||
        e.message.toLowerCase().contains("password")) {
      title = "Weak Password";
      message = "Password must be at least 6 characters with letters and numbers.";
    } else if (e.message.toLowerCase().contains("network")) {
      title = "Connection Error";
      message = "Please check your internet connection.";
    } else if (e.message.toLowerCase().contains("too many requests")) {
      title = "Too Many Attempts";
      message = "Please wait a moment before trying again.";
    } else {
      message = e.message;
    }

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
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(10),
      borderRadius: 10,
    );
  }

  Future<void> initUser(String email, String name, String userId) async {
    final supabase = Supabase.instance.client;

    try {
      // التحقق من وجود المستخدم في save_users (نفس الجدول الذي نُدخل فيه)
      final existingUser = await supabase
          .from('save_users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (existingUser == null) {
        final newUser = UserModel(
          email: email,
          name: name,
          id: userId,
          status: true, // المستخدم متصل عند التسجيل
        );

        await supabase.from('save_users').insert(newUser.toJson());
        print("✅ User inserted successfully into save_users");
      } else {
        print("ℹ️ User already exists in save_users");
      }
    } catch (e) {
      print("❌ Error in initUser: $e");
      // محاولة ثانية باستخدام upsert
      try {
        final newUser = UserModel(
          email: email,
          name: name,
          id: userId,
          status: true,
        );
        await supabase.from('save_users').upsert(newUser.toJson());
        print("✅ User upserted successfully");
      } catch (e2) {
        print("❌ Error in upsert: $e2");
      }
    }
  }

  Future<void> saveSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    print("🟢 session saved: $userId"); // ✅ Debug
  }
}
