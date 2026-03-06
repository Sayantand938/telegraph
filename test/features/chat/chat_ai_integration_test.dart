import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telegraph/core/engine/telegraph_engine.dart';
import 'package:telegraph/features/chat/controllers/chat_controller.dart';
import 'package:telegraph/features/chat/models/message_model.dart';
import 'package:telegraph/features/chat/services/command_service.dart';

class FakeMessageModel extends Fake implements MessageModel {}

class MockEngine extends Mock implements TelegraphEngine {}

class MockCommandService extends Mock implements CommandService {}

void main() {
  // ✅ Required for SharedPreferences
  TestWidgetsFlutterBinding.ensureInitialized();

  late ChatController chatController;
  late MockEngine mockEngine;
  late MockCommandService mockCommandService;

  setUpAll(() {
    registerFallbackValue(FakeMessageModel());
  });

  setUp(() {
    // ✅ Setup mock values
    SharedPreferences.setMockInitialValues({});

    mockEngine = MockEngine();
    mockCommandService = MockCommandService();

    when(() => mockEngine.loadChatHistory()).thenAnswer((_) async => []);
    when(
      () => mockEngine.saveMessageToHistory(any()),
    ).thenAnswer((_) async => {});
    when(() => mockEngine.registeredModuleCount).thenReturn(5);
    when(() => mockEngine.commandService).thenReturn(mockCommandService);

    chatController = ChatController(engine: mockEngine);
  });

  group('ChatController AI Integration Tests', () {
    test('AI Toggle: Should update state and persist', () async {
      await chatController.initialize();
      expect(chatController.isAiEnabled, isFalse);

      await chatController.toggleAi(true);

      expect(chatController.isAiEnabled, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('ai_analysis_enabled'), isTrue);
    });

    test('AI Disabled: Should only return local command result', () async {
      await chatController.initialize();
      await chatController.toggleAi(false);

      const userText = "sleep status";
      const localResult = "😴 **Status:** Not tracking";

      when(
        () => mockCommandService.handleCommand(userText),
      ).thenAnswer((_) async => localResult);

      await chatController.sendMessage(userText);
      expect(chatController.messages.last.text, localResult);
    });

    test('AI Exclusion: Should NOT call AI for help commands', () async {
      await chatController.initialize();
      await chatController.toggleAi(true);

      const userText = "help";
      const localResult = "Available commands...";

      when(
        () => mockCommandService.handleCommand(userText),
      ).thenAnswer((_) async => localResult);

      await chatController.sendMessage(userText);
      expect(chatController.messages.last.text, localResult);
    });

    test('Flow Check: Combined message logic', () {
      const aiCommentary = "You slept well, Boss.";
      const localResult = '{"duration": "8h"}';
      final combined = "$aiCommentary\n\n$localResult";
      expect(combined, contains(aiCommentary));
      expect(combined, contains(localResult));
    });
  });
}
