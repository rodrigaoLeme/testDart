import 'package:flutter/material.dart';

import '../../../../ui/modules/settings/settings_page.dart';
import '../../presenters/settings/settings_presenter_factory.dart';

Widget makeSettingsPage() => SettingsPage(presenter: makeSettingsPresenter());
