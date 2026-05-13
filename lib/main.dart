import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String appName = 'BINET HERVE JACQUES';
const bool screenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = LocalOpsRepository(disabled: screenshotMode);
  final records = screenshotMode ? sampleRecords() : await repository.load();

  runApp(BinetOpsApp(repository: repository, initialRecords: records));
}

class BinetOpsApp extends StatelessWidget {
  const BinetOpsApp({
    required this.repository,
    required this.initialRecords,
    super.key,
  });

  final OpsRepository repository;
  final List<OpsRecord> initialRecords;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: OperationsShell(
        repository: repository,
        initialRecords: initialRecords,
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BinetOpsApp(
      repository: MemoryOpsRepository(),
      initialRecords: sampleRecords(),
    );
  }
}

ThemeData _buildTheme() {
  const primary = Color(0xFF315F95);
  const secondary = Color(0xFF2F766D);
  const tertiary = Color(0xFFB66B2E);
  const surface = Color(0xFFF7F9FC);

  final scheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.light,
    primary: primary,
    secondary: secondary,
    tertiary: tertiary,
    surface: surface,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: surface,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: surface,
      foregroundColor: Color(0xFF172033),
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Color(0xFF172033),
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: secondary.withValues(alpha: 0.16),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected ? primary : const Color(0xFF5B6678),
        );
      }),
    ),
  );
}

enum OperationArea { tasks, inventory, maintenance, visitors }

extension OperationAreaDetails on OperationArea {
  String get storageKey => name;

  String get label {
    switch (this) {
      case OperationArea.tasks:
        return 'Tasks';
      case OperationArea.inventory:
        return 'Stock';
      case OperationArea.maintenance:
        return 'Maint';
      case OperationArea.visitors:
        return 'Visits';
    }
  }

  String get fullLabel {
    switch (this) {
      case OperationArea.tasks:
        return 'Task management';
      case OperationArea.inventory:
        return 'Inventory tracking';
      case OperationArea.maintenance:
        return 'Maintenance requests';
      case OperationArea.visitors:
        return 'Visitor management';
    }
  }

  String get emptyTitle {
    switch (this) {
      case OperationArea.tasks:
        return 'No tasks yet';
      case OperationArea.inventory:
        return 'No stock items yet';
      case OperationArea.maintenance:
        return 'No requests yet';
      case OperationArea.visitors:
        return 'No visitors logged';
    }
  }

  IconData get icon {
    switch (this) {
      case OperationArea.tasks:
        return Icons.checklist_rounded;
      case OperationArea.inventory:
        return Icons.inventory_2_rounded;
      case OperationArea.maintenance:
        return Icons.handyman_rounded;
      case OperationArea.visitors:
        return Icons.badge_rounded;
    }
  }

  Color accent(ColorScheme scheme) {
    switch (this) {
      case OperationArea.tasks:
        return scheme.primary;
      case OperationArea.inventory:
        return scheme.secondary;
      case OperationArea.maintenance:
        return scheme.tertiary;
      case OperationArea.visitors:
        return const Color(0xFF5B4CA8);
    }
  }

  static OperationArea fromStorage(String value) {
    return OperationArea.values.firstWhere(
      (area) => area.storageKey == value,
      orElse: () => OperationArea.tasks,
    );
  }
}

class OpsRecord {
  const OpsRecord({
    required this.id,
    required this.area,
    required this.title,
    required this.detail,
    required this.owner,
    required this.status,
    required this.priority,
    required this.schedule,
    required this.metric,
    required this.createdAt,
  });

  final String id;
  final OperationArea area;
  final String title;
  final String detail;
  final String owner;
  final String status;
  final String priority;
  final String schedule;
  final String metric;
  final DateTime createdAt;

  bool get isClosed => status == 'Done' || status == 'Cleared';
  bool get needsAttention => priority == 'High' || status == 'Blocked';

