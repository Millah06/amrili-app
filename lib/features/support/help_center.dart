import 'package:everywhere/features/support/provider.dart';
import 'package:everywhere/features/support/support_chat_screen.dart';
import 'package:everywhere/shared/functions/shared_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constraints/vendor_theme.dart';

class HelpCenter extends StatelessWidget {
  const HelpCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Help Center',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.only(left: 12, right: 12, top: 16),
        child: Column(
          children: [
            _listTile(
                Icons.email,
                'Email Us',
                'amrilidigitalservices@gmail.com',
                onTap: () {
                    SharedFunctions.launchEmail('Complain on data');
                }
            ),
            _listTile(
                Icons.phone,
                'Give Us a phone call',
                '+86 13248938580',
                onTap: () {
                  SharedFunctions.openDialer('+86 13248938580');
                }
            ),
            _listTile(
                Icons.chat,
                'In app chat',
                'With a customer support',
                onTap: () async {
                  final pov = context.read<SupportProvider>();
                  showDialog(context: context,
                      barrierDismissible: false, builder: (_) => const Dialog(
                        backgroundColor: VendorTheme.background,
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: VendorTheme.circularProgressColor,),
                              SizedBox(width: 16),
                              Text("Creating chat..."),
                            ],
                          ),
                        ),
                      ));
                  pov.chatId == null && pov.supportName == null ? await pov.init() : null;
                  if (context.mounted) {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) =>
                        SupportChatScreen(roomId: pov.chatId!,
                            otherUserName: pov.supportName!)));
                  }

                }
            ),
          ],
        ),

      )
    );
  }

  Widget _listTile (IconData icon, text, subTile, {required Function() onTap}) {
    return GestureDetector(
      onTap: onTap,
      child:  ListTile(
          leading: Icon(icon, color: const Color(0xFF177E85)),
          title: Text(text),
          subtitle: Text(subTile),
          textColor: Colors.white,
          trailing: const Icon(Icons.chevron_right, color: Colors.grey)
      ),
    );
  }
}
