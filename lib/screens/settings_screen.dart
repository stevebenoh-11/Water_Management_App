import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/user_settings.dart';
import '../l10n/app_strings.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  final StorageService storageService;

  const SettingsScreen({super.key, required this.storageService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late UserSettings _settings;
  late TextEditingController _capacityController;
  late TextEditingController _hpController;
  late TextEditingController _rateController;
  late TextEditingController _overflowController;

  @override
  void initState() {
    super.initState();
    _settings = widget.storageService.getUserSettings();
    _capacityController = TextEditingController(text: _settings.tankCapacityLitres.toStringAsFixed(0));
    _hpController = TextEditingController(text: _settings.motorHp.toStringAsFixed(1));
    _rateController = TextEditingController(text: _settings.electricityRate.toStringAsFixed(1));
    _overflowController = TextEditingController(text: _settings.typicalOverflowMinutes.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _capacityController.dispose();
    _hpController.dispose();
    _rateController.dispose();
    _overflowController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    final double capacity = double.tryParse(_capacityController.text) ?? 1000.0;
    final double hp = double.tryParse(_hpController.text) ?? 1.0;
    final double rate = double.tryParse(_rateController.text) ?? 6.0;
    final double overflow = double.tryParse(_overflowController.text) ?? 5.0;

    final updated = _settings.copyWith(
      tankCapacityLitres: capacity,
      motorHp: hp,
      electricityRate: rate,
      typicalOverflowMinutes: overflow,
    );

    await widget.storageService.saveUserSettings(updated);
    setState(() => _settings = updated);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully!'), backgroundColor: Colors.green),
    );
  }

  void _toggleLanguage(String lang) async {
    final updated = _settings.copyWith(language: lang);
    await widget.storageService.saveUserSettings(updated);
    setState(() => _settings = updated);
  }

  void _toggleDemoMode(bool val) async {
    final updated = _settings.copyWith(isDemoMode: val);
    await widget.storageService.saveUserSettings(updated);
    setState(() => _settings = updated);
  }

  void _recalibrateMotor() async {
    await widget.storageService.saveMotorCalibration(0, 0);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Motor calibration reset. Go to Motor Guard tab to re-calibrate.')),
    );
  }

  void _resetAllData() {
    final lang = _settings.language;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.get('reset_data', lang)),
        content: Text(AppStrings.get('confirm_reset', lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.get('cancel', lang)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await widget.storageService.clearAll();
              if (!mounted) return;
              Navigator.of(ctx).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => OnboardingScreen(storageService: widget.storageService),
                ),
              );
            },
            child: Text(AppStrings.get('confirm', lang)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = _settings.language;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('settings', lang)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language Selector Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.get('language', lang), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(value: 'en', label: Text(AppStrings.get('english', lang))),
                        ButtonSegment(value: 'ta', label: Text(AppStrings.get('tamil', lang))),
                      ],
                      selected: {_settings.language},
                      onSelectionChanged: (val) => _toggleLanguage(val.first),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Demo Mode Toggle Card
            Card(
              child: SwitchListTile(
                title: Text(AppStrings.get('demo_mode_setting', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Compresses 1 minute into 1 second for fast testing'),
                value: _settings.isDemoMode,
                onChanged: _toggleDemoMode,
              ),
            ),
            const SizedBox(height: 16),

            // Edit Household Parameters
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Household Parameters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _capacityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: AppStrings.get('tank_capacity', lang),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _hpController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: AppStrings.get('motor_hp', lang),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _rateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: AppStrings.get('elec_rate', lang),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _overflowController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: AppStrings.get('typical_overflow', lang),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveSettings,
                      child: const Text('Save Parameters'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Recalibrate & Reset Buttons
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.refresh, color: Colors.blue),
                    title: const Text('Recalibrate Motor'),
                    onTap: _recalibrateMotor,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: Text(AppStrings.get('reset_data', lang), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    onTap: _resetAllData,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