  OpsRecord copyWith({String? status, String? priority, String? schedule}) {
    return OpsRecord(
      id: id,
      area: area,
      title: title,
      detail: detail,
      owner: owner,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      schedule: schedule ?? this.schedule,
      metric: metric,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'area': area.storageKey,
      'title': title,
      'detail': detail,
      'owner': owner,
      'status': status,
      'priority': priority,
      'schedule': schedule,
      'metric': metric,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OpsRecord.fromJson(Map<String, Object?> json) {
    return OpsRecord(
      id:
          json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      area: OperationAreaDetails.fromStorage(json['area'] as String? ?? ''),
      title: json['title'] as String? ?? 'Untitled record',
      detail: json['detail'] as String? ?? '',
      owner: json['owner'] as String? ?? 'Unassigned',
      status: json['status'] as String? ?? 'Open',
      priority: json['priority'] as String? ?? 'Normal',
      schedule: json['schedule'] as String? ?? 'Today',
      metric: json['metric'] as String? ?? '1 item',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

abstract class OpsRepository {
  Future<List<OpsRecord>> load();

  Future<void> save(List<OpsRecord> records);
}

class LocalOpsRepository implements OpsRepository {
  const LocalOpsRepository({this.disabled = false});

  static const _storageKey = 'binet_ops_records';
  final bool disabled;

  @override
  Future<List<OpsRecord>> load() async {
    if (disabled) {
      return sampleRecords();
    }
    final preferences = await SharedPreferences.getInstance();
    final payload = preferences.getString(_storageKey);
    if (payload == null || payload.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(payload) as List<dynamic>;
    return decoded
        .whereType<Map<String, Object?>>()
        .map(OpsRecord.fromJson)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> save(List<OpsRecord> records) async {
    if (disabled) {
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      records.map((record) => record.toJson()).toList(),
    );
    await preferences.setString(_storageKey, encoded);
  }
}

class MemoryOpsRepository implements OpsRepository {
  MemoryOpsRepository([List<OpsRecord>? seed])
    : _records = List.of(seed ?? const []);

  List<OpsRecord> _records;

  @override
  Future<List<OpsRecord>> load() async => List.of(_records);

  @override
  Future<void> save(List<OpsRecord> records) async {
    _records = List.of(records);
  }
}

List<OpsRecord> sampleRecords() {
  final now = DateTime(2026, 5, 12, 9);
  return [
    OpsRecord(
      id: 'task-floor-open',
      area: OperationArea.tasks,
      title: 'Prepare south floor opening',
      detail:
          'Assign cleaning, counter checks, and morning handover notes before doors open.',
      owner: 'Aline',
      status: 'In progress',
      priority: 'High',
      schedule: 'Today 08:30',
      metric: '6 checkpoints',
      createdAt: now,
    ),
    OpsRecord(
      id: 'task-vendor-close',
      area: OperationArea.tasks,
      title: 'Confirm supplier delivery window',
      detail:
          'Call the supplier and attach the receiving slot to the operations board.',
      owner: 'Marc',
      status: 'Open',
      priority: 'Normal',
      schedule: 'Today 11:00',
      metric: '1 call',
      createdAt: now.subtract(const Duration(minutes: 8)),
    ),
    OpsRecord(
      id: 'inventory-gloves',
      area: OperationArea.inventory,
      title: 'Nitrile gloves',
      detail: 'Box count is below the reorder mark for the maintenance closet.',
      owner: 'Stock room',
      status: 'Low stock',
      priority: 'High',
      schedule: 'Reorder today',
      metric: '18 boxes',
      createdAt: now.subtract(const Duration(minutes: 16)),
    ),
    OpsRecord(
      id: 'inventory-badges',
      area: OperationArea.inventory,
      title: 'Visitor badge cards',
      detail:
          'Enough stock for planned visits this week. Recount after Friday reception.',
      owner: 'Front desk',
      status: 'Available',
      priority: 'Normal',
      schedule: 'Review Friday',
      metric: '240 cards',
      createdAt: now.subtract(const Duration(minutes: 30)),
    ),
    OpsRecord(
      id: 'maintenance-hvac',
      area: OperationArea.maintenance,
      title: 'HVAC alert in meeting room B',
      detail:
          'Temperature drift reported twice. Technician visit assigned for the afternoon.',
      owner: 'Facilities',
      status: 'Scheduled',
      priority: 'High',
      schedule: 'Today 14:00',
      metric: 'Room B',
      createdAt: now.subtract(const Duration(minutes: 44)),
    ),
    OpsRecord(
      id: 'maintenance-door',
      area: OperationArea.maintenance,
      title: 'North loading door sensor',
      detail:
          'Sensor sometimes misses close events. Watch during next receiving run.',
      owner: 'Security',
      status: 'Watching',
      priority: 'Normal',
      schedule: 'Tomorrow',
      metric: 'Gate 3',
      createdAt: now.subtract(const Duration(hours: 1)),
    ),
    OpsRecord(
      id: 'visitor-audit',
      area: OperationArea.visitors,
      title: 'Audit partner visit',
      detail:
          'Two visitors expected for document review. Front desk packet is ready.',
      owner: 'Reception',
      status: 'Expected',
      priority: 'Normal',
      schedule: 'Today 15:30',
      metric: '2 guests',
      createdAt: now.subtract(const Duration(hours: 2)),
    ),
    OpsRecord(
      id: 'visitor-contractor',
      area: OperationArea.visitors,
      title: 'Electrical contractor',
      detail: 'Temporary badge and escort required for panel inspection.',
      owner: 'Facilities',
      status: 'Checked in',
      priority: 'High',
      schedule: 'On site',
      metric: '1 guest',
      createdAt: now.subtract(const Duration(hours: 3)),
    ),
  ];
}

class OperationsShell extends StatefulWidget {
  const OperationsShell({
    required this.repository,
    required this.initialRecords,
    super.key,
  });

  final OpsRepository repository;
  final List<OpsRecord> initialRecords;

  @override
  State<OperationsShell> createState() => _OperationsShellState();
}

class _OperationsShellState extends State<OperationsShell> {
  late List<OpsRecord> _records;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _records = List.of(widget.initialRecords)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  OperationArea get _currentArea {
    switch (_selectedIndex) {
      case 1:
        return OperationArea.tasks;
      case 2:
        return OperationArea.inventory;
      case 3:
        return OperationArea.maintenance;
      case 4:
        return OperationArea.visitors;
      default:
        return OperationArea.tasks;
    }
  }

  Future<void> _persist() async {
    await widget.repository.save(_records);
  }

  void _upsertRecord(OpsRecord record) {
    setState(() {
      final index = _records.indexWhere((existing) => existing.id == record.id);
      if (index == -1) {
        _records = [record, ..._records];
      } else {
        _records = List.of(_records)..[index] = record;
      }
    });
    _persist();
  }

  void _deleteRecord(OpsRecord record) {
    setState(() {
      _records = _records
          .where((existing) => existing.id != record.id)
          .toList();
    });
    _persist();
    Navigator.of(context).maybePop();
  }

  Future<void> _openRecordSheet([OperationArea? area]) async {
    final created = await showModalBottomSheet<OpsRecord>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return AddRecordSheet(initialArea: area ?? _currentArea);
      },
    );
    if (created != null) {
      _upsertRecord(created);
    }
  }

  void _openDetail(OpsRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return RecordDetailPage(
            record: record,
            onUpdate: _upsertRecord,
            onDelete: _deleteRecord,
          );
        },
      ),
    );
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => const SettingsPage()));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      OverviewPage(
        records: _records,
        onCreate: _openRecordSheet,
        onOpenRecord: _openDetail,
      ),
      AreaPage(
        area: OperationArea.tasks,
        records: _records,
        onOpenRecord: _openDetail,
      ),
      AreaPage(
        area: OperationArea.inventory,
        records: _records,
        onOpenRecord: _openDetail,
      ),
      AreaPage(
        area: OperationArea.maintenance,
        records: _records,
        onOpenRecord: _openDetail,
      ),
      AreaPage(
        area: OperationArea.visitors,
        records: _records,
        onOpenRecord: _openDetail,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(appName),
        actions: [
          IconButton(
            key: const Key('settings-button'),
            tooltip: 'Settings and privacy',
            onPressed: _openSettings,
            icon: const Icon(Icons.admin_panel_settings_rounded),
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      floatingActionButton: _selectedIndex == 0
          ? null
          : FloatingActionButton.extended(
              key: const Key('add-record-fab'),
              onPressed: () => _openRecordSheet(_currentArea),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add'),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist_rounded),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Icon(Icons.handyman_outlined),
            selectedIcon: Icon(Icons.handyman_rounded),
            label: 'Maint',
          ),
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge_rounded),
            label: 'Visits',
          ),
        ],
      ),
    );
  }
}

