import 'flavors.dart';
import 'main.dart' as main_common;

Future<void> main() async {
  Flavor.flavorType = FlavorTypes.prod;
  await main_common.main();
}
