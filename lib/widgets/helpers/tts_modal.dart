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
  late bool _isMale;
  late String _voiceName;

  @override
  void initState() {
    super.initState();
    _rate = widget.ttsHelper.rate;
    _pitch = widget.ttsHelper.pitch;
    _isMale = widget.ttsHelper.isMale;
    _voiceName = widget.ttsHelper.voiceName;
  }

  Future<void> _saveSettings() async {
    await widget.ttsHelper.setRate(_rate);
    await widget.ttsHelper.setPitch(_pitch);
    await widget.ttsHelper.setGender(_isMale);
    setState(() {
      _voiceName = widget.ttsHelper.voiceName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.settings, color: Colors.indigo),
          SizedBox(width: 8),
          Text('TTS Voice Settings'),
        ],
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSection(
              label: "Voice Gender",
              child: DropdownButton<bool>(
                value: _isMale,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: true, child: Text("Male")),
                  DropdownMenuItem(value: false, child: Text("Female")),
                ],
                onChanged: (value) async {
                  if (value != null) {
                    setState(() => _isMale = value);
                    await widget.ttsHelper.setGender(_isMale);
                    setState(() => _voiceName = widget.ttsHelper.voiceName);
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
              onChanged: (value) => setState(() => _rate = value),
            ),

            _buildSliderSection(
              title: "Pitch",
              value: _pitch,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              iconLow: Icons.music_note,
              iconHigh: Icons.music_video,
              onChanged: (value) => setState(() => _pitch = value),
            ),

            const SizedBox(height: 12),

            if (_voiceName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
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
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.volume_up),
              label: const Text("Preview Voice"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                await widget.ttsHelper.setRate(_rate);
                await widget.ttsHelper.setPitch(_pitch);
                await widget.ttsHelper.setGender(_isMale);
                setState(() => _voiceName = widget.ttsHelper.voiceName);
                await widget.ttsHelper.speak(
                  "This is a preview of your voice settings.",
                );
              },
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          onPressed: () async {
            await _saveSettings();
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          label: const Text("Save"),
        ),
      ],
    );
  }

  Widget _buildSection({required String label, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
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
    required ValueChanged<double> onChanged,
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
                valueIndicatorColor: Colors.indigo,
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
