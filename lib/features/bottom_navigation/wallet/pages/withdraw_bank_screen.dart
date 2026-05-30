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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Move funds from your NexPay wallet to a Nigerian bank account.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                maxLength: 10,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Account number',
                  counterText: '',
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
              const SizedBox(height: 16),
              // select a bank
              GestureDetector(
                onTap: () async {
                  ListOfBanks ? bank = await Navigator.push(context,
                      MaterialPageRoute(builder: (context) => BankSearchScreen()));

                  setState(() {
                    if (bank != null) {
                      selectedBank = bank;
                      withdrawalProvider.clear();
                      withdrawalProvider.resolveBank(
                          accountNumber: _accountNumberController.text, bankCode: selectedBank!.bankCode);
                    }
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(left: 5, right: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(selectedBank?.bankName ?? "Select Bank", style: selectedBank == null ?
                      TextStyle(color: Colors.white60, fontSize: 16) : TextStyle(color: Colors.white, fontSize: 16),),
                      Icon(Icons.arrow_forward_ios_sharp)
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (selectedBank != null)
                withdrawalProvider.isResolving ? CircularProgressIndicator(color: kCircularProgressColor,) : Container(
                  margin: EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.all(10),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF1E293B),
                  ),
                  child: Row(
                    children: [
                      Icon(withdrawalProvider.invalidDetails! ? Icons.error : Icons.verified),
                      SizedBox(width: 5,),
                      Text(withdrawalProvider.accountHolder, style: TextStyle(color: Colors.white),)
                    ],
                  ),),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Amount (NGN)',
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
                      : () {
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


