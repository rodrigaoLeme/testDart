import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:seven_chat_app/ui/components/user_menu_button.dart';

import '../../domain/entities/entities.dart';
import '../../main/routes_app.dart';
import '../../share/utils/app_colors.dart';
import '../helpers/helpers.dart';
import 'drawer_language_button.dart';

class AppDrawer extends StatelessWidget {
  final UserEntity? currentUser;
  final VoidCallback? onNewConversation;
  const AppDrawer({
    super.key,
    this.currentUser,
    this.onNewConversation,
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
            _buildSearch(),
            //_buildMenuItems(context),
            _buildConversationsSection(context),
            _buildConversationHistory(),
            const Spacer(),
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

  Widget _buildSearch() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            color: AppColors.textPrimary,
            size: 25,
          ),
          const SizedBox(width: 12),
          Text(
            R.string.search,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

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
      margin: const EdgeInsets.only(top: 32),
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

  Widget _buildConversationHistory() {
    // FUTURO: Lista das conversas recentes
    final conversations = [];

    if (conversations.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        children: conversations
            .map((conversation) => _buildConversationItem(conversation))
            .toList(),
      ),
    );
  }

  Widget _buildConversationItem(String title) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            // FUTURO: Abrir conversa específica
            // onOpenConversation?.call(conversationId);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              title,
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
}
