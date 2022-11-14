import 'package:mad_bus/mad_bus.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  group('Simple stream manager operations.', () {
    test(
        'Manager creates a new stream when getting an unregistered stream, fetch identical stream when getting registered one.',
        () {
      MadSimpleStreamManager streamManager = MadSimpleStreamManager();
      const String topicName = '_test.1';

      expect(streamManager.hasStream(topicName), isFalse);
      Stream<String> s1 = streamManager.stream<String>(topicName);
      expect(streamManager.hasStream(topicName), isTrue);
      expect(streamManager.streamType(topicName), String);
      Stream<String> s2 = streamManager.stream<String>(topicName);

      expectLater(s1, emitsInOrder(['test-1', 'test-2', emitsDone]));
      expectLater(s2, emitsInOrder(['test-1', 'test-2', emitsDone]));
      streamManager.emit(topicName, 'test-1');
      streamManager.emit(topicName, 'test-2');

      streamManager.deregister(topicName);
      expect(streamManager.hasStream(topicName), isFalse);
    });
    test('Emitting wrong type causes no value to be emitted', () {
      MadSimpleStreamManager streamManager = MadSimpleStreamManager();
      const String topicName = '_test.1';

      Stream<int> s1 = streamManager.stream<int>(topicName);
      expectLater(s1, emitsInOrder([1, emitsDone]));

      expect(streamManager.emit(topicName, "abcd"), isFalse);
      expect(streamManager.emit(topicName, 1), isTrue);
      streamManager.deregister(topicName);
    });
    test(
        'Register adds the provided stream on no topic, or keep the old stream on existing topic.',
        () {
      MadSimpleStreamManager streamManager = MadSimpleStreamManager();
      const String topicName = '_test.1';

      PublishSubject<String> s1 = PublishSubject<String>();
      expect(streamManager.hasStream(topicName), isFalse);
      expect(streamManager.register<String>(topicName, s1), isTrue);
      expect(streamManager.hasStream(topicName), isTrue);
      expect(streamManager.streamType(topicName), String);
      Stream<String> s1Test = streamManager.stream<String>(topicName);

      PublishSubject<String> s2 = PublishSubject<String>();
      expect(streamManager.register<String>(topicName, s2), isFalse);
      Stream<String> s2Test = streamManager.stream<String>(topicName);

      // s1, s1Test, s2Test should be identical, but s2 is a different
      expectLater(s1, emitsInOrder(['test-1', 'test-2', emitsDone]));
      expectLater(s1Test, emitsInOrder(['test-1', 'test-2', emitsDone]));
      expectLater(s2Test, emitsInOrder(['test-1', 'test-2', emitsDone]));
      // nothing should be emitted to s2
      expectLater(s2, emitsInOrder([emitsDone]));

      streamManager.emit(topicName, 'test-1');
      streamManager.emit(topicName, 'test-2');

      streamManager.deregister(topicName);
      expect(streamManager.hasStream(topicName), isFalse);
      expect(s1.isClosed, isTrue);
      s2.close();
    });
    test(
        'Deregister closed the stream on existing topic, returns null on non-existent topic.',
        () {
      MadSimpleStreamManager streamManager = MadSimpleStreamManager();
      const String topicName1 = '_test.1';
      const String topicName2 = '_test.2';

      PublishSubject<String> s1 = PublishSubject<String>();
      streamManager.register<String>(topicName1, s1);
      Stream? ds1 = streamManager.deregister(topicName1);
      expect(ds1, isNotNull);
      expect(s1.isClosed, true);
      Stream? ds2 = streamManager.deregister(topicName2);
      expect(ds2, isNull);
    });
  });
}
