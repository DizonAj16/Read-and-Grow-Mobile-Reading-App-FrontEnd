import 'package:deped_reading_app_laravel/widgets/helpers/tts_helper.dart';
import 'package:flutter/material.dart';

class TTSSettingsModal extends StatefulWidget {
  final TTSHelper ttsHelper;

  const TTSSettingsModal({super.key, required this.ttsHelper});

  @override
  State<TTSSettingsModal> createState() => _TTSSettingsModalState();
}

class _TTSSettingsModalState extends State<TTSSettingsModal> {
  late double _rate;
  late double _pitch;
  late String _voiceName;
  List<Map<String, String>> _voices = [];

  bool _isSaving = false;
  bool _isSaved = false;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _rate = widget.ttsHelper.rate;
    _pitch = widget.ttsHelper.pitch;
    _voiceName = widget.ttsHelper.voiceName;

    _loadVoices();
  }

  Future<void> _loadVoices() async {
    final voices = await widget.ttsHelper.getAvailableVoices();
    if (mounted) {
      setState(() => _voices = voices);
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
      _isSaved = false;
    });

    await widget.ttsHelper.setRate(_rate);
    await widget.ttsHelper.setPitch(_pitch);

    if (_voiceName.isNotEmpty) {
      await widget.ttsHelper.setVoiceByName(_voiceName);
    }

    setState(() {
      _voiceName = widget.ttsHelper.voiceName;
      _isSaving = false;
      _isSaved = true;
    });

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _previewVoice() async {
    if (_isSpeaking) return;

    setState(() => _isSpeaking = true);
    await widget.ttsHelper.setRate(_rate);
    await widget.ttsHelper.setPitch(_pitch);

    if (_voiceName.isNotEmpty) {
      await widget.ttsHelper.setVoiceByName(_voiceName);
    }

    setState(() => _voiceName = widget.ttsHelper.voiceName);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Playing voice preview...')),
    );

    await widget.ttsHelper.speak(
      "This is how I will sound when I read to you.",
    );

    setState(() => _isSpeaking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8, // ✅ prevent overflow
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: const [
                    Icon(Icons.settings, color: Colors.indigo, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'TTS Voice Settings',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildSection(
                  label: "Available Voices",
                  child: DropdownButtonFormField<String>(
                    isExpanded: true, // ✅ prevents text cutoff
                    value: _voiceName.isNotEmpty ? _voiceName : null,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: _voices
                        .map(
                          (v) => DropdownMenuItem(
                            value: v['name'],
                            child: Text(
                              "${v['name']} (${v['locale']})",
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) async {
                      if (value != null) {
                        setState(() => _voiceName = value);
                        await widget.ttsHelper.setVoiceByName(value);
                      }
                    },
                  ),
                ),

                _buildSliderSection(
                  title: "Speech Rate",
                  value: _rate,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  iconLow: Icons.slow_motion_video,
                  iconHigh: Icons.speed,
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _rate = value),
                ),

                _buildSliderSection(
                  title: "Pitch",
                  value: _pitch,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  iconLow: Icons.music_note,
                  iconHigh: Icons.music_video,
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _pitch = value),
                ),

                if (_voiceName.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.record_voice_over,
                          size: 20,
                          color: Colors.indigo,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Voice: $_voiceName",
                            style: const TextStyle(fontStyle: FontStyle.italic),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1, // ✅ ensures no overflow
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                ElevatedButton.icon(
                  icon: const Icon(Icons.volume_up),
                  label: const Text("Preview Voice"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  onPressed: (_isSaving || _isSpeaking) ? null : _previewVoice,
                ),

                const SizedBox(height: 20),

                if (_isSaved)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          "Settings saved!",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed:
                            _isSaving ? null : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isSaving ? "Saving..." : "Save"),
                        onPressed: _isSaving ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String label, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildSliderSection({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required IconData iconLow,
    required IconData iconHigh,
    required ValueChanged<double>? onChanged,
  }) {
    return _buildSection(
      label: title,
      child: Row(
        children: [
          Icon(iconLow, color: Colors.grey.shade600),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                activeTrackColor: Colors.indigo,
                inactiveTrackColor: Colors.grey.shade300,
                thumbColor: Colors.indigo,
                overlayColor: Colors.indigo.withOpacity(0.2),
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                label: value.toStringAsFixed(2),
                onChanged: onChanged,
              ),
            ),
          ),
          Icon(iconHigh, color: Colors.grey.shade600),
        ],
      ),
    );
  }
}
