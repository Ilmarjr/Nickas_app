// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Nickas Lists';

  @override
  String get settings => 'Settings';

  @override
  String get theme => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirmTitle => 'Logout?';

  @override
  String get logoutConfirmMessage => 'You will need to login again.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get deleteSelected => 'Delete Selected';

  @override
  String get newList => 'New List';

  @override
  String get pending => 'Pending';

  @override
  String get completed => 'Completed';

  @override
  String get selectAll => 'Select All';

  @override
  String get selected => 'selected';

  @override
  String get emptyList => 'Your list is empty';

  @override
  String get total => 'Total';

  @override
  String get items => 'items';

  @override
  String get addItem => 'Add Item';

  @override
  String get editItem => 'Edit Item';

  @override
  String get save => 'Save';

  @override
  String get name => 'Name';

  @override
  String get brand => 'Brand';

  @override
  String get quantity => 'Qty';

  @override
  String get price => 'Price';

  @override
  String deleteConfirmMessage(int count) {
    return 'Are you sure you want to delete $count items? This action cannot be undone.';
  }

  @override
  String get editTransaction => 'Edit Transaction';

  @override
  String get spendingAnalysis => 'Spending Analysis';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get dontHaveAccount => 'Don\'t have an account? Register';

  @override
  String get createAccount => 'Create Account';

  @override
  String get username => 'Username';

  @override
  String get birthDate => 'Date of Birth';

  @override
  String get invalidCredentials => 'Invalid email or password';

  @override
  String get financeTitle => 'Finances';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get balance => 'Balance';

  @override
  String get market => 'Market';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get viewAll => 'View All';

  @override
  String get newTransaction => 'New Transaction';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get pickColor => 'Pick Color';

  @override
  String get description => 'Description';

  @override
  String get category => 'Category';

  @override
  String get enterEmail => 'Please enter email';

  @override
  String get enterPassword => 'Please enter password';

  @override
  String get enterUsername => 'Please enter username';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get fillAllFields => 'Please fill all fields';

  @override
  String get transactions => 'Transactions';

  @override
  String get noTransactionsYet => 'No transactions yet';

  @override
  String get tabFinances => 'Finances';

  @override
  String get tabShopping => 'Shopping';
}
