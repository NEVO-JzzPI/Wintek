import 'package:orbital_core/orbital_core.dart';
import 'package:test/test.dart';

void main() {
  // REQ-INF-001.7
  test('coreVersion is the fixed scaffold version', () {
    expect(coreVersion, '1.0.0');
  });
}
