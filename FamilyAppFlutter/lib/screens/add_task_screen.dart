import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/task.dart';
import '../providers/family_data.dart';
import '../services/geo_service.dart';

/// Screen for adding a new task. Users can provide title, description,
/// due date, assignee and status.
class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  static const String routeName = 'AddTaskScreen';

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  final GeoService _geoService = const GeoService();

  DateTime? _dueDate;
  TaskStatus _status = TaskStatus.todo;
  String? _assigneeId;
  bool _reminderEnabled = false;
  bool _geoReminderEnabled = false;
  double _radiusMeters = 150;
  double? _latitude;
  double? _longitude;

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final initialDate = _dueDate ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (!mounted || date == null) return;
    final timeOfDay = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate ?? now),
    );
    if (!mounted) return;
    setState(() {
      _dueDate = DateTime(
        date.year,
        date.month,
        date.day,
        timeOfDay?.hour ?? initialDate.hour,
        timeOfDay?.minute ?? initialDate.minute,
      );
    });
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    if (_geoReminderEnabled && (_latitude == null || _longitude == null)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('taskGeoReminderMissingLocation'))),
        );
      }
      return;
    }
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final pointsValue = int.tryParse(_pointsController.text.trim());
    final String locationLabel = _locationController.text.trim();

    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description.isEmpty ? null : description,
      dueDate: _dueDate,
      status: _status,
      assigneeId: _assigneeId,
      points: pointsValue,
      reminderEnabled: _reminderEnabled,
      locationLabel:
          _geoReminderEnabled && locationLabel.isNotEmpty ? locationLabel : null,
      latitude: _geoReminderEnabled ? _latitude : null,
      longitude: _geoReminderEnabled ? _longitude : null,
      radiusMeters: _geoReminderEnabled ? _radiusMeters : null,
    );

    await context.read<FamilyData>().addTask(task);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final members = context.watch<FamilyData>().members;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('addTaskTitle'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: context.tr('taskTitleLabel')),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.tr('validationEnterTitle');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: context.tr('taskDescriptionLabel')),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.tr('taskDueDate')),
                  subtitle: Text(
                    _dueDate == null
                        ? context.tr('dateNotSet')
                        : context.loc.formatDate(_dueDate!, withTime: true),
                  ),
                  trailing: IconButton(
                    onPressed: _pickDueDate,
                    icon: const Icon(Icons.calendar_today),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TaskStatus>(

                  initialValue: _status,

                  decoration: InputDecoration(labelText: context.tr('taskStatusLabel')),
                  items: TaskStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(context.tr('taskStatus.${status.name}')),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _status = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(

                  initialValue: _assigneeId,

                  decoration: InputDecoration(labelText: context.tr('assignToLabel')),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('—'),
                    ),
                    ...members.map(
                      (member) => DropdownMenuItem<String?>(
                        value: member.id,
                        child: Text(member.name ?? context.tr('noNameLabel')),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _assigneeId = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pointsController,
                  decoration: InputDecoration(
                    labelText: context.tr('rewardPointsLabel'),
                    hintText: context.tr('rewardPointsHint'),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  value: _reminderEnabled,
                  onChanged: (value) => setState(() => _reminderEnabled = value),
                  title: Text(context.tr('taskTimeReminderToggle')),
                  subtitle: Text(context.tr('taskTimeReminderDescription')),
                ),
                SwitchListTile.adaptive(
                  value: _geoReminderEnabled,
                  onChanged: (value) {
                    setState(() {
                      _geoReminderEnabled = value;
                      if (!value) {
                        _latitude = null;
                        _longitude = null;
                      }
                    });
                  },
                  title: Text(context.tr('taskGeoReminderToggle')),
                  subtitle: Text(context.tr('taskGeoReminderDescription')),
                ),
                if (_geoReminderEnabled) ...[
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: context.tr('taskLocationLabel'),
                      hintText: context.tr('taskLocationHint'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.loc.taskRadiusMeters(_radiusMeters.toInt()),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _radiusMeters,
                          min: 50,
                          max: 1000,
                          divisions: 19,
                          label: '${_radiusMeters.toInt()}m',
                          onChanged: (value) {
                            setState(() => _radiusMeters = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _useCurrentLocation,
                      icon: const Icon(Icons.my_location),
                      label: Text(context.tr('taskUseCurrentLocation')),
                    ),
                  ),
                  if (_latitude != null && _longitude != null)
                    Text(
                      '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: Text(context.tr('saveAction')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    final position = await _geoService.getCurrentPosition();
    if (!mounted) return;
    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('locationPermissionDeniedMessage')),
          action: SnackBarAction(
            label: context.tr('openSettingsAction'),
            onPressed: Geolocator.openAppSettings,
          ),
        ),
      );
      return;
    }
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
    });
  }
}
