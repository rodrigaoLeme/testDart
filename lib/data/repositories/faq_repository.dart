import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/entities.dart';
import '../../domain/helpers/helpers.dart';
import '../../domain/usecases/faq/load_faq_items.dart';
import '../../domain/usecases/faq/sync_faq_items.dart';
import '../../infra/cache/cache.dart';
import '../models/faq/faq_item_model.dart';
import '../models/faq/faq_metadata_model.dart';

class FAQRepository implements LoadFAQItems, SyncFAQItems {
  final FirebaseFirestore firestore;
  final SharedPreferencesStorageAdapter localStorage;

  static const String _faqItemsKey = 'faq_items_cache';
  static const String _faqMetadataKey = 'faq_metadata_cache';
  static const String _lastSyncKey = 'faq_last_sync';

  FAQRepository({
    required this.firestore,
    required this.localStorage,
  });

  @override
  Future<List<FAQItemEntity>> load() async {
    try {
      // Tenta carregar do cache primeiro
      final cachedItems = await _loadFromCache();
      if (cachedItems.isNotEmpty) {
        return cachedItems.map((model) => model.toEntity()).toList();
      }

      // Se não há cache, busca do Firestore
      return await sync();
    } catch (error) {
      throw DomainError.unexpected;
    }
  }

  @override
  Future<List<FAQItemEntity>> sync({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && !await _shouldSync()) {
        final cachedItems = await _loadFromCache();
        return cachedItems.map((model) => model.toEntity()).toList();
      }

      final metadata = await _fetchMetadata();

      final items = await _fetchItems();

      await _saveToCache(items, metadata);

      // Atualiza timestamp do último sync
      await localStorage.save(
        key: _lastSyncKey,
        value: DateTime.now().toIso8601String(),
      );

      return items.map((model) => model.toEntity()).toList();
    } catch (error) {
      final cachedItems = await _loadFromCache();
      if (cachedItems.isNotEmpty) {
        return cachedItems.map((model) => model.toEntity()).toList();
      }

      throw DomainError.networkError;
    }
  }

  Future<FAQMetadataModel> _fetchMetadata() async {
    final doc = await firestore.collection('faq').doc('metadata').get();

    if (!doc.exists || doc.data() == null) {
      throw DomainError.notFound;
    }

    return FAQMetadataModel.fromFirestore(doc.data()!);
  }

  Future<List<FAQItemModel>> _fetchItems() async {
    final querySnapshot = await firestore
        .collection('faq')
        .doc('items')
        .collection('questions')
        .orderBy('order')
        .get();

    return querySnapshot.docs
        .map((doc) => FAQItemModel.fromFirestore(doc.data()))
        .where((item) => item.active)
        .toList();
  }

  Future<List<FAQItemModel>> _loadFromCache() async {
    try {
      final cacheString = await localStorage.fetch(_faqItemsKey);
      if (cacheString == null || cacheString.isEmpty) {
        return [];
      }

      return FAQItemModel.fromCacheString(cacheString);
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveToCache(
      List<FAQItemModel> items, FAQMetadataModel metadata) async {
    await localStorage.save(
      key: _faqItemsKey,
      value: FAQItemModel.listToCacheString(items),
    );

    await localStorage.save(
      key: _faqMetadataKey,
      value: metadata.toCacheString(),
    );
  }

  Future<bool> _shouldSync() async {
    try {
      // Verifica se passou do tempo limite (24 horas)
      final lastSyncString = await localStorage.fetch(_lastSyncKey);
      if (lastSyncString == null) return true;

      final lastSync = DateTime.parse(lastSyncString);
      final timeDifference = DateTime.now().difference(lastSync);

      // Se passou mais de 24 horas, precisa sincronizar
      if (timeDifference.inHours >= 24) {
        return true;
      }

      // Verifica se a versão mudou no servidor
      final cachedMetadataString = await localStorage.fetch(_faqMetadataKey);
      if (cachedMetadataString == null) return true;

      final cachedMetadata =
          FAQMetadataModel.fromCacheString(cachedMetadataString);
      final serverMetadata = await _fetchMetadata();

      if (cachedMetadata.version != serverMetadata.version) {
        return true;
      }

      return false;
    } catch (_) {
      return true;
    }
  }
}
