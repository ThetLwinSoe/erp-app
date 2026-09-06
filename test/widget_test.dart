// Basic smoke test: confirms the app's widget tree builds without
// throwing. This replaces the default `flutter create` counter-app
// template test, which referenced a MyApp/counter UI this app never had.

import 'package:flutter_test/flutter_test.dart';

import 'package:erp_sales_app/main.dart';

void main() {
  testWidgets('ERPSalesApp builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ERPSalesApp());
    await tester.pump();

    expect(find.byType(ERPSalesApp), findsOneWidget);
  });
}
