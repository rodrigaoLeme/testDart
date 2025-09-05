import '../../../data/repositories/report_repository.dart';
import '../http/http.dart';

ReportRepository makeReportRepository() => ReportRepository(
      httpClient: makeDioAdapter(),
      webhookUrl: 'https://autoflow.adv.st/webhook/ia-adventista',
    );
