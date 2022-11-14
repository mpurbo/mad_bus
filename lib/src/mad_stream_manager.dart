/// A collection of `Stream` and `StreamController` organized in "topics". Each
/// of the stream managed will have a topic name associated with it.
abstract class MadStreamManager {
  /// Gets a stream named `topicName`. If the topic with such name hasn't been
  /// registered yet a new `StreamController`-compatible (most likely an Rx
  /// `Subject` extension) instance will be created and assigned to the name.
  Stream<T> stream<T>(String topicName);

  /// Gets the stream type defined for the topic specified.
  Type? streamType(String topicName);

  /// Register a new stream created elsewhere. This manager is reponsible for
  /// cleaning up the stream only if the stream passed is also a
  /// `StreamController`. Otherwise the responsibility for cleaning up the
  /// stream is assumed to be elswhere.
  /// Returns true if the stream passed is successfully registered to the topic
  /// specified. If the topic name is already used, the stream passed will not
  /// be registered and the function returns false.
  bool register<T>(String topicName, Stream<T> stream);

  /// Remove the stream associated to the name passed from the registry. If the
  /// stream is registered and it is also a `StreamController`, it will be
  /// closed before returned. Null is returned when the stream is not
  /// registered.
  Stream<T>? deregister<T>(String topicName);

  /// Returns true if a stream is associated with the topic name specified,
  /// false otherwise.
  bool hasStream(String topicName);

  /// Emit a data to a stream associated with the name and retursn true,
  /// only if:
  /// - The topic is registered.
  /// - The stream associated with the topic is `StreamController`-compatible.
  /// - The stream is of type T.
  /// Returns false otherwise.
  bool emit<T>(String topicName, T data);

  /// Register a new topic based on a transformation to an existing registered
  /// topic as defined by the stream processor specified.
  bool registerProcessor<T, R>(String inputTopic, String newOutputTopic,
      Stream<R> Function(Stream<T>) processor);

  /// Inject the values of a stream registered as the `inputTopic` into another
  /// registered stream `outputTopic` after transformed using `transformer`
  /// specified.
  bool injectInfuser<T, R>(
      String inputTopic, String outputTopic, R Function(T) transformer);

  /// Inject the values of an external stream provided as `inputStream` into\
  /// a stream registered into a topic `outputTopic` after transformed using
  /// `transformer` specified.
  bool injectExternalInfuser<T, R>(
      Stream<T> inputStream, String outputTopic, R Function(T) transformer);

  /// Inject a future value into a registered stream `outputTopic` after
  /// transformed using `transformer` specified.
  Future<bool> injectFutureValue<T, R>(
      Future<T> futureValue, String outputTopic, R Function(T) transformer);

  /// Closing all `StreamController`-compatible streams managed by this class.
  /// Nothing will be done on non-`StreamController` as the source of the
  /// stream is assumed to be elsewhere.
  void dispose();
}
