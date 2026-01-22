// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Listas Nickas';

  @override
  String get settings => 'Configurações';

  @override
  String get theme => 'Aparência';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get language => 'Idioma';

  @override
  String get logout => 'Sair';

  @override
  String get logoutConfirmTitle => 'Sair da conta?';

  @override
  String get logoutConfirmMessage => 'Você terá que fazer login novamente.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Deletar';

  @override
  String get deleteSelected => 'Deletar Selecionados';

  @override
  String get newList => 'Nova Lista';

  @override
  String get pending => 'Pendente';

  @override
  String get completed => 'Concluído';

  @override
  String get selectAll => 'Selecionar Todos';

  @override
  String get selected => 'selecionado(s)';

  @override
  String get emptyList => 'Sua lista está vazia';

  @override
  String get total => 'Total';

  @override
  String get items => 'itens';

  @override
  String get addItem => 'Adicionar Item';

  @override
  String get editItem => 'Editar Item';

  @override
  String get save => 'Salvar';

  @override
  String get name => 'Nome';

  @override
  String get brand => 'Marca';

  @override
  String get quantity => 'Qtd';

  @override
  String get price => 'Preço';

  @override
  String deleteConfirmMessage(int count) {
    return 'Tem certeza que deseja deletar $count itens? Esta ação não pode ser desfeita.';
  }
}
