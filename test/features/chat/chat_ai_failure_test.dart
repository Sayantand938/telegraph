import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telegraph/core/engine/telegraph_engine.dart';
import 'package:telegraph/features/chat/controllers/chat_controller.dart';
import 'package:telegraph/features/chat/models/message_model.dart';
import 'package:telegraph/features/chat/services/command_service.dart';

class MockEngine extends Mock implements TelegraphEngine {}

class MockCommandService extends Mock implements CommandService {}

class FakeMessageModel extends Fake implements MessageModel {}

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

  group('ChatController Resilience (AI Bridge Down)', () {
    test(
      'Should fall back to local result if AI Worker times out/fails',
      () async {
        await chatController.initialize();
        await chatController.toggleAi(true);

        const userText = "time status";
        const localResult = "🕒 **Tracking**";

        when(
          () => mockCommandService.handleCommand(userText),
        ).thenAnswer((_) async => localResult);

        await chatController.sendMessage(userText);

        expect(chatController.messages.last.text, contains(localResult));
        expect(chatController.isTyping, isFalse);
      },
    );
  });
}
