import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/repositories/faq_repository.dart';
import '../cache/shared_preferences_storage_adapter_factory.dart';

FAQRepository makeFAQRepository() => FAQRepository(
      firestore: FirebaseFirestore.instance,
      localStorage: makeSharedPreferencesStorageAdapter(),
    );
