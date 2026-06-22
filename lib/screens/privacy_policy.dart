import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_html/flutter_html.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
   State createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  String _htmlContent = '';

  @override
  void initState() {
    super.initState();
    loadHtml();
  }

  Future<void> loadHtml() async {
    final content = await rootBundle.loadString('assets/privacy_policy.html');
    setState(() {
      _htmlContent = content;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Privacy Policy',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          iconTheme: IconThemeData(
            color: Colors.white
          ),
        ),
        body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800), child: _htmlContent.isEmpty
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(child: Html(data: _htmlContent)))),
         );
     }
}