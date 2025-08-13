import '../../../domain/entities/entities.dart';
import '../../../ui/helpers/helpers.dart';
import '../../../ui/mixins/navigation_data.dart';
import '../../mixins/mixins.dart';

abstract class FAQPresenter {
  Stream<List<FAQItemEntity>> get faqItemsStream;
  Stream<NavigationData?> get navigateToStream;
  Stream<UIError?> get mainErrorStream;
  Stream<LoadingData> get isLoadingStream;
  Stream<String> get searchQueryStream;

  List<FAQItemEntity> get faqItems;
  String get searchQuery;

  Future<void> loadFAQ();
  Future<void> refreshFAQ();
  void searchFAQ(String query);
  void goBack();
}
