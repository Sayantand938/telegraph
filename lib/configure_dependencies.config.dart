// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import 'services/database/finance_database.dart' as _i646;
import 'services/database/i_finance_database.dart' as _i81;
import 'services/database/i_session_database.dart' as _i7;
import 'services/database/session_database.dart' as _i27;
import 'services/tools/tool_service.dart' as _i378;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.lazySingleton<_i81.IFinanceDatabase>(() => _i646.FinanceDatabase());
    gh.lazySingleton<_i7.ISessionDatabase>(() => _i27.SessionDatabase());
    gh.factory<_i378.ToolService>(
      () => _i378.ToolService(
        gh<_i7.ISessionDatabase>(),
        gh<_i81.IFinanceDatabase>(),
      ),
    );
    return this;
  }
}
