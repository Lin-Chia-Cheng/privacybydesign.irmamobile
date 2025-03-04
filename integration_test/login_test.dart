import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/src/widgets/yivi_themed_button.dart';

import 'helpers/helpers.dart';
import 'irma_binding.dart';
import 'util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('irma-login', () {
    // Initialize the app's repository for integration tests (enable developer mode, etc.)
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets('tc1', (tester) async {
      // Scenario 1 of login process
      // Initialize the app for integration tests
      await pumpAndUnlockApp(tester, irmaBinding.repository);

      // Open more tab
      await tester.tapAndSettle(find.byKey(const Key('nav_button_more')));
      // Logout
      final logoutButtonFinder = find.byKey(const Key('log_out_button')).hitTestable();
      await tester.scrollUntilVisible(logoutButtonFinder, 100);
      await tester.tapAndSettle(logoutButtonFinder);
      // login using wrong pin
      await tester.waitFor(find.byKey(const Key('pin_screen')));
      await enterPin(tester, '54321');
      // Check error dialog
      await tester.waitFor(find.byKey(const Key('irma_dialog')));
      // Check "Wrong PIN" dialog title text
      String string = tester.getAllText(find.byKey(const Key('irma_dialog_title'))).first;
      expect(string, 'PIN incorrect');
      // Check dialog text
      string = tester.getAllText(find.byKey(const Key('irma_dialog_content'))).first;
      expect(string,
          'This PIN is not correct. You have 2 attempts left before your Yivi app will be blocked temporarily.');

      await tester.tapAndSettle(find.descendant(
        of: find.byKey(const Key('irma_dialog')),
        matching: find.byType(YiviThemedButton),
      ));
    });

    testWidgets('tc2', (tester) async {
      // Scenario 2 of login process: User is blocked after 3 failed attempts.
      // Initialize the app for integration tests
      await pumpAndUnlockApp(tester, irmaBinding.repository);
      // Open more tab
      await tester.tapAndSettle(find.byKey(const Key('nav_button_more')));
      // Logout
      final logoutButtonFinder = find.byKey(const Key('log_out_button')).hitTestable();
      await tester.scrollUntilVisible(logoutButtonFinder, 100);
      await tester.tapAndSettle(logoutButtonFinder);
      // login using wrong pin
      await tester.waitFor(find.byKey(const Key('pin_screen')));
      await enterPin(tester, '54321');
      // Check error dialog
      await tester.waitFor(find.byKey(const Key('irma_dialog')));
      // Check "Wrong PIN" dialog title text
      String string = tester.getAllText(find.byKey(const Key('irma_dialog_title'))).first;
      expect(string, 'PIN incorrect');
      // Check dialog text
      string = tester.getAllText(find.byKey(const Key('irma_dialog_content'))).first;
      expect(string,
          'This PIN is not correct. You have 2 attempts left before your Yivi app will be blocked temporarily.');
      await tester.tapAndSettle(find.descendant(
        of: find.byKey(const Key('irma_dialog')),
        matching: find.byType(YiviThemedButton),
      ));
      // login using wrong pin
      await enterPin(tester, '54321');
      // Check error dialog
      await tester.waitFor(find.byKey(const Key('irma_dialog')));
      // Check "Wrong PIN" dialog title text
      string = tester.getAllText(find.byKey(const Key('irma_dialog_title'))).first;
      expect(string, 'PIN incorrect');
      // Check dialog text
      string = tester.getAllText(find.byKey(const Key('irma_dialog_content'))).first;
      expect(
          string, 'This PIN is not correct. You have 1 attempt left before your Yivi app will be blocked temporarily.');
      await tester.tapAndSettle(find.descendant(
        of: find.byKey(const Key('irma_dialog')),
        matching: find.byType(YiviThemedButton),
      ));
      // login using wrong pin
      await enterPin(tester, '54321');
      // Check error dialog
      await tester.waitFor(find.byKey(const Key('irma_dialog')));
      // Check "Wrong PIN" dialog title text
      string = tester.getAllText(find.byKey(const Key('irma_dialog_title'))).first;
      expect(string, 'App blocked');
      // Check dialog text
      string = tester.getAllText(find.byKey(const Key('irma_dialog_content'))).first;

      expect(string, 'Your app has been blocked for 1 minute. Please try again later.');
      await tester.tapAndSettle(find.descendant(
        of: find.byKey(const Key('irma_dialog')),
        matching: find.byType(YiviThemedButton),
      ));
      // Wait 65 seconds and try again using the correct pin
      await tester.pumpAndSettle(const Duration(seconds: 65));
      await unlock(tester);
    });
  });
}
