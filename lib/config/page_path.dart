import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:get/route_manager.dart';
import 'package:wissal_app/model/user_model.dart';
import 'package:wissal_app/pages/Auth/auth_page.dart';
import 'package:wissal_app/pages/Auth/widgets/loginform.dart';
import 'package:wissal_app/pages/Homepage/home_page.dart';
import 'package:wissal_app/pages/main_navigation_page.dart';
import 'package:wissal_app/pages/contact_page/contact_page.dart';
import 'package:wissal_app/pages/profile_page.dart/profile_page.dart';
import 'package:wissal_app/pages/user_profile/user_profile_page.dart';
import 'package:wissal_app/pages/user_profile/update_user_profile.dart';
import 'package:wissal_app/pages/welcom_page/welcom_page.dart';

var pagePath = [
  GetPage(
      name: "/authpage",
      page: () => AuthPage(),
      transition: Transition.leftToRight),
  GetPage(
      name: "/welcome",
      page: () => WelcomPage(),
      transition: Transition.leftToRight),
  GetPage(
      name: "/homepage",
      page: () => const MainNavigationPage(),
      transition: Transition.fadeIn),
  GetPage(
      name: "/chatspage",
      page: () => const HomePage(),
      transition: Transition.leftToRight),
  GetPage(
      name: "/loginform",
      page: () => LoginForm(),
      transition: Transition.leftToRight),
  GetPage(
      name: "/userprofilepage",
      page: () => UserProfilePage(user: UserModel()),
      transition: Transition.leftToRight),
  GetPage(
      name: "/userupdateprofilepage",
      page: () => UserUpdateProfile(),
      transition: Transition.leftToRight),
  GetPage(
      name: "/profilepage",
      page: () => ProfilePage(),
      transition: Transition.leftToRight),
  GetPage(
      name: "/contactpage",
      page: () => ContactPage(),
      transition: Transition.leftToRight),
];
