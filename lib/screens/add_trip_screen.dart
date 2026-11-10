import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/countries.dart';
import '../models/trip.dart';
import '../state/trips_controller.dart';

class AddTripScreen extends StatefulWidget {
  const AddTripScreen({super.key});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  Country? _destination;
  Country? _origin;
  DateTime? _departure;
  DateTime? _return;
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isReturn}) async {
    final today = DateTime.now();
    final first = isReturn ? (_departure ?? today) : today;
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(first.year, first.month, first.day),
      lastDate: DateTime(today.year + 3),
      initialDate: isReturn ? (_return ?? first) : (_departure ?? today),
    );
    if (picked == null) return;
    setState(() {
      if (isReturn) {
        _return = picked;
      } else {
        _departure = picked;
        if (_return != null && _return!.isBefore(picked)) _return = null;
      }
    });
  }

  Future<void> _save() async {
    if (_destination == null || _departure == null) return;
    setState(() => _saving = true);
    final trip = await context.read<TripsController>().add(Trip(
          destinationCode: _destination!.code,
          originCode: _origin?.code,
          departureDate: _departure!,
          returnDate: _return,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          createdAt: DateTime.now(),
        ));
    if (mounted) Navigator.of(context).pop(trip);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMd();
    final canSave = _destination != null && _departure != null && !_saving;

    return Scaffold(
      appBar: AppBar(title: const Text('New trip')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CountryField(
            label: 'Destination country *',
            value: _destination,
            onChanged: (c) => setState(() => _destination = c),
          ),
          const SizedBox(height: 16),
          _CountryField(
            label: 'Travelling from (optional)',
            value: _origin,
            onChanged: (c) => setState(() => _origin = c),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.flight_takeoff),
                  label: Text(_departure == null
                      ? 'Departure *'
                      : fmt.format(_departure!)),
                  onPressed: () => _pickDate(isReturn: false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.flight_land),
                  label: Text(
                      _return == null ? 'Return' : fmt.format(_return!)),
                  onPressed: () => _pickDate(isReturn: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: canSave ? _save : null,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save trip'),
          ),
        ],
      ),
    );
  }
}

/// Opens a searchable bottom sheet to choose a country.
class _CountryField extends StatelessWidget {
  final String label;
  final Country? value;
  final ValueChanged<Country> onChanged;

  const _CountryField(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () async {
        final picked = await showModalBottomSheet<Country>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => const _CountryPicker(),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        isEmpty: value == null,
        child: value == null ? null : Text('${value!.flag}  ${value!.name}'),
      ),
    );
  }
}

class _CountryPicker extends StatefulWidget {
  const _CountryPicker();

  @override
  State<_CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<_CountryPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final results = countries
        .where((c) =>
            c.name.toLowerCase().contains(q) || c.code.toLowerCase() == q)
        .toList();

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search country',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (_, i) {
                final c = results[i];
                return ListTile(
                  leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                  title: Text(c.name),
                  onTap: () => Navigator.of(context).pop(c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
