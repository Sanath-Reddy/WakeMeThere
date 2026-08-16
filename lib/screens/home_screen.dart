import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/alarm_provider.dart';

import 'time_alarms_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  Widget _buildGeoAlarmsTab() {
    final alarms = ref.watch(alarmProvider);
    return Scaffold(
      body: alarms.isEmpty
          ? const Center(
              child: Text(
                'No geo alarms set.\nTap + to add one!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: alarms.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final alarm = alarms[index];
                final isExpired = alarm.validTo != null && DateTime.now().isAfter(alarm.validTo!);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: isExpired && !alarm.isActive ? Colors.grey.withValues(alpha: 0.1) : null,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    title: Text(
                      alarm.name, 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 18,
                        decoration: isExpired && !alarm.isActive ? TextDecoration.lineThrough : null,
                      )
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Radius: ${alarm.radiusInMeters.toInt()}m'),
                        if (alarm.validFrom != null && alarm.validTo != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Valid: ${DateFormat('MMM dd, HH:mm').format(alarm.validFrom!)} - ${DateFormat('MMM dd, HH:mm').format(alarm.validTo!)}',
                            style: const TextStyle(fontSize: 12, color: Colors.blueAccent),
                          ),
                        ]
                      ],
                    ),
                    trailing: Switch(
                      value: alarm.isActive && !isExpired,
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                      onChanged: isExpired ? null : (_) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Geo Alarms' : 'Time Alarms'),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildGeoAlarmsTab(),
          const TimeAlarmsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Geo Alarms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Time Alarms',
          ),
        ],
      ),
    );
  }
}
