import './translation.dart';

class Us implements Translation {
  // ACCOUNT
  @override
  String get passwordNotMatch => 'The passwords do not match.';
  @override
  String get codeBaseInvalid => 'Invalid base code.';
  @override
  String get incorrectPassword => 'Invalid password';
  @override
  String get reload => 'Reload';

  // MESSAGES
  @override
  String get msgEmailInUse => 'The email is already in use.';
  @override
  String get msgInvalidCredentials =>
      'Incorrect email or password. Please try again.';
  @override
  String get msgInvalidField => 'Invalid email';
  @override
  String get msgRequiredField => 'Required';
  @override
  String get msgUnexpectedError =>
      'Failed to load information. Please try again soon.';
  @override
  String get feedbackSuccess =>
      'Feedback sent successfully! Thank you for helping us improve.';
  @override
  String get feedbackError => 'Error sending feedback. Please try again.';

  //BUTTON
  @override
  String get next => 'Next';
  @override
  String get cancel => 'Cancel';
  @override
  String get logoutBtn => 'logout';
  @override
  String get loginBtn => 'Login';
  @override
  String get submit => 'Submit';

  // SHARED
  @override
  String get sloganApp =>
      'Artificial Intelligence of the Seventh-day\nAdventist Church in South America';
  @override
  String get sendFeedback => 'Send feedback';
  @override
  String get noConnectionsAvailable => 'No connections available';
  @override
  String get search => 'Search';
  @override
  String get conversations => 'Conversations';
  @override
  String get newConversation => 'New conversation';
  @override
  String get faq => 'faq';
  @override
  String get sureLogout => 'Are you sure you want to log out?';
  @override
  String get msgCopiedToClipboard => 'Text copied!';
  @override
  String get copyLabel => 'Copy';
  @override
  String get selectAllLabel => 'Select all';
  @override
  String get copyTextTooltipe => 'Copy text';
  @override
  String get reportTextTooltipe => 'Report problem';
  @override
  String get helpUsImproveIA => 'Help us improve AI';
  @override
  String get reportedMessage => 'Reported message';
  @override
  String get describeTheProblem => 'Describe the problem';
  @override
  String get messageExample =>
      'Ex: The answer is incorrect, does not answer the question, outdated information...';
  @override
  String get thinking => 'Thinking';

  //PAGES
  @override
  String get successTitle => 'Success';
  @override
  String get checkInternetAccess => 'Check if the device has internet access';
  @override
  String get youAreOffline => 'It looks like you are offline';
  @override
  String get anErrorHasOccurred => 'Something went wrong';
  @override
  String get settings => 'Settings';
  @override
  String get language => 'Language';
  @override
  String get provider => 'Provider';
  @override
  String get logout => 'Logout';
  @override
  String get changeLanguage => 'Change language';
  @override
  String get save => 'Save';
  @override
  String get english => 'English';
  @override
  String get portuguese => 'Português';
  @override
  String get spanish => 'Español';
  @override
  String get faqLabel =>
      'Find answers to the most common questions about the Adventist AI Assistant, how it works, and how to use it in the best possible way.';
  @override
  String get loadQuestions => 'Loading questions...';
  @override
  String get tryDiferentSequences => 'Try using different words';
  @override
  String get noQuestionsFounded => 'No questions found';
  @override
  String get noQuestionsAvaliable => 'No questions available';
  @override
  String get homeMessage =>
      'This is the official Artificial\nIntelligence of the Seventh-day\nAdventist Church in South America.';
  @override
  String get messageWarning =>
      'The adventist AI assistant may make mistakes.\nVerify important information.';
  @override
  String get messagePlaceholder => 'Type your message...';

  // Social Login
  @override
  String get loginWithApple => 'Continue with Apple';
  @override
  String get loginWithFacebook => 'Continue with Facebook';
  @override
  String get loginWithGoogle => 'Continue with Google';
  @override
  String get loginWithMicrosoft => 'Continue with Microsoft';
  @override
  String get authCancelled => 'Login cancelled by user';
  @override
  String get authInProgress => 'Login already in progress';
  @override
  String get networkError => 'Network connection problem';
  @override
  String get configurationError => 'Authentication configuration error';
  @override
  String get accountDisabled => 'Account has been disabled';
  @override
  String get tooManyRequests => 'Too many login attempts. Try again later';
  @override
  String get webContextCancelled => 'Authentication process canceled by user';
}
