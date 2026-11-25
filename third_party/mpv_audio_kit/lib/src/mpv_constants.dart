// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The constants of libmpv's client API the package uses: plain Dart, so the
// code that only needs the numbers does not import the FFI bindings
// (mpv_bindings.dart re-exports them).

// ---------------------------------------------------------------------------
// mpv_error  (subset, limited to required error codes)
// ---------------------------------------------------------------------------
/// Mirror of libmpv's `mpv_error` return codes (the subset this package uses).
///
/// Negative values indicate an error; [mpvErrorSuccess] (0) means success.
abstract final class MpvError {
  /// No error (`MPV_ERROR_SUCCESS`).
  static const int mpvErrorSuccess = 0;

  /// The event ringbuffer is full (`MPV_ERROR_EVENT_QUEUE_FULL`).
  static const int mpvErrorEventQueueFull = -1;

  /// Memory allocation failed (`MPV_ERROR_NOMEM`).
  static const int mpvErrorNomem = -2;

  /// The mpv core was not configured or initialized
  /// (`MPV_ERROR_UNINITIALIZED`).
  static const int mpvErrorUninitialized = -3;

  /// A function received an invalid parameter (`MPV_ERROR_INVALID_PARAMETER`).
  static const int mpvErrorInvalidParameter = -4;

  /// The named option does not exist (`MPV_ERROR_OPTION_NOT_FOUND`).
  static const int mpvErrorOptionNotFound = -5;

  /// The option value has an unsupported format (`MPV_ERROR_OPTION_FORMAT`).
  static const int mpvErrorOptionFormat = -6;

  /// Setting the option failed (`MPV_ERROR_OPTION_ERROR`).
  static const int mpvErrorOptionError = -7;

  /// The named property does not exist (`MPV_ERROR_PROPERTY_NOT_FOUND`).
  static const int mpvErrorPropertyNotFound = -8;

  /// The property cannot be used in the requested format
  /// (`MPV_ERROR_PROPERTY_FORMAT`).
  static const int mpvErrorPropertyFormat = -9;

  /// The property exists but is currently unavailable
  /// (`MPV_ERROR_PROPERTY_UNAVAILABLE`).
  static const int mpvErrorPropertyUnavailable = -10;

  /// A generic error occurred accessing the property
  /// (`MPV_ERROR_PROPERTY_ERROR`).
  static const int mpvErrorPropertyError = -11;

  /// A command failed during execution (`MPV_ERROR_COMMAND`).
  static const int mpvErrorCommand = -12;

  /// Loading the requested file or URL failed (`MPV_ERROR_LOADING_FAILED`).
  static const int mpvErrorLoadingFailed = -13;

  /// Initializing the audio output failed (`MPV_ERROR_AO_INIT_FAILED`).
  static const int mpvErrorAoInitFailed = -14;

  /// Initializing the video output failed (`MPV_ERROR_VO_INIT_FAILED`).
  static const int mpvErrorVoInitFailed = -15;

  /// There was nothing to play (`MPV_ERROR_NOTHING_TO_PLAY`).
  static const int mpvErrorNothingToPlay = -16;

  /// The file format could not be determined (`MPV_ERROR_UNKNOWN_FORMAT`).
  static const int mpvErrorUnknownFormat = -17;

  /// The operation is not supported (`MPV_ERROR_UNSUPPORTED`).
  static const int mpvErrorUnsupported = -18;

  /// The API function is not implemented (`MPV_ERROR_NOT_IMPLEMENTED`).
  static const int mpvErrorNotImplemented = -19;

  /// An unspecified error occurred (`MPV_ERROR_GENERIC`).
  static const int mpvErrorGeneric = -20;
}

// ---------------------------------------------------------------------------
// mpv_format
// ---------------------------------------------------------------------------
/// Mirror of libmpv's `mpv_format` data-type tags used when reading or
/// writing properties and decoding [MpvNode] values.
abstract final class MpvFormat {
  /// No value or invalid format (`MPV_FORMAT_NONE`).
  static const int mpvFormatNone = 0;

  /// UTF-8 string (`MPV_FORMAT_STRING`).
  static const int mpvFormatString = 1;

  /// OSD-formatted string (`MPV_FORMAT_OSD_STRING`).
  static const int mpvFormatOsdString = 2;

  /// Boolean flag, stored as an int (`MPV_FORMAT_FLAG`).
  static const int mpvFormatFlag = 3;

  /// 64-bit signed integer (`MPV_FORMAT_INT64`).
  static const int mpvFormatInt64 = 4;

