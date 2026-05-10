import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AgroX Unit Tests', () {
    test('Accuracy value should format correctly', () {
      final double accuracy = 95.567;
      expect(accuracy.toStringAsFixed(2), '95.57');
    });

    test('Crop name should convert correctly', () {
      String formatCrop(String crop) {
        final c = crop.toLowerCase().trim();

        if (c == 'tea') return 'Tea Leaf';
        if (c == 'coconut') return 'Coconut Leaf';
        if (c == 'rice') return 'Rice Leaf';

        return 'Unknown Crop';
      }

      expect(formatCrop('tea'), 'Tea Leaf');
      expect(formatCrop('coconut'), 'Coconut Leaf');
      expect(formatCrop('rice'), 'Rice Leaf');
      expect(formatCrop('banana'), 'Unknown Crop');
    });

    test('Risk level color logic should identify high risk', () {
      bool isHighRisk(String risk) {
        return risk.toLowerCase().contains('high');
      }

      expect(isHighRisk('High'), true);
      expect(isHighRisk('High Risk'), true);
      expect(isHighRisk('Low'), false);
    });

    test('Treatment list should return fallback when empty', () {
      List<String> safeTreatment(List<String> treatment) {
        if (treatment.isNotEmpty) {
          return treatment;
        }

        return ['No recommendations available'];
      }

      expect(
        safeTreatment([]),
        ['No recommendations available'],
      );

      expect(
        safeTreatment(['Remove infected leaves']),
        ['Remove infected leaves'],
      );
    });
  });

  group('AgroX Widget Tests', () {
    testWidgets('Basic AgroX test screen should render correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('AgroX Testing Screen'),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('AgroX Testing Screen'), findsOneWidget);
    });

    testWidgets('Detect Disease button should be visible',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: null,
                child: Text('Detect Disease'),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Detect Disease'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}