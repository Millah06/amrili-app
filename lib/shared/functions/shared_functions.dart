
import 'package:url_launcher/url_launcher.dart';

class SharedFunctions {

  static void openDialer(String phoneNumber) async {
    final Uri emailLaunchUri = Uri(
      scheme : 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
    else {
      throw 'Could not launch email app';
    }
  }

  static void launchEmail(String subject, {String email = 'team.nexpay@gmail.com'}) async {
    final Uri emailLaunchUri = Uri.parse(
      'mailto:$email?subject=${Uri.encodeComponent(subject)}',
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      throw 'Could not launch email app';
    }
  }

  static  void openUrl(String url) async {
    final Uri uri = Uri.parse('https://$url');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {

      throw Exception('Could not launch');
    }
  }

  static  void openDeepLink(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {

      throw Exception('Could not launch');
    }
  }

}