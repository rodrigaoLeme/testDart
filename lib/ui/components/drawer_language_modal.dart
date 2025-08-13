import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/entities.dart';
import '../../main/services/language_service.dart';
import '../../share/utils/app_colors.dart';
import '../helpers/helpers.dart';

class DrawerLanguageModal extends StatefulWidget {
  final Function(String) onLanguageChanged;

  const DrawerLanguageModal({
    super.key,
    required this.onLanguageChanged,
  });

  @override
  State<DrawerLanguageModal> createState() => _DrawerLanguageModalState();
}

class _DrawerLanguageModalState extends State<DrawerLanguageModal> {
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _selectedLanguage = LanguageService.instance.currentLanguageCode;
  }

  List<LanguageEntity> _getAvailableLanguages() {
    return [
      LanguageEntity(
        code: 'en',
        name: R.string.english,
        flag: 'lib/ui/assets/images/countries/en.png',
        isSelected: _selectedLanguage == 'en',
      ),
      LanguageEntity(
        code: 'pt_BR',
        name: R.string.portuguese,
        flag: 'lib/ui/assets/images/countries/br.png',
        isSelected: _selectedLanguage == 'pt_BR',
      ),
      LanguageEntity(
        code: 'es',
        name: R.string.spanish,
        flag: 'lib/ui/assets/images/countries/es.png',
        isSelected: _selectedLanguage == 'es',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkBlue,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildLanguagesList(),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.textPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            R.string.changeLanguage,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagesList() {
    final languages = _getAvailableLanguages();

    return Column(
      children: languages.map((language) {
        return _buildLanguageOption(language);
      }).toList(),
    );
  }

  Widget _buildLanguageOption(LanguageEntity language) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedLanguage = language.code;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  child: language.code == _selectedLanguage
                      ? Container(
                          margin: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Image.asset(
                  language.flag,
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                ),
                const SizedBox(width: 12),
                Text(
                  language.name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SafeArea(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(30, 16, 30, 5),
        child: ElevatedButton(
          onPressed: () async {
            HapticFeedback.selectionClick();
            await LanguageService.instance.changeLanguage(_selectedLanguage);
            widget.onLanguageChanged(_selectedLanguage);
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.lightGray,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check,
                color: AppColors.textPrimary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                R.string.save,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
