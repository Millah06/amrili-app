import 'package:everywhere/components/reusable_card.dart';
import 'package:everywhere/constraints/constants.dart';
import 'package:everywhere/models/notification_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

// class NotificationScreen extends StatelessWidget {
//   final RemoteMessage? message; // Optional: passed when tapped
//
//   const NotificationScreen({super.key, this.message});
//
//   @override
//   Widget build(BuildContext context) {
//     // Clear badge when screen opens
//
//     return Scaffold(
//       appBar: AppBar(title: const Text('Notifications')),
//       body: ValueListenableBuilder(
//         valueListenable: Hive.box<AppNotification>('notifications').listenable(),
//         builder: (context, Box box, widget) {
//           if (box.isEmpty) {
//             return const Center(child: Text('No notifications yet'));
//           }
//
//           // Show newest first
//           var items = box.values.toList().reversed.toList();
//
//           return ListView.builder(
//             itemCount: items.length,
//             itemBuilder: (context, index) {
//               var notif = items[index];
//
//               return Dismissible(
//                 key: Key(notif['receivedAt']), // Unique key
//                 onDismissed: (_) {
//                   box.deleteAt(box.keyAt(box.values.firstWhere((type) => type = notif)));
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Notification deleted')),
//                   );
//                 },
//                 child: ListTile(
//                   leading: const Icon(Icons.notifications, color: Colors.blue),
//                   title: Text(notif['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(notif['body']),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Received: ${DateTime.parse(notif['receivedAt']).formatTime()}',
//                         style: const TextStyle(fontSize: 12, color: Colors.grey),
//                       ),
//                     ],
//                   ),
//                   // Optional: Show data (e.g., amount, sender)
//                   onTap: () {
//                     if (notif['data'].isNotEmpty) {
//                       showDialog(
//                         context: context,
//                         builder: (_) => AlertDialog(
//                           title: const Text("Details"),
//                           content: Text("Data: ${notif['data']}"),
//                           actions: [
//                             TextButton(
//                               onPressed: () => Navigator.pop(context),
//                               child: const Text("Close"),
//                             ),
//                           ],
//                         ),
//                       );
//                     }
//                   },
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

class NotificationScreen extends StatelessWidget {
  final RemoteMessage? message;

  const NotificationScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<AppNotification>('notifications').listenable(),
        builder: (context, Box<AppNotification> box, _) {
          if (box.isEmpty) {
            return const Center(child: Text('No notifications yet'));
          }

          var items = box.values.toList().reversed.toList();

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final notif = items[index];
          
              return Dismissible(
                key: Key(notif.receivedAt.toIso8601String()),
                onDismissed: (_) {
                  box.deleteAt(index);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification deleted')),
                  );
                },
                child: ReusableCard(
                  child: ListTile(
                    leading: const Icon(Icons.notifications, color: kIconColor),
                    title: Text(
                      notif.title,
                      style: GoogleFonts.raleway(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notif.body, style: TextStyle(color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(
                          'Received: ${DateTime.parse(notif.receivedAt.toIso8601String()).formatTime()}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    onTap: () {
                      if (notif.data.isNotEmpty) {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Details"),
                            content: Text("Data: ${notif.data}"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Close"),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


// Helper: Format time (e.g., "2:30 PM")
extension TimeFormat on DateTime {
  String formatTime() {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final today = DateTime(now.year, now.month, now.day);

    if (isAfter(today)) {
      return 'Today ${hour > 12 ? hour - 12 : hour}:${minute.toString().padLeft(2, '0')} '
          '${hour >= 12 ? 'PM' : 'AM'}';
    } else if (isAfter(yesterday)) {
      return 'Yesterday ${hour > 12 ? hour - 12 : hour}:${this.minute.toString().padLeft(2, '0')} ${this.hour >= 12 ? 'PM' : 'AM'}';
    } else {
      return '$day/$month ${hour > 12 ? hour - 12 : hour}:${minute.toString().padLeft(2, '0')} ${hour >= 12 ? 'PM' : 'AM'}';
    }
  }
}