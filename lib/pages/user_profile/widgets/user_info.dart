import 'package:flutter/material.dart';

class UserInfo extends StatelessWidget {
  final String profileImage;
  final String userName;
  final String userEmail;

  const UserInfo({
    super.key,
    required this.profileImage,
    required this.userName,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: 250,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xffB8DFF2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.amber,
                    width: 4,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    profileImage.isNotEmpty
                        ? profileImage
                        : "https://i.ibb.co/V04vrTtV/blank-profile-picture-973460-1280.png",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            Text(userEmail, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.call, color: Colors.green, size: 18),
                        label: const Text('Call',
                            style: TextStyle(color: Colors.green, fontSize: 12)),
                        style: TextButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.onBackground,
                          side: const BorderSide(color: Colors.green),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.video_call, color: Colors.orange, size: 18),
                        label: const Text('Video',
                            style: TextStyle(color: Colors.orange, fontSize: 12)),
                        style: TextButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.onBackground,
                          side: const BorderSide(color: Colors.orange),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.message, color: Colors.blue, size: 18),
                        label: const Text('Chat',
                            style: TextStyle(color: Colors.blue, fontSize: 12)),
                        style: TextButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.onBackground,
                          side: const BorderSide(color: Colors.blue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
