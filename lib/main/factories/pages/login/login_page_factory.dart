import 'package:flutter/material.dart';

import '../../../../ui/modules/login/login_page.dart';
import '../../presenters/login/login_presenter_factory.dart';

Widget makeLoginPage() => LoginPage(presenter: makeLoginPresenter());
