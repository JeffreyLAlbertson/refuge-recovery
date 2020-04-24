import 'package:get_it/get_it.dart';
import 'navigator/service.dart';
import 'package:refugerecovery/args/usersitdetails.dart';

GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton(() => NavigationService());
  locator.registerLazySingleton<UserSitDetailsArgs>(()=> UserSitDetailsArgs(
      '00000000-0000-0000-0000-000000000000',
      '00000000-0000-0000-0000-000000000000',
      '',
      DateTime.now(),
      Duration.zero));
}