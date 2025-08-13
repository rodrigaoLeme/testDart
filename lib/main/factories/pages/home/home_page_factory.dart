import 'package:flutter/material.dart';

import '../../../../ui/modules/home/home_page.dart';
import '../../presenters/chat/chat_presenter_factory.dart';
import 'home_presenter_factory.dart';

Widget makeHomePage() => HomePage(
      presenter: makeHomePresenter(),
      chatPresenter: makeChatPresenter(),
    );
