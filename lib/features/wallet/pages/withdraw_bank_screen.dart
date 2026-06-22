import 'package:everywhere/shared/widgets/confirmation_page.dart';
import 'package:everywhere/models/list_of_banks.dart';
import 'package:everywhere/providers/withdrawal_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../constraints/constants.dart';
import '../../../../constraints/firebase_constant.dart';
import '../../../../services/external_withdrawal_services.dart';
import '../../../../services/transaction_service.dart';
import 'package:everywhere/features/verification/verification_gate.dart';

class WithdrawBankScreen extends StatefulWidget {
  const WithdrawBankScreen({super.key});

  @override
  State<WithdrawBankScreen> createState() => _WithdrawBankScreenState();
}

class _WithdrawBankScreenState extends State<WithdrawBankScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  ListOfBanks ? selectedBank;
  String verifiedAccountHolder = '';

  bool _submitting = false;

  List<ListOfBanks> ? _banks;
  String ? currentRequestId;

  @override
  Widget build(BuildContext context) {
    final withdrawalProvider = Provider.of<WithdrawalProvider>(context);

    void loadBanks() {
      withdrawalProvider.loadBank();
    }

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Text(
          'Withdraw to Bank',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recipient details',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                maxLength: 10,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  labelText: 'Account number',
                  labelStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF177E85)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  errorStyle: GoogleFonts.inter(color: Colors.red, fontSize: 12),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter account number';
                  }
                  if (value.trim().length != 10) {
                    return 'Account number must be 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final ListOfBanks? bank = await Navigator.push(context,
                      MaterialPageRoute(builder: (context) => BankSearchScreen()));
                  if (bank != null) {
                    setState(() => selectedBank = bank);
                    withdrawalProvider.clear();
                    withdrawalProvider.resolveBank(
                        accountNumber: _accountNumberController.text,
                        bankCode: selectedBank!.bankCode);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_outlined,
                          color: Color(0xFF177E85), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          selectedBank?.bankName ?? 'Select bank',
                          style: GoogleFonts.inter(
                            color: selectedBank == null ? Colors.white38 : Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (selectedBank != null)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: withdrawalProvider.isResolving
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Color(0xFF177E85)),
                            ),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: withdrawalProvider.invalidDetails == true
                                ? Colors.red.withOpacity(0.08)
                                : const Color(0xFF177E85).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: withdrawalProvider.invalidDetails == true
                                  ? Colors.red.withOpacity(0.3)
                                  : const Color(0xFF177E85).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                withdrawalProvider.invalidDetails == true
                                    ? Icons.error_outline_rounded
                                    : Icons.verified_outlined,
                                color: withdrawalProvider.invalidDetails == true
                                    ? Colors.red
                                    : const Color(0xFF177E85),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  withdrawalProvider.accountHolder.isNotEmpty
                                      ? withdrawalProvider.accountHolder
                                      : 'Could not verify account',
                                  style: GoogleFonts.inter(
                                    color: withdrawalProvider.invalidDetails == true
                                        ? Colors.red
                                        : Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              const SizedBox(height: 20),
              Text(
                'Amount',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  labelText: 'Amount (NGN)',
                  labelStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 14, right: 8),
                    child: Text('₦', style: TextStyle(color: Colors.white54, fontSize: 18, height: 2.8)),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF177E85)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  errorStyle: GoogleFonts.inter(color: Colors.red, fontSize: 12),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter amount to withdraw';
                  }
                  final parsed = double.tryParse(value.replaceAll(',', ''));
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  labelText: 'Note (optional)',
                  labelStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF177E85)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                ),
              ),


              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kButtonColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _submitting
                      ? null
                      : () {
                          VerificationGate.ensureVerified(
                            context,
                            reason: 'to withdraw funds',
                            action: () {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => _submitting = true);

                          showModalBottomSheet(context: context,  isScrollControlled: true, builder: (context) {
                            return ConfirmationPage(
                                amount: _amountController.text,
                                onTap: (amount, reward, useReward) {
                                  final WithdrawalApiServices apiService = WithdrawalApiServices();
                                  TransactionService.handlePurchase(
                                    context: context,
                                    purchaseFunction: () async {
                                      try {
                                        if (currentRequestId != null) {
                                          return {
                                            'status' : false
                                          };
                                        }
                                        currentRequestId = FirebaseConstant.clientRequestId();
                                        String humanReference = FirebaseConstant.generateTransactionId();
                                        final res = await  apiService.initiateWithdrawal(
                                            clientRequestId: currentRequestId!,
                                            amount: _amountController.text,
                                            name: withdrawalProvider.accountHolder,
                                            reason: _noteController.text,
                                            bankCode: selectedBank!.bankCode,
                                            accountNumber: _accountNumberController.text,
                                            humanRef: humanReference);
                                        print(res);
                                        return res;

                                      }
                                      catch(e) {
                                        rethrow;
                                      }
                                      finally {
                                        setState(() {
                                          currentRequestId = null;
                                        });
                                      }
                                    },
                                  );
                                },
                                receiptData: {
                                  'Product Name' : 'Bank Withdrawal',
                                  'Actual Amount': '${kFormatter.format(double.parse(_amountController
                                      .text.replaceAll(',', '')))} NGN',
                                  'Account Number' : _accountNumberController.text,
                                  'Name' : withdrawalProvider.accountHolder,
                                  'Bank' : selectedBank!.bankName
                                },
                                isRecharge: false,
                                bonusEarn: 0
                            );
                          });

                          setState(() => _submitting = false);
                            },
                          );
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
          ),
        ),
      ),
      ),
    ),
    );
  }
}

class BankSearchScreen extends StatefulWidget {
  const BankSearchScreen({super.key});

  @override
  State<BankSearchScreen> createState() => _BankSearchScreenState();
}

class _BankSearchScreenState extends State<BankSearchScreen> {

  List<ListOfBanks> filteredBanks = [];
  String searchQuery = "";

  void searchBank(String query, WithdrawalProvider provider) {
    setState(() {
      searchQuery = query;

      if (query.isEmpty) {
        filteredBanks = provider.banks;
      } else {
        filteredBanks = provider.banks
            .where((bank) =>
            bank.bankName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void initState() {
    _loadInitialData();
    // TODO: implement initState
    super.initState();
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WithdrawalProvider>().loadBank();

    });
  }



  @override
  Widget build(BuildContext context) {



    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Bank", style: TextStyle(color: Colors.white),),
      ),

      body: Consumer<WithdrawalProvider>(builder: (context, withdrawalProvider, _) {

        if (filteredBanks.isEmpty && searchQuery.isEmpty) {
          filteredBanks = withdrawalProvider.banks;
        }
        if (withdrawalProvider.isLoading && withdrawalProvider.banks.isEmpty) {
          return Center(child: CircularProgressIndicator(),);
        }
        return Column(
          children: [

            /// SEARCH BAR
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (value) => searchBank(value, withdrawalProvider),
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search bank...",
                  prefixIcon: const Icon(Icons.search),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            /// LIST
            Expanded(
              child: ListView(
                children: [

                  /// ALL BANKS
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "All Banks",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  ...filteredBanks.map((bank) => bankTile(bank)),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget bankTile(ListOfBanks bank) {
    return ListTile(
      leading: const CircleAvatar(
        child: Icon(Icons.account_balance),
      ),
      title: Text(bank.bankName, style: TextStyle(color: Colors.white),),
      onTap: () {
        Navigator.pop(context, bank);
      },
    );
  }
}


