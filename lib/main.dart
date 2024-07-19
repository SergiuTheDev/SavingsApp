import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for TextInputFormatter

void main() {
  runApp(MyApp());
}

class SettingsPage extends StatefulWidget {
  final String selectedCurrency;
  final Function(String) onCurrencyChanged;

  const SettingsPage({
    required this.selectedCurrency,
    required this.onCurrencyChanged,
  });

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Select Currency',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.blue),
          ),
          SizedBox(height: 20),
          DropdownButton<String>(
            value: widget.selectedCurrency,
            items: ['EUR', 'USD', 'RON'].map((String currency) {
              return DropdownMenuItem<String>(
                value: currency,
                child: Text(currency),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                widget.onCurrencyChanged(newValue);
              }
            },
          ),
        ],
      ),
    );
  }
}

class SavingEntry {
  final String? title;
  final double? goalAmount;
  double? currentAmount;

  SavingEntry({
    this.title,
    this.goalAmount,
    this.currentAmount,
  });

  double get progress {
    if (goalAmount == null || goalAmount == 0) {
      return 0;
    }
    return (currentAmount ?? 0) / goalAmount! * 100;
  }

  String getFormattedAmount(String currency) {
    return '${currencySymbol(currency)}${(currentAmount ?? 0).toStringAsFixed(2)}';
  }

  String currencySymbol(String currency) {
    switch (currency) {
      case 'EUR':
        return '€';
      case 'USD':
        return '\$';
      case 'RON':
        return 'lei';
      default:
        return '';
    }
  }
}

class SavingsPage extends StatelessWidget {
  final List<SavingEntry> entries;
  final Function(int) onDeleteEntry;
  final Function(int, double, bool) onUpdateEntry;
  final String currency;

  const SavingsPage({
    required this.entries,
    required this.onDeleteEntry,
    required this.onUpdateEntry,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Text('No savings entries', style: Theme.of(context).textTheme.headlineLarge),
      );
    }
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            elevation: 5,
            child: ListTile(
              contentPadding: EdgeInsets.all(16.0),
              title: Text(
                entry.title ?? 'Unnamed Entry',
                style: TextStyle(
                  fontSize: 24, // Increased font size for the title
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: (entry.goalAmount != null && entry.goalAmount! > 0)
                        ? (entry.currentAmount ?? 0) / entry.goalAmount!
                        : 0,
                    backgroundColor: Colors.grey[300],
                    color: Colors.green,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${entry.getFormattedAmount(currency)}/ ${entry.goalAmount?.toStringAsFixed(2) ?? '0.00'} (${entry.progress.toStringAsFixed(0)}%)',
                    style: TextStyle(
                      fontSize: 20, // Increased font size for the progress text
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showTransactionDialog(context, index),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      onDeleteEntry(index);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Entry removed: ${entry.title ?? 'Unnamed Entry'}')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTransactionDialog(BuildContext context, int index) {
    final TextEditingController _transactionController = TextEditingController();
    bool _isAdd = true; // Default to adding

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add or Deduct for ${entries[index].title ?? 'Unnamed Entry'}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _transactionController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      hintText: 'Enter amount to add or deduct',
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^(\d*\.?\d*)$')),
                    ],
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isAdd = true;
                          });
                        },
                        child: Text('Add'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isAdd ? Colors.green : Colors.grey,
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isAdd = false;
                          });
                        },
                        child: Text('Deduct'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !_isAdd ? Colors.red : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    final transactionAmount = double.tryParse(_transactionController.text) ?? 0.0;
                    if (transactionAmount != 0.0) {
                      if (_isAdd) {
                        onUpdateEntry(index, transactionAmount, true);
                      } else {
                        // Deduct only if the amount to deduct is less than or equal to the current amount
                        if (transactionAmount <= (entries[index].currentAmount ?? 0)) {
                          onUpdateEntry(index, transactionAmount, false);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Cannot deduct more than the current amount')),
                          );
                        }
                      }
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text(_isAdd ? 'Add' : 'Deduct'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class AddPage extends StatefulWidget {
  final Function(SavingEntry) onAddEntry;
  final String currency;

  const AddPage({
    required this.onAddEntry,
    required this.currency,
  });

  @override
  _AddPageState createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final title = _titleController.text.isEmpty ? null : _titleController.text;
      final amount = double.tryParse(_amountController.text);

      final entry = SavingEntry(title: title, goalAmount: amount);
      widget.onAddEntry(entry);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saving entry added: ${title ?? 'Unnamed Entry'}, ${widget.currency}${amount?.toStringAsFixed(2) ?? '0.00'}')),
      );

      _titleController.clear();
      _amountController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add New Saving Entry',
              style: Theme.of(context).textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Saving for',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Total amount needed',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitForm,
              child: Text('Add Saving Goal'),
            ),
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _selectedCurrency = 'USD'; // Default currency

  void _updateCurrency(String newCurrency) {
    setState(() {
      _selectedCurrency = newCurrency;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Savings Tracker',
      theme: ThemeData(
        primarySwatch: Colors.green,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: PageIndex(
        selectedCurrency: _selectedCurrency,
        onCurrencyChanged: _updateCurrency,
      ),
    );
  }
}

class PageIndex extends StatefulWidget {
  final String selectedCurrency;
  final Function(String) onCurrencyChanged;

  const PageIndex({
    super.key,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
  });

  @override
  State<PageIndex> createState() => _PageIndexState();
}

class _PageIndexState extends State<PageIndex> {
  int _currentIndex = 0;
  List<SavingEntry> _entries = [];

  void _onAddEntry(SavingEntry entry) {
    setState(() {
      _entries.add(entry);
    });
  }

  void _onDeleteEntry(int index) {
    setState(() {
      _entries.removeAt(index);
    });
  }

  void _onUpdateEntry(int index, double amount, bool isAdd) {
    setState(() {
      if (isAdd) {
        _entries[index].currentAmount = (_entries[index].currentAmount ?? 0) + amount;
      } else {
        // Deduct amount but ensure it does not go below zero
        _entries[index].currentAmount = ((_entries[index].currentAmount ?? 0) - amount).clamp(0.0, _entries[index].goalAmount ?? 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      SavingsPage(
        entries: _entries,
        onDeleteEntry: _onDeleteEntry,
        onUpdateEntry: _onUpdateEntry,
        currency: widget.selectedCurrency,
      ),
      AddPage(
        onAddEntry: _onAddEntry,
        currency: widget.selectedCurrency,
      ),
      SettingsPage(
        selectedCurrency: widget.selectedCurrency,
        onCurrencyChanged: widget.onCurrencyChanged,
      ),
    ];

    // Determine the background color and app bar title based on the selected index
    Color _bottomNavBarColor;
    String _appBarTitle;
    switch (_currentIndex) {
      case 1:
        _bottomNavBarColor = Colors.yellow;
        _appBarTitle = 'Add Goals';
        break;
      case 2:
        _bottomNavBarColor = Colors.blue;
        _appBarTitle = 'Settings';
        break;
      default:
        _bottomNavBarColor = Colors.green;
        _appBarTitle = 'Savings Goals';
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _bottomNavBarColor,
        title: Center(
          child: Text(
            _appBarTitle,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: _bottomNavBarColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.savings),
            label: "Savings",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: "Add",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
      body: _pages[_currentIndex],
    );
  }
}
