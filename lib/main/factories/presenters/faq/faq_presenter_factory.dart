import '../../../../presentation/presenters/faq/faq_presenter.dart';
import '../../../../presentation/presenters/faq/stream_faq_presenter.dart';
import '../../usecases/faq/faq.dart';

FAQPresenter makeFAQPresenter() => StreamFAQPresenter(
      loadFAQItems: makeLoadFAQItems(),
      syncFAQItems: makeSyncFAQItems(),
    );
