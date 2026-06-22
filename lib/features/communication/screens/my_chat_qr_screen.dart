import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/platform/qr_export.dart';
import '../../../providers/user_provider.dart';
import '../../marketPlace/widgets/amril_qr_code.dart';
import '../theme/chat_theme.dart';

/// Personal chat QR: a "My Code" tab (your scannable code + save/share/copy)
/// and a "Scan" entry that opens the camera scanner. Scanning someone's code
/// routes to the chat-user landing via amril.app/chat-user/:id.
class MyChatQrScreen extends StatefulWidget {
  const MyChatQrScreen({super.key});

  static String payloadFor(String userId) =>
      'https://amril.app/chat-user/$userId';

  @override
  State<MyChatQrScreen> createState() => _MyChatQrScreenState();
}

class _MyChatQrScreenState extends State<MyChatQrScreen> {
  final GlobalKey _qrKey = GlobalKey();
  bool _busy = false;

  Future<Uint8List?> _capture() async {
    final boundary =
        _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: ChatTheme.surface),
    );
  }

  Future<void> _save(String userId) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _capture();
      if (bytes == null) {
        _toast('Could not render code');
        return;
      }
      final result = await saveQrImage(bytes, fileName: 'amril_chat_$userId');
      _toast(result.message);
    } catch (_) {
      _toast('Couldn’t save code');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareImage(String userId, String name) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _capture();
      if (bytes == null) {
        _toast('Could not render code');
        return;
      }
      final files = await buildQrShareFiles(bytes, fileName: 'amril_chat_$userId');
      await SharePlus.instance.share(
        ShareParams(
          files: files,
          text: 'Chat with $name on Amril\n${MyChatQrScreen.payloadFor(userId)}',
        ),
      );
    } catch (_) {
      _toast('Couldn’t share code');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyLink(String userId) async {
    await Clipboard.setData(
        ClipboardData(text: MyChatQrScreen.payloadFor(userId)));
    HapticFeedback.selectionClick();
    _toast('Link copied');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final userId = user?.userId ?? '';
    final name = user?.name ?? 'My code';
    final userName = user?.userProfile.userName;
    final text = Theme.of(context).textTheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: ChatTheme.scaffold,
        appBar: AppBar(
          title: const Text('My QR code'),
          bottom: const TabBar(
            indicatorColor: ChatTheme.brandBright,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'My Code'),
              Tab(text: 'Scan'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ── My Code ──────────────────────────────────────────────
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (userId.isEmpty)
                        Text('Sign in to get your code',
                            style: text.bodyMedium
                                ?.copyWith(color: Colors.white54))
                      else ...[
                        RepaintBoundary(
                          key: _qrKey,
                          child: AmrilQRCode(
                            data: MyChatQrScreen.payloadFor(userId),
                            label: name,
                            caption: userName != null
                                ? '@$userName · Scan to chat'
                                : 'Scan to chat with me',
                            logoUrl: user?.userProfile.avatarUrl,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _CodeAction(
                                icon: Icons.download_rounded,
                                label: 'Save',
                                busy: _busy,
                                onTap: () => _save(userId),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _CodeAction(
                                icon: Icons.ios_share_rounded,
                                label: 'Share',
                                busy: _busy,
                                onTap: () => _shareImage(userId, name),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _CodeAction(
                                icon: Icons.link_rounded,
                                label: 'Copy',
                                onTap: () => _copyLink(userId),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Show or share this code to let someone start a chat with you.',
                          textAlign: TextAlign.center,
                          style: text.bodySmall?.copyWith(
                              color: Colors.white38, height: 1.4),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // ── Scan ─────────────────────────────────────────────────
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_scanner_rounded,
                        size: 64, color: Colors.white24),
                    const SizedBox(height: 16),
                    Text('Scan a friend’s chat code',
                        style: text.bodyLarge?.copyWith(color: Colors.white70)),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => context.push('/scan'),
                      style: FilledButton.styleFrom(
                        backgroundColor: ChatTheme.brand,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 13),
                      ),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Open scanner'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeAction extends StatelessWidget {
  const _CodeAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ChatTheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: ChatTheme.brandBright))
                  : Icon(icon, color: ChatTheme.brandBright, size: 22),
              const SizedBox(height: 6),
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
