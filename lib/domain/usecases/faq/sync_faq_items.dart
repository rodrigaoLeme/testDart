import '../../entities/entities.dart';

abstract class SyncFAQItems {
  Future<List<FAQItemEntity>> sync({bool forceRefresh = false});
}
