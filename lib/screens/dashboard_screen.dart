import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/trip.dart';
import '../state/trips_controller.dart';
import 'add_trip_screen.dart';
import 'settings_screen.dart';
import 'trip_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _addTrip(BuildContext context) async {
    final trip = await Navigator.of(context).push<Trip>(
      MaterialPageRoute(builder: (_) => const AddTripScreen()),
    );
    if (trip != null && context.mounted) {
      // Drill straight into the new trip so the user sees the guidance.
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<TripsController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Travels'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addTrip(context),
        icon: const Icon(Icons.add),
        label: const Text('New trip'),
      ),
      body: c.loading
          ? const Center(child: CircularProgressIndicator())
          : c.trips.isEmpty
              ? _EmptyState(onAdd: () => _addTrip(context))
              : _TripList(trips: c.trips),
    );
  }
}

class _TripList extends StatelessWidget {
  final List<Trip> trips;
  const _TripList({required this.trips});

  @override
  Widget build(BuildContext context) {
    final upcoming = trips.where((t) => !t.isPast).toList();
    final past = trips.where((t) => t.isPast).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      children: [
        if (upcoming.isNotEmpty) ...[
          const _SectionHeader('Upcoming'),
          ...upcoming.map((t) => _TripCard(trip: t)),
        ],
        if (past.isNotEmpty) ...[
          const _SectionHeader('Past'),
          ...past.map((t) => _TripCard(trip: t)),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMd();
    final dates = trip.returnDate == null
        ? fmt.format(trip.departureDate)
        : '${fmt.format(trip.departureDate)} – ${fmt.format(trip.returnDate!)}';
    final from = trip.origin == null ? '' : 'From ${trip.origin!.name} · ';

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Text(trip.destination.flag, style: const TextStyle(fontSize: 32)),
        title: Text(trip.destination.name),
        subtitle: Text('$from$dates'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
        ),
        onLongPress: () => _confirmDelete(context),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete trip?'),
        content: Text('Remove your trip to ${trip.destination.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<TripsController>().remove(trip);
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flight_takeoff,
                size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('No trips planned yet',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Add a destination to see what you can and can\'t carry '
              'through customs.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Plan a trip'),
            ),
          ],
        ),
      ),
    );
  }
}
