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
}
