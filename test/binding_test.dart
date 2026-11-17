import 'package:any/any.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

void main() {
  group('Binding', () {
    test('eager binding exposes type, instance, and is not lazy', () {
      const repository = CounterRepository(3);
      final binding = Binding<CounterRepository>(repository);

      expect(binding, isA<RepositoryBinding>());
      expect(binding.type, CounterRepository);
      expect(binding.isLazy, isFalse);
      expect(identical(binding.instance, repository), isTrue);
    });

    test('lazy binding creates once and caches the instance', () {
      var creations = 0;
      const repository = CounterRepository(9);
      final binding = Binding<CounterRepository>.lazy(() {
        creations++;
        return repository;
      });

      expect(binding.type, CounterRepository);
      expect(binding.isLazy, isTrue);
      expect(creations, 0);

      expect(identical(binding.instance, repository), isTrue);
      expect(identical(binding.instance, repository), isTrue);
      expect(creations, 1);
      expect(binding.isLazy, isTrue);
    });

    test('lazy factory errors propagate on first access', () {
      final error = StateError('repository creation failed');
      final binding = Binding<CounterRepository>.lazy(() => throw error);

      expect(() => binding.instance, throwsA(same(error)));
      expect(() => binding.instance, throwsA(same(error)));
    });
  });
}
