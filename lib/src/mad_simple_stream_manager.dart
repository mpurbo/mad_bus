import 'dart:developer' as dev;
import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'mad_stream_manager.dart';

// TODO: maybe extend MadStreamTopic<T> from Stream<T> (like dart's internal CastStream)
class _MadStreamTopic<T> {
  final Stream<T> _source;
  final Type _type = T;
  _MadStreamTopic(this._source);
}

class MadSimpleStreamManager implements MadStreamManager {
  final Map<String, _MadStreamTopic> _topics = <String, _MadStreamTopic>{};

  @override
  Stream<T> stream<T>(String topicName) =>
      _rawStream<T>(topicName, T).cast<T>();

  @override
  Type? streamType(String topicName) => _topics[topicName]?._type;

  T _extractOptionalTopic<T>(String topicName,
      {required T Function(_MadStreamTopic) onTopicRegistered,
      required T Function() onTopicNotRegistered}) {
    final _MadStreamTopic? topic = _topics[topicName];
    return topic != null
        ? onTopicRegistered.call(topic)
        : onTopicNotRegistered.call();
  }

  Stream _rawStream<T>(String topicName, Type streamType) =>
      _extractOptionalTopic(topicName,
          onTopicRegistered: (topic) => topic._source,
          onTopicNotRegistered: () {
            PublishSubject<T> subject = PublishSubject<T>();
            _topics[topicName] = _MadStreamTopic<T>(subject);
            return subject;
          });

  @override
  bool register<T>(String topicName, Stream<T> stream) =>
      _extractOptionalTopic(topicName,
          onTopicRegistered: (topic) => false,
          onTopicNotRegistered: () {
            _topics[topicName] = _MadStreamTopic<T>(stream);
            return true;
          });

  @override
  Stream<T>? deregister<T>(String topicName) => _extractOptionalTopic(topicName,
      onTopicRegistered: (topic) {
        _closeStream(topicName, topic._source);
        _topics.remove(topicName);
        return topic._source.cast<T>();
      },
      onTopicNotRegistered: () => null);

  @override
  bool hasStream(String topicName) => _topics[topicName] != null;

  bool _emit<T, R>(String targetTopicName, T dataSource,
      void Function(void Function(R), T) emitter) {
    Stream targetStream = _rawStream<T>(targetTopicName, T);
    Type? targetType = streamType(targetTopicName);
    if (targetStream is StreamController &&
        targetType != null &&
        R == targetType) {
      emitter.call((targetStream as StreamController).add, dataSource);
      return true;
    }
    return false;
  }

  @override
  bool emit<T>(String topicName, T data) =>
      _emit<T, T>(topicName, data, (f, d) => f(d));

  @override
  bool registerProcessor<T, R>(String inputTopic, String newOutputTopic,
          Stream<R> Function(Stream<T>) processor) =>
      register<R>(newOutputTopic, processor.call(stream<T>(inputTopic)));

  @override
  bool injectInfuser<T, R>(
          String inputTopic, String outputTopic, R Function(T) transformer) =>
      injectExternalInfuser<T, R>(
          stream<T>(inputTopic), outputTopic, transformer);

  @override
  bool injectExternalInfuser<T, R>(
      Stream<T> inputStream, String outputTopic, R Function(T) transformer) {
    return _emit<Stream<T>, R>(outputTopic, inputStream,
        (f, d) => d.asyncMap(transformer).forEach((element) => f(element)));
  }

  @override
  Future<bool> injectFutureValue<T, R>(
      Future<T> futureValue, String outputTopic, R Function(T) transformer) {
    return Future.value(_emit<Future<T>, R>(outputTopic, futureValue,
        (f, d) => d.then((value) => f(transformer(value)))));
  }

  @override
  void dispose() {
    _topics.forEach(_closeTopic);
    _topics.clear();
  }

  void _closeTopic(String key, _MadStreamTopic topic) =>
      _closeStream(key, topic._source);

  void _closeStream(String key, Stream stream) {
    if (stream is StreamController) {
      dev.log('Disposing stream controller with key = $key',
          name: runtimeType.toString());
      (stream as StreamController).close();
    }
  }
}
