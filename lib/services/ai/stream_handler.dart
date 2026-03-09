import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Handler for streaming responses from LLM API
class StreamHandler {
  final http.StreamedResponse response;
  final StringBuffer _buffer = StringBuffer();
  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  StreamHandler(this.response);

  /// Get the stream of content chunks
  Stream<String> get stream => _controller.stream;

  /// Start processing the stream
  void start() {
    _processStream();
  }

  /// Cancel the stream
  void cancel() {
    _controller.close();
  }

  /// Process the streamed response
  Future<void> _processStream() async {
    try {
      final lines = response.stream
          .transform(const Utf8Decoder())
          .transform(const LineSplitter());

      await for (final line in lines) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') {
            _controller.close();
            return;
          }

          try {
            final jsonData = jsonDecode(data);
            if (jsonData['choices'] != null &&
                jsonData['choices'].isNotEmpty &&
                jsonData['choices'][0]['delta'] != null) {
              final delta = jsonData['choices'][0]['delta'];
              final content = delta['content'];
              if (content != null) {
                _buffer.write(content);
                _controller.add(content);
              }
            }
          } catch (e) {
            // Skip malformed JSON lines silently
          }
        }
      }

      _controller.close();
    } catch (e, stackTrace) {
      _controller.addError(e, stackTrace);
      _controller.close();
    }
  }

  /// Get the complete accumulated content
  String get accumulatedContent => _buffer.toString();
}

/// Wrapper for streaming LLM responses
class StreamingResponse {
  final StreamHandler streamHandler;
  final Completer<String> _completer = Completer<String>();
  final StringBuffer _fullContent = StringBuffer();

  StreamingResponse(this.streamHandler) {
    streamHandler.stream.listen(
      (chunk) {
        _fullContent.write(chunk);
      },
      onDone: () {
        if (!_completer.isCompleted) {
          _completer.complete(_fullContent.toString());
        }
      },
      onError: (error, stackTrace) {
        if (!_completer.isCompleted) {
          _completer.completeError(error, stackTrace);
        }
      },
    );
  }

  /// Get the full content as a future (completes when stream ends)
  Future<String> get fullContent => _completer.future;

  /// Get the stream of individual chunks
  Stream<String> get chunks => streamHandler.stream;

  /// Cancel the stream
  void cancel() {
    streamHandler.cancel();
    if (!_completer.isCompleted) {
      _completer.completeError(StreamCanceledException());
    }
  }
}

/// Exception thrown when a stream is canceled
class StreamCanceledException implements Exception {
  @override
  String toString() => 'Stream was canceled';
}
