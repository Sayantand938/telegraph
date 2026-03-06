import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:telegraph/core/module_registry.dart';
import 'package:telegraph/core/module_interface.dart';

class MockFeatureHandler extends Mock implements FeatureCommandHandler {}

class MockModule extends Mock implements TelegraphModule {}

void main() {
  group('ModuleRegistry Robustness', () {
    late ModuleRegistry registry;

    setUp(() {
      registry = ModuleRegistry();
    });

    test('should overwrite module if registered with same key', () {
      final handler1 = MockFeatureHandler();
      final handler2 = MockFeatureHandler();
      when(() => handler1.moduleKey).thenReturn('test');
      when(() => handler2.moduleKey).thenReturn('test');

      final mod1 = MockModule();
      final mod2 = MockModule();
      when(() => mod1.handler).thenReturn(handler1);
      when(() => mod2.handler).thenReturn(handler2);

      registry.register(mod1);
      registry.register(mod2); // Duplicate key

      expect(registry.count, 1);
      expect(registry.getModule('test'), mod2); // Should be the latest one
    });

    test('unregistering non-existent module should not crash', () {
      expect(() => registry.unregister('ghost'), returnsNormally);
    });

    test('clear() should empty all collections', () {
      final handler = MockFeatureHandler();
      when(() => handler.moduleKey).thenReturn('temp');
      final mod = MockModule();
      when(() => mod.handler).thenReturn(handler);

      registry.register(mod);
      registry.clear();

      expect(registry.count, 0);
      expect(registry.allHandlers, isEmpty);
    });
  });
}
