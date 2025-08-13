import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/entities.dart';
import '../../main/services/language_service.dart';
import '../../share/utils/app_colors.dart';
import '../helpers/helpers.dart';
import './drawer_language_modal.dart';

class DrawerLanguageButton extends StatefulWidget {
  const DrawerLanguageButton({super.key});

  @override
  State<DrawerLanguageButton> createState() => _DrawerLanguageButtonState();
}

class _DrawerLanguageButtonState extends State<DrawerLanguageButton> {
  String _currentLanguageCode = 'en';

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  void _loadCurrentLanguage() {
    _currentLanguageCode = LanguageService.instance.currentLanguageCode;
  }

  LanguageEntity _getCurrentLanguageEntity() {
    switch (_currentLanguageCode) {
      case 'pt_BR':
        return LanguageEntity(
          code: 'pt_BR',
          name: 'Português',
          flag: 'lib/ui/assets/images/countries/br.png',
          isSelected: true,
        );
      case 'es':
        return LanguageEntity(
          code: 'es',
          name: 'Español',
          flag: 'lib/ui/assets/images/countries/es.png',
          isSelected: true,
        );
      default:
        return LanguageEntity(
          code: 'en',
          name: 'English',
          flag: 'lib/ui/assets/images/countries/en.png',
          isSelected: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = _getCurrentLanguageEntity();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            _showLanguageModal();
          },
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
                  'lib/ui/assets/images/icons/globe.png',
                  height: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    R.string.language,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Image.asset(
                  currentLanguage.flag,
                  width: 20,
                  height: 20,
                  fit: BoxFit.cover,
                ),
                const SizedBox(width: 8),
                Text(
                  currentLanguage.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textPrimary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DrawerLanguageModal(
        onLanguageChanged: (languageCode) {
          setState(() {
            _currentLanguageCode = languageCode;
          });
        },
      ),
    );
  }
}
