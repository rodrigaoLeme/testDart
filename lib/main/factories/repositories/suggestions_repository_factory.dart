import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/repositories/suggestions_repository.dart';
import '../cache/shared_preferences_storage_adapter_factory.dart';

SuggestionsRepository makeSuggestionsRepository() => SuggestionsRepository(
      firestore: FirebaseFirestore.instance,
      localStorage: makeSharedPreferencesStorageAdapter(),
    );
