import 'package:flutter_test/flutter_test.dart';
import 'package:orbital_core/orbital_core.dart';
import 'package:wintek/main.dart';

void main() {
  // REQ-INF-001.9
  testWidgets('WintekApp shows the placeholder screen', (tester) async {
    await tester.pumpWidget(const WintekApp());
    expect(find.text('Wintek'), findsWidgets);
  });

  // REQ-INF-001.4, REQ-INF-001.7
  test('orbital_core resolves across the package boundary', () {
    expect(coreVersion, '1.0.0');
  });
}
