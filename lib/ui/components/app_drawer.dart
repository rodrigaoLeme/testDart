import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:seven_chat_app/ui/components/user_menu_button.dart';

import '../../domain/entities/entities.dart';
import '../../main/routes_app.dart';
import '../../presentation/presenters/home/home_presenter.dart';
import '../../share/utils/app_colors.dart';
import '../helpers/helpers.dart';
import 'components.dart';
import 'drawer_language_button.dart';

class AppDrawer extends StatelessWidget {
  final UserEntity? currentUser;
  final VoidCallback? onNewConversation;
  final Function(String)? onOpenConversation;
  final HomePresenter? homePresenter;
  final Function(String)? onDeleteCurrentConversation;
  const AppDrawer({
    super.key,
    this.currentUser,
    this.onNewConversation,
    this.onOpenConversation,
    this.homePresenter,
    this.onDeleteCurrentConversation,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HapticFeedback.lightImpact();
    });

    return Drawer(
      backgroundColor: AppColors.darkBlue,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            //_buildSearch(),
            //_buildMenuItems(context),
            _buildConversationsSection(context),
            _buildConversationHistory(),
            //const Spacer(),
            _buildBottomActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Center(
              child: Image.asset(
                'lib/ui/assets/images/logo/logo.png',
                height: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            '7chat.ai',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            icon: const Icon(
              Icons.close,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
  // Devem ser usados em uma próxima feature
  // Widget _buildSearch() {
  //   return Container(
  //     margin: const EdgeInsets.symmetric(horizontal: 16),
  //     padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
  //     decoration: BoxDecoration(
  //       color: AppColors.blue,
  //       borderRadius: BorderRadius.circular(20),
  //     ),
  //     child: Row(
  //       children: [
  //         const Icon(
  //           Icons.search,
  //           color: AppColors.textPrimary,
  //           size: 25,
  //         ),
  //         const SizedBox(width: 12),
  //         Text(
  //           R.string.search,
  //           style: const TextStyle(
  //               color: AppColors.textPrimary,
  //               fontFamily: 'Poppins',
  //               fontSize: 16,
  //               fontWeight: FontWeight.w500),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildMenuItems(BuildContext context) {
  //   final menuItems = [
  //     MenuItemEntity(
  //       id: 'manual',
  //       title: 'Church\'s manual',
  //       icon: 'book-atlas.png',
  //       route: '/manual',
  //     ),
  //     MenuItemEntity(
  //       id: 'missionary',
  //       title: 'Missionary book',
  //       icon: 'book-open.png',
  //       route: '/missionary',
  //     ),
  //     MenuItemEntity(
  //       id: 'agents',
  //       title: 'See more Agents',
  //       icon: 'plus.png',
  //       route: '/agents',
  //     ),
  //   ];

  //   return Container(
  //     margin: const EdgeInsets.only(top: 20),
  //     child: Column(
  //       children:
  //           menuItems.map((item) => _buildMenuItem(context, item)).toList(),
  //     ),
  //   );
  // }

  // Widget _buildMenuItem(BuildContext context, MenuItemEntity item) {
  //   return Container(
  //     margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  //     child: Material(
  //       color: Colors.transparent,
  //       child: InkWell(
  //         onTap: () {
  //           HapticFeedback.lightImpact();
  //           Navigator.of(context).pop();
  //           // Modular.to.pushNamed(item.route);
  //         },
  //         borderRadius: BorderRadius.circular(8),
  //         child: Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //           child: Row(
  //             children: [
  //               SizedBox(
  //                 width: 20,
  //                 child: Center(
  //                   child: Image.asset(
  //                     'lib/ui/assets/images/icons/${item.icon}',
  //                     height: 20,
  //                   ),
  //                 ),
  //               ),
  //               const SizedBox(width: 12),
  //               Text(
  //                 item.title,
  //                 style: const TextStyle(
  //                   color: AppColors.textPrimary,
  //                   fontFamily: 'Poppins',
  //                   fontSize: 16,
  //                   fontWeight: FontWeight.w500,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildConversationsSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título "Conversas". Deve ser reexibdo quando houver outros agentes
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 16),
          //   child: Text(
          //     R.string.conversations.toUpperCase(),
          //     style: const TextStyle(
          //       color: AppColors.textPrimary,
          //       fontFamily: 'Poppins',
          //       fontSize: 14,
          //       fontWeight: FontWeight.w500,
          //       letterSpacing: 0,
          //     ),
          //   ),
          // ),
          // const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).pop();

                  // CHAMA CALLBACK PARA NOVA CONVERSA
                  if (onNewConversation != null) {
                    onNewConversation!();
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'lib/ui/assets/images/icons/plus.png',
                        height: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        R.string.newConversation,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildConversationHistory() {
  //   if (homePresenter == null) {
  //     return const SizedBox.shrink();
  //   }

  //   return Expanded(
  //     child: StreamBuilder<List<ConversationEntity>>(
  //         stream: homePresenter!.conversationsStream,
  //         initialData: homePresenter!.conversations,
  //         builder: (context, snapshot) {
  //           final conversations = snapshot.data ?? [];

  //           if (conversations.isEmpty) {
  //             return const SizedBox();
  //           }

  //           return Container(
  //             margin: const EdgeInsets.symmetric(vertical: 8),
  //             child: ListView.builder(
  //               padding: EdgeInsets.zero,
  //               physics: const BouncingScrollPhysics(),
  //               itemCount: conversations.length,
  //               itemBuilder: (context, index) {
  //                 return _buildConversationItem(conversations[index]);
  //               },
  //             ),
  //           );
  //         }),
  //   );
  // }

  Widget _buildConversationHistory() {
    return Expanded(
      child: StreamBuilder<List<ConversationEntity>>(
        stream: homePresenter!.conversationsStream,
        builder: (context, snapshot) {
          final conversations = snapshot.data ?? homePresenter!.conversations;

          if (conversations.isEmpty) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.only(top: 16),
            constraints: const BoxConstraints(maxHeight: 300), // Altura máxima
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                // Detecta quando usuário está próximo do final
                if (scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent - 100) {
                  // Carrega mais conversas automaticamente
                  if (homePresenter!.hasMoreConversations &&
                      !homePresenter!.isLoadingMore) {
                    homePresenter!.loadMoreConversations();
                  }
                }
                return false;
              },
              child: ListView.builder(
                itemCount: conversations.length +
                    (homePresenter!.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  // Conversas normais
                  if (index < conversations.length) {
                    final conversation = conversations[index];
                    return _buildConversationItem(conversation, context);
                  }

                  // Indicador de loading
                  if (homePresenter!.isLoadingMore) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textSecondary),
                          ),
                        ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversationItem(
      ConversationEntity conversation, BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onOpenConversation?.call(conversation.id);
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            _showConversationOptions(conversation, context);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              conversation.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    if (currentUser != null) {
      return Column(
        children: [
          UserMenuButton(user: currentUser!),
          const SizedBox(height: 16),
        ],
      );
    } else {
      return Column(
        children: [
          WhatsAppLauncherButton(
            phoneNumber: '5512982000062',
            icon: 'esperanca.png',
            title: R.string.hopeBot,
          ),
          const DrawerLanguageButton(),
          _buildBottomAction(
            icon: 'faq.png',
            title: R.string.faq,
            onTap: () {
              HapticFeedback.selectionClick();
              Modular.to.pushNamed('/faq');
            },
          ),
          _buildBottomAction(
            icon: 'login.png',
            title: 'Login',
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).pop();
              Modular.to.pushNamed(Routes.login);
            },
          ),
          const SizedBox(height: 16),
        ],
      );
    }
  }

  Widget _buildBottomAction({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Image.asset(
                  'lib/ui/assets/images/icons/$icon',
                  height: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showConversationOptions(
      ConversationEntity conversation, BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkBlue,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle do modal
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Título da conversa
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  conversation.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),

              // Opção de deletar
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                title: Text(
                  R.string.deleteConversation,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop(); // Fecha o modal
                  _confirmDeleteConversation(conversation, context);
                },
              ),

              // Cancelar
              ListTile(
                leading: const Icon(
                  Icons.cancel_outlined,
                  color: AppColors.textPrimary,
                ),
                title: Text(
                  R.string.cancel,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteConversation(
      ConversationEntity conversation, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.darkBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            R.string.deleteConversation,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          content: Text(
            '${R.string.msgSureDeleteConversation} "${conversation.title}"?\n\n${R.string.msgActionCannotBeUndone}.',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                R.string.cancel,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                try {
                  // Mostra loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        R.string.msgDeletingConversation,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                        ),
                      ),
                      backgroundColor: AppColors.lightBlue,
                    ),
                  );

                  // Deleta a conversa
                  homePresenter?.deleteConversation(conversation.id);

                  // Verifica se é a conversa atual aberta
                  if (onDeleteCurrentConversation != null) {
                    onDeleteCurrentConversation!(conversation.id);
                  }

                  // Sucesso
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        R.string.conversationDeletedSuccessfully,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                        ),
                      ),
                      backgroundColor: AppColors.darkBlue,
                    ),
                  );
                } catch (error) {
                  // Erro
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${R.string.errorDeletingConversation}: $error',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                        ),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(
                R.string.delete,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
