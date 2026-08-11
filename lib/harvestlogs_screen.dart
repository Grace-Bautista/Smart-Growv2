import 'package:flutter/material.dart';
import '../../services/harvest_log_service.dart';

class HarvestLogWidget extends StatefulWidget {
  const HarvestLogWidget({super.key});

  @override
  State<HarvestLogWidget> createState() => _HarvestLogWidgetState();
}

class _HarvestLogWidgetState extends State<HarvestLogWidget> {
  final HarvestLogService _harvestService = HarvestLogService();

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  double _number(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _totalGrams(List<Map<String, dynamic>> records) {
    return records.fold<double>(0, (sum, record) {
      return sum + _number(record['grams']);
    });
  }

  double _totalEarnings(List<Map<String, dynamic>> records) {
    return records.fold<double>(0, (sum, record) {
      return sum + _number(record['price']);
    });
  }

  bool _isToday(String date) {
    final parsed = DateTime.tryParse(date);

    if (parsed == null) {
      return false;
    }

    final now = DateTime.now();

    return parsed.year == now.year &&
        parsed.month == now.month &&
        parsed.day == now.day;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Something went wrong: $error'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  // ------------------------------------------------------------
  // ADD / EDIT
  // ------------------------------------------------------------

  Future<void> _showForm({Map<String, dynamic>? existing}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return _HarvestFormDialog(existing: existing);
      },
    );

    if (!mounted || result == null) {
      return;
    }

    try {
      if (existing == null) {
        await _harvestService.addHarvest(result);
      } else {
        final id = existing['_id']?.toString();

        if (id == null || id.isEmpty) {
          throw Exception('Harvest record ID is missing.');
        }

        await _harvestService.updateHarvest(id: id, record: result);
      }

      if (!mounted) {
        return;
      }

      _showMessage(
        existing == null ? 'Harvest record added.' : 'Harvest record updated.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(error);
    }
  }

  // ------------------------------------------------------------
  // DELETE
  // ------------------------------------------------------------

  Future<void> _deleteRecord(Map<String, dynamic> record) async {
    final id = record['_id']?.toString();

    if (id == null || id.isEmpty) {
      _showMessage('Unable to identify this harvest record.');
      return;
    }

    final name = record['name']?.toString() ?? 'this harvest record';

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Harvest Record'),
          content: Text('Are you sure you want to delete "$name"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await _harvestService.deleteHarvest(id);

      if (!mounted) {
        return;
      }

      _showMessage('Harvest record deleted.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(error);
    }
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _harvestService.watchHarvestLogs(),
      builder: (context, snapshot) {
        // ------------------------------------------------------
        // LOADING
        // ------------------------------------------------------

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2.5),
          );
        }

        // ------------------------------------------------------
        // ERROR
        // ------------------------------------------------------

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 46,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Unable to load harvest records',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF373431),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF77736D),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final records = snapshot.data ?? [];

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ------------------------------------------------
              // HEADER
              // ------------------------------------------------
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Harvest Records',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF373431),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Record harvested weight and estimated earnings.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF77736D),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  FilledButton.icon(
                    onPressed: () {
                      _showForm();
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Record'),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ------------------------------------------------
              // SUMMARY
              // ------------------------------------------------
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.scale_outlined,
                      label: 'Total Harvest',
                      value: '${_totalGrams(records).toStringAsFixed(2)} g',
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.payments_outlined,
                      label: 'Total Earnings',
                      value: '₱${_totalEarnings(records).toStringAsFixed(2)}',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ------------------------------------------------
              // RECORDS
              // ------------------------------------------------
              if (records.isEmpty)
                const _EmptyHarvestState()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: records.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final record = records[index];

                    return _HarvestRecordCard(
                      record: record,
                      onEdit: () {
                        _showForm(existing: record);
                      },
                      onDelete: () {
                        _deleteRecord(record);
                      },
                      isToday: _isToday(record['date']?.toString() ?? ''),
                    );
                  },
                ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class _HarvestFormDialog extends StatefulWidget {
  const _HarvestFormDialog({this.existing});

  final Map<String, dynamic>? existing;

  @override
  State<_HarvestFormDialog> createState() => _HarvestFormDialogState();
}

class _HarvestFormDialogState extends State<_HarvestFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _gramsController;
  late final TextEditingController _priceController;

  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;

    _nameController = TextEditingController(
      text: existing?['name']?.toString() ?? '',
    );

    _gramsController = TextEditingController(
      text: existing?['grams']?.toString() ?? '',
    );

    _priceController = TextEditingController(
      text: existing?['price']?.toString() ?? '',
    );

    _selectedDate =
        DateTime.tryParse(existing?['date']?.toString() ?? '') ??
        DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gramsController.dispose();
    _priceController.dispose();

    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final initialDate = _selectedDate.isAfter(now) ? now : _selectedDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: now,
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = picked;
    });
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.of(context).pop({
      'name': _nameController.text.trim(),
      'date': _dateOnly(_selectedDate),
      'grams': double.parse(_gramsController.text.trim()),
      'price': double.parse(_priceController.text.trim()),
    });
  }

  static String _dateOnly(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');

    final month = value.month.toString().padLeft(2, '0');

    final day = value.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Harvest Record' : 'Add Harvest Record'),

      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ---------------------------------------------
              // NAME
              // ---------------------------------------------
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Harvest / Batch Name',
                  hintText: 'Example: Batch 1',
                  prefixIcon: Icon(Icons.agriculture_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a harvest or batch name.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              // ---------------------------------------------
              // DATE
              // ---------------------------------------------
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Harvest Date',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    MaterialLocalizations.of(
                      context,
                    ).formatMediumDate(_selectedDate),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ---------------------------------------------
              // WEIGHT
              // ---------------------------------------------
              TextFormField(
                controller: _gramsController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Weight (grams)',
                  hintText: 'Example: 850',
                  prefixIcon: Icon(Icons.scale_outlined),
                  suffixText: 'g',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final grams = double.tryParse(value?.trim() ?? '');

                  if (grams == null) {
                    return 'Enter a valid weight.';
                  }

                  if (grams <= 0) {
                    return 'Weight must be greater than 0.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              // ---------------------------------------------
              // PRICE
              // ---------------------------------------------
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Estimated Price',
                  hintText: 'Example: 150',
                  prefixText: '₱ ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final price = double.tryParse(value?.trim() ?? '');

                  if (price == null) {
                    return 'Enter a valid price.';
                  }

                  if (price < 0) {
                    return 'Price cannot be negative.';
                  }

                  return null;
                },
              ),
            ],
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),

        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save'),
        ),
      ],
    );
  }
}

