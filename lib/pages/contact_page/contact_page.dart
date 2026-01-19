import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wissal_app/controller/contact_controller/contact_controller.dart';
import 'package:wissal_app/controller/profile_controller/profile_controller.dart';
import 'package:wissal_app/model/user_model.dart';
import 'package:wissal_app/pages/Homepage/widgets/chat_tile.dart';
import 'package:wissal_app/pages/Homepage/widgets/group/new_group/new_group.dart';
import 'package:wissal_app/pages/chat_page/chat_page.dart';
import 'package:wissal_app/pages/contact_page/widgets/new_contact_tile.dart';

import '../../controller/chat_controller/chat_controller.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  bool isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  ContactController contactcontroller = Get.put(ContactController());
  ProfileController profileController = Get.put(ProfileController());
  ChatController chatcontroller = Get.put(ChatController());

  void _openChat(UserModel user) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      Get.snackbar('خطأ', 'يجب تسجيل الدخول أولاً');
      return;
    }
    Get.to(() => ChatPage(userModel: user));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: Text(
          'Select Contact',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (isSearching)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search contacts...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            NewContactTile(
              btnname: 'New Contact',
              icon: Icons.person_add,
              ontap: () {},
            ),
            NewContactTile(
              btnname: 'New Group',
              icon: Icons.group_add,
              ontap: () {
                Get.to(NewGroup());
              },
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 10, top: 10),
              child: Row(
                children: [
                  Text(
                    'Contacts on Wessal app',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
            Obx(
              () => Column(
                children: contactcontroller.userList
                    .map((e) => InkWell(
                          onTap: () {
                            _openChat(e);
                          },
                          child: ChatTile(
                            imgUrl: e.profileimage ??
                                'https://i.ibb.co/V04vrTtV/blank-profile-picture-973460-1280.png',
                            name: e.name ?? " User  ",
                            lastChat: e.about ?? 'hey there',
                            lastTime: e.email ==
                                    profileController.currentUser.value.email
                                ? 'You'
                                : "",
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
