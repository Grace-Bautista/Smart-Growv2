import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:smart_grow_code/logs/models/harvest_record.dart';

/// Keeps the existing Hive box and record fields; only the presentation changed.
class HarvestLogWidget extends StatefulWidget {
  const HarvestLogWidget({super.key});

  @override
  State<HarvestLogWidget> createState() => _HarvestLogWidgetState();
}

class _HarvestLogWidgetState extends State<HarvestLogWidget> {
  Box? _box;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _openBox();
  }

  Future<void> _openBox() async {
    _box = Hive.isBoxOpen('harvestBox')
        ? Hive.box('harvestBox')
        : await Hive.openBox('harvestBox');
    if (mounted) setState(() => _loading = false);
  }

  List<HarvestRecord> get _records =>
      _box?.values.map(HarvestRecord.fromHive).toList() ?? [];
  double get _grams => _records.fold(0, (sum, item) => sum + item.grams);
  double get _earnings =>
      _records.fold(0, (sum, item) => sum + item.estimatedPrice);

  void _save(HarvestRecord record, int? index) {
    if (index == null) {
      _box?.add(record.toHive());
    } else {
      _box?.putAt(index, record.toHive());
    }
    setState(() {});
  }

  void _delete(int index) {
    _box?.deleteAt(index);
    setState(() {});
  }

  Future<void> _confirmDelete(int index) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete harvest record?'),
        content: const Text('This removes this record from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes == true) _delete(index);
  }

  Future<void> _form({HarvestRecord? existing, int? index}) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final grams = TextEditingController(text: existing?.grams.toString() ?? '');
    final price = TextEditingController(
      text: existing?.estimatedPrice.toString() ?? '',
    );
    var date = existing?.date ?? DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            existing == null ? 'Add Harvest Record' : 'Edit Harvest Record',
          ),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: grams,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Grams',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: price,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Estimated Price (₱)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Harvest date'),
                    subtitle: Text(DateFormat('MMMM d, y').format(date)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setDialogState(() => date = picked);
                    },
                  ),
                ],

              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                _save(
                  HarvestRecord(
                    name: name.text.trim().isEmpty
                        ? 'Unnamed harvest'
                        : name.text.trim(),
                    date: date,
                    grams: double.tryParse(grams.text) ?? 0,
                    estimatedPrice: double.tryParse(price.text) ?? 0,
                  ),
                  index,
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final records = _records;
    return SingleChildScrollView(
      key: const ValueKey('harvest'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Harvest Records',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _form(),
                icon: const Icon(Icons.add),
                label: const Text('Add Record'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth > 650
                  ? (constraints.maxWidth - 24) / 3
                  : constraints.maxWidth > 380
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _Summary(
                    'Total Harvest',
                    '${_grams.toStringAsFixed(1)} g',
                    Icons.agriculture_outlined,
                  ),
                  _Summary(
                    'Estimated Earnings',
                    '₱${_earnings.toStringAsFixed(2)}',
                    Icons.payments_outlined,
                  ),
                  _Summary(
                    'Number of Records',
                    '${records.length}',
                    Icons.receipt_long_outlined,
                  ),
                ].map((item) => SizedBox(width: width, child: item)).toList(),
              );
            },
          ),
          const SizedBox(height: 18),
          if (records.isEmpty)
            const Padding(
              padding: EdgeInsets.all(36),
              child: Center(
                child: Text(
                  'No harvest records yet. Add your first record above.',
                ),
              ),
            )
          else
            ...List.generate(
              records.length,
              (index) => _RecordCard(
                record: records[index],
                onEdit: () => _form(existing: records[index], index: index),
                onDelete: () => _confirmDelete(index),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE0E8E1)),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF537D42)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(label, style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });
  final HarvestRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE0E8E1)),
    ),
    child: Row(
      children: [
        const Icon(Icons.agriculture_outlined, color: Color(0xFF537D42)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${DateFormat('MMM d, y').format(record.date)} · ${record.grams.toStringAsFixed(1)} g · ₱${record.estimatedPrice.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Edit',
        ),
        IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          tooltip: 'Delete',
        ),
      ],
    ),
  );
}
