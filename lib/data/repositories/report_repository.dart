import '../../domain/entities/feedback/report_entity.dart';
import '../../domain/helpers/domain_error.dart';
import '../../domain/usecases/feedback/submit_report.dart';
import '../../main/services/logger_service.dart';
import '../http/http_client.dart';

class ReportRepository implements SubmitReport {
  final HttpClient httpClient;
  final String webhookUrl;

  ReportRepository({
    required this.httpClient,
    required this.webhookUrl,
  });

  @override
  Future<void> submit(ReportEntity report) async {
    try {
      LoggerService.debug(
        'Enviando report para webhook: ${report.messageId}',
        name: 'ReportRepository',
      );

      await httpClient.request(
        url: webhookUrl,
        method: HttpMethod.post,
        headers: {
          'Content-Type': 'application/json',
        },
        body: {
          'user_id': report.userId,
          'message': report.message,
          'conversation_id': report.conversationId,
          'user_query': report.userQuery,
          'user_feedback': report.userFeedback,
        },
      );

      LoggerService.debug(
        'Report enviado com sucesso: ${report.messageId}',
        name: 'ReportRepository',
      );
    } catch (error) {
      LoggerService.error(
        'Erro ao enviar report: $error',
        name: 'ReportRepository',
      );

      if (error.toString().contains('network') ||
          error.toString().contains('timeout')) {
        throw DomainError.networkError;
      } else {
        throw DomainError.unexpected;
      }
    }
  }
}
