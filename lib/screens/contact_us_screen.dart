import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_grow_code/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_grow_code/custom_header_button.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final isWide = screen.width > 600;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const CustomHeaderButton(title: "Contact Us"),
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(screen.width * 0.05),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: isWide ? 500 : double.infinity,
                        ),
                        padding: EdgeInsets.all(screen.width * 0.06),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: AppTheme.cardSurface.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Get in Touch",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isWide ? 28 : 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown.shade800,
                              ),
                            ),
                            SizedBox(height: screen.height * 0.02),
                            Text(
                              "We’d love to hear from you",
                              style: TextStyle(
                                fontSize: isWide ? 16 : 14,
                                color: Colors.brown.shade600,
                              ),
                            ),
                            SizedBox(height: screen.height * 0.04),
                            _contactTile(
                              context,
                              icon: Icons.email_outlined,
                              label: "bloqdevz@gmail.com",
                              onTap: () => _launchEmail(),
                            ),
                            SizedBox(height: screen.height * 0.02),
                            _contactTile(
                              context,
                              icon: Icons.phone_outlined,
                              label: "0945-670-341",
                              onTap: () => _launchPhone(),
                            ),
                          ],
                        ),
                      ),
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

  ///  CONTACT TILE
  Widget _contactTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final screen = MediaQuery.of(context).size;

    return InkWell(
      borderRadius: BorderRadius.circular(15),

      onTap: onTap,

      onLongPress: () async {
        await Clipboard.setData(ClipboardData(text: label));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Copied: $label"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },

      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: screen.height * 0.018,
          horizontal: screen.width * 0.05,
        ),

        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.2),
          ),
        ),

        child: Row(
          children: [
            Icon(icon, color: Colors.brown.shade700, size: screen.width * 0.06),

            SizedBox(width: screen.width * 0.04),

            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: screen.width * 0.042,
                  color: Colors.brown.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            Icon(Icons.copy, color: Colors.brown.shade400),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(scheme: 'mailto', path: 'bloqdevz@gmail.com');

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '0945670341');

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }
}
