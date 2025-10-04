// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow_app/main.dart';
import 'package:taskflow_app/services/preferences_service.dart';

void main() {
  testWidgets('TaskFlow app smoke test', (WidgetTester tester) async {
    // Inicializa o serviço de preferências
    final preferencesService = PreferencesService();
    await preferencesService.init();

    // Build our app and trigger a frame.
    await tester.pumpWidget(TaskFlowApp(preferencesService: preferencesService));

    // Verifica se o app carrega a tela de splash
    expect(find.text('TaskFlow'), findsOneWidget);

    // Aguarda um pouco para a navegação automática
    await tester.pumpAndSettle();

    // Verifica se navegou para onboarding (primeiro uso)
    expect(find.text('Bem-vindo ao TaskFlow'), findsOneWidget);
  });
}
