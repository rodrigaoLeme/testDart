import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/suggestions/suggestion_entity.dart';
import '../../domain/helpers/helpers.dart';
import '../../domain/usecases/suggestions/suggestions.dart';
import '../../infra/cache/cache.dart';
import '../models/suggestions/suggestions.dart';

class SuggestionsRepository
    implements LoadSuggestions, SyncSuggestions, GetRandomSuggestions {
  final FirebaseFirestore firestore;
  final SharedPreferencesStorageAdapter localStorage;

  static const String _suggestionsItemsKey = 'suggestions_items_cache';
  static const String _suggestionsMetadataKey = 'suggestions_metadata_cache';
  static const String _lastSyncKey = 'suggestions_last_sync';

  SuggestionsRepository({
    required this.firestore,
    required this.localStorage,
  });

  @override
  Future<List<SuggestionEntity>> load() async {
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
  Future<List<SuggestionEntity>> sync({bool forceRefresh = false}) async {
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

  @override
  List<SuggestionEntity> getRandomSuggestions(
    List<SuggestionEntity> allSuggestions, {
    int count = 4,
  }) {
    if (allSuggestions.length <= count) {
      return List<SuggestionEntity>.from(allSuggestions)..shuffle();
    }

    final random = Random();
    final shuffled = List<SuggestionEntity>.from(allSuggestions)
      ..shuffle(random);
    return shuffled.take(count).toList();
  }

  Future<SuggestionMetadataModel> _fetchMetadata() async {
    final doc = await firestore.collection('suggestions').doc('metadata').get();

    if (!doc.exists || doc.data() == null) {
      throw DomainError.notFound;
    }

    return SuggestionMetadataModel.fromFirestore(doc.data()!);
  }

  Future<List<SuggestionModel>> _fetchItems() async {
    final querySnapshot = await firestore
        .collection('suggestions')
        .doc('items')
        .collection('texts')
        .orderBy('order')
        .get();

    return querySnapshot.docs
        .map((doc) => SuggestionModel.fromFirestore(doc.data()))
        .where((item) => item.active)
        .toList();
  }

  Future<List<SuggestionModel>> _loadFromCache() async {
    try {
      final cacheString = await localStorage.fetch(_suggestionsItemsKey);
      if (cacheString == null || cacheString.isEmpty) {
        return [];
      }

      return SuggestionModel.fromCacheString(cacheString);
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveToCache(
      List<SuggestionModel> items, SuggestionMetadataModel metadata) async {
    await localStorage.save(
      key: _suggestionsItemsKey,
      value: SuggestionModel.listToCacheString(items),
    );

    await localStorage.save(
      key: _suggestionsMetadataKey,
      value: metadata.toCacheString(),
    );
  }

  Future<bool> _shouldSync() async {
    try {
      // Verifica se passou do tempo limite (7 dias)
      final lastSyncString = await localStorage.fetch(_lastSyncKey);
      if (lastSyncString == null) return true;

      final lastSync = DateTime.parse(lastSyncString);
      final timeDifference = DateTime.now().difference(lastSync);

      // Se passou mais de 7 dias, precisa sincronizar
      if (timeDifference.inDays >= 7) {
        return true;
      }

      // Verifica se a versão mudou no servidor
      final cachedMetadataString =
          await localStorage.fetch(_suggestionsMetadataKey);
      if (cachedMetadataString == null) return true;

      final cachedMetadata =
          SuggestionMetadataModel.fromCacheString(cachedMetadataString);
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
