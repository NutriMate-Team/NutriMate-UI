import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:nutri_mate_ui/config/theme.dart';
import '../../providers/dashboard_provider.dart';

class ActivityLogPage extends StatefulWidget {
  ActivityLogPage({super.key});

  @override
  State<ActivityLogPage> createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends State<ActivityLogPage> {
  late List<ActivityLogEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = [
      ActivityLogEntry(
        id: 'run-${DateTime.now().millisecondsSinceEpoch}',
        dateTime: DateTime.now().subtract(const Duration(minutes: 30)),
        exerciseName: 'Chạy bộ',
        durationMinutes: 30,
        caloriesBurned: 320,
      ),
      ActivityLogEntry(
        id: 'lift-${DateTime.now().millisecondsSinceEpoch - 1}',
        dateTime: DateTime.now().subtract(const Duration(hours: 2)),
        exerciseName: 'Tập tạ',
        durationMinutes: 45,
        caloriesBurned: 380,
      ),
      ActivityLogEntry(
        id: 'bike-${DateTime.now().millisecondsSinceEpoch - 2}',
        dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
        exerciseName: 'Đạp xe',
        durationMinutes: 50,
        caloriesBurned: 420,
      ),
      ActivityLogEntry(
        id: 'yoga-${DateTime.now().millisecondsSinceEpoch - 3}',
        dateTime: DateTime.now().subtract(const Duration(days: 2)),
        exerciseName: 'Yoga',
        durationMinutes: 40,
        caloriesBurned: 180,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final groupedEntries = _groupEntriesByDate(_entries);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhật ký Hoạt động'),
      ),
      body: groupedEntries.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: groupedEntries.length,
              itemBuilder: (context, index) {
                final group = groupedEntries[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...group.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Dismissible(
                            key: ValueKey(entry.id),
                            direction: DismissDirection.endToStart,
                            background: _buildDismissBackground(),
                            confirmDismiss: (_) async => true,
                            onDismissed: (_) => _handleDelete(entry),
                            child: _ActivityLogCard(
                              entry: entry,
                              onEdit: () => _showEditDialog(entry),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: HumanizeUI.asymmetricRadius20,
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: const [
          Icon(Icons.delete_outline, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'Xóa',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _handleDelete(ActivityLogEntry entry) {
    final entryIndex = _entries.indexWhere((item) => item.id == entry.id);
    if (entryIndex == -1) return;

    final removedEntry = _entries.removeAt(entryIndex);
    setState(() {});

    // Sync dashboard summary (Đã đốt) after a deletion
    Provider.of<DashboardProvider>(context, listen: false).fetchSummary();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xóa ${removedEntry.exerciseName}'),
        action: SnackBarAction(
          label: 'Hoàn tác',
          onPressed: () {
            setState(() {
              _entries.insert(entryIndex, removedEntry);
            });
            // Re-sync dashboard summary after undo
            Provider.of<DashboardProvider>(context, listen: false).fetchSummary();
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showEditDialog(ActivityLogEntry entry) {
    final index = _entries.indexWhere((item) => item.id == entry.id);
    if (index == -1) return;

    final durationController =
        TextEditingController(text: entry.durationMinutes.toStringAsFixed(0));
    double currentMinutes = entry.durationMinutes;
    final double caloriesPerMinute =
        entry.durationMinutes <= 0 ? 0 : entry.caloriesBurned / entry.durationMinutes;
    final double caloriesPerHour = caloriesPerMinute * 60;
    double estimatedCalories = entry.caloriesBurned;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) {
          void updateMinutes(double minutes) {
            currentMinutes = minutes.clamp(0, 600);
            durationController.value = durationController.value.copyWith(
              text: currentMinutes.toStringAsFixed(0),
              selection: TextSelection.collapsed(
                offset: currentMinutes.toStringAsFixed(0).length,
              ),
            );
            estimatedCalories = caloriesPerMinute * currentMinutes;
            setStateDialog(() {});
          }

          return AlertDialog(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ghi log: ${entry.exerciseName}'),
                const SizedBox(height: 4),
                Text(
                  '${caloriesPerHour.toStringAsFixed(0)} calo/giờ',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thời lượng (phút)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStepperButton(
                      icon: Icons.remove,
                      onTap: () {
                        final value = double.tryParse(durationController.text) ?? 0;
                        updateMinutes((value - 5).clamp(0, 600));
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          hintText: 'Bạn đã tập bao nhiêu phút?',
                          border: OutlineInputBorder(),
                        ),
                        autofocus: true,
                        onChanged: (value) {
                          final minutes = double.tryParse(value) ?? 0;
                          updateMinutes(minutes);
                        },
                      ),
                    ),
                    _buildStepperButton(
                      icon: Icons.add,
                      onTap: () {
                        final value = double.tryParse(durationController.text) ?? 0;
                        updateMinutes((value + 5).clamp(0, 600));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Calo đốt cháy dự kiến: ${estimatedCalories.toStringAsFixed(0)} calo',
                  style: const TextStyle(
                    color: Color(0xFFFF7043),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                child: const Text(
                  'Hủy',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(
                width: 150,
                child: ElevatedButton(
                  onPressed: () {
                    final minutes = double.tryParse(durationController.text);
                    if (minutes == null || minutes <= 0) return;

                    final updatedEntry = entry.copyWith(
                      durationMinutes: currentMinutes,
                      caloriesBurned: estimatedCalories,
                    );
                    setState(() {
                      _entries[index] = updatedEntry;
                    });

                    // Sync dashboard summary after editing an entry
                    Provider.of<DashboardProvider>(context, listen: false)
                        .fetchSummary();

                    Navigator.of(ctx).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã cập nhật ${entry.exerciseName}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BFA5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Lưu'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepperButton({required IconData icon, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: const Color(0xFFE0F2F1),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Icon(
              icon,
              color: const Color(0xFF00BFA5),
            ),
          ),
        ),
      ),
    );
  }

  List<_GroupedEntries> _groupEntriesByDate(List<ActivityLogEntry> entries) {
    if (entries.isEmpty) return [];

    entries.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    final Map<String, List<ActivityLogEntry>> grouped = {};
    for (final entry in entries) {
      final label = _dateLabelFor(entry.dateTime);
      grouped.putIfAbsent(label, () => []).add(entry);
    }

    return grouped.entries
        .map((e) => _GroupedEntries(label: e.key, entries: e.value))
        .toList();
  }

  String _dateLabelFor(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(
      DateTime(date.year, date.month, date.day),
    );

    if (difference.inDays == 0) return 'Hôm nay';
    if (difference.inDays == 1) return 'Hôm qua';
    if (difference.inDays <= 7) {
      final formatter = DateFormat('EEEE', 'vi');
      return formatter.format(date);
    }

    return DateFormat('dd/MM/yyyy').format(date);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.run_circle_outlined,
              size: 72,
              color: Color(0xFF00BFA5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có hoạt động nào',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy thêm bài tập đầu tiên của bạn để theo dõi lượng calo đã đốt cháy!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Thêm bài tập',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityLogCard extends StatelessWidget {
  final ActivityLogEntry entry;
  final VoidCallback onEdit;

  const _ActivityLogCard({
    required this.entry,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat('HH:mm').format(entry.dateTime);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: HumanizeUI.asymmetricRadius20,
        boxShadow: HumanizeUI.softElevation(
          baseColor: Colors.white,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.directions_run,
                color: Color(0xFF00BFA5),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.exerciseName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$timeLabel • ${entry.durationMinutes.toStringAsFixed(0)} phút',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: Colors.grey,
                  ),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  splashRadius: 20,
                  tooltip: 'Chỉnh sửa',
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Color(0xFFFF7043),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.caloriesBurned.toStringAsFixed(0)} calo',
                      style: const TextStyle(
                        color: Color(0xFFFF7043),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ActivityLogEntry {
  final String id;
  final DateTime dateTime;
  final String exerciseName;
  final double durationMinutes;
  final double caloriesBurned;

  ActivityLogEntry({
    required this.id,
    required this.dateTime,
    required this.exerciseName,
    required this.durationMinutes,
    required this.caloriesBurned,
  });

  ActivityLogEntry copyWith({
    DateTime? dateTime,
    double? durationMinutes,
    double? caloriesBurned,
  }) {
    return ActivityLogEntry(
      id: id,
      dateTime: dateTime ?? this.dateTime,
      exerciseName: exerciseName,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
    );
  }
}

class _GroupedEntries {
  final String label;
  final List<ActivityLogEntry> entries;

  _GroupedEntries({required this.label, required this.entries});
}

