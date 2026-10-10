import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/user_settings.dart';
import '../l10n/app_strings.dart';
import 'main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final StorageService storageService;

  const OnboardingScreen({super.key, required this.storageService});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late TextEditingController _capacityController;
  late TextEditingController _hpController;
  late TextEditingController _rateController;
  late TextEditingController _overflowController;

  @override
  void initState() {
    super.initState();
    final settings = widget.storageService.getUserSettings();
    _capacityController = TextEditingController(text: settings.tankCapacityLitres.toStringAsFixed(0));
    _hpController = TextEditingController(text: settings.motorHp.toStringAsFixed(1));
    _rateController = TextEditingController(text: settings.electricityRate.toStringAsFixed(1));
    _overflowController = TextEditingController(text: settings.typicalOverflowMinutes.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _capacityController.dispose();
    _hpController.dispose();
    _rateController.dispose();
    _overflowController.dispose();
    super.dispose();
  }

  void _finishSetup() async {
    final double capacity = double.tryParse(_capacityController.text) ?? 1000.0;
    final double hp = double.tryParse(_hpController.text) ?? 1.0;
    final double rate = double.tryParse(_rateController.text) ?? 6.0;
    final double overflow = double.tryParse(_overflowController.text) ?? 5.0;

    final currentSettings = widget.storageService.getUserSettings();
    final updatedSettings = currentSettings.copyWith(
      tankCapacityLitres: capacity <= 0 ? 1000.0 : capacity,
      motorHp: hp <= 0 ? 1.0 : hp,
      electricityRate: rate <= 0 ? 6.0 : rate,
      typicalOverflowMinutes: overflow <= 0 ? 5.0 : overflow,
      isOnboardingCompleted: true,
    );

    await widget.storageService.saveUserSettings(updatedSettings);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainScreen(storageService: widget.storageService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.storageService.getUserSettings();
    final lang = settings.language;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (idx) {
                  setState(() => _currentPage = idx);
                },
                children: [
                  _buildPage(
                    icon: Icons.water_drop_rounded,
                    title: AppStrings.get('onboarding_title_1', lang),
                    description: AppStrings.get('onboarding_desc_1', lang),
                  ),
                  _buildPage(
                    icon: Icons.timer_rounded,
                    title: AppStrings.get('onboarding_title_2', lang),
                    description: AppStrings.get('onboarding_desc_2', lang),
                  ),
                  _buildPage(
                    icon: Icons.build_circle_rounded,
                    title: AppStrings.get('onboarding_title_3', lang),
                    description: AppStrings.get('onboarding_desc_3', lang),
                  ),
                  _buildFormPage(lang),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicator
                  Row(
                    children: List.generate(
                      4,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 16 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < 3) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finishSetup();
                      }
                    },
                    child: Text(
                      _currentPage == 3
                          ? AppStrings.get('get_started', lang)
                          : 'Next',
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 90, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.black70),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPage(String lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            AppStrings.get('setup_title', lang),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.get('setup_subtitle', lang),
            style: const TextStyle(fontSize: 14, color: Colors.black70),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _capacityController,
            label: AppStrings.get('tank_capacity', lang),
            icon: Icons.opacity,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _hpController,
            label: AppStrings.get('motor_hp', lang),
            icon: Icons.flash_on,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _rateController,
            label: AppStrings.get('elec_rate', lang),
            icon: Icons.currency_rupee,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _overflowController,
            label: AppStrings.get('typical_overflow', lang),
            icon: Icons.timer,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
