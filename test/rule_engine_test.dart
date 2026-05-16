import 'package:flutter_test/flutter_test.dart';
import 'package:ai_driving_assistant/core/rule_engine.dart';

void main() {
  group('RuleEngine Drowsiness Detection', () {
    late RuleEngine ruleEngine;

    setUp(() {
      ruleEngine = RuleEngine();
    });

    test('Case 1: Eyes closed for less than 1.5 seconds should NOT trigger alert', () {
      ruleEngine.resetDrowsiness();

      final result1 = ruleEngine.analyzeDrowsiness(0.1, 0.1);
      expect(result1, isFalse);
      expect(ruleEngine.isDrowsy, isFalse);
    });

    test('Case 2: Eyes closed for more than 1.5 seconds should trigger alert', () async {
      ruleEngine.resetDrowsiness();

      ruleEngine.analyzeDrowsiness(0.1, 0.1);

      await Future.delayed(const Duration(milliseconds: 1600));
      
      final result = ruleEngine.analyzeDrowsiness(0.1, 0.1);
      expect(result, isTrue);
      expect(ruleEngine.isDrowsy, isTrue);
    });

    test('Case 3: Only one eye closed should NOT trigger alert', () async {
      ruleEngine.resetDrowsiness();

      ruleEngine.analyzeDrowsiness(0.1, 0.9);
      await Future.delayed(const Duration(milliseconds: 1600));
      
      final result1 = ruleEngine.analyzeDrowsiness(0.1, 0.9);
      expect(result1, isFalse);
      expect(ruleEngine.isDrowsy, isFalse);

      ruleEngine.analyzeDrowsiness(0.9, 0.1);
      await Future.delayed(const Duration(milliseconds: 1600));
      
      final result2 = ruleEngine.analyzeDrowsiness(0.9, 0.1);
      expect(result2, isFalse);
      expect(ruleEngine.isDrowsy, isFalse);
    });

    test('Case 4: Eyes reopen should reset drowsiness state', () async {
      ruleEngine.resetDrowsiness();

      ruleEngine.analyzeDrowsiness(0.1, 0.1);

      await Future.delayed(const Duration(milliseconds: 1600));
      
      ruleEngine.analyzeDrowsiness(0.1, 0.1);
      expect(ruleEngine.isDrowsy, isTrue);

      final result = ruleEngine.analyzeDrowsiness(0.9, 0.9);
      expect(result, isFalse);
      expect(ruleEngine.isDrowsy, isFalse);
    });

    test('Normal blinking (100-400ms) should NOT trigger alert', () async {
      ruleEngine.resetDrowsiness();

      ruleEngine.analyzeDrowsiness(0.1, 0.1);

      await Future.delayed(const Duration(milliseconds: 300));
      
      final result = ruleEngine.analyzeDrowsiness(0.9, 0.9);
      expect(result, isFalse);
      expect(ruleEngine.isDrowsy, isFalse);
    });

    test('Eyes at threshold boundary (0.20) should NOT be considered closed', () async {
      ruleEngine.resetDrowsiness();

      ruleEngine.analyzeDrowsiness(0.20, 0.20);
      await Future.delayed(const Duration(milliseconds: 1600));
      
      final result = ruleEngine.analyzeDrowsiness(0.20, 0.20);
      expect(result, isFalse);
      expect(ruleEngine.isDrowsy, isFalse);
    });

    test('Eyes just below threshold (0.19) should be considered closed', () async {
      ruleEngine.resetDrowsiness();

      ruleEngine.analyzeDrowsiness(0.19, 0.19);
      await Future.delayed(const Duration(milliseconds: 1600));
      
      final result = ruleEngine.analyzeDrowsiness(0.19, 0.19);
      expect(result, isTrue);
      expect(ruleEngine.isDrowsy, isTrue);
    });

    test('resetDrowsiness should clear all state', () async {
      ruleEngine.resetDrowsiness();

      ruleEngine.analyzeDrowsiness(0.1, 0.1);

      await Future.delayed(const Duration(milliseconds: 1600));
      
      ruleEngine.analyzeDrowsiness(0.1, 0.1);
      expect(ruleEngine.isDrowsy, isTrue);

      ruleEngine.resetDrowsiness();
      expect(ruleEngine.isDrowsy, isFalse);

      final result = ruleEngine.analyzeDrowsiness(0.1, 0.1);
      expect(result, isFalse);
    });
  });
}

