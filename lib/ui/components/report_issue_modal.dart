import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seven_chat_app/main/services/logger_service.dart';

import '../../share/utils/app_colors.dart';
import '../helpers/helpers.dart';

class ReportIssueModal extends StatefulWidget {
  final String messageContent;
  final String messageId;

  const ReportIssueModal({
    super.key,
    required this.messageContent,
    required this.messageId,
  });

  @override
  State<ReportIssueModal> createState() => _ReportIssueModalState();
}

class _ReportIssueModalState extends State<ReportIssueModal> {
  final TextEditingController _feedbackController = TextEditingController();
  final FocusNode _feedbackFocusNode = FocusNode();
  bool _isSubmitting = false;
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();

    _feedbackController.addListener(() {
      final isComposing = _feedbackController.text.trim().isNotEmpty;
      if (isComposing != _isComposing) {
        setState(() {
          _isComposing = isComposing;
        });
      }
    });

    // Auto-focus no campo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _feedbackFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _feedbackFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildContent(),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                'lib/ui/assets/images/icons/exclamation-triangle.png',
                height: 20,
              )),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  R.string.reportTextTooltipe,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  R.string.helpUsImproveIA,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            icon: const Icon(
              Icons.close,
              color: AppColors.textPrimary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mensagem original (preview)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.darkBlue.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.darkBlue,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${R.string.reportedMessage}:',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.messageContent.length > 100
                      ? '${widget.messageContent.substring(0, 100)}...'
                      : widget.messageContent,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Campo de feedback
          Text(
            '${R.string.describeTheProblem}:',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _feedbackController,
              focusNode: _feedbackFocusNode,
              maxLines: 4,
              minLines: 3,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
              decoration: InputDecoration(
                hintText: R.string.messageExample,
                hintStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Row(
          children: [
            // Botão Cancelar
            Expanded(
              child: TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: AppColors.lightBlue),
                child: Text(
                  R.string.cancel,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Botão Enviar
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed:
                    (_isComposing && !_isSubmitting) ? _submitReport : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isComposing ? AppColors.redDanger : AppColors.lightGray,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.darkBlue,
                        ),
                      )
                    : Text(
                        R.string.submit,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: _isComposing
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (!_isComposing || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      HapticFeedback.lightImpact();

      // TODO: Implementar envio para webhook
      final reportData = {
        'messageId': widget.messageId,
        'messageContent': widget.messageContent,
        'feedback': _feedbackController.text.trim(),
        'timestamp': DateTime.now().toIso8601String(),
        'userId': 'user_id_here', // TODO: Pegar do presenter
      };

      // Simula envio
      await Future.delayed(const Duration(seconds: 2));

      LoggerService.debug('Report enviado: $reportData', name: 'ReportIssue');

      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              R.string.feedbackSuccess,
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: AppColors.lightBlue,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (error) {
      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              R.string.feedbackError,
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}
