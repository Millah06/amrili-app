
import 'dart:io';

import 'package:intl/intl.dart';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/constant/api_constants.dart';

class AppLinkHandler {
  static String _appLink = "";
  static int _buildNumber = 0;
  static String _version = '';

  // Initialize the app link with dynamic package name
  static Future<void> init() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    _appLink = "https://play.google.com/store/apps/details?id=${packageInfo.packageName}";
    _buildNumber = int.parse(packageInfo.buildNumber);
    _version = packageInfo.version;
  }

  // Get the app link
  static String get appLink => _appLink;
  static int get buildNumber => _buildNumber;
  static String get currentVersion => _version;

  // Method to copy app link to clipboard
  static Future<void> copyAppLink() async {
    await Clipboard.setData(ClipboardData(text: _appLink));
  }

  // Method to share app link using native share dialog
  static Future<void> shareAppLink() async {
    try {
      final ByteData bytes = await rootBundle.load('images/FRAME 5.png');
      final Directory tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/frame.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await SharePlus.instance.share(
        ShareParams(
          files:  [XFile(file.path)],
          title: 'NexPay App Share',
          text : ' ❤️Check out this amazing app!\n\n🔥🔥NexPay isn’t just top-ups — '
              'it lets you create stunning Airtime Gifts 🎁\n\nA platform — where '
              'thousands create and share moments like this every day.\n\nTry it → $appLink  '

        ),
      );
    }
    catch (e) {
      print(e);
    }
  }

  // Method to open app in Play Store
  static Future<void> openInPlayStore() async {
    final Uri url = Uri.parse(_appLink);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppShareHelper — builds + shares Amril deep links (store / product / table /
// post / referral). This is SEPARATE from AppLinkHandler, which shares the
// Play-Store download link. All URLs come from ApiConstants so the share sheet
// and the QR generator (Phase 2) stay in lock-step. Uses the confirmed
// share_plus API: SharePlus.instance.share(ShareParams(...)).
// ─────────────────────────────────────────────────────────────────────────────
class AppShareHelper {
  AppShareHelper._();

  static Future<void> _shareText({required String text, String? subject}) async {
    try {
      await SharePlus.instance.share(ShareParams(text: text, title: subject));
    } catch (e) {
      // Sharing is best-effort; never crash the calling screen.
      // ignore: avoid_print
      print('AppShareHelper share error: $e');
    }
  }

  static Future<void> shareStore(String vendorId, {String? storeName}) {
    final url = ApiConstants.storeUrl(vendorId);
    final name = (storeName != null && storeName.trim().isNotEmpty)
        ? storeName.trim()
        : 'this store';
    return _shareText(
      subject: 'Check out $name on Amril',
      text: 'Check out $name on Amril 👇\n$url',
    );
  }

  static Future<void> shareProduct(String menuItemId, {String? productName}) {
    final url = ApiConstants.productUrl(menuItemId);
    final name = (productName != null && productName.trim().isNotEmpty)
        ? productName.trim()
        : 'this item';
    return _shareText(
      subject: name,
      text: 'Check out $name on Amril 👇\n$url',
    );
  }

  static Future<void> shareTable(String vendorId, String tableId,
      {String? storeName}) {
    final url = ApiConstants.tableUrl(vendorId, tableId);
    final name = (storeName != null && storeName.trim().isNotEmpty)
        ? storeName.trim()
        : 'this table';
    return _shareText(
      subject: 'Order at $name',
      text: 'Scan to order at $name on Amril 👇\n$url',
    );
  }

  // Used in Phase 2 to replace the hardcoded everywhere.app/post links.
  static Future<void> sharePost(String postId, String userName, String text) {
    final url = ApiConstants.postUrl(postId);
    final snippet = text.trim().isEmpty
        ? ''
        : '\n\n“${text.trim().length > 140 ? '${text.trim().substring(0, 140)}…' : text.trim()}”';
    return _shareText(
      subject: '$userName on Amril',
      text: '$userName on Amril$snippet\n\n$url',
    );
  }

  static Future<void> shareProfile(String userName, {String? displayName}) {
    final url = ApiConstants.profileUrl(userName);
    final name = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName.trim()
        : '@$userName';
    return _shareText(
      subject: 'Check out $name on Amril',
      text: 'Check out $name on Amril 👇\n$url',
    );
  }

  static Future<void> shareReferral(String referralCode) {
    final url = ApiConstants.referralUrl(referralCode);
    return _shareText(
      subject: 'Join me on Amril',
      text: 'Join me on Amril and let\’s both earn 🎁\n$url',
    );
  }
}

class MyFormatManager {

  static String formatMyDate(DateTime myDate, String formatterString) {
    String rowDate = DateFormat(formatterString).format(myDate);
    String req = rowDate.split(' ')[1].split(',').first;
    String formatted = '';
    if (req.endsWith('11') || req.endsWith('12') || req.endsWith('13')) {
      formatted = '${req}th';
    }
    else if (req.endsWith('1')) {
      formatted = '${req}st';
    }
    else if (req.endsWith('2')) {
      formatted = '${req}nd';
    }
    else if (req.endsWith('3')) {
      formatted = '${req}rd';
    }
    else {
      formatted = '${req}th';
    }
    return DateFormat(formatterString).format(myDate).replaceFirst(req, formatted);
  }

  static List<String> getUnavailableServices(Map<String, bool> services) {
    return services.entries
        .where((e) => e.value == false) // pick only false ones
        .map((e) => e.key)              // keep the keys
        .toList();
  }

  static String formatUnavailable(List<String> items, String provider) {
    if (items.isEmpty) return '';

    if (items.length == 1) return '${items[0]} $provider';

    // join all except the last with commas
    final allButLast = items.sublist(0, items.length - 1).join(', ');
    final last = items.last;

    return '$allButLast and $last $provider';
  }
}