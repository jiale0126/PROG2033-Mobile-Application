import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/ai_services.dart';
import 'result_screens.dart';

class InputScreen extends StatefulWidget {
  @override
  _InputScreenState createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  double _duration = 2.0;
  double _budget = 500.0;
  int _participants = 50;
  String _theme = 'Tech Talk';
  String _location = 'Hall';
  bool _isLoading = false;

  final List<String> _themes = [
    'Tech Talk',
    'Gaming Night',
    'Charity Event',
    'Career Fair',
  ];
  final List<String> _locations = [
    'Hall',
    'Classroom',
    'Outdoor Area',
    'Computer Lab',
  ];

  void _generateEventPlan() async {
    setState(() => _isLoading = true);

    var results = await Future.wait([
      AiService.generatePoster(_theme, _location, _budget),
      AiService.generatePlanning(
        _theme,
        _duration,
        _budget,
        _participants,
        _location,
      ),
    ]);

    Uint8List? imageBytes = results[0] as Uint8List?;
    Map<String, dynamic> planData = results[1] as Map<String, dynamic>;

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ResultScreen(imageBytes: imageBytes, planData: planData),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Organizer Planner')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              value: _theme,
              decoration: const InputDecoration(labelText: 'Event Theme'),
              items: _themes.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) => setState(() => _theme = newValue!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _location,
              decoration: const InputDecoration(labelText: 'Event Location'),
              items: _locations.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) => setState(() => _location = newValue!),
            ),
            const SizedBox(height: 16),
            Text('Duration: ${_duration.toInt()} hours'),
            Slider(
              value: _duration,
              min: 1,
              max: 24,
              divisions: 23,
              onChanged: (val) => setState(() => _duration = val),
            ),
            Text('Budget: RM ${_budget.toInt()}'),
            Slider(
              value: _budget,
              min: 0,
              max: 5000,
              divisions: 50,
              onChanged: (val) => setState(() => _budget = val),
            ),
            Text('Expected Participants: $_participants'),
            Slider(
              value: _participants.toDouble(),
              min: 10,
              max: 500,
              divisions: 49,
              onChanged: (val) => setState(() => _participants = val.toInt()),
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _generateEventPlan,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text(
                      'Generate Event Plan',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