class OverviewPage extends StatelessWidget {
  const OverviewPage({
    required this.records,
    required this.onCreate,
    required this.onOpenRecord,
    super.key,
  });

  final List<OpsRecord> records;
  final ValueChanged<OperationArea> onCreate;
  final ValueChanged<OpsRecord> onOpenRecord;

  @override
  Widget build(BuildContext context) {
    final active = records.where((record) => !record.isClosed).toList();
    final urgent = records.where((record) => record.needsAttention).length;
    final today = records
        .where((record) => record.schedule.toLowerCase().contains('today'))
        .length;

    return ListView(
      key: const Key('home-page'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _CommandHeader(activeCount: active.length, urgentCount: urgent),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Active',
                value: active.length.toString(),
                icon: Icons.timeline_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'Today',
                value: today.toString(),
                icon: Icons.today_rounded,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'Priority',
                value: urgent.toString(),
                icon: Icons.priority_high_rounded,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Create a record',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: OperationArea.values.map((area) {
            return ActionChip(
              avatar: Icon(area.icon, size: 18),
              label: Text(area.fullLabel),
              onPressed: () => onCreate(area),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        SectionTitle(
          title: 'Operations board',
          trailing: '${active.length} open',
        ),
        const SizedBox(height: 10),
        if (records.isEmpty)
          const EmptyState(
            title: 'Start with the first operation record',
            message:
                'Add a task, stock item, request, or visitor entry for the current workday.',
          )
        else
          ...records
              .take(5)
              .map(
                (record) => RecordCard(
                  record: record,
                  onTap: () => onOpenRecord(record),
                ),
              ),
      ],
    );
  }
}

class _CommandHeader extends StatelessWidget {
  const _CommandHeader({required this.activeCount, required this.urgentCount});

