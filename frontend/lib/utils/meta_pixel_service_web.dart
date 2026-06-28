import 'dart:js_interop';

@JS('window.hhMetaPixelInitialize')
external JSFunction? get _initializeFunction;

@JS('window.hhMetaPixelTrack')
external JSFunction? get _trackFunction;

void initialize(String pixelId) {
  _initializeFunction?.callAsFunction(null, pixelId.toJS);
}

void track(String eventName, Map<String, Object?> parameters, {String? eventId}) {
  _trackFunction?.callAsFunction(null, eventName.toJS, parameters.jsify(), eventId?.toJS);
}
