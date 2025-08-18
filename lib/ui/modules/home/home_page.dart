import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:seven_chat_app/domain/entities/entities.dart';

import '../../../domain/entities/chat/chat.dart';
import '../../../main/routes_app.dart';
import '../../../main/services/logger_service.dart';
import '../../../presentation/presenters/chat/chat_presenter.dart';
import '../../../presentation/presenters/home/home_presenter.dart';
import '../../../share/ds/ds_logo.dart';
import '../../../share/utils/app_colors.dart';
import '../../components/components.dart';
import '../../helpers/helpers.dart';
import 'widgets/widgets.dart';

class HomePage extends StatefulWidget {
  final HomePresenter presenter;
  final ChatPresenter chatPresenter;
  const HomePage({
    super.key,
    required this.presenter,
    required this.chatPresenter,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool isTyping = false;
  bool isKeyboardVisible = false;
  bool isInChatMode = false;
  final bool _shouldScrollToNewMessage = false;

  // VARIÁVEIS PARA CONTROLE DE SCROLL
  bool _userIsScrolling = false;
  bool _autoScrollEnabled = true;
  Timer? _scrollDebounceTimer;

  @override
  void initState() {
    super.initState();
    widget.presenter.loadCurrentUser();

    // tenta pegar do cache se já existir
    _tryLoadCachedSuggestions();

    // observer para detectar mudanças de teclado mais rapidamente
    WidgetsBinding.instance.addObserver(this);

    // velocidade aumentada para sincar
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Listener pro texto
    _controller.addListener(() {
      final text = _controller.text.trim();
      if (text.isNotEmpty != isTyping) {
        setState(() {
          isTyping = text.isNotEmpty;
        });
        _updateVisibility();
      }
    });

    // Listener pro foco
    _focusNode.addListener(() {
      _updateVisibility();
    });

    // Escuta mudanças no chat
    widget.chatPresenter.messagesStream.listen((messages) {
      setState(() {
        isInChatMode = messages.isNotEmpty;
      });
      _updateVisibility();
    });

    // 🚀 LISTENER PARA DETECTAR SCROLL MANUAL DO USUÁRIO
    _scrollController.addListener(_onScrollChanged);
  }

  void _tryLoadCachedSuggestions() {
    // Se já foi carregado no splash, o stream já vai ter dados
    // Se não foi, vai usar as suggestions padrão sem loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Pequeno delay para permitir que o presenter seja configurado
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && widget.presenter.suggestions.isEmpty) {
          // Só carrega se realmente não tem nada (rare case)
          widget.presenter.loadSuggestions();
        }
      });
    });
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // delay pro contexto ser atualizado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateVisibility();
      }
    });
  }

  void _updateVisibility() {
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    // Só esconde conteúdo superior quando:
    // Está no modo chat ou
    // há FOCO + TECLADO ou
    //quando está digitando
    final shouldHideTopContent =
        isInChatMode || (_focusNode.hasFocus && keyboardVisible) || isTyping;

    if (keyboardVisible != isKeyboardVisible) {
      setState(() {
        isKeyboardVisible = keyboardVisible;
      });
    }

    // Controle da animação
    if (shouldHideTopContent &&
        _animationController.status != AnimationStatus.forward &&
        _animationController.status != AnimationStatus.completed) {
      _animationController.forward();
    } else if (!shouldHideTopContent &&
        _animationController.status != AnimationStatus.reverse &&
        _animationController.status != AnimationStatus.dismissed) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollDebounceTimer?.cancel();
    _scrollController.removeListener(_onScrollChanged);
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSuggestionTap(String suggestion) {
    _controller.text = suggestion;

    setState(() {
      isTyping = true;
    });
    _focusNode.requestFocus();

    // ENVIA AUTOMATICAMENTE
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleSendMessage();
    });
  }

  void _handleSendMessage() {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    // FECHA O TECLADO IMEDIATAMENTE
    _focusNode.unfocus();

    // ENTRA NO MODO CHAT
    setState(() {
      isInChatMode = true;
      isTyping = false;
    });

    // PROCESSA MENSAGEM VIA CHAT PRESENTER
    if (widget.chatPresenter.currentConversation == null) {
      widget.chatPresenter.createNewConversation(message);
    } else {
      widget.chatPresenter.sendMessage(message);
    }

    _controller.clear();
    _updateVisibility();

    // SCROLL PARA O FINAL
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      },
    );
  }

  // NOVA CONVERSA (chamado pelo drawer)
  void startNewConversation() {
    setState(() {
      isInChatMode = false;
      isTyping = false;
    });

    // LIMPA CHAT PRESENTER
    widget.chatPresenter.clearCurrentConversation();

    _controller.clear();
    _focusNode.unfocus();
    _updateVisibility();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateVisibility();

    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments?['shouldReloadUser'] == true) {
      widget.presenter.loadCurrentUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserEntity?>(
      stream: widget.presenter.currentUserStream,
      builder: (context, snapshot) {
        final currentUser = snapshot.data;

        return GestureDetector(
          onTap: () {
            if (_focusNode.hasFocus) {
              _focusNode.unfocus();
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.blue,
            drawer: AppDrawer(
              currentUser: currentUser,
              onNewConversation: startNewConversation,
            ),
            onDrawerChanged: (isOpened) {
              if (!isOpened) {
                HapticFeedback.lightImpact();
              }
            },
            appBar: _buildAppBar(currentUser),
            body: Column(
              children: [
                // CONTEÚDO SUPERIOR (logo/slogan) OU CHAT
                Expanded(
                  child:
                      isInChatMode ? _buildChatContent() : _buildHomeContent(),
                ),
                // SUGGESTIONS (só quando não está no chat)
                if (!isInChatMode)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    height: isTyping ? 0 : 60,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 100),
                      opacity: isTyping ? 0 : 1,
                      child: _buildSuggestions(),
                    ),
                  ),

                // INPUT (sempre presente)
                _buildMessageInput(),
              ],
            ),
          ),
        );
      },
    );
  }

  // CONTEÚDO QUANDO EM MODO HOME
  Widget _buildHomeContent() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -50 * (1 - _fadeAnimation.value)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: _fadeAnimation.value > 0
                ? _buildTopContent()
                : const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  // CONTEÚDO QUANDO EM MODO CHAT
  Widget _buildChatContent() {
    return Column(
      children: [
        // Lista de mensagens
        Expanded(
          child: _buildIntegratedMessagesList(),
        ),
      ],
    );
  }

  // Lista integrada com indicadores
  Widget _buildIntegratedMessagesList() {
    return StreamBuilder<List<MessageEntity>>(
      stream: widget.chatPresenter.messagesStream,
      builder: (context, snapshot) {
        final messages = snapshot.data ?? widget.chatPresenter.messages;

        return StreamBuilder<bool>(
          stream: widget.chatPresenter.isThinkingStream,
          builder: (context, thinkingSnapshot) {
            final isThinking =
                thinkingSnapshot.data ?? widget.chatPresenter.isThinking;

            return StreamBuilder<String>(
              stream: widget.chatPresenter.typingTextStream,
              builder: (context, typingSnapshot) {
                final typingText = typingSnapshot.data ?? '';
                final isTyping = widget.chatPresenter.isTyping;

                if (messages.isEmpty && !isThinking) {
                  return const SizedBox.shrink();
                }

                // 🚀 SÓ FAZ AUTO-SCROLL SE PERMITIDO
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_autoScrollEnabled &&
                      !_shouldScrollToNewMessage &&
                      (snapshot.hasData ||
                          isThinking ||
                          (isTyping && typingText.isNotEmpty))) {
                    _scrollToBottom();
                  }
                });

                return Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      // Conta mensagens + indicadores ativos
                      itemCount: messages.length +
                          (isThinking ? 1 : 0) +
                          (isTyping && typingText.isNotEmpty ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Mensagens normais
                        if (index < messages.length) {
                          final message = messages[index];
                          final isLastMessage = index == messages.length - 1;

                          return MessageBubble(
                            message: message,
                            isLastMessage: isLastMessage,
                          );
                        }

                        // Indicador de "pensando" logo após a última mensagem
                        if (isThinking && index == messages.length) {
                          return const ThinkingIndicator();
                        }

                        // Indicador de "digitando" após o "pensando" ou mensagens
                        if (isTyping && typingText.isNotEmpty) {
                          return Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 0, vertical: 8),
                            child: TypingIndicator(
                              text: typingText,
                              onComplete: () {
                                _scrollToBottom();
                              },
                            ),
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    ),
                    // BOTÃO FLUTUANTE "VOLTAR AO FINAL"
                    if (!_autoScrollEnabled && _userIsScrolling)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: AnimatedOpacity(
                          opacity: _userIsScrolling ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: FloatingActionButton.small(
                            onPressed: _jumpToBottom,
                            backgroundColor: AppColors.lightBlue,
                            child: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients || !_autoScrollEnabled) {
      LoggerService.debug('Auto-scroll desabilitado', name: 'ScrollControl');
      return;
    }

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // MÉTODO PARA USUÁRIO FORÇAR IR AO FINAL
  void _jumpToBottom() {
    if (!_scrollController.hasClients) return;

    // Força ir ao final e reabilita auto-scroll
    setState(() {
      _userIsScrolling = false;
      _autoScrollEnabled = true;
    });

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );

    LoggerService.debug('Usuário forçou ir ao final', name: 'ScrollControl');
  }

  // DETECTA QUANDO USUÁRIO FAZ SCROLL MANUAL
  void _onScrollChanged() {
    if (!_scrollController.hasClients) return;

    final currentPosition = _scrollController.offset;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final isAtBottom =
        (maxScroll - currentPosition) < 100; // 100px de tolerância

    // Se usuário scrollou para cima (não está no final), desabilita auto-scroll
    if (!isAtBottom && _autoScrollEnabled) {
      setState(() {
        _userIsScrolling = true;
        _autoScrollEnabled = false;
      });

      LoggerService.debug('🤚 Usuário tomou controle do scroll',
          name: 'ScrollControl');

      // Timer para reabilitar auto-scroll se usuário voltar ao final
      _scrollDebounceTimer?.cancel();
      _scrollDebounceTimer = Timer(const Duration(seconds: 2), () {
        if (mounted && _scrollController.hasClients) {
          final currentMax = _scrollController.position.maxScrollExtent;
          final currentPos = _scrollController.offset;
          final stillAtBottom = (currentMax - currentPos) < 100;

          if (stillAtBottom) {
            setState(() {
              _userIsScrolling = false;
              _autoScrollEnabled = true;
            });
            LoggerService.debug('✅ Auto-scroll reabilitado',
                name: 'ScrollControl');
          }
        }
      });
    }

    // Se usuário scrollou até o final, reabilita auto-scroll imediatamente
    else if (isAtBottom && !_autoScrollEnabled) {
      setState(() {
        _userIsScrolling = false;
        _autoScrollEnabled = true;
      });
      LoggerService.debug('✅ Auto-scroll reabilitado (usuário no final)',
          name: 'ScrollControl');
    }
  }

  PreferredSizeWidget _buildAppBar(UserEntity? currentUser) {
    return AppBar(
      backgroundColor: AppColors.darkBlue,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white, size: 24),
      title: Row(
        children: [
          Image.asset(
            'lib/ui/assets/images/logo/logo.png',
            height: 24,
          ),
          const SizedBox(width: 8),
          const Text(
            '7chat.ai',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        if (currentUser == null)
          LoginButton(
            onTap: () {
              Modular.to.pushNamed(Routes.login);
            },
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTopContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const DSLogo(type: DSLogoType.white, widht: 140),
          const SizedBox(height: 30),
          const Text(
            '7Chat.ai',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 24,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            R.string.homeMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w400,
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 25),
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.textSecondary,
            size: 25,
          ),
          const SizedBox(height: 8),
          Text(
            R.string.messageWarning.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return StreamBuilder<List<SuggestionEntity>>(
      stream: widget.presenter.suggestionsStream,
      builder: (context, snapshot) {
        final suggestions = snapshot.data ?? widget.presenter.suggestions;

        if (suggestions.isEmpty) {
          // se não carregou ainda
          return const SizedBox(height: 48);
        }

        return SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return SuggestionChip(
                text: suggestion.text,
                onTap: () => _handleSuggestionTap(suggestion.text),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(15),
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
                  controller: _controller,
                  focusNode: _focusNode,
                  minLines: 3,
                  maxLines: 5,
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
                  color: isTyping ? AppColors.primary : AppColors.lightGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: isTyping ? _handleSendMessage : null,
                  icon: Icon(
                    Icons.send,
                    color:
                        isTyping ? AppColors.darkBlue : AppColors.textSecondary,
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
}
