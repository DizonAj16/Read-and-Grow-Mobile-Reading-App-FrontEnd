import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'landing_page.dart';
import '../../widgets/navigation/page_transition.dart';
import 'package:flutter/services.dart';

class SetBaseUrlPage extends StatefulWidget {
  const SetBaseUrlPage({super.key});

  @override
  State<SetBaseUrlPage> createState() => _SetBaseUrlPageState();
}

class _SetBaseUrlPageState extends State<SetBaseUrlPage> {
  final _controller = TextEditingController();
  String? _errorText;

  bool _isValidIpPort(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return false;

    // Regular expression for a string starting with 192. and then three groups of 1-3 digits separated by dots,
    // followed by a colon and 1-5 digits representing the port.
    final regex = RegExp(r'^192\.(\d{1,3})\.(\d{1,3})\.(\d{1,3}):(\d{1,5})$');
    final match = regex.firstMatch(trimmed);
    if (match == null) return false;

    // Validate that each octet is between 0 and 255.
    for (int i = 1; i <= 3; i++) {
      final octet = int.tryParse(match[i]!);
      if (octet == null || octet < 0 || octet > 255) {
        return false;
      }
    }

    // Validate the port is in a typical range (0-65535)
    final port = int.tryParse(match.group(4)!);
    if (port == null || port < 0 || port > 65535) return false;

    return true;
  }

  Future<void> _saveUrl() async {
    final input = _controller.text.trim();
    if (!_isValidIpPort(input)) {
      setState(() {
        _errorText =
            input.isEmpty
                ? 'IP Address and Port cannot be blank.'
                : 'Please enter a valid IP and Port (e.g. 192.168.1.100:8000)';
      });
      return;
    }
    setState(() {
      _errorText = null;
    });

    // Show loading dialog (refactored)
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder:
          (context) => Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 75,
                    height: 75,
                    child: Lottie.asset('assets/animation/loading1.json'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Loading...',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );

    // Transform the ip:port input into a full URL.
    final fullUrl = 'http://$input/api';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('base_url', fullUrl);
    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 4000));

    Navigator.pop(context);

    Navigator.of(
      context,
    ).pushReplacement(PageTransition(page: const LandingPage()));
  }

  Future<void> _useDefaultUrl() async {
    // Show loading dialog (refactored)
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder:
          (context) => Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 75,
                    height: 75,
                    child: Lottie.asset('assets/animation/loading1.json'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Loading...',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );

    // For consistency, the default is provided as a full URL.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('base_url', 'http://10.0.2.2:8000/api');
    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 4000));

    Navigator.pop(context); // Close loading dialog
    Navigator.of(
      context,
    ).pushReplacement(PageTransition(page: const LandingPage()));
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
                        Icon(
                          Icons.settings_ethernet,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Enter IP Address and Port",
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            labelText: "IP Address and Port",
                            hintStyle: const TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            errorText: _errorText,
                          ),
                          // Only allow digits, dots, and colon.
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9\.:]'),
                            ),
                          ],
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
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
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
                              foregroundColor:
                                  Theme.of(context).colorScheme.primary,
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