// ============================================================
// SUMMARY CARD
// ============================================================

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E1DC)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F0E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF537D42)),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF373431),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF77736D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// RECORD CARD
// ============================================================

class _HarvestRecordCard extends StatelessWidget {
  const _HarvestRecordCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
    required this.isToday,
  });

  final Map<String, dynamic> record;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  final bool isToday;

  double _number(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final name = record['name']?.toString() ?? 'Unnamed Harvest';

    final rawDate = record['date']?.toString() ?? '';

    final parsedDate = DateTime.tryParse(rawDate);

    final date = parsedDate == null
        ? rawDate
        : MaterialLocalizations.of(context).formatMediumDate(parsedDate);

    final grams = _number(record['grams']);

    final price = _number(record['price']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E1DC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4EEE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.agriculture_outlined,
                  color: Color(0xFFB68C63),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF373431),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF77736D),
                      ),
                    ),
                  ],
                ),
              ),

              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9F0E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'TODAY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF537D42),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _RecordValue(
                    label: 'Weight',
                    value: '${grams.toStringAsFixed(2)} g',
                  ),
                ),

                Container(width: 1, height: 36, color: const Color(0xFFE5E1DC)),

                Expanded(
                  child: _RecordValue(
                    label: 'Price',
                    value: '₱${price.toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),

              const SizedBox(width: 6),

              TextButton.icon(
                onPressed: onDelete,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                ),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordValue extends StatelessWidget {
  const _RecordValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF373431),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF77736D)),
        ),
      ],
    );
  }
}

// ============================================================
// EMPTY STATE
// ============================================================

class _EmptyHarvestState extends StatelessWidget {
  const _EmptyHarvestState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E1DC)),
      ),
      child: const Column(
        children: [
          Icon(Icons.agriculture_outlined, size: 42, color: Color(0xFFB68C63)),
          SizedBox(height: 14),
          Text(
            'No harvest records yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF373431),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Add your first harvest record to begin tracking yield and earnings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF77736D),
            ),
          ),
        ],
      ),
    );
  }
}
