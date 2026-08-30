import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_grow_code/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_grow_code/custom_header_button.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  static const String _email = 'bloqdevz@gmail.com';
  static const String _phoneDisplay = '0945-670-341';
  static const String _phoneNumber = '0945670341';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const CustomHeaderButton(title: 'Contact Us'),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // -------------------------------------------------
                        // INTRO
                        // -------------------------------------------------
                        _buildIntro(context),

                        const SizedBox(height: 28),

                        // -------------------------------------------------
                        // CONTACT CARD
                        // -------------------------------------------------
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.cardSurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.divider),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Contact Information',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                'Choose how you would like to reach us.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppTheme.textSecondary),
                              ),

                              const SizedBox(height: 20),

                              _ContactTile(
                                icon: Icons.mail_outline_rounded,
                                title: 'Email',
                                value: _email,
                                actionIcon: Icons.open_in_new_rounded,
                                onTap: () => _launchEmail(context),
                                onAction: () => _launchEmail(context),
                                onCopy: () => _copyToClipboard(context, _email),
                              ),

                              const SizedBox(height: 12),

                              _ContactTile(
                                icon: Icons.phone_outlined,
                                title: 'Phone',
                                value: _phoneDisplay,
                                actionIcon: Icons.call_outlined,
                                onTap: () => _launchPhone(context),
                                onAction: () => _launchPhone(context),
                                onCopy: () =>
                                    _copyToClipboard(context, _phoneDisplay),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // -------------------------------------------------
                        // SMALL INFO SECTION
                        // -------------------------------------------------
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.info_outline_rounded,
                                  size: 20,
                                  color: AppTheme.primary,
                                ),
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Need assistance?',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      'Send us an email or contact us through the phone number above.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppTheme.textSecondary,
                                            height: 1.5,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        Center(
                          child: Text(
                            'Smart Grow Support',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.support_agent_rounded,
            size: 34,
            color: AppTheme.primary,
          ),
        ),

        const SizedBox(height: 18),

        Text(
          'Get in Touch',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Have a question or need help with Smart Grow?\nWe’re here to help.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));

    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text('$text copied to clipboard')),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: _email);

    final bool launched = await launchUrl(
      emailUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && context.mounted) {
      await Clipboard.setData(const ClipboardData(text: _email));

      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('No email app found. Email address copied instead.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _launchPhone(BuildContext context) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: _phoneNumber);

    final bool launched = await launchUrl(
      phoneUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && context.mounted) {
      await Clipboard.setData(const ClipboardData(text: _phoneNumber));

      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Calling is not available on this device. Phone number copied instead.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }
}

// ============================================================================
// CONTACT TILE
// ============================================================================

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.actionIcon,
    required this.onTap,
    required this.onCopy,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  final VoidCallback onCopy;
  final IconData actionIcon;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 22),
              ),

              const SizedBox(width: 14),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Copy button
              IconButton(
                tooltip: 'Copy',
                onPressed: onCopy,
                icon: const Icon(Icons.content_copy_rounded, size: 19),
                color: AppTheme.textSecondary,
              ),

              IconButton(
                tooltip: title == 'Email' ? 'Open email' : 'Call',
                onPressed: onAction,
                icon: Icon(actionIcon, size: 19),
                color: AppTheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
