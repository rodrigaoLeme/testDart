import 'package:flutter/material.dart';

import '../../../../ui/modules/chat/chat_page.dart';
import '../../presenters/chat/chat_presenter_factory.dart';

Widget makeChatPage({
  String? conversationId,
  String? initialMessage,
  bool autoSend = false,
}) =>
    ChatPage(
      presenter: makeChatPresenter(),
      conversationId: conversationId,
      initialMessage: initialMessage,
      autoSend: autoSend,
    );
