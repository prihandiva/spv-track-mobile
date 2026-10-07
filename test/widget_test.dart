import 'package:flutter_test/flutter_test.dart';
import 'package:spv_track_mobile/main.dart';

void main() {
  testWidgets('SPV-Track Mobile smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SpvTrackApp());
    await tester.pump();
    expect(find.byType(SpvTrackApp), findsOneWidget);
  });
}
