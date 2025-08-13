enum DomainError {
  unexpected,
  invalidCredentials,
  emailInUse,
  accessDenied,
  expiredSession,
  noInternetConnection,
  notFound,

  // Social Login
  authCancelled,
  authInProgress,
  networkError,
  configurationError,
  accountDisabled,
  tooManyRequests,
  webContextCancelled,
  unknownError,
}
