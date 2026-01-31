import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../data/models/finance_models.dart';

class TransactionFormScreen extends StatefulWidget {
  final TransactionModel? transaction; // Optional: for editing

  const TransactionFormScreen({super.key, this.transaction});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _type = 'expense';
  String? _selectedCategoryId;
  bool _isRecurring = false;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final t = widget.transaction!;
      _descController.text = t.description;
      _amountController.text = t.amount.toString();
      _selectedDate = t.date;
      _type = t.type;
      _selectedCategoryId = t.categoryId;
      _isRecurring = t.isRecurring;
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;

    // Auto-fill logic (same as before)
    if (_type == 'expense' &&
        _descController.text.isEmpty &&
        _selectedCategoryId != null) {
      final categories = Provider.of<FinanceProvider>(
        context,
        listen: false,
      ).categories;
      try {
        final cat = categories.firstWhere((c) => c.id == _selectedCategoryId);
        _descController.text = cat.name;
      } catch (e) {
        // ignore
      }
    }

    if (_descController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.fillAllFields)));
      return;
    }

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.invalidAmount)));
      return;
    }

    final provider = Provider.of<FinanceProvider>(context, listen: false);

    if (widget.transaction != null) {
      // Update existing
      final updated = TransactionModel(
        id: widget.transaction!.id,
        userId: widget.transaction!.userId,
        description: _descController.text,
        amount: amount,
        date: _selectedDate,
        type: _type,
        categoryId: _type == 'expense' ? _selectedCategoryId : null,
        isRecurring: _isRecurring,
      );
      provider.updateTransaction(updated);
    } else {
      // Create new
      await provider.addTransaction(
        description: _descController.text,
        amount: amount,
        date: _selectedDate,
        type: _type,
        categoryId: _type == 'expense' ? _selectedCategoryId : null,
        isRecurring: _isRecurring,
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = Provider.of<FinanceProvider>(context).categories;
    final isEditing = widget.transaction != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.editTransaction : l10n.newTransaction),
      ), // 'Edit Transaction' needs l10n key ideally
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Type Switcher
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'expense',
                  label: Text(l10n.expense),
                  icon: const Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: 'income',
                  label: Text(l10n.income),
                  icon: const Icon(Icons.arrow_downward),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _type = newSelection.first;
                });
              },
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.resolveWith<Color>((
                  states,
                ) {
                  if (states.contains(MaterialState.selected)) {
                    return _type == 'expense' ? Colors.red : Colors.green;
                  }
                  return Colors.grey;
                }),
              ),
            ),
            const SizedBox(height: 16),

            if (_type == 'expense') ...[
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: l10n.category,
                  border: const OutlineInputBorder(),
                ),
                items: categories.map((c) {
                  return DropdownMenuItem(
                    value: c.id,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          color: Color(int.parse(c.color)),
                        ),
                        const SizedBox(width: 8),
                        Text(c.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategoryId = val;
                    if (_descController.text.isEmpty && val != null) {
                      final cat = categories.firstWhere((c) => c.id == val);
                      _descController.text = cat.name;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

            TextFormField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: l10n.description,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),

            const SizedBox(height: 16),

            // Date Picker
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat.yMd(
                    Localizations.localeOf(context).toString(),
                  ).format(_selectedDate),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Discreet Recurring Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Fixo',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(width: 8),
                Transform.scale(
                  scale: 0.8, // Smaller switch
                  child: Switch(
                    value: _isRecurring,
                    onChanged: (val) => setState(() => _isRecurring = val),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(onPressed: _submit, child: Text(l10n.save)),
            ),
          ],
        ),
      ),
    );
  }
}
