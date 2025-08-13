import 'package:flutter/material.dart';

import '../../../../ui/modules/faq/faq_page.dart';
import '../../presenters/faq/faq_presenter_factory.dart';

Widget makeFAQPage() => FAQPage(presenter: makeFAQPresenter());
