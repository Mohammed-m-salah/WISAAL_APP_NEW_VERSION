import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:wissal_app/controller/chat_controller/chat_controller.dart';
import 'package:wissal_app/controller/status_controller/status_controller.dart';
import 'package:wissal_app/pages/Homepage/widgets/call_list_page.dart';
import 'package:wissal_app/pages/Homepage/widgets/chat_list_page.dart';
import 'package:wissal_app/pages/Homepage/widgets/group/groups_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ChatController chatController = Get.put(ChatController());
  final StatusController statusController = Get.put(StatusController());

  @override
  void initState() {
    super.initState();
    chatController.listenToIncomingMessages();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
            backgroundColor: Theme.of(context).colorScheme.primary,
            onPressed: () {
              Get.toNamed('/contactpage');
            },
            child: Icon(
              Icons.add,
            )),
        appBar: AppBar(
          elevation: 2,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          leading: IconButton(
            onPressed: () {},
            icon: SvgPicture.asset(
              'assets/icons/Vector.svg',
              width: 30,
              height: 30,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          title: Text(
            'Wesaal App',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                // contactcontroller.getChatRoomList();
              },
              icon: const Icon(Icons.search, color: Colors.white),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: () {
                Get.toNamed('/profilepage');
              },
              icon: const Icon(Icons.more_vert, color: Colors.white),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Chats'),
              Tab(text: 'Groups'),
              Tab(text: 'Calls'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            //chats
            Center(
              child: ChatListPage(),
            ),
            //groups
            Center(child: GroupListPage()),
            //calls
            Center(child: CallListPage()),
          ],
        ),
      ),
    );
  }
}
