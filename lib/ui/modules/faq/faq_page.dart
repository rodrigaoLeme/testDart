import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/entities/entities.dart';
import '../../../main/services/language_service.dart';
import '../../../presentation/presenters/faq/faq_presenter.dart';
import '../../../share/utils/app_colors.dart';
import '../../components/faq_item_tile.dart';
import '../../helpers/helpers.dart';
import '../../mixins/mixins.dart';

class FAQPage extends StatefulWidget {
  final FAQPresenter presenter;

  const FAQPage({super.key, required this.presenter});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage>
    with LoadingManager, NavigationManager, UIErrorManager {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late StreamSubscription _languageSubscription;
  String _currentLanguage = '';

  @override
  void initState() {
    super.initState();
    _currentLanguage = LanguageService.instance.currentLanguageCode;

    Future.microtask(() => widget.presenter.refreshFAQ());

    _searchController.addListener(() {
      widget.presenter.searchFAQ(_searchController.text);
    });

    _languageSubscription = Stream.periodic(
      const Duration(milliseconds: 500),
      (count) => LanguageService.instance.currentLanguageCode,
    ).distinct().listen((newLanguage) {
      if (mounted && newLanguage != _currentLanguage) {
        _currentLanguage = newLanguage;

        // Recarrega FAQ com novo idioma
        widget.presenter.loadFAQ();

        // Força rebuild da página para atualizar textos estáticos
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _languageSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    handleLoading(context, widget.presenter.isLoadingStream);
    handleNavigation(widget.presenter.navigateToStream);
    handleMainError(context, widget.presenter.mainErrorStream);

    return Scaffold(
      backgroundColor: AppColors.blue,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.darkBlue,
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
        icon: const Icon(
          Icons.arrow_back,
          color: Colors.white,
          size: 24,
        ),
      ),
      title: Text(
        R.string.faq.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildHeader(),
        _buildSearchBar(),
        Expanded(child: _buildFAQList()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Image.asset(
            'lib/ui/assets/images/logo/logo.png',
            width: 80,
          ),
          const SizedBox(height: 16),
          Text(
            R.string.faq.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            R.string.faqLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            color: AppColors.textPrimary,
            size: 25,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
              decoration: InputDecoration(
                hintText: R.string.search,
                hintStyle: const TextStyle(
                  color: Colors.white54,
                  fontFamily: 'Poppins',
                ),
                border: InputBorder.none,
              ),
              onChanged: (value) {},
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                _searchFocusNode.unfocus();
              },
              icon: const Icon(
                Icons.close,
                color: Colors.white54,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFAQList() {
    return StreamBuilder<List<FAQItemEntity>>(
      stream: widget.presenter.faqItemsStream,
      builder: (context, snapshot) {
        final faqItems = snapshot.data ?? widget.presenter.faqItems;

        if (faqItems.isEmpty &&
            snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (faqItems.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: widget.presenter.refreshFAQ,
          color: AppColors.primary,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: ListView.builder(
              itemCount: faqItems.length,
              itemBuilder: (context, index) {
                return FAQItemTile(item: faqItems[index]);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          Text(
            R.string.loadQuestions,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchController.text.isNotEmpty
                ? Icons.search_off
                : Icons.help_outline,
            color: Colors.white54,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? R.string.noQuestionsFounded
                : R.string.noQuestionsAvaliable,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              color: Colors.white54,
            ),
          ),
          if (_searchController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              R.string.tryDiferentSequences,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.white38,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
