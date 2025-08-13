import '../../entities/entities.dart';

abstract class LoadFAQItems {
  Future<List<FAQItemEntity>> load();
}
