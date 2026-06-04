import 'package:everywhere/constraints/firebase_constant.dart';
import 'package:everywhere/services/brain.dart';
import 'package:everywhere/services/transfer_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../constraints/constants.dart';

class P2PTransferScreen extends StatefulWidget {
  const P2PTransferScreen({super.key});

  @override
  State<P2PTransferScreen> createState() => _P2PTransferScreenState();
}

class _P2PTransferScreenState extends State<P2PTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneLast10Controller = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _submitting = false;
  bool receiverExist = false;
  bool readyToShowSearchResult = false;
  ReceiverInfo ? receiverInfo;
  String ? currentRequestId;

  @override
  Widget build(BuildContext context) {
    final pov = Provider.of<Brain>(context);
    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Text(
          'Transfer to NexPay',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send money to another NexPay user using their phone number (last 10 digits).',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneLast10Controller,
                keyboardType: TextInputType.number,
                maxLength: 10,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Recipient phone (last 10 digits)',
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter recipient phone digits';
                  }
                  if (value.trim().length != 10) {
                    return 'Must be exactly 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Visibility(
                visible: !readyToShowSearchResult || !receiverExist,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kButtonColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => PopScope(
                            canPop: false,
                            child: const Center(child: CircularProgressIndicator(
                              value: 20,
                              backgroundColor: kCardColor,
                              color: kButtonColor,
                            ),),
                          ),
                        );
                        receiverInfo = await TransferService()
                            .getReceiverInfo(phoneNumber: _phoneLast10Controller.text);
                        Navigator.pop(context);
                        if (receiverInfo != null) {
                          setState(() {
                            receiverExist = true;
                          });
                        }
                        setState(() {
                          readyToShowSearchResult = true;
                        });
                      }
                      catch(e) {
                        rethrow;
                      }
                    },
                    child: Text(
                      'Continue',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: readyToShowSearchResult,
                child: Container(
                  margin: EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.all(10),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(receiverExist ? Icons.verified : Icons.info, color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          receiverExist ? receiverInfo!.name.toUpperCase() : 'Sorry, No user found',
                          style: GoogleFonts.inter(

                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Visibility(
                visible: receiverExist,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Amount (NGN)',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter an amount';
                          }
                          final parsed = double.tryParse(value.replaceAll(',', ''));
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _noteController,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Note (optional)',
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.white70, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This is a preview UI. Actual debits/credits will be handled securely on the server later.',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kButtonColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _submitting
                              ? null
                              : () async {
                            if (!_formKey.currentState!.validate()) return;
                            setState(() => _submitting = true);
                            currentRequestId = FirebaseConstant.clientRequestId();
                            final res = await TransferService().createWalletTransfer(
                              senderUid: pov.currentUser,
                              receiverUid: receiverInfo!.uid,
                              amount: double.parse(_amountController.text),
                              clientRequestId: currentRequestId!,
                            );
                            print('response');
                            setState(() => _submitting = false);
                          },
                          child: _submitting
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                              : Text(
                            'Continue',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
              ),

            ],
          ),
        ),
      ),
    );
  }
}


