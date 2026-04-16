import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../../l10n/app_localizations.dart';
import 'transaction_form_screen.dart';
import 'categories_screen.dart';
import '../../data/models/finance_models.dart';
import '../providers/auth_provider.dart';
import 'settings_screen.dart';

class FinanceDashboardScreen extends StatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  State<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends State<FinanceDashboardScreen> {
  final Set<String> _selectedIds = {};
  int _touchedIndex = -1;

  bool get _hasSelection => _selectedIds.isNotEmpty;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  void _deleteSelected(FinanceProvider finance) {
    for (var id in _selectedIds.toList()) {
      if (id == 'virtual_market') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cannot delete Market summary")),
        );
      } else {
        finance.deleteTransaction(id);
      }
    }
    _clearSelection();
    _clearSelection();
  }

  void _showLogoutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logoutConfirmTitle),
        content: Text(l10n.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pop(ctx);
            },
            child: Text(l10n.logout, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Text(
          l10n.financeTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        leading: _hasSelection
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              )
            : IconButton(
                icon: const Icon(Icons.category_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                ),
              ),
        actions: [
          if (_hasSelection)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteSelected(
                Provider.of<FinanceProvider>(context, listen: false),
              ),
            )
          else ...[
            PopupMenuButton<String>(
              offset: const Offset(0, 48),
              icon: CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.person,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              onSelected: (value) {
                if (value == 'settings') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                } else if (value == 'logout') {
                  _showLogoutDialog(context);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [
                      const Icon(Icons.settings, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(l10n.settings),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: Colors.red),
                      const SizedBox(width: 12),
                      Text(
                        l10n.logout,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, finance, _) {
          final selectedDate = finance.selectedDate;
          final monthStr = DateFormat('MMMM yyyy', locale).format(selectedDate);

          double income = 0;
          double expenses = 0;
          Map<String, double> categoryExpenses = {};

          for (var t in finance.transactions) {
            if (t.type == 'income') {
              income += t.amount;
            } else {
              expenses += t.amount;
              if (t.categoryId != null) {
                categoryExpenses[t.categoryId!] =
                    (categoryExpenses[t.categoryId!] ?? 0) + t.amount;
              } else {
                categoryExpenses['Uncategorized'] =
                    (categoryExpenses['Uncategorized'] ?? 0) + t.amount;
              }
            }
          }

          if (finance.marketExpense > 0) {
            expenses += finance.marketExpense;
            categoryExpenses['Market_Virtual_ID'] = finance.marketExpense;
          }

          double balance = income - expenses;

          final List<dynamic> displayTransactions = [...finance.transactions];
          if (finance.marketExpense > 0) {
            displayTransactions.add({
              'id': 'virtual_market',
              'description': l10n.market,
              'amount': finance.marketExpense,
              'date': DateTime(selectedDate.year, selectedDate.month, 1),
              'type': 'expense',
              'isVirtual': true,
              'categoryId': 'Market_Virtual_ID',
            });
            displayTransactions.sort((a, b) {
              DateTime da = a is Map ? a['date'] : a.date;
              DateTime db = b is Map ? b['date'] : b.date;
              return db.compareTo(da);
            });
          }

          final categoryEntries = categoryExpenses.entries.toList();
          // Sort larger first for better visualization
          categoryEntries.sort((a, b) => b.value.compareTo(a.value));

          return RefreshIndicator(
            onRefresh: () => finance.loadData(),
            child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: finance.previousMonth,
                      icon: Icon(
                        Icons.chevron_left,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      monthStr.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: theme.colorScheme.onBackground.withOpacity(0.8),
                      ),
                    ),
                    IconButton(
                      onPressed: finance.nextMonth,
                      icon: Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Balance Card (Hero)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF311B92),
                              const Color(0xFF6200EE),
                            ] // Deep Purple 900 -> 500
                          : [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withOpacity(0.7),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isDark
                                    ? const Color(0xFF311B92)
                                    : theme.colorScheme.primary)
                                .withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.balance,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        NumberFormat.simpleCurrency(
                          locale: locale,
                        ).format(balance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _CompactStat(
                              label: l10n.income,
                              value: income,
                              icon: Icons.arrow_downward,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.white24,
                          ),
                          Expanded(
                            child: _CompactStat(
                              label: l10n.expense,
                              value: expenses,
                              icon: Icons.arrow_upward,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                if (expenses > 0) ...[
                  // Chart Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.spendingAnalysis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        NumberFormat.compactSimpleCurrency(
                          locale: locale,
                        ).format(expenses),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 280,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            // If no section touched
                            if (pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              // Only deselect on specific "up" events on empty space
                              if (event is FlTapUpEvent) {
                                setState(() => _touchedIndex = -1);
                              }
                              return;
                            }

                            // Broaden the "Click" definition: TapUp, LongPressEnd, or even PanEnd (lazy tap)
                            if (event is FlTapUpEvent ||
                                event is FlLongPressEnd ||
                                event is FlPanEndEvent) {
                              final newIndex = pieTouchResponse
                                  .touchedSection!
                                  .touchedSectionIndex;
                              setState(() {
                                if (_touchedIndex == newIndex) {
                                  _touchedIndex = -1; // Deselect
                                } else {
                                  _touchedIndex = newIndex; // Select
                                }
                              });
                            }
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 2,
                        centerSpaceRadius: 60, // Slightly smaller hole
                        sections: List.generate(categoryEntries.length, (i) {
                          final entry = categoryEntries[i];
                          final isTouched = i == _touchedIndex;
                          final double fontSize = isTouched ? 16 : 12;
                          // Increase base radius for easier hitting
                          final double radius = isTouched ? 65 : 55;

                          Color color = Colors.grey;
                          String name = "?";

                          if (entry.key == 'Market_Virtual_ID') {
                            color = Colors.orange;
                            name = l10n.market;
                          } else if (entry.key == 'Uncategorized') {
                            color = Colors.grey;
                            name = l10n.uncategorized;
                          } else {
                            try {
                              final cat = finance.categories.firstWhere(
                                (c) => c.id == entry.key,
                              );
                              color = Color(int.parse(cat.color));
                              name = cat.name;
                            } catch (_) {}
                          }

                          final pct = (entry.value / expenses * 100)
                              .toStringAsFixed(0);

                          return PieChartSectionData(
                            color: color,
                            value: entry.value,
                            title: isTouched ? "$name\n$pct%" : "$pct%",
                            radius: radius,
                            titleStyle: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: const [Shadow(blurRadius: 2)],
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  // Legend
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categoryEntries.map((e) {
                      Color color = Colors.grey;
                      String name = "?";
                      if (e.key == 'Market_Virtual_ID') {
                        color = Colors.orange;
                        name = l10n.market;
                      } else if (e.key == 'Uncategorized') {
                        color = Colors.grey;
                        name = l10n.uncategorized;
                      } else {
                        try {
                          final cat = finance.categories.firstWhere(
                            (c) => c.id == e.key,
                          );
                          color = Color(int.parse(cat.color));
                          name = cat.name;
                        } catch (_) {}
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(radius: 4, backgroundColor: color),
                            const SizedBox(width: 6),
                            Text(
                              name,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.transactions,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!_hasSelection)
                      IconButton(
                        icon: const Icon(Icons.add_circle, size: 28),
                        color: theme.colorScheme.primary,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TransactionFormScreen(),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                if (displayTransactions.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        l10n.noTransactionsYet,
                        style: TextStyle(color: theme.hintColor),
                      ),
                    ),
                  ),

                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: displayTransactions.length,
                  itemBuilder: (ctx, i) {
                    final item = displayTransactions[i];
                    final isVirtual = item is Map;
                    final String id = isVirtual ? item['id'] : item.id;
                    final String description = isVirtual
                        ? item['description']
                        : item.description;
                    final double amount = isVirtual
                        ? item['amount']
                        : item.amount;
                    final DateTime date = isVirtual ? item['date'] : item.date;
                    final String type = isVirtual ? item['type'] : item.type;
                    final String? catId = isVirtual
                        ? item['categoryId']
                        : item.categoryId;

                    final isExpense = type == 'expense';
                    final isSelected = _selectedIds.contains(id);

                    Color color = theme.colorScheme.primary;
                    IconData icon = Icons.attach_money;

                    if (catId == 'Market_Virtual_ID') {
                      color = Colors.orange;
                      icon = Icons.shopping_cart;
                    } else if (catId != null) {
                      try {
                        final cat = finance.categories.firstWhere(
                          (c) => c.id == catId,
                        );
                        color = Color(int.parse(cat.color));

                        // Icon Logic
                        if (cat.icon != null) {
                          switch (cat.icon) {
                            case 'work':
                              icon = Icons.work;
                              break;
                            case 'home':
                              icon = Icons.home;
                              break;
                            case 'directions_bus':
                              icon = Icons.directions_bus;
                              break;
                            case 'fitness_center':
                              icon = Icons.fitness_center;
                              break;
                            case 'movie':
                              icon = Icons.movie;
                              break;
                            case 'trending_up':
                              icon = Icons.trending_up;
                              break;
                            case 'restaurant':
                              icon = Icons.restaurant;
                              break;
                            case 'category':
                              icon = Icons.category;
                              break;
                            default:
                              icon = Icons.category;
                          }
                        } else {
                          // Fallback by name
                          final name = cat.name.toLowerCase();
                          if (name.contains('salário') ||
                              name.contains('salary'))
                            icon = Icons.work;
                          else if (name.contains('investimento') ||
                              name.contains('invest'))
                            icon = Icons.trending_up;
                          else if (name.contains('aluguel') ||
                              name.contains('rent') ||
                              name.contains('casa'))
                            icon = Icons.home;
                          else if (name.contains('transporte') ||
                              name.contains('transport') ||
                              name.contains('uber') ||
                              name.contains('onibus'))
                            icon = Icons.directions_bus;
                          else if (name.contains('saúde') ||
                              name.contains('health') ||
                              name.contains('academia'))
                            icon = Icons.fitness_center;
                          else if (name.contains('lazer') ||
                              name.contains('leisure'))
                            icon = Icons.movie;
                          else if (name.contains('aliment') ||
                              name.contains('comida') ||
                              name.contains('restaur') ||
                              name.contains('food'))
                            icon = Icons.restaurant;
                          else
                            icon = Icons.category;
                        }
                      } catch (_) {}
                    }

                    return GestureDetector(
                      onLongPress: () {
                        if (!isVirtual) _toggleSelection(id);
                      },
                      onTap: () {
                        if (_hasSelection) {
                          if (!isVirtual) _toggleSelection(id);
                        } else if (!isVirtual) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TransactionFormScreen(
                                transaction: item as TransactionModel,
                              ),
                            ),
                          );
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primaryContainer.withOpacity(
                                  0.5,
                                )
                              : theme.cardTheme.color ?? theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 2,
                                )
                              : Border.all(color: Colors.transparent),
                          boxShadow: [
                            if (!isSelected && !isDark)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    description,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(date),
                                    style: TextStyle(
                                      color: theme.hintColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isExpense ? '-' : '+'}${NumberFormat.simpleCurrency(locale: locale).format(amount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isExpense
                                    ? Colors.redAccent
                                    : Colors.green,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 80),
              ],
            ),
          ), // SingleChildScrollView
          ); // RefreshIndicator

        },
      ),
      floatingActionButton:
          null, // Moved to header for cleaner look, or restore if preferred
    );
  }
}

class _CompactStat extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;

  const _CompactStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          NumberFormat.compactSimpleCurrency(locale: locale).format(value),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
