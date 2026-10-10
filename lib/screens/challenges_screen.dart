import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../l10n/app_strings.dart';

class ChallengesScreen extends StatefulWidget {
  final StorageService storageService;

  const ChallengesScreen({super.key, required this.storageService});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final List<Map<String, dynamic>> _challenges = const [
    {'title': 'Use a bucket instead of a hose to wash your vehicle', 'litres': 100.0},
    {'title': 'Reuse RO water purifier reject water for mopping floors', 'litres': 40.0},
    {'title': 'Turn off the tap while brushing your teeth', 'litres': 15.0},
    {'title': 'Take a 5-minute timed shower or use a single bucket', 'litres': 50.0},
    {'title': 'Wash full loads of clothes in the washing machine', 'litres': 60.0},
    {'title': 'Fix any dripping faucet or showerhead in the house', 'litres': 30.0},
    {'title': 'Use a bowl to wash fruits and vegetables instead of running water', 'litres': 10.0},
    {'title': 'Water plants early in the morning to reduce evaporation loss', 'litres': 20.0},
    {'title': 'Install low-flow aerators on kitchen and bathroom taps', 'litres': 45.0},
    {'title': 'Collect rainwater for watering garden plants', 'litres': 50.0},
    {'title': 'Use left-over drinking water in bottles for household plants', 'litres': 5.0},
    {'title': 'Use a broom instead of water to clean driveways and balconies', 'litres': 80.0},
    {'title': 'Sweep before mopping to use less wash water', 'litres': 15.0},
    {'title': 'Keep a pitcher of cold water in the fridge instead of running the tap until cold', 'litres': 10.0},
    {'title': 'Soak pots and pans instead of letting water run while scrubbing', 'litres': 25.0},
    {'title': 'Check your toilet flush tank for hidden silent leaks using food coloring', 'litres': 100.0},
    {'title': 'Turn off shower water while applying soap or shampoo', 'litres': 35.0},
    {'title': 'Reuse AC condensation water for cleaning or gardening', 'litres': 20.0},
    {'title': 'Turn off main water supply valve when traveling away from home', 'litres': 200.0},
    {'title': 'Use a single mug of water for shaving instead of a running tap', 'litres': 12.0},
    {'title': 'Mop floors using a dual-bucket system to save dirty water dump', 'litres': 15.0},
    {'title': 'Wash dishes in a filled sink basin rather than continuous running water', 'litres': 40.0},
    {'title': 'Place a plastic water bottle inside toilet tank to decrease flush volume', 'litres': 15.0},
    {'title': 'Report outdoor public pipe leaks to local municipal authorities', 'litres': 500.0},
    {'title': 'Educate family members or housemates on overhead motor timing', 'litres': 100.0},
    {'title': 'Use a water-efficient dual flush button correctly', 'litres': 20.0},
    {'title': 'Don’t use running tap water to thaw frozen food; use fridge overnight', 'litres': 30.0},
    {'title': 'Cover outdoor water tanks and sumps to prevent evaporation loss', 'litres': 50.0},
    {'title': 'Rinse razor in a small cup instead of running water', 'litres': 10.0},
    {'title': 'Celebrate 30 days of water saving awareness!', 'litres': 100.0},
  ];

  int _streak = 0;
  List<String> _badges = [];
  bool _isDoneToday = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  void _loadState() {
    _streak = widget.storageService.getChallengeStreak();
    _badges = widget.storageService.getBadges();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    _isDoneToday = widget.storageService.getLastChallengeDate() == todayStr;
    setState(() {});
  }

  void _completeChallenge(double litresSaved) async {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    if (_isDoneToday) return;

    final int newStreak = _streak + 1;
    final List<String> updatedBadges = List.from(_badges);
    if (newStreak >= 3 && !updatedBadges.contains('3_day')) updatedBadges.add('3_day');
    if (newStreak >= 7 && !updatedBadges.contains('7_day')) updatedBadges.add('7_day');
    if (newStreak >= 30 && !updatedBadges.contains('30_day')) updatedBadges.add('30_day');

    await widget.storageService.saveChallengeCompletion(
      streak: newStreak,
      dateStr: todayStr,
      badges: updatedBadges,
    );

    await widget.storageService.addSavings(
      litres: litresSaved,
      kwh: litresSaved * 0.002,
      rupees: litresSaved * 0.01,
    );

    _loadState();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.storageService.getUserSettings().language;
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final todayChallenge = _challenges[dayOfYear % _challenges.length];

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('challenges', lang)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Streak Card
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, size: 50, color: Colors.orange),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_streak ${AppStrings.get('days', lang)} Streak!',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text('Keep saving water daily to grow your streak!'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Today's rotated challenge
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Today’s Water Saver Challenge', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(
                      todayChallenge['title'],
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Chip(
                      avatar: const Icon(Icons.water_drop, color: Colors.blue, size: 18),
                      label: Text('Saves ~${todayChallenge['litres']} Litres'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isDoneToday ? Colors.grey : Colors.green,
                        ),
                        onPressed: _isDoneToday
                            ? null
                            : () => _completeChallenge((todayChallenge['litres'] as num).toDouble()),
                        icon: Icon(_isDoneToday ? Icons.check_circle : Icons.task_alt),
                        label: Text(_isDoneToday ? AppStrings.get('completed', lang) : AppStrings.get('mark_done', lang)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Badges Section
            const Text('Your Badges', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBadge('3-Day Saver', Icons.emoji_events, _badges.contains('3_day')),
                _buildBadge('7-Day Guardian', Icons.military_tech, _badges.contains('7_day')),
                _buildBadge('30-Day Master', Icons.workspace_premium, _badges.contains('30_day')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String title, IconData icon, bool isUnlocked) {
    return Column(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: isUnlocked ? Colors.amber : Colors.grey.shade300,
          child: Icon(icon, size: 36, color: isUnlocked ? Colors.white : Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
            color: isUnlocked ? Colors.black87 : Colors.grey,
          ),
        ),
      ],
    );
  }
}
