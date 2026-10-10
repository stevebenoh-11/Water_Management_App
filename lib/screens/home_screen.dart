import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/storage_service.dart';
import '../models/user_settings.dart';
import '../l10n/app_strings.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storageService;
  final Function(int) onTabSwitch;

  const HomeScreen({
    super.key,
    required this.storageService,
    required this.onTabSwitch,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late UserSettings _settings;
  double _weeklyLitres = 0.0;
  double _weeklyKwh = 0.0;
  double _weeklyRupees = 0.0;
  int _streak = 0;

  final List<String> _dailyLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<double> _weeklyChartData = List.filled(7, 0.0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _settings = widget.storageService.getUserSettings();
    _streak = widget.storageService.getChallengeStreak();

    final savingsMap = widget.storageService.getDailySavingsMap();
    double totalL = 0.0;
    double totalKwh = 0.0;
    double totalRs = 0.0;

    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final dateKey = day.toIso8601String().substring(0, 10);
      if (savingsMap.containsKey(dateKey)) {
        final rec = savingsMap[dateKey]!;
        totalL += rec.litres;
        totalKwh += rec.kwh;
        totalRs += rec.rupees;

        // Map day of week (1=Mon ... 7=Sun) to chart index (0..6)
        final dayOfWeekIndex = day.weekday - 1;
        if (dayOfWeekIndex >= 0 && dayOfWeekIndex < 7) {
          _weeklyChartData[dayOfWeekIndex] += rec.litres;
        }
      }
    }

    setState(() {
      _weeklyLitres = totalL;
      _weeklyKwh = totalKwh;
      _weeklyRupees = totalRs;
    });
  }

  void _completeTodayChallenge() async {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = widget.storageService.getLastChallengeDate();

    if (lastDate == todayStr) return; // Already completed today

    int newStreak = _streak + 1;
    List<String> badges = widget.storageService.getBadges();
    if (newStreak >= 3 && !badges.contains('3_day')) badges.add('3_day');
    if (newStreak >= 7 && !badges.contains('7_day')) badges.add('7_day');
    if (newStreak >= 30 && !badges.contains('30_day')) badges.add('30_day');

    await widget.storageService.saveChallengeCompletion(
      streak: newStreak,
      dateStr: todayStr,
      badges: badges,
    );

    await widget.storageService.addSavings(
      litres: 25.0, // Water saved by daily challenge
      kwh: 0.1,
      rupees: 0.6,
    );

    _loadData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Challenge Completed! Saved ~25 Litres of water.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = _settings.language;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final isDoneToday = widget.storageService.getLastChallengeDate() == todayStr;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('app_name', lang)),
        actions: [
          if (_settings.isDemoMode)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'DEMO',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Savings Header Card
            Card(
              color: Theme.of(context).primaryColor,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      AppStrings.get('saved_this_week', lang),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn('${_weeklyLitres.toStringAsFixed(0)} L', 'Water'),
                        _buildStatColumn('${_weeklyKwh.toStringAsFixed(1)} kWh', 'Energy'),
                        _buildStatColumn('₹${_weeklyRupees.toStringAsFixed(1)}', 'Money'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Big Round Motor ON Button
            Center(
              child: GestureDetector(
                onTap: () => widget.onTabSwitch(1), // Switch to Motor Guard
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0288D1), Color(0xFF00BCD4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.power_settings_new_rounded, size: 48, color: Colors.white),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.get('motor_on', lang),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Today's Challenge Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.get('today_challenge', lang),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Chip(
                          avatar: const Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
                          label: Text('$_streak ${AppStrings.get('days', lang)}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Turn off the tap while brushing teeth or shaving today.',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: isDoneToday ? null : _completeTodayChallenge,
                        icon: Icon(isDoneToday ? Icons.check : Icons.task_alt),
                        label: Text(
                          isDoneToday
                              ? AppStrings.get('completed', lang)
                              : AppStrings.get('mark_done', lang),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Weekly Savings Chart (fl_chart)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.get('weekly_savings', lang),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (_weeklyChartData.reduce((a, b) => a > b ? a : b) + 10).clamp(50.0, 1000.0),
                          barTouchData: BarTouchDataEnabled(false),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx >= 0 && idx < _dailyLabels.length) {
                                    return Text(_dailyLabels[idx], style: const TextStyle(fontSize: 12));
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(
                            7,
                            (index) => BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: _weeklyChartData[index],
                                  color: Theme.of(context).primaryColor,
                                  width: 16,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}
