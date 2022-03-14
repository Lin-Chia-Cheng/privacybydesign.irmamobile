import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:irmamobile/src/data/irma_bridge.dart';
import 'package:irmamobile/src/models/authentication_events.dart';
import 'package:irmamobile/src/models/change_pin_events.dart';
import 'package:irmamobile/src/models/client_preferences.dart';
import 'package:irmamobile/src/models/credential_events.dart';
import 'package:irmamobile/src/models/enrollment_events.dart';
import 'package:irmamobile/src/models/error_event.dart';
import 'package:irmamobile/src/models/event.dart';
import 'package:irmamobile/src/models/handle_url_event.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/issue_wizard.dart';
import 'package:irmamobile/src/models/log_entry.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/sentry/sentry.dart';

typedef EventUnmarshaller = Event Function(Map<String, dynamic>);

class IrmaClientBridge extends IrmaBridge {
  final MethodChannel _methodChannel;

  static final Map<Type, EventUnmarshaller> _eventUnmarshallers = {
    IrmaConfigurationEvent: (j) => IrmaConfigurationEvent.fromJson(j),
    CredentialsEvent: (j) => CredentialsEvent.fromJson(j),
    EnrollmentStatusEvent: (j) => EnrollmentStatusEvent.fromJson(j),
    LogsEvent: (j) => LogsEvent.fromJson(j),

    HandleURLEvent: (j) => HandleURLEvent.fromJson(j),

    EnrollmentSuccessEvent: (j) => EnrollmentSuccessEvent.fromJson(j),
    EnrollmentFailureEvent: (j) => EnrollmentFailureEvent.fromJson(j),

    AuthenticationSuccessEvent: (j) => AuthenticationSuccessEvent.fromJson(j),
    AuthenticationFailedEvent: (j) => AuthenticationFailedEvent.fromJson(j),
    AuthenticationErrorEvent: (j) => AuthenticationErrorEvent.fromJson(j),

    ChangePinSuccessEvent: (j) => ChangePinSuccessEvent.fromJson(j),
    ChangePinFailedEvent: (j) => ChangePinFailedEvent.fromJson(j),
    ChangePinErrorEvent: (j) => ChangePinErrorEvent.fromJson(j),

    ClientPreferencesEvent: (j) => ClientPreferencesEvent.fromJson(j),

    StatusUpdateSessionEvent: (j) => StatusUpdateSessionEvent.fromJson(j),
    RequestVerificationPermissionSessionEvent: (j) => RequestVerificationPermissionSessionEvent.fromJson(j),
    RequestIssuancePermissionSessionEvent: (j) => RequestIssuancePermissionSessionEvent.fromJson(j),
    RequestPinSessionEvent: (j) => RequestPinSessionEvent.fromJson(j),
    PairingRequiredSessionEvent: (j) => PairingRequiredSessionEvent.fromJson(j),
    SuccessSessionEvent: (j) => SuccessSessionEvent.fromJson(j),
    CanceledSessionEvent: (j) => CanceledSessionEvent.fromJson(j),
    KeyshareBlockedSessionEvent: (j) => KeyshareBlockedSessionEvent.fromJson(j),
    ClientReturnURLSetSessionEvent: (j) => ClientReturnURLSetSessionEvent.fromJson(j),
    FailureSessionEvent: (j) => FailureSessionEvent.fromJson(j),

    IssueWizardContentsEvent: (j) => IssueWizardContentsEvent.fromJson(j),

    ErrorEvent: (j) => ErrorEvent.fromJson(j),

    // FooBar: (j) => FooBar.fromJson(j),
  };

  // Create a lookup of unmarshallers
  static final Map<String, EventUnmarshaller> _eventUnmarshallerLookup =
      _eventUnmarshallers.map((Type t, EventUnmarshaller u) => MapEntry<String, EventUnmarshaller>(t.toString(), u));

  IrmaClientBridge() : _methodChannel = const MethodChannel('irma.app/irma_mobile_bridge') {
    // Start listening to method calls from the native side
    _methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    try {
      final data = jsonDecode(call.arguments as String) as Map<String, dynamic>;
      final unmarshaller = _eventUnmarshallerLookup[call.method];

      if (unmarshaller == null) {
        // Don't send 'call.arguments' to Sentry; it might contain personal data.
        reportError('Unrecognized bridge event received: ${call.method}', null);
        return;
      }

      if (kDebugMode) {
        debugPrint('Received bridge event: ${call.method} with payload ${call.arguments}');
      }

      final Event event = unmarshaller(data);
      addEvent(event);
    } catch (e, stacktrace) {
      reportError(e, stacktrace);
    }

    return;
  }

  @override
  void dispatch(Event event) {
    final encodedEvent = jsonEncode(event);
    if (kDebugMode) {
      debugPrint('Sending ${event.runtimeType.toString()} to bridge: $encodedEvent');
    }

    _methodChannel.invokeMethod(event.runtimeType.toString(), encodedEvent);
  }
}