  /// Double-precision float (`MPV_FORMAT_DOUBLE`).
  static const int mpvFormatDouble = 5;

  /// Generic [MpvNode] value (`MPV_FORMAT_NODE`).
  static const int mpvFormatNode = 6;

  /// Node array (`MPV_FORMAT_NODE_ARRAY`).
  static const int mpvFormatNodeArray = 7;

  /// Node map or key-value object (`MPV_FORMAT_NODE_MAP`).
  static const int mpvFormatNodeMap = 8;

  /// Raw byte array (`MPV_FORMAT_BYTE_ARRAY`).
  static const int mpvFormatByteArray = 9;
}

// ---------------------------------------------------------------------------
// mpv_event_id
// ---------------------------------------------------------------------------
/// Mirror of libmpv's `mpv_event_id` tags delivered by `mpv_wait_event`.
abstract final class MpvEventId {
  /// No event was available (`MPV_EVENT_NONE`).
  static const int mpvEventNone = 0;

  /// The mpv core is shutting down (`MPV_EVENT_SHUTDOWN`).
  static const int mpvEventShutdown = 1;

  /// A log message is available (`MPV_EVENT_LOG_MESSAGE`).
  static const int mpvEventLogMessage = 2;

  /// Reply to an async `mpv_get_property` (`MPV_EVENT_GET_PROPERTY_REPLY`).
  static const int mpvEventGetPropertyReply = 3;

  /// Reply to an async `mpv_set_property` (`MPV_EVENT_SET_PROPERTY_REPLY`).
  static const int mpvEventSetPropertyReply = 4;

  /// Reply to an async command (`MPV_EVENT_COMMAND_REPLY`).
  static const int mpvEventCommandReply = 5;

  /// Playback of a new file has started (`MPV_EVENT_START_FILE`).
  static const int mpvEventStartFile = 6;

  /// Playback of a file has ended (`MPV_EVENT_END_FILE`).
  static const int mpvEventEndFile = 7;

  /// The file was loaded and decoding is about to start
  /// (`MPV_EVENT_FILE_LOADED`).
  static const int mpvEventFileLoaded = 8;

  /// The player has entered idle mode with nothing loaded (`MPV_EVENT_IDLE`).
  static const int mpvEventIdle = 11;

  /// Periodic timer tick (`MPV_EVENT_TICK`).
  static const int mpvEventTick = 14;

  /// A client message was received (`MPV_EVENT_CLIENT_MESSAGE`).
  static const int mpvEventClientMessage = 16;

  /// Video output was reconfigured (`MPV_EVENT_VIDEO_RECONFIG`).
  static const int mpvEventVideoReconfig = 17;

  /// Audio output was reconfigured (`MPV_EVENT_AUDIO_RECONFIG`).
  static const int mpvEventAudioReconfig = 18;

  /// A seek was initiated (`MPV_EVENT_SEEK`).
  static const int mpvEventSeek = 20;

  /// Playback restarted after a seek or file load
  /// (`MPV_EVENT_PLAYBACK_RESTART`).
  static const int mpvEventPlaybackRestart = 21;

  /// An observed property changed value (`MPV_EVENT_PROPERTY_CHANGE`).
  static const int mpvEventPropertyChange = 22;

  /// The event queue overflowed and events were dropped
  /// (`MPV_EVENT_QUEUE_OVERFLOW`).
  static const int mpvEventQueueOverflow = 24;

  /// A registered hook was triggered (`MPV_EVENT_HOOK`).
  static const int mpvEventHook = 25;
}

// ---------------------------------------------------------------------------
// mpv_end_file_reason
// ---------------------------------------------------------------------------
/// Mirror of libmpv's `mpv_end_file_reason`, carried in [MpvEventEndFile].
abstract final class MpvEndFileReason {
  /// The file reached its natural end (`MPV_END_FILE_REASON_EOF`).
  static const int mpvEndFileReasonEof = 0;

  /// Playback was stopped by command (`MPV_END_FILE_REASON_STOP`).
  static const int mpvEndFileReasonStop = 2;

  /// The player is quitting (`MPV_END_FILE_REASON_QUIT`).
  static const int mpvEndFileReasonQuit = 3;

  /// Playback ended due to an error (`MPV_END_FILE_REASON_ERROR`).
  static const int mpvEndFileReasonError = 4;

  /// Playback was redirected to another file (`MPV_END_FILE_REASON_REDIRECT`).
  static const int mpvEndFileReasonRedirect = 5;
}
