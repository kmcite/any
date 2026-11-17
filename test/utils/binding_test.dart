import 'package:any/utils/any.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Binding', () {
    test('eager binding exposes its registered type and instance', () {
      final repository = _Repository();
      final binding = Binding<_Repository>(repository);

      expect(binding.type, _Repository);
      expect(binding.isLazy, isFalse);
      expect(identical(binding.instance, repository), isTrue);
    });

    test('lazy binding creates and caches its repository on first access', () {
      var creations = 0;
      final repository = _Repository();
      final binding = Binding<_Repository>.lazy(() {
        creations++;
        return repository;
      });

      expect(binding.type, _Repository);
      expect(binding.isLazy, isTrue);
      expect(creations, 0);
      expect(identical(binding.instance, repository), isTrue);
      expect(identical(binding.instance, repository), isTrue);
      expect(creations, 1);
      expect(binding.isLazy, isTrue);
    });

    test('lazy factory errors propagate to the caller', () {
      final error = StateError('repository creation failed');
      final binding = Binding<_Repository>.lazy(() => throw error);

      expect(() => binding.instance, throwsA(same(error)));
    });
  });
}

class _Repository {}
