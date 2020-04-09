import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_bloc.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_event.dart';
import 'package:irmamobile/src/screens/change_pin/models/change_pin_state.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/choose_pin.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/confirm_error_dialog.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/confirm_pin.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/enter_error_dialog.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/enter_pin.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/success.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/updating_pin.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/valdating_pin.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_bloc.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_event.dart';
import 'package:irmamobile/src/screens/pin/pin_screen.dart';
import 'package:irmamobile/src/widgets/pin_common/pin_wrong_attempts.dart';
import 'package:irmamobile/src/widgets/pin_common/pin_wrong_blocked.dart';

class ChangePinScreen extends StatelessWidget {
  static const routeName = "/change_pin";

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChangePinBloc>(
        builder: (_) => ChangePinBloc(),
        child: BlocBuilder<ChangePinBloc, ChangePinState>(builder: (context, _) {
          final bloc = BlocProvider.of<ChangePinBloc>(context);
          return ProvidedChangePinScreen(bloc: bloc);
        }));
  }
}

class ProvidedChangePinScreen extends StatefulWidget {
  final ChangePinBloc bloc;

  const ProvidedChangePinScreen({this.bloc}) : super();

  @override
  State<StatefulWidget> createState() => ProvidedChangePinScreenState(bloc: bloc);
}

class ProvidedChangePinScreenState extends State<ProvidedChangePinScreen> {
  final ChangePinBloc bloc;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final FocusNode currentPinFocusNode = FocusNode();
  final FocusNode newPinFocusNode = FocusNode();

  ProvidedChangePinScreenState({this.bloc}) : super();

  Map<String, WidgetBuilder> _routeBuilders() {
    return {
      EnterPin.routeName: (_) =>
          EnterPin(pinFocusNode: currentPinFocusNode, submitOldPin: submitOldPin, cancel: cancel),
      ValidatingPin.routeName: (_) => ValidatingPin(cancel: cancel),
      ChoosePin.routeName: (_) => ChoosePin(
          pinFocusNode: newPinFocusNode, chooseNewPin: chooseNewPin, toggleLongPin: toggleLongPin, cancel: cancel),
      ConfirmPin.routeName: (_) => ConfirmPin(confirmNewPin: confirmNewPin, cancel: () => {}),
      UpdatingPin.routeName: (_) => UpdatingPin(cancel: cancel),
      Success.routeName: (_) => Success(cancel: cancel),
    };
  }

  void submitOldPin(String pin) {
    bloc.dispatch(OldPinEntered(pin: pin));
  }

  void toggleLongPin() {
    bloc.dispatch(ToggleLongPin());
  }

  void chooseNewPin(BuildContext context, String pin) {
    bloc.dispatch(NewPinChosen(pin: pin));
    navigatorKey.currentState.pushNamed(ConfirmPin.routeName);
  }

  void confirmNewPin(String pin) {
    bloc.dispatch(NewPinConfirmed(pin: pin));
  }

  void cancel() {
    bloc.dispatch(ChangePinCanceled());
  }

  @override
  Widget build(BuildContext context) {
    final routeBuilders = _routeBuilders();

    return BlocListener<ChangePinBloc, ChangePinState>(
      condition: (ChangePinState previous, ChangePinState current) {
        return current.newPinConfirmed != previous.newPinConfirmed ||
            current.oldPinVerified != previous.oldPinVerified ||
            current.validatingPin != previous.validatingPin ||
            current.attemptsRemaining != previous.attemptsRemaining;
      },
      listener: (BuildContext context, ChangePinState state) {
        if (state.newPinConfirmed == ValidationState.valid) {
          navigatorKey.currentState.pushNamedAndRemoveUntil(Success.routeName, (_) => false);
        } else if (state.newPinConfirmed == ValidationState.invalid) {
          navigatorKey.currentState.pop();
          // show error overlay
          showDialog(
            context: context,
            builder: (BuildContext context) => ConfirmErrorDialog(onClose: () async {
              // close the overlay
              Navigator.of(context).pop();
              newPinFocusNode.requestFocus();
            }),
          );
        } else if (state.oldPinVerified == ValidationState.valid) {
          navigatorKey.currentState.pushReplacementNamed(ChoosePin.routeName);
        } else if (state.oldPinVerified == ValidationState.invalid) {
          // go back
          navigatorKey.currentState.pop();
          // and show error to user
          if (state.attemptsRemaining != 0) {
            showDialog(
              context: context,
              child: PinWrongAttemptsDialog(attemptsRemaining: state.attemptsRemaining),
            );
          } else {
            Navigator.of(context, rootNavigator: true).pushReplacementNamed(PinScreen.routeName);
            PinBloc().dispatch(Lock());
            showDialog(
              context: context,
              child: PinWrongBlockedDialog(blocked: state.blockedUntil.difference(DateTime.now()).inSeconds),
            );
          }
        } else if (state.oldPinVerified == ValidationState.error) {
          // go back
          navigatorKey.currentState.pop();
          // and show error overlay
          showDialog(
            context: context,
            builder: (BuildContext context) => EnterErrorDialog(onClose: () async {
              // close the overlay
              Navigator.of(context).pop();
              currentPinFocusNode.requestFocus();
            }),
          );
        } else if (state.updatingPin == true) {
          navigatorKey.currentState.pushNamed(UpdatingPin.routeName);
        } else if (state.validatingPin == true) {
          navigatorKey.currentState.pushNamed(ValidatingPin.routeName);
        }
      },
      child: Navigator(
        key: navigatorKey,
        initialRoute: EnterPin.routeName,
        onGenerateRoute: (RouteSettings settings) {
          if (!routeBuilders.containsKey(settings.name)) {
            throw Exception('Invalid route: ${settings.name}');
          }
          final child = routeBuilders[settings.name];

          return MaterialPageRoute(builder: child, settings: settings);
        },
      ),
    );
  }
}
