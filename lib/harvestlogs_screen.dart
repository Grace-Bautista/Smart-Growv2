import 'package:flutter/material.dart';
import 'package:hive/hive.dart';


class HarvestLogWidget extends StatefulWidget {
  const HarvestLogWidget({super.key});

  @override
  State<HarvestLogWidget> createState() => _HarvestLogWidgetState();
}

class _HarvestLogWidgetState extends State<HarvestLogWidget> {
  Box? box;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initHive();
  }

  ///  SAFE HIVE INIT 
  Future<void> initHive() async {
    if (Hive.isBoxOpen('harvestBox')) {
      box = Hive.box('harvestBox');
    } else {
      box = await Hive.openBox('harvestBox');
    }

    setState(() {
      isLoading = false;
    });
  }

  List<Map<String, dynamic>> get records {
    if (box == null) return [];
    return box!.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  void addRecord(Map<String, dynamic> record) {
    box?.add(record);
    setState(() {});
  }

  void updateRecord(int index, Map<String, dynamic> record) {
    box?.putAt(index, record);
    setState(() {});
  }

  void deleteRecord(int index) {
    box?.deleteAt(index);
    setState(() {});
  }

  double get totalGrams =>
      records.fold(0, (sum, item) => sum + (item["grams"] ?? 0));

  double get totalEarnings =>
      records.fold(0, (sum, item) => sum + (item["price"] ?? 0));

  void showDeleteConfirm(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Delete this record?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              deleteRecord(index);
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          )
        ],
      ),
    );
  }

  void showForm({Map<String, dynamic>? existing, int? index}) {
  final name = TextEditingController(text: existing?["name"] ?? "");
  final grams =
      TextEditingController(text: existing?["grams"]?.toString() ?? "");
  final price =
      TextEditingController(text: existing?["price"]?.toString() ?? "");

  DateTime selectedDate =
      existing != null ? DateTime.parse(existing["date"]) : DateTime.now();

  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setStateDialog) {
        return AlertDialog(
          title: Text(existing == null ? "Add Record" : "Edit Record"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ///  NAME
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: "Name",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                ///  DATE PICKER
                Row(
                  children: [
                    const Text("Date:", style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "${selectedDate.toLocal()}".split(' ')[0],
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );

                        if (picked != null) {
                          setStateDialog(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    )
                  ],
                ),

                const SizedBox(height: 12),

                ///  GRAMS
                TextField(
                  controller: grams,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Grams",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                ///  PRICE
                TextField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Estimated Price (₱)",
                    border: OutlineInputBorder(),
                  ),
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
                final record = {
                  "name": name.text,
                  "date": selectedDate.toString().split(" ")[0],
                  "grams": double.tryParse(grams.text) ?? 0,
                  "price": double.tryParse(price.text) ?? 0,
                };

                if (existing == null) {
                  addRecord(record);
                } else {
                  updateRecord(index!, record);
                }

                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    ///  SHOW LOADING FIRST (prevents crash)
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () => showForm(),
            child: const Text("+ Add Record"),
          ),

          const SizedBox(height: 10),

          Text(
            "Total: ${totalGrams.toStringAsFixed(2)} g | ₱${totalEarnings.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 18),
          ),

          const SizedBox(height: 10),

          records.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("No records yet", style: TextStyle(fontSize: 18)),
                )
              : ListView.builder(
                  shrinkWrap: true, //  IMPORTANT
                  physics:
                      const NeverScrollableScrollPhysics(), 
                  itemCount: records.length,
                  itemBuilder: (_, i) {
  final r = records[i];

  final String name = r["name"] ?? "Unknown";
  final String date = r["date"] ?? "-";
  final double grams = (r["grams"] ?? 0).toDouble();
  final double price = (r["price"] ?? 0).toDouble();

  ///  Check if record is today
  final String today = DateTime.now().toString().split(" ")[0];
  final bool isToday = date == today;

  ///  Highlight big earnings
  final bool isHighValue = price >= 1000;

  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isHighValue ? Colors.green : Colors.green.shade300,
        width: isHighValue ? 2 : 1.5,
      ),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 4)
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// 🌾 NAME + BADGE
        Row(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            if (isToday)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "NEW",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 10),

        /// DETAILS BOX
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [

              ///  DATE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Date",
                      style: TextStyle(fontSize: 16)),
                  Text(date,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),

              const SizedBox(height: 6),

              ///  GRAMS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Grams",
                      style: TextStyle(fontSize: 16)),
                  Text("${grams.toStringAsFixed(2)} g",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),

              const SizedBox(height: 6),

              ///  PRICE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Price",
                      style: TextStyle(fontSize: 16)),
                  Text(
                    "₱${price.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isHighValue ? Colors.green : Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        ///  BUTTONS
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => showForm(existing: r, index: i),
                icon: const Icon(Icons.edit),
                label: const Text("Edit"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => showDeleteConfirm(i),
                icon: const Icon(Icons.delete),
                label: const Text("Delete"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
                )
        ],
      ),
    );
  }
}