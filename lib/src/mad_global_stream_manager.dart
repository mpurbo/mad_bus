import 'mad_stream_manager.dart';
import 'mad_simple_stream_manager.dart';

/// Singleton to be used as a global stream manager.
class MadGlobalStreamManager implements MadStreamManager {
  MadGlobalStreamManager._();
  static final MadGlobalStreamManager _instance = MadGlobalStreamManager._();
  static MadGlobalStreamManager get instance => _instance;

  final MadStreamManager _delegate = MadSimpleStreamManager();

  @override
  Stream<T>? deregister<T>(String topicName) =>
      _delegate.deregister<T>(topicName);

  @override
  void dispose() => _delegate.dispose();

  @override
  bool emit<T>(String topicName, T data) => _delegate.emit<T>(topicName, data);

  @override
  bool hasStream(String topicName) => _delegate.hasStream(topicName);

  @override
  bool injectExternalInfuser<T, R>(Stream<T> inputStream, String outputTopic,
          R Function(T) transformer) =>
      injectExternalInfuser<T, R>(inputStream, outputTopic, transformer);

  @override
  Future<bool> injectFutureValue<T, R>(Future<T> futureValue,
          String outputTopic, R Function(T) transformer) =>
      _delegate.injectFutureValue<T, R>(futureValue, outputTopic, transformer);

  @override
  bool injectInfuser<T, R>(
          String inputTopic, String outputTopic, R Function(T) transformer) =>
      _delegate.injectInfuser<T, R>(inputTopic, outputTopic, transformer);

  @override
  bool register<T>(String topicName, Stream<T> stream) =>
      _delegate.register<T>(topicName, stream);

  @override
  bool registerProcessor<T, R>(String inputTopic, String newOutputTopic,
          Stream<R> Function(Stream<T>) processor) =>
      _delegate.registerProcessor(inputTopic, newOutputTopic, processor);

  @override
  Stream<T> stream<T>(String topicName) => _delegate.stream<T>(topicName);

  @override
  Type? streamType(String topicName) => _delegate.streamType(topicName);
}
