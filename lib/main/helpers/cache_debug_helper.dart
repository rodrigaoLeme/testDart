import 'dart:convert';
import 'dart:io';

import '../../infra/cache/cache.dart';
import '../services/logger_service.dart';

class CacheDebugHelper {
  static final SharedPreferencesStorageAdapter _storage =
      SharedPreferencesStorageAdapter();

  // Imprime todo o cache formatado
  static Future<void> printAllCache() async {
    LoggerService.debug('=== CACHE DEBUG ===', name: 'CacheDebug');

    try {
      // Metadata de sincronização
      final syncMetadata = await _storage.fetch('dify_sync_metadata');
      if (syncMetadata != null) {
        final json = jsonDecode(syncMetadata);
        LoggerService.debug(
          'Sync Metadata:\n${_formatJson(json)}',
          name: 'CacheDebug',
        );
      }

      // Conversas em cache
      final conversations = await _storage.fetch('dify_conversations_cache');
      if (conversations != null) {
        final json = jsonDecode(conversations);
        LoggerService.debug(
          'Conversas (${(json as List).length}):\n${_formatJson(json)}',
          name: 'CacheDebug',
        );
      }

      // Cache do Dify
      final difyCache = await _storage.fetch('dify_conversation_cache');
      if (difyCache != null) {
        LoggerService.debug(
          'Dify Cache:\n$difyCache',
          name: 'CacheDebug',
        );
      }
    } catch (error) {
      LoggerService.error('Erro ao ler cache: $error', name: 'CacheDebug');
    }
  }

  // Exporta cache para arquivo (útil para debug)
  static Future<void> exportCacheToFile() async {
    if (!Platform.isIOS && !Platform.isAndroid) {
      LoggerService.debug('Export só funciona em iOS/Android',
          name: 'CacheDebug');
      return;
    }

    try {
      final Map<String, dynamic> allCache = {};

      // Coleta todos os dados do cache
      final keys = [
        'dify_sync_metadata',
        'dify_conversations_cache',
        'conversations_cache',
        'conversations_last_sync',
      ];

      for (final key in keys) {
        final value = await _storage.fetch(key);
        if (value != null) {
          try {
            allCache[key] = jsonDecode(value);
          } catch (_) {
            allCache[key] = value;
          }
        }
      }

      // Salva em arquivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'cache_export_$timestamp.json';
      final documentsDir = await _getDocumentsDirectory();
      final file = File('${documentsDir.path}/$fileName');

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(allCache),
      );

      LoggerService.debug(
        'Cache exportado para: ${file.path}',
        name: 'CacheDebug',
      );
    } catch (error) {
      LoggerService.error('Erro ao exportar cache: $error', name: 'CacheDebug');
    }
  }

  // Limpa cache seletivamente
  static Future<void> clearCache({
    bool conversations = false,
    bool messages = false,
    bool syncMetadata = false,
    bool all = false,
  }) async {
    if (all) {
      await _clearAllCache();
      return;
    }

    if (conversations) {
      await _storage.delete('dify_conversations_cache');
      await _storage.delete('conversations_cache');
      LoggerService.debug('Cache de conversas limpo', name: 'CacheDebug');
    }

    if (syncMetadata) {
      await _storage.delete('dify_sync_metadata');
      await _storage.delete('conversations_last_sync');
      LoggerService.debug('Metadata de sync limpo', name: 'CacheDebug');
    }

    if (messages) {
      // Limpa todas as mensagens em cache
      await _clearMessagesCache();
      LoggerService.debug('Cache de mensagens limpo', name: 'CacheDebug');
    }
  }

  static Future<void> _clearAllCache() async {
    try {
      // Lista todas as keys conhecidas
      final keys = [
        'dify_sync_metadata',
        'dify_conversations_cache',
        'conversations_cache',
        'conversations_last_sync',
        'dify_conversation_cache',
      ];

      for (final key in keys) {
        await _storage.delete(key);
      }

      // Limpa mensagens
      await _clearMessagesCache();

      LoggerService.debug('TODO o cache foi limpo', name: 'CacheDebug');
    } catch (error) {
      LoggerService.error('Erro ao limpar cache: $error', name: 'CacheDebug');
    }
  }

  static Future<void> _clearMessagesCache() async {
    LoggerService.debug('Limpando cache de mensagens...', name: 'CacheDebug');
  }

  static String _formatJson(dynamic json) {
    try {
      return const JsonEncoder.withIndent('  ').convert(json);
    } catch (_) {
      return json.toString();
    }
  }

  static Future<Directory> _getDocumentsDirectory() async {
    if (Platform.isIOS) {
      return Directory.systemTemp;
    } else {
      return Directory.systemTemp;
    }
  }

  // Método para verificar tamanho do cache
  static Future<void> checkCacheSize() async {
    int totalSize = 0;
    int conversationCount = 0;
    int messageCount = 0;

    try {
      // Verifica conversas
      final conversations = await _storage.fetch('dify_conversations_cache');
      if (conversations != null) {
        totalSize += conversations.length;
        final list = jsonDecode(conversations) as List;
        conversationCount = list.length;
      }

      LoggerService.debug(
        'Cache Stats:\n'
        '  - Total: ${_formatBytes(totalSize)}\n'
        '  - Conversas: $conversationCount\n'
        '  - Mensagens: ~$messageCount',
        name: 'CacheDebug',
      );
    } catch (error) {
      LoggerService.error('Erro ao verificar tamanho: $error',
          name: 'CacheDebug');
    }
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
