import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/entities/chat/chat.dart';
import '../../../presentation/presenters/chat/chat_presenter.dart';
import '../../../share/utils/app_colors.dart';
import '../../helpers/helpers.dart';
import '../../mixins/mixins.dart';
import 'widgets/widgets.dart';

class ChatPage extends StatefulWidget {
  final ChatPresenter presenter;
  final String? conversationId; // Null = nova conversa
  final String? initialMessage; // Mensagem inicial para nova conversa
  final bool autoSend;

  const ChatPage({
    super.key,
    required this.presenter,
    this.conversationId,
    this.initialMessage,
    this.autoSend = false,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with LoadingManager, NavigationManager, UIErrorManager {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  bool _isComposing = false;
  bool isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();

    _messageController.addListener(() {
      final isComposing = _messageController.text.trim().isNotEmpty;
      if (isComposing != _isComposing) {
        setState(() {
          _isComposing = isComposing;
        });
      }
    });

    // Se tem mensagem inicial, coloca no campo
    if (widget.initialMessage != null) {
      _messageController.text = widget.initialMessage!;
      setState(() {
        _isComposing = true;
      });
    }

    // Listener pro foco
    _messageFocusNode.addListener(() {
      _updateVisibility();
    });

    _initializeChat();
  }

  void _initializeChat() {
    if (widget.conversationId != null) {
      // Carrega conversa existente
      widget.presenter.loadConversation(widget.conversationId!);
    } else if (widget.initialMessage != null && widget.autoSend) {
      // Cria nova conversa com mensagem inicial
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(); // Envia a mensagem inicial automaticamente
      });
    }
    // Se ambos forem null, fica em modo "nova conversa"
  }

  void _updateVisibility() {
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    // Atualiza estado do teclado se mudou
    if (keyboardVisible != isKeyboardVisible) {
      setState(() {
        isKeyboardVisible = keyboardVisible;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _addUserMessageToUI(message);

    if (widget.presenter.currentConversation == null) {
      // Cria nova conversa
      _processNewConversation(message);
    } else {
      // Envia mensagem na conversa existente
      _processExistingConversation(message);
    }

    _messageController.clear();
    setState(() {
      _isComposing = false;
    });

    _scrollToBottom();

    // Scroll para o final após enviar
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (_scrollController.hasClients) {
    //     _scrollController.animateTo(
    //       _scrollController.position.maxScrollExtent,
    //       duration: const Duration(milliseconds: 300),
    //       curve: Curves.easeOut,
    //     );
    //   }
    // });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _addUserMessageToUI(String message) {
    // Simula MessageEntity do usuário (temporário)
    final userMessage = MessageEntity(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.presenter.currentConversation?.id ?? 'temp',
      content: message,
      type: MessageType.user,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    // Atualiza UI imediatamente
    final currentMessages = widget.presenter.messages;
    final updatedMessages = [...currentMessages, userMessage];

    // Force update da UI (será substituído quando o presenter processar)
    setState(() {
      // Força rebuild da lista de mensagens
    });
  }

  void _processNewConversation(String message) async {
    try {
      // Cria conversa SEM loader
      await widget.presenter.createNewConversation(message);
    } catch (error) {
      // Mostra erro mas continua na tela
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar mensagem: $error')),
      );
    }
  }

  void _processExistingConversation(String message) async {
    try {
      await widget.presenter.sendMessage(message);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar mensagem: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    handleLoading(context, widget.presenter.isLoadingStream);
    handleNavigation(widget.presenter.navigateToStream);
    handleMainError(context, widget.presenter.mainErrorStream);

    return GestureDetector(
      onTap: () {
        if (_messageFocusNode.hasFocus) {
          _messageFocusNode.unfocus();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.blue,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            // Lista de mensagens
            Expanded(
              child: _buildMessagesList(),
            ),

            // Indicador de "pensando" (antes do typing)
            _buildThinkingIndicator(),

            // Indicador de digitação (se AI está respondendo)
            _buildTypingIndicator(),

            // Campo de input
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.darkBlue,
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          widget.presenter.goBack();
        },
        icon: const Icon(
          Icons.arrow_back,
          color: Colors.white,
          size: 24,
        ),
      ),
      title: StreamBuilder<ConversationEntity?>(
        stream: widget.presenter.currentConversationStream,
        builder: (context, snapshot) {
          final conversation =
              snapshot.data ?? widget.presenter.currentConversation;

          return Row(
            children: [
              Image.asset(
                'lib/ui/assets/images/logo/logo.png',
                height: 24,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '7Chat.ai',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  if (conversation != null)
                    Text(
                      conversation.title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<List<MessageEntity>>(
      stream: widget.presenter.messagesStream,
      builder: (context, snapshot) {
        final messages = snapshot.data ?? widget.presenter.messages;

        if (messages.isEmpty && !snapshot.hasData) {
          return _buildEmptyState();
        }

        // Auto-scroll quando novas mensagens chegam
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (snapshot.hasData && messages.isNotEmpty) {
            _scrollToBottom();
          }
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isLastMessage = index == messages.length - 1;

            return MessageBubble(
              message: message,
              isLastMessage: isLastMessage,
            );
          },
        );
      },
    );
  }

  // Widget para indicador de "pensando"
  Widget _buildThinkingIndicator() {
    return StreamBuilder<bool>(
      stream: widget.presenter.isThinkingStream,
      builder: (context, snapshot) {
        final isThinking = snapshot.data ?? widget.presenter.isThinking;

        if (!isThinking) {
          return const SizedBox.shrink();
        }

        return const ThinkingIndicator();
      },
    );
  }

  Widget _buildTypingIndicator() {
    return StreamBuilder<String>(
      stream: widget.presenter.typingTextStream,
      builder: (context, snapshot) {
        final typingText = snapshot.data ?? '';
        final isTyping = widget.presenter.isTyping;

        if (!isTyping || typingText.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TypingIndicator(
            text: typingText,
            onComplete: () {
              // Scroll quando digitação termina
              _scrollToBottom();
            },
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 5, 15, 15),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: AppColors.lightBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  maxLines: 5,
                  minLines: 3,
                  textInputAction: TextInputAction.newline,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: R.string.messagePlaceholder,
                    hintStyle: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _isComposing ? AppColors.primary : AppColors.lightGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _isComposing ? _sendMessage : null,
                  icon: Icon(
                    Icons.send,
                    color: _isComposing
                        ? AppColors.darkBlue
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.white24,
          ),
          SizedBox(height: 16),
          Text(
            'Inicie uma conversa!',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 18,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Digite sua mensagem abaixo',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}
