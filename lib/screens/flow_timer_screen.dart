import 'dart:async';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/calc_service.dart';
import '../models/fixture.dart';
import '../l10n/app_strings.dart';

class FlowTimerScreen extends StatefulWidget {
  final StorageService storageService;

  const FlowTimerScreen({super.key, required this.storageService});

  @override
  State<FlowTimerScreen> createState() => _FlowTimerScreenState();
}

class _FlowTimerScreenState extends State<FlowTimerScreen> {
  List<Fixture> _fixtures = [];
  Fixture? _selectedFixture;

  // Usage state
  double _limitLitres = 40.0;
  bool _isTimerRunning = false;
  int _elapsedSeconds = 0;
  Timer? _timer;

  // Calibration state
  bool _isCalibrating = false;
  int _calibSeconds = 0;
  Timer? _calibTimer;
  final TextEditingController _fixtureNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFixtures();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _calibTimer?.cancel();
    _fixtureNameController.dispose();
    super.dispose();
  }

  void _loadFixtures() {
    final list = widget.storageService.getFixtures();
    setState(() {
      _fixtures = list;
      if (list.isNotEmpty) _selectedFixture = list.first;
    });
  }

  void _toggleUsageTimer() {
    if (_isTimerRunning) {
      _stopUsageTimer();
    } else {
      _startUsageTimer();
    }
  }

  void _startUsageTimer() {
    if (_selectedFixture == null) return;
    setState(() {
      _isTimerRunning = true;
      _elapsedSeconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _stopUsageTimer() async {
    _timer?.cancel();
    final double litresUsed = CalcService.calculateLitresUsed(
      _selectedFixture?.flowRateLps ?? 0.1,
      _elapsedSeconds.toDouble(),
    );

    setState(() {
      _isTimerRunning = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Session completed! Used ${litresUsed.toStringAsFixed(1)} Litres.'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _startCalibration() {
    setState(() {
      _isCalibrating = true;
      _calibSeconds = 0;
    });
    _calibTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _calibSeconds++;
      });
    });
  }

  void _stopCalibrationAndSave() {
    _calibTimer?.cancel();
    final double calibSecs = _calibSeconds > 0 ? _calibSeconds.toDouble() : 10.0;
    final double flowRate = CalcService.calculateFixtureFlowRateLps(calibSecs);

    _showSaveFixtureDialog(flowRate);
  }

  void _showSaveFixtureDialog(double flowRate) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Fixture'),
        content: TextField(
          controller: _fixtureNameController,
          decoration: const InputDecoration(
            labelText: 'Fixture Name (e.g. Garden Hose)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _isCalibrating = false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final String name = _fixtureNameController.text.trim();
              if (name.isNotEmpty) {
                final newFixture = Fixture(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  flowRateLps: flowRate,
                );
                final updated = [..._fixtures, newFixture];
                await widget.storageService.saveFixtures(updated);
                _fixtureNameController.clear();
                _loadFixtures();
              }
              if (!mounted) return;
              Navigator.of(ctx).pop();
              setState(() => _isCalibrating = false);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.storageService.getUserSettings().language;
    final double litresUsed = _selectedFixture != null
        ? CalcService.calculateLitresUsed(_selectedFixture!.flowRateLps, _elapsedSeconds.toDouble())
        : 0.0;
    final bool isLimitExceeded = litresUsed >= _limitLitres;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('flow_timer', lang)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Calibration Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Calibrate 1L Bottle',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if (_isCalibrating)
                          Chip(
                            label: Text('$_calibSeconds s'),
                            backgroundColor: Colors.amber.shade200,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Fill a 1-litre bottle to calculate tap flow rate.'),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isCalibrating ? Colors.orange : Colors.teal,
                      ),
                      onPressed: _isCalibrating ? _stopCalibrationAndSave : _startCalibration,
                      icon: Icon(_isCalibrating ? Icons.stop : Icons.science),
                      label: Text(_isCalibrating ? 'Stop Calibration' : 'Start 1L Calibration'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Live Usage Timer Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<Fixture>(
                      value: _selectedFixture,
                      decoration: const InputDecoration(
                        labelText: 'Select Tap / Shower Fixture',
                        border: OutlineInputBorder(),
                      ),
                      items: _fixtures.map((f) {
                        return DropdownMenuItem(
                          value: f,
                          child: Text('${f.name} (${(f.flowRateLps * 60).toStringAsFixed(1)} L/min)'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedFixture = val);
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Limit (Litres):', style: TextStyle(fontWeight: FontWeight.bold)),
                        Slider(
                          value: _limitLitres,
                          min: 10,
                          max: 100,
                          divisions: 18,
                          label: '${_limitLitres.toInt()} L',
                          onChanged: (val) => setState(() => _limitLitres = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Progress Ring
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 160,
                          height: 160,
                          child: CircularProgressIndicator(
                            value: (_limitLitres > 0) ? (litresUsed / _limitLitres).clamp(0.0, 1.0) : 0.0,
                            strokeWidth: 12,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isLimitExceeded ? Colors.red : Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${litresUsed.toStringAsFixed(1)} L',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: isLimitExceeded ? Colors.red : Colors.black87,
                              ),
                            ),
                            Text('/ ${_limitLitres.toInt()} Litres Limit'),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isTimerRunning ? Colors.red : Colors.blue,
                        minimumSize: const Size(200, 50),
                      ),
                      onPressed: _toggleUsageTimer,
                      icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow),
                      label: Text(_isTimerRunning ? 'Stop Flow' : 'Start Flow Timer'),
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
}
