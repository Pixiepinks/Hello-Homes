import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class CookieConsentBanner extends StatefulWidget {
  const CookieConsentBanner({super.key});

  @override
  State<CookieConsentBanner> createState() => _CookieConsentBannerState();
}

class _CookieConsentBannerState extends State<CookieConsentBanner> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _checkConsent();
  }

  Future<void> _checkConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final hasConsented = prefs.getBool('cookie_consent_given') ?? false;
    if (!hasConsented) {
      setState(() => _isVisible = true);
    }
  }

  Future<void> _handleConsent(bool accepted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cookie_consent_given', true);
    setState(() => _isVisible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Material(
        elevation: 20,
        child: Container(
          color: AppTheme.darkBlue,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 40,
            vertical: 24,
          ),
          child: SafeArea(
            top: false,
            child: isMobile 
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMessage(),
                    const SizedBox(height: 20),
                    _buildButtons(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildMessage()),
                    const SizedBox(width: 40),
                    _buildButtons(),
                  ],
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'We value your privacy',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We collect essential personal information during login and checkout to process your orders securely. Your data is protected and used only to improve your experience.',
          style: TextStyle(
            color: Colors.white.withAlpha(200),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: () => _handleConsent(false),
          child: const Text('Decline', style: TextStyle(color: Colors.white70)),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () => _handleConsent(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Accept Cookies'),
        ),
      ],
    );
  }
}
