import 'package:everywhere/components/pin_entry.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../constraints/constants.dart';
import '../services/brain.dart';
import '../shared/utils/flush_bar_message.dart';

 class TransactionPin extends StatelessWidget {

   final Function(String) onCompleted;
   final Function() onForgotPin;
   // final Function() onCorrect;
   const TransactionPin({super.key, required this.onCompleted, required this.onForgotPin,
     // required this.onCorrect
   });

   @override
   Widget build(BuildContext context) {
     return FractionallySizedBox(
       heightFactor: 0.55,
       child:  PinEntryScreen(
           onCompleted: onCompleted,
           onForgotPin: onForgotPin,
           onBiometricPressed: () async {
             final LocalAuthentication auth = LocalAuthentication();
             final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
             final bool canAuthenticate =
                 canAuthenticateWithBiometrics || await auth.isDeviceSupported();
             if (canAuthenticate) {
               bool result = await auth.authenticate(
                   localizedReason: 'Use Fingerprint  to confirm transaction',
                   options: const AuthenticationOptions(biometricOnly: true),
               );
               result ?   onCompleted :
               FlushBarMessage.showFlushBar(
                 context: context,
                 message: 'Your device does\'nt support this method, use passcode instead.',
                 title: 'Ops',
                 icon: Icon(Icons.error_outline,
                   color: kErrorIconColor, size: 30,),
               );
             }
           }
       ),
     );
   }
 }

