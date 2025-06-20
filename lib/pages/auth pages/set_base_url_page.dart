import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'landing_page.dart';
import '../../widgets/navigation/page_transition.dart';

class SetBaseUrlPage extends StatefulWidget {
  const SetBaseUrlPage({super.key});

  @override
  State<SetBaseUrlPage> createState() => _SetBaseUrlPageState();
}

class _SetBaseUrlPageState extends State<SetBaseUrlPage> {
  final _controller = TextEditingController();
  String? _errorText;

  bool _isValidUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;
    final uri = Uri.tryParse(trimmed);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  Future<void> _saveUrl() async {
    final input = _controller.text.trim();
    if (!_isValidUrl(input)) {
      setState(() {
        _errorText = input.isEmpty
            ? 'Base URL cannot be blank.'
            : 'Please enter a valid URL (e.g. http://192.168.1.100:8000/api)';
      });
      return;
    }
    setState(() {
      _errorText = null;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('base_url', input);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageTransition(page: const LandingPage()),
    );
  }

  Future<void> _useDefaultUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('base_url', 'http://10.0.2.2:8000/api');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageTransition(page: const LandingPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/background/480681008_1020230633459316_6070422237958140538_n.jpg',
              fit: BoxFit.fill,
            ),
          ),
          // Centered card
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 12,
                color: Colors.white.withOpacity(0.95),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.settings_ethernet, size: 48, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          "Enter Backend IP Address or URL",
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            labelText: "Base URL (e.g. http://192.168.1.100:8000/api)",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            errorText: _errorText,
                          ),
                          onChanged: (_) {
                            if (_errorText != null) {
                              setState(() {
                                _errorText = null;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _saveUrl,
                            icon: const Icon(Icons.save),
                            label: const Text("Save & Continue"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _useDefaultUrl,
                            icon: const Icon(Icons.flash_on),
                            label: const Text("Use Default Base URL"),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                              foregroundColor: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}