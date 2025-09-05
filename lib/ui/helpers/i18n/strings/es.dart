import './translation.dart';

class Es implements Translation {
  // ACCOUNT
  @override
  String get passwordNotMatch => 'Las contraseñas no coinciden.';
  @override
  String get codeBaseInvalid => 'Código base no válido.';
  @override
  String get incorrectPassword => 'Contraseña inválida';
  @override
  String get reload => 'Recargar';

  // MESSAGES
  @override
  String get msgEmailInUse => 'El correo electrónico ya está en uso.';
  @override
  String get msgInvalidCredentials =>
      'Correo electrónico o contraseña incorrectos. Inténtalo de nuevo.';
  @override
  String get msgInvalidField => 'Correo electrónico no válido';
  @override
  String get msgRequiredField => 'Campo obligatorio';
  @override
  String get msgUnexpectedError =>
      'No se pudo cargar la información. Inténtalo de nuevo pronto.';
  @override
  String get feedbackSuccess =>
      '¡Comentarios enviados correctamente! Gracias por ayudarnos a mejorar.';
  @override
  String get feedbackError =>
      'Error al enviar el comentario. Inténtalo de nuevo.';
  @override
  String get msgSureDeleteConversation =>
      '¿Estás seguro de que deseas eliminar la conversación?';
  @override
  String get msgActionCannotBeUndone => 'Esta acción no se puede deshacer.';
  @override
  String get msgDeletingConversation => 'Borrando conversación...';
  @override
  String get conversationDeletedSuccessfully =>
      'Conversación eliminada exitosamente';
  @override
  String get errorDeletingConversation => 'Error al eliminar la conversación';
  @override
  String get whatsAppNotAvailable => 'WhatsApp no ​​disponible';
  @override
  String get unableToOpenWhatsApp =>
      'No se puede abrir WhatsApp. Comprueba si la aplicación está instalada.';

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
  @override
  String get delete => 'Borrar';

  // SHARED
  @override
  String get sloganApp =>
      'Inteligencia Artificial de la Iglesia Adventista del Séptimo Día en Sudamérica';
  @override
  String get sendFeedback => 'Enviar comentarios';
  @override
  String get noConnectionsAvailable => 'Sin conexión';
  @override
  String get search => 'Buscar';
  @override
  String get conversations => 'Conversaciones';
  @override
  String get newConversation => 'Nueva conversación';
  @override
  String get faq => 'faq';
  @override
  String get sureLogout => '¿Estás seguro que deseas cerrar la sesión?';
  @override
  String get msgCopiedToClipboard => '¡Texto copiado!';
  @override
  String get copyLabel => 'Copiar';
  @override
  String get selectAllLabel => 'Seleccionar todo';
  @override
  String get copyTextTooltipe => 'Copiar texto';
  @override
  String get reportTextTooltipe => 'Informar de un problema';
  @override
  String get helpUsImproveIA => 'Ayúdanos a mejorar la IA';
  @override
  String get reportedMessage => 'Mensaje reportado';
  @override
  String get describeTheProblem => 'Describe el problema';
  @override
  String get messageExample =>
      'Ej: La respuesta es incorrecta, no responde a la pregunta, información desactualizada...';
  @override
  String get thinking => 'Pensando';
  @override
  String get hopeBot => 'Esperanza';

  //PAGES
  @override
  String get successTitle => 'Éxito';
  @override
  String get checkInternetAccess =>
      'Compruebe si el dispositivo tiene acceso a Internet';
  @override
  String get youAreOffline => 'Parece que estás desconectado';
  @override
  String get anErrorHasOccurred => 'Algo salió mal';
  @override
  String get settings => 'Configuración';
  @override
  String get language => 'Idioma';
  @override
  String get provider => 'Proveedor';
  @override
  String get logout => 'Cerrar sesión';
  @override
  String get changeLanguage => 'Cambiar idioma';
  @override
  String get save => 'Guardar';
  @override
  String get english => 'Inglés';
  @override
  String get portuguese => 'Portugués';
  @override
  String get spanish => 'Español';
  @override
  String get faqLabel =>
      'Encuentre respuestas a las preguntas más comunes sobre el Asistente de IA Adventista, cómo funciona y cómo usarlo de la mejor manera posible.';
  @override
  String get loadQuestions => 'Cargando preguntas...';
  @override
  String get tryDiferentSequences => 'Prueba a usar palabras diferentes';
  @override
  String get noQuestionsFounded => 'No se encontraron preguntas';
  @override
  String get noQuestionsAvaliable => 'No hay preguntas disponibles';
  @override
  String get homeMessage =>
      'Esta es la Inteligencia Artificial oficial\nde la Iglesia Adventista del Séptimo Día\nen Sudamérica.';
  @override
  String get messageWarning =>
      'El asistente de inteligencia artificial adventista\npuede cometer errores.\nVerifique información importante.';
  @override
  String get messagePlaceholder => 'Escribe tu mensaje...';
  @override
  String get deleteConversation => 'Eliminar conversación';

  // Social Login
  @override
  String get loginWithApple => 'Continuar con Apple';
  @override
  String get loginWithFacebook => 'Continuar con Facebook';
  @override
  String get loginWithGoogle => 'Continuar con Google';
  @override
  String get loginWithMicrosoft => 'Continuar con Microsoft';
  @override
  String get authCancelled => 'Inicio de sesión cancelado por el usuario';
  @override
  String get authInProgress => 'El inicio de sesión ya está en progreso';
  @override
  String get networkError => 'Problema de conexión de red';
  @override
  String get configurationError => 'Error de configuración de autenticación';
  @override
  String get accountDisabled => 'La cuenta ha sido deshabilitada';
  @override
  String get tooManyRequests =>
      'Demasiados intentos de inicio de sesión. Inténtalo de nuevo más tarde.';
  @override
  String get webContextCancelled =>
      'Proceso de autenticación cancelado por el usuario';
  @override
  String get noTitleChat => 'Conversación sin título';
}
