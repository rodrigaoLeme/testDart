import '../../../data/http/http.dart';
import '../../decorators/decorators.dart';
import 'dio_client_factory.dart';

HttpClient makeAuthorizeHttpClientDecorator() => AuthorizeHttpClientDecorator(
      decoratee: makeDioAdapter(),
    );
