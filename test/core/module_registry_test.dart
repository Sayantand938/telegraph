import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:telegraph/core/module_registry.dart';
import 'package:telegraph/core/module_interface.dart';

// ✅ Using mocktail for the command handler
class MockCommandHandler extends Mock implements FeatureCommandHandler {}

class MockModule implements TelegraphModule {
  final String key;
  final FeatureCommandHandler _handler;

  MockModule(this.key, this._handler);

  @override
  String get name => 'Mock $key';

  @override
  FeatureCommandHandler get handler => _handler;

  @override
  List<String> get onCreateSql => ['CREATE TABLE mock_$key (id INTEGER)'];

  // ✅ Added missing implementations required by TelegraphModule
  @override
  bool get isEnabled => true;

  @override
  int get version => 1;
}

void main() {
  group('ModuleRegistry', () {
    late ModuleRegistry registry;
    late MockCommandHandler mockHandler;

    setUp(() {
      registry = ModuleRegistry();
      mockHandler = MockCommandHandler();
      // Setup default behavior for the mock
      when(() => mockHandler.moduleKey).thenReturn('test_key');
    });

    test('should register and retrieve modules', () {
      final module = MockModule('test_key', mockHandler);
      registry.register(module);

      expect(registry.count, 1);
      expect(registry.isRegistered('test_key'), isTrue);
      expect(registry.getModule('test_key'), module);
    });

    test('should aggregate all SQL scripts correctly', () {
      final handlerA = MockCommandHandler();
      final handlerB = MockCommandHandler();
      when(() => handlerA.moduleKey).thenReturn('a');
      when(() => handlerB.moduleKey).thenReturn('b');

      registry.registerAll([
        MockModule('a', handlerA),
        MockModule('b', handlerB),
      ]);

      final sql = registry.allCreateSql;
      expect(sql.length, 2);
      expect(sql[0], contains('mock_a'));
      expect(sql[1], contains('mock_b'));
    });

    test('should throw error on empty moduleKey', () {
      when(() => mockHandler.moduleKey).thenReturn('');
      expect(
        () => registry.register(MockModule('', mockHandler)),
        throwsArgumentError,
      );
    });
  });
}
