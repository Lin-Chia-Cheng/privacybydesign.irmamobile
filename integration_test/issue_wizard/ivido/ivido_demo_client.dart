import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/screens/issue_wizard/widgets/issue_wizard_success_screen.dart';
import 'package:irmamobile/src/screens/issue_wizard/widgets/wizard_scaffold.dart';
import 'package:irmamobile/src/screens/scanner/widgets/qr_scanner.dart';
import 'package:irmamobile/src/widgets/collapsible.dart';
import 'package:irmamobile/src/widgets/irma_card.dart';
import 'package:irmamobile/src/widgets/irma_markdown.dart';
import 'package:irmamobile/src/widgets/irma_stepper.dart';
import 'package:irmamobile/src/widgets/issuer_verifier_header.dart';

import '../../helpers/helpers.dart';
import '../../helpers/issuance_helpers.dart';
import '../../irma_binding.dart';
import '../../util.dart';

Future<void> ividoDemoClientTest(WidgetTester tester, IntegrationTestIrmaBinding irmaBinding) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Navigate to the scanner screen
  await tester.tapAndSettle(find.byKey(const Key('nav_button_scanner')));

  // Create a pointer for the Ivido demo
  final ividoIssueWizardPointer = IssueWizardPointer('irma-demo-requestors.ivido.demo-client');

  // Feed the pointer to the onFound in the QrScanner widget to mock starting a session via QR code
  final qrScannerFinder = find.byType(QRScanner);
  final qrScannerWidget = qrScannerFinder.evaluate().first.widget as QRScanner;
  qrScannerWidget.onFound(ividoIssueWizardPointer);

  // This takes quite some time
  await tester.pumpAndSettle(const Duration(seconds: 3));

  // Expect the issue wizard
  expect(find.byType(WizardScaffold), findsOneWidget);

  // Expect to find the header
  final headerFinder = find.byType(IssuerVerifierHeader);
  expect(headerFinder, findsOneWidget);

  // Expect the header with the right text
  expect(
    find.descendant(
      of: headerFinder,
      matching: find.text('Ivido PHE'),
    ),
    findsOneWidget,
  );

  // Expect the right background color from Ivido
  final headerWidget = headerFinder.evaluate().first.widget as IssuerVerifierHeader;
  expect(headerWidget.backgroundColor, const Color(0xffe7dffe));

  // Test the questions and answers
  final qAndAs = {
    'Which data are added?':
        'You retrieve your personal data. You need this data to show who you are. That way only you can log in on your account.',
    'Where do you get the data?':
        'You retrieve your personal data from the dutch personal records database ("Basis Registratie Personen", BRP). You log in with DigiD at the municipality of Nijmegen. Even if you live in another city. Nijmegen offers this service for everyone with a DigiD.',
    'How does it work?':
        'Your login data are stored only in your IRMA app on your phone. To log in at Ivido you show who you are with your IRMA app.',
    'What is Ivido?':
        'Ivido is a Personal Health Environment (PHE, dutch: PHO). In Ivido you can store everything about your healt. You choose yourself with who you share this data. You use IRMA to register and log in at Ivido.',
  };

  // There should be a collapsible card for every expected q and a item.
  final collapsiblesFinder = find.byType(Collapsible);
  expect(collapsiblesFinder, findsNWidgets(qAndAs.length));

  for (var i = 0; i < qAndAs.entries.length; i++) {
    final qAndAEntry = qAndAs.entries.elementAt(i);
    final question = qAndAEntry.key;
    final answer = qAndAEntry.value;

    // Find the specific collapsible which we are checking this iteration.
    final collapsibleFinder = collapsiblesFinder.at(i);

    if (!tester.any(collapsibleFinder)) {
      await tester.scrollUntilVisible(collapsibleFinder, 100);
    }
    expect(collapsibleFinder, findsOneWidget);

    // Expect the question text to be present on this collapsible
    final questionFinder = find.descendant(
      of: collapsibleFinder,
      matching: find.text(question).hitTestable(),
    );
    expect(questionFinder, findsOneWidget);

    // Unfold answer.
    await tester.tapAndSettle(questionFinder);

    // The collapsible should have IrmaMarkdown as content
    final markDownFinder = find.descendant(
      of: collapsibleFinder,
      matching: find.byType(IrmaMarkdown),
    );
    expect(markDownFinder, findsOneWidget);

    // Because markdown is hard to test we compare the expected markdown with the markdown in the widget
    // Note: This does not check the actual text on the screen!
    final markdownWidget = markDownFinder.evaluate().first.widget as IrmaMarkdown;
    expect(markdownWidget.data, answer);

    // Fold answer again.
    await tester.tapAndSettle(
      questionFinder,
      duration: const Duration(seconds: 1),
    );
  }

  // Go to the actual issue wizard
  await tester.tapAndSettle(find.text('Add'));

  // TODO Check the progress indicator

  // Expect stepper with two cards
  final stepperFinder = find.byType(IrmaStepper);
  expect(stepperFinder, findsOneWidget);

  final stepperCardsFinder = find.descendant(
    of: stepperFinder,
    matching: find.byType(IrmaCard),
  );
  expect(stepperCardsFinder, findsNWidgets(2));

  // Expect the right content on the first card
  expect(
    tester.getAllText(stepperCardsFinder.first),
    [
      'Demo Personal data',
      'Retrieve your personal data from the dutch personal records database ("Basis Registratie Personen", BRP). You do this with DigiD. You need this information to show who you are.',
    ],
  );

  // Expect the right content on the second card
  expect(
    tester.getAllText(stepperCardsFinder.at(1)),
    [
      'Demo Ivido Login',
      'Retrieve your Ivido login pass. This way you can log at Ivido in easily and safely.',
    ],
  );

  // Retrieve the demo personal data
  await issueMunicipalityPersonalData(
    tester,
    irmaBinding,
    continueOnSecondDevice: false,
  );

  // Issue the Ivido login card.
  await issueDemoIvidoLogin(
    tester,
    irmaBinding,
    continueOnSecondDevice: false,
  );

  // Press OK and complete the issue wizard
  await tester.tapAndSettle(find.text('OK'));

  // Expect success screen
  final successScreenFinder = find.byType(IssueWizardSuccessScreen);
  expect(successScreenFinder, findsOneWidget);

  // Expect the correct text on the success screen
  expect(find.text('Done!'), findsOneWidget);
  // The english content text is in dutch too for this demo issue wizard
  expect(find.text('Je kunt nu inloggen bij Ivido.'), findsOneWidget);

  await tester.tapAndSettle(find.text('OK'));
  expect(find.byType(WizardScaffold), findsNothing);
}
