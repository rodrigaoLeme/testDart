import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

class DSLogo extends StatelessWidget {
  final double? widht;
  final DSLogoType type;
  const DSLogo({super.key, this.widht, this.type = DSLogoType.white});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widht,
      child: FadeInImage(
        placeholder: MemoryImage(kTransparentImage),
        image: AssetImage(type.logo),
      ),
    );
  }
}

enum DSLogoType { white, black }

extension DSLogoTypeEx on DSLogoType {
  static final Map<DSLogoType, String> _logos = {
    DSLogoType.black: 'lib/ui/assets/images/logo/7chat_1024.png',
    DSLogoType.white: 'lib/ui/assets/images/logo/7chat_1024.png'
  };

  String get logo => _logos[this]!;
}
