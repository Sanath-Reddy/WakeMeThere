import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/time_alarm_provider.dart';

class TimeAlarmsTab extends ConsumerWidget {
  const TimeAlarmsTab({super.key});

  void _showAddAlarmDialog(BuildContext context, WidgetRef ref) {
    String name = "New Alarm";
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    bool continuousRing = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Add Time Alarm"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(labelText: "Alarm Name"),
                      onChanged: (val) => name = val,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text("Date: ${DateFormat('MMM dd, yyyy').format(selectedDate)}"),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => selectedDate = date);
                        }
                      },
                    ),
                    ListTile(
                      title: Text("Time: ${selectedTime.format(context)}"),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (time != null) {
                          setState(() => selectedTime = time);
                        }
                      },
                    ),
                    SwitchListTile(
                      title: const Text("Continuous Ringing"),
                      subtitle: const Text("Rings for up to 1 min until dismissed"),
                      value: continuousRing,
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                      onChanged: (val) => setState(() => continuousRing = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final scheduledDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );
                    
                    if (scheduledDateTime.isBefore(DateTime.now())) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cannot schedule alarm in the past!')),
                      );
                      return;
                    }

                    ref.read(timeAlarmProvider.notifier).addAlarm(
                      name.isEmpty ? "New Alarm" : name,
                      scheduledDateTime,
                      continuousRing,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarms = ref.watch(timeAlarmProvider);

    return Scaffold(
      body: alarms.isEmpty
          ? const Center(
              child: Text(
                'No time alarms set.\nTap + to add one!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: alarms.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final alarm = alarms[index];
                final isPast = alarm.scheduledDateTime.isBefore(DateTime.now());
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: isPast && !alarm.isActive ? Colors.grey.withValues(alpha: 0.1) : null,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    title: Text(
                      alarm.name, 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 18,
                        decoration: isPast && !alarm.isActive ? TextDecoration.lineThrough : null,
                      )
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Scheduled for: ${DateFormat('MMM dd, yyyy - hh:mm a').format(alarm.scheduledDateTime)}'),
                        if (alarm.continuousRing)
                          const Text('🔔 Continuous Ringing Enabled', style: TextStyle(fontSize: 12, color: Colors.blueAccent)),
                      ],
                    ),
                    trailing: Switch(
                      value: alarm.isActive && !isPast,
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                      onChanged: isPast ? null : (_) {
                        ref.read(timeAlarmProvider.notifier).toggleAlarm(alarm.id);
                      },
                    ),
                    onLongPress: () {
                      ref.read(timeAlarmProvider.notifier).deleteAlarm(alarm.id);
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAlarmDialog(context, ref),
        child: const Icon(Icons.add_alarm),
      ),
    );
  }
}
