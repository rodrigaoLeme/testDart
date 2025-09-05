import '../../entities/feedback/report_entity.dart';

abstract class SubmitReport {
  Future<void> submit(ReportEntity report);
}
