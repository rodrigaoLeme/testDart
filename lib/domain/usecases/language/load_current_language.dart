import '../../entities/entities.dart';

abstract class LoadCurrentLanguage {
  Future<LanguageEntity> load();
}
