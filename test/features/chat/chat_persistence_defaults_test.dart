import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telegraph/core/engine/telegraph_engine.dart';
import 'package:telegraph/features/chat/controllers/chat_controller.dart';

class MockEngine extends Mock implements TelegraphEngine {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChatController Persistence Defaults', () {
    late MockEngine mockEngine;

    setUp(() {
      mockEngine = MockEngine();
      when(() => mockEngine.loadChatHistory()).thenAnswer((_) async => []);
      when(() => mockEngine.registeredModuleCount).thenReturn(5);
    });

    test('should default to AI OFF when no preference exists', () async {
      // Setup mock with NO values
      SharedPreferences.setMockInitialValues({});

      final controller = ChatController(engine: mockEngine);
      await controller.initialize();

      expect(controller.isAiEnabled, isFalse);
    });

    test('should load AI ON if preference was previously saved', () async {
      // Setup mock with existing TRUE value
      SharedPreferences.setMockInitialValues({'ai_analysis_enabled': true});

      final controller = ChatController(engine: mockEngine);
      await controller.initialize();

      expect(controller.isAiEnabled, isTrue);
    });
  });
}
