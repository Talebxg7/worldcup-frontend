import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';

class AddMatchScreen extends ConsumerStatefulWidget {
  const AddMatchScreen({super.key});

  @override
  ConsumerState<AddMatchScreen> createState() => _AddMatchScreenState();
}

class _AddMatchScreenState extends ConsumerState<AddMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _homeTeamCtrl = TextEditingController();
  final _awayTeamCtrl = TextEditingController();
  final _homeFlagCtrl = TextEditingController();
  final _awayFlagCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();

  String _selectedStage = AppConstants.stages[0];
  String? _selectedGroup;
  DateTime? _kickoffTime;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _homeTeamCtrl.dispose();
    _awayTeamCtrl.dispose();
    _homeFlagCtrl.dispose();
    _awayFlagCtrl.dispose();
    _venueCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime(2026, 6, 1),
      lastDate: DateTime(2026, 7, 31),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
    );
    if (time == null) return;

    setState(() {
      _kickoffTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _addMatch() async {
    if (!_formKey.currentState!.validate()) return;
    if (_kickoffTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select kickoff time')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ApiClient.instance.post('/matches', data: {
        'home_team': _homeTeamCtrl.text.trim(),
        'away_team': _awayTeamCtrl.text.trim(),
        'home_team_flag': _homeFlagCtrl.text.trim(),
        'away_team_flag': _awayFlagCtrl.text.trim(),
        'venue': _venueCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'country': _countryCtrl.text.isEmpty ? 'United States' : _countryCtrl.text.trim(),
        'kickoff_time': _kickoffTime!.toUtc().toIso8601String(),
        'stage': _selectedStage,
        'group': _selectedGroup,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Match added successfully! ✅'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d, yyyy • HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Match'),
        centerTitle: true,
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Teams section
              _SectionTitle('Teams'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _homeTeamCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Home Team *',
                        hintText: 'e.g., Brazil',
                      ),
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      controller: _homeFlagCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Flag',
                        hintText: '🇧🇷',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _awayTeamCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Away Team *',
                        hintText: 'e.g., Argentina',
                      ),
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      controller: _awayFlagCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Flag',
                        hintText: '🇦🇷',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _SectionTitle('Match Info'),
              const SizedBox(height: 12),

              // Stage picker
              DropdownButtonFormField<String>(
                value: _selectedStage,
                decoration: const InputDecoration(labelText: 'Stage *'),
                items: AppConstants.stages
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _selectedStage = v!;
                  if (v != 'Group Stage') _selectedGroup = null;
                }),
              ),

              if (_selectedStage == 'Group Stage') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedGroup,
                  decoration: const InputDecoration(labelText: 'Group'),
                  items: AppConstants.groups
                      .map((g) => DropdownMenuItem(value: g, child: Text('Group $g')))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedGroup = v),
                ),
              ],

              const SizedBox(height: 12),

              // Kickoff time picker
              GestureDetector(
                onTap: _pickDateTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _kickoffTime == null
                          ? Theme.of(context).inputDecorationTheme.enabledBorder!.borderSide.color
                          : AppColors.primary,
                      width: _kickoffTime == null ? 1 : 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: _kickoffTime == null ? Colors.grey : AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _kickoffTime == null
                            ? 'Select Kickoff Time *'
                            : dateFormat.format(_kickoffTime!),
                        style: TextStyle(
                          color: _kickoffTime == null
                              ? Colors.grey
                              : Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight: _kickoffTime != null ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.edit_calendar_outlined,
                          color: _kickoffTime == null ? Colors.grey : AppColors.primary),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              _SectionTitle('Venue'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _venueCtrl,
                decoration: const InputDecoration(
                  labelText: 'Stadium / Venue *',
                  hintText: 'e.g., MetLife Stadium',
                  prefixIcon: Icon(Icons.stadium_rounded),
                ),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'City *',
                        hintText: 'New York',
                      ),
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _countryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        hintText: 'USA',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _addMatch,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add_circle_rounded, color: Colors.white),
                  label: const Text(
                    'Add Match',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        letterSpacing: 0.5,
      ),
    );
  }
}
