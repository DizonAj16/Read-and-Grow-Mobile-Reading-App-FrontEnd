import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
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

  bool _isValidIpPort(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return false;

    final regex = RegExp(
      r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3}):(\d{1,5})$',
    );
    final match = regex.firstMatch(trimmed);
    if (match == null) return false;

    for (int i = 1; i <= 4; i++) {
      final octet = int.tryParse(match[i]!);
      if (octet == null || octet < 0 || octet > 255) return false;
    }

    final port = int.tryParse(match[5]!);
    return port != null && port >= 0 && port <= 65535;
  }

  Future<void> _saveUrl() async {
    final input = _controller.text.trim();
    if (!_isValidIpPort(input)) {
      setState(() {
        _errorText =
            input.isEmpty
                ? 'IP Address and Port cannot be blank.'
                : 'Please enter a valid IP:Port (e.g. 192.168.1.100:8000)';
      });
      return;
    }
    setState(() => _errorText = null);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => WillPopScope(
            onWillPop: () async => false,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset(
                      'assets/animation/loading_rainbow.json',
                      height: 90,
                      width: 90,
                    ),
                    Text(
                      'Configuring...',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.surface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    try {
      final fullUrl = 'http://$input/api';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('base_url', fullUrl);

      // Wait minimum display time
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(
          context,
        ).pushReplacement(PageTransition(page: const LandingPage()));
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog on error
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _useDefaultUrl() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => WillPopScope(
            onWillPop: () async => false,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset(
                      'assets/animation/loading_rainbow.json',
                      height: 90,
                      width: 90,
                    ),
                    Text(
                      'Configuring...',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.surface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('base_url', 'http://10.0.2.2:8000/api');

      // Wait minimum display time
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(
          context,
        ).pushReplacement(PageTransition(page: const LandingPage()));
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog on error
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            // Darkened background image
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.3),
                  BlendMode.darken,
                ),
                child: Image.asset(
                  'assets/background/480681008_1020230633459316_6070422237958140538_n.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Warning banner
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.orange[700],
                child: const Center(
                  child: Text(
                    'DEVELOPMENT SETTINGS ONLY - NOT FOR PRODUCTION USE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),

            // Main content
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Card(
                    elevation: 16,
                    color: Colors.white.withOpacity(0.93),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header
                            Icon(
                              Icons.developer_mode,
                              size: 50,
                              color: Colors.orange[800],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Development Server Configuration",
                              style: Theme.of(
                                context,
                              ).textTheme.headlineSmall?.copyWith(
                                color: Colors.orange[800],
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Configure backend server connection for development",
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[700]),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            // Input field
                            TextField(
                              controller: _controller,
                              decoration: InputDecoration(
                                labelText: "Server IP:Port",
                                hintText: "192.168.1.100:8000",
                                prefixIcon: const Icon(Icons.dns),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                errorText: _errorText,
                                errorStyle: const TextStyle(color: Colors.red),
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9\.:]'),
                                ),
                              ],
                              onChanged:
                                  (_) => setState(() => _errorText = null),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Enter your local development server address",
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 24),

                            // Action buttons
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _saveUrl,
                                icon: const Icon(Icons.save),
                                label: const Text("SAVE CONFIGURATION"),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: Colors.orange[800],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _useDefaultUrl,
                                icon: const Icon(Icons.settings_backup_restore),
                                label: const Text("USE DEFAULT (EMULATOR)"),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(color: Colors.orange[800]!),
                                  foregroundColor: Colors.orange[800],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 12),
                            Text(
                              "Note: This configuration page is only for development purposes. "
                              "In production, the backend URL should be configured automatically.",
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: Colors.red[700],
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
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
}
