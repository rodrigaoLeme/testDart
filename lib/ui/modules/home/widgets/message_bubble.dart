import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/entities/chat/chat.dart';
import '../../../../share/utils/app_colors.dart';
import '../../../components/components.dart';
import '../../../helpers/i18n/resources.dart';

class MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isLastMessage;

  const MessageBubble({
    super.key,
    required this.message,
    this.isLastMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.type == MessageType.user;
    final isAssistant = message.type == MessageType.assistant;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width,
                  ),
                  margin: EdgeInsets.only(
                    left: isUser ? 48 : 0,
                    bottom: isUser ? 10 : 0,
                    right: isUser ? 8 : 0,
                  ),
                  padding: isUser
                      ? const EdgeInsets.symmetric(horizontal: 16, vertical: 15)
                      : const EdgeInsets.all(0),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.lightBlue : Colors.transparent,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(10),
                      topRight: const Radius.circular(10),
                      bottomLeft: isUser
                          ? const Radius.circular(10)
                          : const Radius.circular(10),
                      bottomRight: isUser
                          ? const Radius.circular(10)
                          : const Radius.circular(10),
                    ),
                  ),
                  child: _buildMessageContent(context, isUser),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 5,
          ),
          if (isAssistant) ...[
            const SizedBox(height: 12),
            _buildFeedbackButtons(context),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, bool isUser) {
    const textColor = AppColors.textPrimary;

    if (isUser) {
      // Usuário: Texto normal
      return Text(
        message.content,
        style: const TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
          height: 1.4,
        ),
      );
    } else {
      // ✅ IA: Texto SELECIONÁVEL
      return SelectableText(
        message.content,
        style: const TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
          height: 1.4,
        ),
        // Configurações de seleção
        cursorColor: AppColors.primary,
        selectionControls: MaterialTextSelectionControls(),
        contextMenuBuilder: (context, editableTextState) {
          return AdaptiveTextSelectionToolbar.buttonItems(
            anchors: editableTextState.contextMenuAnchors,
            buttonItems: [
              ContextMenuButtonItem(
                label: R.string.copyLabel,
                onPressed: () {
                  editableTextState
                      .copySelection(SelectionChangedCause.toolbar);
                },
              ),
              ContextMenuButtonItem(
                label: R.string.selectAllLabel,
                onPressed: () {
                  editableTextState.selectAll(SelectionChangedCause.toolbar);
                },
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildFeedbackButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFeedbackButton(
            icon: 'copy.png',
            tooltip: R.string.copyTextTooltipe,
            onTap: () => _copyToClipboard(context),
            paddingLeft: false,
          ),
          const SizedBox(width: 12),
          _buildFeedbackButton(
            icon: 'exclamation-triangle.png',
            tooltip: R.string.reportTextTooltipe,
            onTap: () => _showReportModal(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackButton({
    required String icon,
    required String tooltip,
    required VoidCallback onTap,
    bool paddingLeft = true,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            padding: EdgeInsets.only(
              left: paddingLeft ? 10 : 0,
              right: 10,
              top: 10,
              bottom: 10,
            ),
            color: Colors.transparent,
            child: Image.asset(
              'lib/ui/assets/images/icons/$icon',
              height: 16,
            ),
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.content));

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 80,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              R.string.msgCopiedToClipboard,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    // Remove depois de 2 segundos
    Future.delayed(const Duration(seconds: 2)).then((_) => entry.remove());
  }

  // Mostrar modal de report
  void _showReportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ReportIssueModal(
        messageContent: message.content,
        messageId: message.id,
      ),
    );
  }
}
