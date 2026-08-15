import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/alarm_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarms = ref.watch(alarmProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Geo Alarms'),
      ),
      body: alarms.isEmpty
          ? const Center(
              child: Text(
                'No alarms set.\nTap + to add one!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: alarms.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final alarm = alarms[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    title: Text(alarm.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text('Radius: ${alarm.radiusInMeters.toInt()}m'),
                    trailing: Switch(
                      value: alarm.isActive,
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                      onChanged: (_) {
                        ref.read(alarmProvider.notifier).toggleAlarm(alarm.id);
                      },
                    ),
                    onLongPress: () {
                      ref.read(alarmProvider.notifier).deleteAlarm(alarm.id);
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/map'),
        child: const Icon(Icons.add_location_alt),
      ),
    );
  }
}
