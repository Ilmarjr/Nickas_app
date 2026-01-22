import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_list_provider.dart';
import '../../domain/entities/item.dart';
import '../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class ShoppingModeScreen extends StatefulWidget {
  final String listId;
  final String listName;

  const ShoppingModeScreen({
    super.key,
    required this.listId,
    required this.listName,
  });

  @override
  State<ShoppingModeScreen> createState() => _ShoppingModeScreenState();
}

class _ShoppingModeScreenState extends State<ShoppingModeScreen> {
  final _itemController = TextEditingController();
  final _brandController = TextEditingController(); // Added Brand
  final _priceController = TextEditingController(); // Added Price
  final _quantityController = TextEditingController(); // Added Quantity

  // Selection state
  final Set<String> _selectedItemIds = {};

  bool get _hasSelection => _selectedItemIds.isNotEmpty;
  bool get _hasSingleSelection => _selectedItemIds.length == 1;
  bool get _hasMultipleSelection => _selectedItemIds.length > 1;

  void _toggleSelection(String itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedItemIds.clear();
    });
  }

  void _selectAll(List<Item> items) {
    setState(() {
      _selectedItemIds.clear();
      _selectedItemIds.addAll(items.map((item) => item.id));
    });
  }

  bool _areAllSelected(List<Item> items) {
    if (items.isEmpty) return false;
    return _selectedItemIds.length == items.length;
  }

  String _formatCurrency(BuildContext context, double value) {
    final localeCode = Localizations.localeOf(context).languageCode;
    return NumberFormat.currency(
      locale: localeCode == 'pt' ? 'pt_BR' : 'en_US',
      symbol: localeCode == 'pt' ? 'R\$' : '\$',
    ).format(value);
  }

  double _parseValue(String text, {double defaultValue = 0.0}) {
    if (text.isEmpty) return defaultValue;
    return double.tryParse(text.replaceAll(',', '.')) ?? defaultValue;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<ShoppingListProvider>(
        context,
        listen: false,
      ).loadItems(widget.listId),
    );
  }

  @override
  void dispose() {
    _itemController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _addItem() {
    if (_itemController.text.isNotEmpty) {
      final newItem = Item(
        listId: widget.listId,
        name: _itemController.text,
        brand: _brandController.text,
        quantity: _parseValue(_quantityController.text, defaultValue: 1.0),
        price: _parseValue(_priceController.text),
      );

      Provider.of<ShoppingListProvider>(
        context,
        listen: false,
      ).addItem(newItem);

      _itemController.clear();
      _brandController.clear();
      _priceController.clear();
      _quantityController.clear();
      Navigator.of(context).pop(); // Close dialog
    }
  }

  void _editItem(Item item) {
    // Pre-fill controllers with existing item data
    _itemController.text = item.name;
    _brandController.text = item.brand;
    _quantityController.text = item.quantity.toString();
    _priceController.text = item.price.toString();

    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.editItem), // "Edit Item"
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _itemController,
                decoration: InputDecoration(labelText: l10n.name),
              ),
              TextField(
                controller: _brandController,
                decoration: InputDecoration(
                  labelText: '${l10n.brand} (Optional)',
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      decoration: InputDecoration(labelText: l10n.quantity),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      decoration: InputDecoration(labelText: l10n.price),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _itemController.clear();
              _brandController.clear();
              _priceController.clear();
              _quantityController.clear();
              Navigator.pop(ctx);
            },
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (_itemController.text.isNotEmpty) {
                final updatedItem = item.copyWith(
                  name: _itemController.text,
                  brand: _brandController.text,
                  quantity: _parseValue(
                    _quantityController.text,
                    defaultValue: 1.0,
                  ),
                  price: _parseValue(_priceController.text),
                );

                Provider.of<ShoppingListProvider>(
                  context,
                  listen: false,
                ).updateItem(updatedItem);

                _itemController.clear();
                _brandController.clear();
                _priceController.clear();
                _quantityController.clear();
                Navigator.of(context).pop();
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    // Clear controllers before showing add dialog
    _itemController.clear();
    _brandController.clear();
    _priceController.clear();
    _quantityController.clear();

    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addItem),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _itemController,
                decoration: InputDecoration(labelText: l10n.name),
                autofocus: true,
              ),
              TextField(
                controller: _brandController,
                decoration: InputDecoration(
                  labelText: '${l10n.brand} (Optional)',
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      decoration: InputDecoration(labelText: l10n.quantity),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      decoration: InputDecoration(labelText: l10n.price),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(onPressed: _addItem, child: Text(l10n.save)),
        ],
      ),
    );
  }

  void _deleteSelectedItems() {
    final count = _selectedItemIds.length;
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(l10n.deleteSelected),
          ],
        ),
        content: Text(l10n.deleteConfirmMessage(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final provider = Provider.of<ShoppingListProvider>(
                context,
                listen: false,
              );
              for (final id in _selectedItemIds) {
                provider.deleteItem(id);
              }
              _clearSelection();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '$count ${count == 1 ? 'item' : 'items'} deleted',
                  ), // TODO: localize
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _editSelectedItem() {
    if (_selectedItemIds.length != 1) return;

    final provider = Provider.of<ShoppingListProvider>(context, listen: false);
    final item = provider.currentItems.firstWhere(
      (item) => item.id == _selectedItemIds.first,
    );

    _clearSelection();
    _editItem(item);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(widget.listName)),
      body: Consumer<ShoppingListProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = provider.currentItems;
          final total = items.fold(0.0, (sum, item) => sum + item.total);

          return Column(
            children: [
              // Summary Header
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${l10n.total}: ${_formatCurrency(context, total)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${items.length} ${l10n.items}',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Select All bar
              if (items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          if (_areAllSelected(items)) {
                            _clearSelection();
                          } else {
                            _selectAll(items);
                          }
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _areAllSelected(items),
                                onChanged: (value) {
                                  if (value == true) {
                                    _selectAll(items);
                                  } else {
                                    _clearSelection();
                                  }
                                },
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.selectAll,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (_hasSelection)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${_selectedItemIds.length} ${l10n.selected}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_basket_outlined,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.emptyList,
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          final pendingItems = items
                              .where((i) => !i.isChecked)
                              .toList();
                          final checkedItems = items
                              .where((i) => i.isChecked)
                              .toList();

                          // Merge lists for building with headers logic or use slivers.
                          // Easy way: Custom ListView builder that handles index mapping
                          final hasBoth =
                              pendingItems.isNotEmpty &&
                              checkedItems.isNotEmpty;

                          return ListView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            children: [
                              // Pending Header (only if we have checked items too, to differentiate)
                              if (pendingItems.isNotEmpty &&
                                  checkedItems.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 8,
                                    top: 4,
                                  ),
                                  child: Text(
                                    '${l10n.pending} (${pendingItems.length})',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),

                              ...pendingItems.map(
                                (item) => _buildItemCard(item),
                              ),

                              if (checkedItems.isNotEmpty) ...[
                                if (pendingItems.isNotEmpty)
                                  const Divider(height: 32, thickness: 1),

                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${l10n.completed} (${checkedItems.length})',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color: Colors.green[300],
                                      ),
                                    ],
                                  ),
                                ),

                                ...checkedItems.map(
                                  (item) => _buildItemCard(item),
                                ),
                              ],

                              // Bottom padding for FAB
                              const SizedBox(height: 80),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _hasSelection
          ? null
          : FloatingActionButton(
              onPressed: _showAddItemDialog,
              child: const Icon(Icons.add_shopping_cart),
            ),
      bottomNavigationBar: _hasSelection
          ? BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _deleteSelectedItems,
                        icon: const Icon(Icons.delete),
                        label: Text(
                          _hasMultipleSelection
                              ? l10n.deleteSelected
                              : l10n.delete,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildItemCard(Item item) {
    final isSelected = _selectedItemIds.contains(item.id);

    return Card(
      elevation: isSelected ? 2 : 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(
                  context,
                ).dividerColor.withOpacity(0.2), // Better border
          width: isSelected ? 2 : 1,
        ),
      ),
      color: isSelected
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).colorScheme.surface,
      child: InkWell(
        onLongPress: () => _toggleSelection(item.id),
        onTap: () {
          if (_hasSelection) {
            _toggleSelection(item.id);
          } else {
            _editItem(item);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Selection indicator circle (custom instead of check icon)
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),

              // Item content
              Expanded(
                child: Opacity(
                  opacity: item.isChecked ? 0.6 : 1.0, // Dim checked items
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                          decoration: item.isChecked
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (item.brand.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest, // Theme aware
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.brand,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              decoration: item.isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${item.quantity} un',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (item.price > 0) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Icon(
                                Icons.circle,
                                size: 4,
                                color: Colors.grey[300],
                              ),
                            ),
                            Text(
                              '${_formatCurrency(context, item.price)}/un',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Total price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCurrency(context, item.total),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: item.isChecked
                          ? Colors.grey
                          : Theme.of(context).colorScheme.primary,
                      decoration: item.isChecked
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
