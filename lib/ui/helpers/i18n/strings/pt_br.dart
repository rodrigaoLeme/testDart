import './translation.dart';

class PtBr implements Translation {
  // ACCOUNT
  @override
  String get passwordNotMatch => 'As senhas não coincidem.';
  @override
  String get codeBaseInvalid => 'Código da base inválido.';
  @override
  String get incorrectPassword => 'Senha inválida';
  @override
  String get reload => 'Recarregar';

  // MESSAGES
  @override
  String get msgEmailInUse => 'O e-mail já está em uso.';
  @override
  String get msgInvalidCredentials =>
      'E-mail ou senha incorretos. Por favor, tente novamente.';
  @override
  String get msgInvalidField => 'E-mail inválido';
  @override
  String get msgRequiredField => 'Campo obrigatório';
  @override
  String get msgUnexpectedError =>
      'Falha ao carregar informações. Por favor, tente novamente em breve.';
  @override
  String get feedbackSuccess =>
      'Feedback enviado com sucesso! Obrigado por nos ajudar a melhorar.';
  @override
  String get feedbackError => 'Erro ao enviar feedback. Tente novamente.';

  //BUTTON
  @override
  String get next => 'Próximo';
  @override
  String get cancel => 'Cancelar';
  @override
  String get logoutBtn => 'Logout';
  @override
  String get loginBtn => 'Login';
  @override
  String get submit => 'Enviar';

  // SHARED
  @override
  String get sloganApp =>
      'Inteligência Artifical da Igreja Adventista\ndo Sétivo dia na América do Sul';
  @override
  String get sendFeedback => 'Enviar feedback';
  @override
  String get noConnectionsAvailable => 'Sem conexão';
  @override
  String get search => 'Buscar';
  @override
  String get conversations => 'Conversas';
  @override
  String get newConversation => 'Nova conversa';
  @override
  String get faq => 'faq';
  @override
  String get sureLogout => 'Tem certeza que deseja sair?';
  @override
  String get msgCopiedToClipboard => 'Texto copiado!';
  @override
  String get copyLabel => 'Copiar';
  @override
  String get selectAllLabel => 'Selecionar tudo';
  @override
  String get copyTextTooltipe => 'Copiar texto';
  @override
  String get reportTextTooltipe => 'Reportar problema';
  @override
  String get helpUsImproveIA => 'Nos ajude a melhorar a IA';
  @override
  String get reportedMessage => 'Mensagem reportada';
  @override
  String get describeTheProblem => 'Descreva o problema';
  @override
  String get messageExample =>
      'Ex: A resposta está incorreta, não responde a pergunta, informação desatualizada...';
  @override
  String get thinking => 'Pensando';

  //PAGES
  @override
  String get successTitle => 'Sucesso';
  @override
  String get checkInternetAccess =>
      'Confira se o dispositive tem acesso à internet';
  @override
  String get youAreOffline => 'Parece que você está desconectado';
  @override
  String get anErrorHasOccurred => 'Algo deu errado';
  @override
  String get settings => 'Configurações';
  @override
  String get language => 'Idioma';
  @override
  String get provider => 'Provedor';
  @override
  String get logout => 'Logout';
  @override
  String get changeLanguage => 'Alterar idioma';
  @override
  String get save => 'Salvar';
  @override
  String get english => 'Inglês';
  @override
  String get portuguese => 'Português';
  @override
  String get spanish => 'Espanhol';
  @override
  String get faqLabel =>
      'Encontre respostas para as perguntas mais comuns sobre o Adventist AI Assistant, como ele funciona e como usá-lo da melhor maneira possível.';
  @override
  String get loadQuestions => 'Carregando perguntas...';
  @override
  String get tryDiferentSequences => 'Tente usar palavras diferentes';
  @override
  String get noQuestionsFounded => 'Nenhuma pergunta encontrada';
  @override
  String get noQuestionsAvaliable => 'Nenhuma pergunta disponível';
  @override
  String get homeMessage =>
      'Esta é a Inteligência Artificial oficial\nda Igreja Adventista do Sétimo Dia\nna América do Sul.';
  @override
  String get messageWarning =>
      'O assistente de IA adventista pode cometer erros.\nVerifique informações importantes.';
  @override
  String get messagePlaceholder => 'Digite sua mensagem...';

  // Login Social
  @override
  String get loginWithApple => 'Continuar com Apple';
  @override
  String get loginWithFacebook => 'Continuar com Facebook';
  @override
  String get loginWithGoogle => 'Continuar com Google';
  @override
  String get loginWithMicrosoft => 'Continuar com Microsoft';
  @override
  String get authCancelled => 'Login cancelado pelo usuário';
  @override
  String get authInProgress => 'Login já está em andamento';
  @override
  String get networkError => 'Problema de conexão com a internet';
  @override
  String get configurationError => 'Erro de configuração da autenticação';
  @override
  String get accountDisabled => 'Conta foi desabilitada';
  @override
  String get tooManyRequests =>
      'Muitas tentativas de login. Tente novamente mais tarde';
  @override
  String get webContextCancelled =>
      'Processo de autenticação cancelado pelo usuário';
}
