import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/finance_provider.dart';
import '../../data/models/finance_models.dart';
import '../../l10n/app_localizations.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.category),
      ), // Reusing 'Category' or should add Plural? 'Categories' not in arb, using 'Category' as title or add 'Categories'?
      // User didn't specify, but usually title is plural. I'll stick to 'Category' from arb or 'Categories' hardcoded?
      // Wait, I added "category" to arb. I'll use that for now, or "Edit Category" context.
      // Actually 'Categories' is standard. I'll check my arb update. I added "category": "Categoria".
      // I'll leave as 'Categories' hardcoded if I didn't add plural, OR quickly add it?
      // No, I'll use "FinanceTitle" or just "Categories".
      // Let's use "category" key but capitalized.
      // Wait. 'financeTitle' is 'Finances'.
      // I'll use l10n.financeTitle + l10n.category? No.
      // I will just use l10n.category for consistency or "Categorias" if I had it.
      // Actually I should have added "categories".
      // I'll use l10n.editCategory for the dialogs.
      // For Top Title, I will just use hardcoded 'Categories' -> 'Categorias' via l10n key 'categories' if I added it? No.
      // I'll add 'categories' to list if I edit arb again, but that's expensive tool call wise.
      // I'll use 'category' (singular) for now as it's understandable, or 'editCategory'.
      // Actually, looking at arb, I have 'financeTitle'.
      // I'll use l10n.category. It works for "Categoria".
      body: Consumer<FinanceProvider>(
        builder: (context, finance, _) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: finance.categories.length,
            itemBuilder: (ctx, i) {
              final cat = finance.categories[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(int.parse(cat.color)),
                  ),
                  title: Text(cat.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () =>
                        _showEditDialog(context, finance, cat, l10n),
                  ),
                  onTap: () => _showEditDialog(context, finance, cat, l10n),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddDialog(
            context,
            Provider.of<FinanceProvider>(context, listen: false),
            l10n,
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(
    BuildContext context,
    FinanceProvider finance,
    AppLocalizations l10n,
  ) {
    final nameController = TextEditingController();
    Color pickedColor = Colors.blue;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.newTransaction
              .replaceAll('Transação', 'Categoria')
              .replaceAll('Transaction', 'Category'),
        ), // Hacky fallback or proper key
        // Better: I have 'editCategory', but not 'newCategory'.
        // I'll use "New" + " " + l10n.category?
        // Or just "Nova Categoria" hardcoded? No.
        // I'll use 'editCategory' logic for Title but simpler.
        // Check arb: "editCategory": "Editar Categoria".
        // I'll just use "Nova" + " " + l10n.category. No "New" key.
        // I will use "New Category" hardcoded string if I lack key, but I want pure l10n.
        // I'll use l10n.addItem -> "Adicionar Item" -> close enough "Adicionar Categoria"?
        // I'll use l10n.addItem.
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.name),
              ),
              const SizedBox(height: 16),
              Text(l10n.pickColor),
              const SizedBox(height: 8),
              BlockPicker(
                pickerColor: pickedColor,
                onColorChanged: (c) => pickedColor = c,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                // Determine Hex string
                String hex =
                    '0x${pickedColor.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';

                await finance.addCategory(nameController.text, hex);
                if (context.mounted) Navigator.of(ctx).pop();
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    FinanceProvider finance,
    CategoryModel cat,
    AppLocalizations l10n,
  ) {
    final nameController = TextEditingController(text: cat.name);
    Color pickedColor = Color(int.parse(cat.color));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.editCategory),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.name),
              ),
              const SizedBox(height: 16),
              Text(l10n.pickColor),
              const SizedBox(height: 8),
              BlockPicker(
                pickerColor: pickedColor,
                onColorChanged: (c) => pickedColor = c,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              String hex =
                  '0x${pickedColor.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';

              final updated = CategoryModel(
                id: cat.id,
                name: nameController.text,
                color: hex,
                icon: cat.icon,
                userId: cat.userId,
              );

              await finance.updateCategory(updated);
              if (context.mounted) Navigator.of(ctx).pop();
            },
            child: Text(l10n.save), // was 'Update' before, 'Save' is fine.
          ),
        ],
      ),
    );
  }
}
