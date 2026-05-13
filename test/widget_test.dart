import 'package:binet_herve_jacques/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows operations dashboard and navigates to stock', (
    tester,
  ) async {
    await tester.pumpWidget(
      BinetOpsApp(
        repository: MemoryOpsRepository(sampleRecords()),
        initialRecords: sampleRecords(),
      ),
    );

    expect(find.text('Daily operations'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);

    await tester.tap(find.text('Stock'));
    await tester.pumpAndSettle();

    expect(find.text('Inventory tracking'), findsOneWidget);
    expect(find.text('Nitrile gloves'), findsOneWidget);
  });

  testWidgets('creates and saves a local task record', (tester) async {
    await tester.pumpWidget(
      BinetOpsApp(repository: MemoryOpsRepository(), initialRecords: const []),
    );

    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-record-fab')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('record-title-field')),
      'Review closing checklist',
    );
    await tester.enterText(
      find.byKey(const Key('record-detail-field')),
      'Confirm cash desk, alarm, and delivery bay notes.',
    );
    await tester.enterText(
      find.byKey(const Key('record-owner-field')),
      'Nadia',
    );
    await tester.enterText(
      find.byKey(const Key('record-metric-field')),
      '3 steps',
    );
    await tester.enterText(
      find.byKey(const Key('record-schedule-field')),
      'Today 18:00',
    );

    await tester.ensureVisible(find.byKey(const Key('save-record-button')));
    await tester.tap(find.byKey(const Key('save-record-button')));
    await tester.pumpAndSettle();

    expect(find.text('Review closing checklist'), findsOneWidget);
    expect(find.text('3 steps'), findsOneWidget);
  });

  testWidgets('opens privacy settings', (tester) async {
    await tester.pumpWidget(
      BinetOpsApp(
        repository: MemoryOpsRepository(sampleRecords()),
        initialRecords: sampleRecords(),
      ),
    );

    await tester.tap(find.byKey(const Key('settings-button')));
    await tester.pumpAndSettle();

    expect(find.text('Local workspace'), findsOneWidget);
    expect(find.text('No data collection'), findsOneWidget);
  });
}