  final int activeCount;
  final int urgentCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFF315F95), Color(0xFF2F766D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Daily operations',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Keep tasks, stock, maintenance, and visitors in one local command view.',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeaderMetric(
                value: activeCount.toString(),
                label: 'active records',
                icon: Icons.assignment_turned_in_rounded,
              ),
              const SizedBox(width: 12),
              _HeaderMetric(
                value: urgentCount.toString(),
                label: 'need attention',
                icon: Icons.report_problem_rounded,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Stored on this device only.',
            style: TextStyle(
              color: scheme.onPrimary.withValues(alpha: 0.82),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AreaPage extends StatelessWidget {
  const AreaPage({
    required this.area,
    required this.records,
    required this.onOpenRecord,
    super.key,
  });

  final OperationArea area;
  final List<OpsRecord> records;
  final ValueChanged<OpsRecord> onOpenRecord;

  @override
  Widget build(BuildContext context) {
    final filtered = records.where((record) => record.area == area).toList();
    final active = filtered.where((record) => !record.isClosed).length;
    final attention = filtered.where((record) => record.needsAttention).length;
    final accent = area.accent(Theme.of(context).colorScheme);

    return ListView(
      key: Key('${area.storageKey}-page'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(area.icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      area.fullLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$active active, $attention priority',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF5B6678),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionTitle(
          title: '${area.label} board',
          trailing: '${filtered.length} total',
        ),
        const SizedBox(height: 10),
        if (filtered.isEmpty)
          EmptyState(
            title: area.emptyTitle,
            message:
                'Tap Add to save the first ${area.fullLabel.toLowerCase()} record.',
          )
        else
          ...filtered.map(
            (record) =>
                RecordCard(record: record, onTap: () => onOpenRecord(record)),
          ),
      ],
    );
  }
}

class RecordCard extends StatelessWidget {
  const RecordCard({required this.record, required this.onTap, super.key});

  final OpsRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = record.area.accent(scheme);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(record.area.icon, color: accent, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          record.detail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF5B6678)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusPill(label: record.status, color: accent),
                  StatusPill(
                    label: record.priority,
                    color: _priorityColor(record.priority, scheme),
                  ),
                  StatusPill(
                    label: record.schedule,
                    color: const Color(0xFF5B6678),
                  ),
                  StatusPill(label: record.metric, color: scheme.secondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecordDetailPage extends StatefulWidget {
  const RecordDetailPage({
    required this.record,
    required this.onUpdate,
    required this.onDelete,
    super.key,
  });

  final OpsRecord record;
  final ValueChanged<OpsRecord> onUpdate;
  final ValueChanged<OpsRecord> onDelete;

  @override
  State<RecordDetailPage> createState() => _RecordDetailPageState();
}

class _RecordDetailPageState extends State<RecordDetailPage> {
  late OpsRecord _record;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _record.area.accent(scheme);

    return Scaffold(
      appBar: AppBar(
        title: Text(_record.area.fullLabel),
        actions: [
          IconButton(
            tooltip: 'Delete record',
            onPressed: () => widget.onDelete(_record),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_record.area.icon, color: accent, size: 34),
                const SizedBox(height: 16),
                Text(
                  _record.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _record.detail,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(height: 1.45),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusPill(label: _record.owner, color: scheme.primary),
                    StatusPill(label: _record.status, color: accent),
                    StatusPill(
                      label: _record.priority,
                      color: _priorityColor(_record.priority, scheme),
                    ),
                    StatusPill(label: _record.metric, color: scheme.secondary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status controls',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Open', label: Text('Open')),
                      ButtonSegment(
                        value: 'In progress',
                        label: Text('Active'),
                      ),
                      ButtonSegment(value: 'Done', label: Text('Done')),
                    ],
                    selected: {_statusBucket(_record.status)},
                    onSelectionChanged: (selection) {
                      final status = selection.first;
                      final updated = _record.copyWith(status: status);
                      setState(() => _record = updated);
                      widget.onUpdate(updated);
                    },
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule_rounded),
                    title: const Text('Schedule'),
                    subtitle: Text(_record.schedule),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person_outline_rounded),
                    title: const Text('Owner'),
                    subtitle: Text(_record.owner),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _statusBucket(String status) {
  if (status == 'Done' || status == 'Cleared') {
    return 'Done';
  }
  if (status == 'Open' || status == 'Expected') {
    return 'Open';
  }
  return 'In progress';
}

class AddRecordSheet extends StatefulWidget {
  const AddRecordSheet({required this.initialArea, super.key});

  final OperationArea initialArea;

  @override
  State<AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends State<AddRecordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailController = TextEditingController();
  final _ownerController = TextEditingController();
  final _metricController = TextEditingController();
  final _scheduleController = TextEditingController(text: 'Today');
  late OperationArea _area;
  String _priority = 'Normal';
  String _status = 'Open';

  @override
  void initState() {
    super.initState();
    _area = widget.initialArea;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    _ownerController.dispose();
    _metricController.dispose();
    _scheduleController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final now = DateTime.now();
    Navigator.of(context).pop(
      OpsRecord(
        id: 'record-${now.microsecondsSinceEpoch}',
        area: _area,
        title: _titleController.text.trim(),
        detail: _detailController.text.trim(),
        owner: _ownerController.text.trim(),
        status: _status,
        priority: _priority,
        schedule: _scheduleController.text.trim(),
        metric: _metricController.text.trim(),
        createdAt: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Add operation record',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<OperationArea>(
                key: const Key('record-area-field'),
                initialValue: _area,
                decoration: const InputDecoration(labelText: 'Record type'),
                items: OperationArea.values
                    .map(
                      (area) => DropdownMenuItem(
                        value: area,
                        child: Text(area.fullLabel),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _area = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('record-title-field'),
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('record-detail-field'),
                controller: _detailController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter the local work note';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('record-owner-field'),
                      controller: _ownerController,
                      decoration: const InputDecoration(
                        labelText: 'Owner',
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      key: const Key('record-metric-field'),
                      controller: _metricController,
                      decoration: const InputDecoration(
                        labelText: 'Metric',
                        prefixIcon: Icon(Icons.pin_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('record-schedule-field'),
                controller: _scheduleController,
                decoration: const InputDecoration(
                  labelText: 'Schedule',
                  prefixIcon: Icon(Icons.event_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _priority,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: const ['Normal', 'High']
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _priority = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items:
                          const [
                                'Open',
                                'In progress',
                                'Scheduled',
                                'Expected',
                                'Done',
                              ]
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _status = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('save-record-button'),
                  onPressed: _save,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save record'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        key: const Key('settings-page'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Local workspace',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Records are kept on this Android device. There is no account sign-in, cloud sync, analytics, advertising, or external service connection.',
                    style: TextStyle(height: 1.45),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const SettingsTile(
            icon: Icons.lock_rounded,
            title: 'Privacy',
            value: 'No data collection',
          ),
          const SettingsTile(
            icon: Icons.storage_rounded,
            title: 'Storage',
            value: 'SharedPreferences local app storage',
          ),
          const SettingsTile(
            icon: Icons.business_rounded,
            title: 'Company',
            value: appName,
          ),
          const SettingsTile(
            icon: Icons.mail_outline_rounded,
            title: 'Support',
            value: 'support@binethervejacques.com',
          ),
        ],
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.icon,
    required this.title,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF5B6678),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({required this.title, required this.trailing, super.key});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        Text(
          trailing,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: const Color(0xFF5B6678),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({required this.title, required this.message, super.key});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(
              Icons.inbox_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF5B6678), height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

Color _priorityColor(String priority, ColorScheme scheme) {
  if (priority == 'High') {
    return scheme.tertiary;
  }
  return scheme.primary;
}
