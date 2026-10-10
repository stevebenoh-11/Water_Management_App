import 'dart:async';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/calc_service.dart';
import '../models/meter_test.dart';
import '../l10n/app_strings.dart';

class LeakCheckScreen extends StatefulWidget {
  final StorageService storageService;

  const LeakCheckScreen({super.key, required this.storageService});

  @override
  State<LeakCheckScreen> createState() => _LeakCheckScreenState();
}

class _LeakCheckScreenState extends State<LeakCheckScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Drip Calc State
  bool _isDripTesting = false;
  int _dripCountdown = 10;
  int _dripCount = 0;
  Timer? _dripTimer;
  Map<String, double>? _dripResult;

  // Night Meter State
  MeterTestRecord? _meterRecord;
  final TextEditingController _nightReadingController = TextEditingController();
  final TextEditingController _morningReadingController = TextEditingController();
  String _unit = 'litres';
  String? _leakCheckResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _meterRecord = widget.storageService.getMeterTestRecord();
    if (_meterRecord != null) {
      _unit = _meterRecord!.unit;
      if (_meterRecord!.nightReading != null) {
        _nightReadingController.text = _meterRecord!.nightReading!.toString();
      }
      if (_meterRecord!.morningReading != null) {
        _morningReadingController.text = _meterRecord!.morningReading!.toString();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dripTimer?.cancel();
    _nightReadingController.dispose();
    _morningReadingController.dispose();
    super.dispose();
  }

  void _startDripTest() {
    setState(() {
      _isDripTesting = true;
      _dripCountdown = 10;
      _dripCount = 0;
      _dripResult = null;
    });

    _dripTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_dripCountdown > 1) {
        setState(() => _dripCountdown--);
      } else {
        _dripTimer?.cancel();
        setState(() {
          _isDripTesting = false;
          _dripResult = CalcService.calculateDripWaste(_dripCount);
        });
      }
    });
  }

  void _recordDripTap() {
    if (_isDripTesting) {
      setState(() => _dripCount++);
    }
  }

  void _markDripFixed() async {
    if (_dripResult == null) return;
    final double litres = _dripResult!['litresPerMonth'] ?? 0.0;

    await widget.storageService.addSavings(
      litres: litres,
      kwh: litres * 0.001,
      rupees: litres * 0.05,
    );

    setState(() => _dripResult = null);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Awesome! Added ${litres.toStringAsFixed(0)} Litres to your savings.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _saveNightReading() async {
    final double? reading = double.tryParse(_nightReadingController.text);
    if (reading == null || reading < 0) return;

    final record = MeterTestRecord(
      nightReading: reading,
      nightTime: DateTime.now(),
      unit: _unit,
    );

    await widget.storageService.saveMeterTestRecord(record);
    setState(() => _meterRecord = record);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Night reading saved. Check again in the morning!')),
    );
  }

  void _checkOvernightLeak() async {
    final double? morningReading = double.tryParse(_morningReadingController.text);
    if (_meterRecord?.nightReading == null || morningReading == null) return;

    final double leakLitres = CalcService.calculateNightMeterLeak(
      nightReading: _meterRecord!.nightReading!,
      morningReading: morningReading,
      unit: _unit,
    );

    final lang = widget.storageService.getUserSettings().language;

    setState(() {
      if (leakLitres > 0) {
        _leakCheckResult = AppStrings.get('leak_found', lang)
            .replaceAll('{litres}', leakLitres.toStringAsFixed(1));
      } else {
        _leakCheckResult = AppStrings.get('no_leak', lang);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.storageService.getUserSettings().language;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('leak_check', lang)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: AppStrings.get('drip_calc', lang)),
            Tab(text: AppStrings.get('night_meter', lang)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Drip Calculator
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          AppStrings.get('tap_per_drip', lang),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),
                        if (_isDripTesting) ...[
                          Text(
                            '$_dripCountdown s',
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _recordDripTap,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: const BoxDecoration(
                                color: Colors.cyan,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  AppStrings.get('tap_drip', lang),
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('${AppStrings.get('drips_count', lang)} $_dripCount'),
                        ] else ...[
                          ElevatedButton.icon(
                            onPressed: _startDripTest,
                            icon: const Icon(Icons.timer),
                            label: Text(AppStrings.get('start_10s_test', lang)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_dripResult != null) ...[
                  const SizedBox(height: 20),
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            AppStrings.get('monthly_waste', lang)
                                .replaceAll('{litres}', _dripResult!['litresPerMonth']!.toStringAsFixed(0))
                                .replaceAll('{buckets}', _dripResult!['bucketsPerMonth']!.toStringAsFixed(1)),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: _markDripFixed,
                            icon: const Icon(Icons.check),
                            label: Text(AppStrings.get('fixed_it', lang)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Tab 2: Night Meter Test
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Meter Unit:', style: TextStyle(fontWeight: FontWeight.bold)),
                            DropdownButton<String>(
                              value: _unit,
                              items: [
                                DropdownMenuItem(value: 'litres', child: Text(AppStrings.get('unit_litres', lang))),
                                DropdownMenuItem(value: 'm3', child: Text(AppStrings.get('unit_m3', lang))),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _unit = v);
                              },
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(AppStrings.get('night_reading', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nightReadingController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: AppStrings.get('enter_reading', lang),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _saveNightReading,
                          child: Text(AppStrings.get('save_night_reading', lang)),
                        ),
                        const Divider(height: 32),
                        Text(AppStrings.get('morning_reading', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _morningReadingController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: AppStrings.get('enter_reading', lang),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                          onPressed: _checkOvernightLeak,
                          child: Text(AppStrings.get('check_leak', lang)),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_leakCheckResult != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: _leakCheckResult!.contains('likely') ? Colors.red.shade50 : Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        _leakCheckResult!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
