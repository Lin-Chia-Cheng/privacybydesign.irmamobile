import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../irma_binding.dart';
import 'empty_app_scenarios/choice.dart';
import 'empty_app_scenarios/choice_mixed.dart';
import 'empty_app_scenarios/completely_optional.dart';
import 'empty_app_scenarios/no_choice.dart';
import 'empty_app_scenarios/no_choice_multiple_creds.dart';
import 'empty_app_scenarios/optionals.dart';
import 'empty_app_scenarios/specific_attribute_values.dart';
import 'filled_app_scenarios/filled_choice.dart';
import 'filled_app_scenarios/filled_choice_mixed.dart';
import 'filled_app_scenarios/filled_discon.dart';
import 'filled_app_scenarios/filled_no_choice_multiple_creds.dart';
import 'filled_app_scenarios/filled_optional_disjunction.dart';
import 'filled_app_scenarios/filled_specific_attribute_values_match.dart';
import 'filled_app_scenarios/filled_specific_attribute_values_no_match.dart';
import 'special_scenarios/attribute_order.dart';
import 'special_scenarios/combined_disclosure_issuance.dart';
import 'special_scenarios/nullables.dart';
import 'special_scenarios/random_blind.dart';
import 'special_scenarios/revocation.dart';
import 'special_scenarios/signing.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('disclosure-session', () {
    setUp(() async => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    group(
      'empty-app-scenarios',
      () {
        // Full name AND nationality
        testWidgets(
          'no-choice',
          (tester) => noChoiceTest(tester, irmaBinding),
        );

        // Email OR your mobile number
        testWidgets(
          'choice',
          (tester) => choiceTest(tester, irmaBinding),
        );

        // Email AND mobile number
        testWidgets(
          'no-choice-multiple-creds',
          (tester) => noChoiceMultipleCredsTest(tester, irmaBinding),
        );

        // Address from multiplicity OR iDIN
        // AND your AGB code (from Nuts)
        testWidgets(
          'choice-mixed',
          (tester) => choiceMixedTest(tester, irmaBinding),
        );

        // TODO Fix this test
        // // Student/employee id from university OR
        // // Full name from municipality AND email address
        // testWidgets(
        //   'choice-mixed-sources',
        //   (tester) => choiceMixedSourcesTest(tester, irmaBinding),
        // );

        // Bank account number from iDeal. BIC has to be RABONL2U. AND
        // Initials, family name and city from iDIN. The city has to be Arnhem
        testWidgets(
          'specific-attribute-values',
          (tester) => specificAttributeValuesTest(tester, irmaBinding),
        );

        // Address from iDIN or municipality
        // And optionally mobile number or e-mail address
        testWidgets('optionals', (tester) => optionalsTest(tester, irmaBinding));

        // E-mail address or nothing
        testWidgets(
          'completely-optional',
          (tester) => completelyOptionalTest(tester, irmaBinding),
        );
      },
    );

    group('filled-app-scenarios', () {
      // All these tests start with a filled app including:
      // An email address
      // Personal data from municipality

      // Email OR your mobile number.
      testWidgets(
        'filled-choice',
        (tester) => filledChoiceTest(tester, irmaBinding),
      );

      // Email AND telephone number
      testWidgets(
        'filled-no-choice-multiple-creds',
        (tester) => filledNoChoiceMultipleCredsTest(tester, irmaBinding),
      );

      // Address from municipality OR
      // Address from iDIN, with city
      testWidgets(
        'filled-choice-mixed',
        (tester) => filledChoiceMixedTest(tester, irmaBinding),
      );

      // Address from municipality OR
      // Address from iDIN AND
      // Email
      testWidgets(
        'filled-discon',
        (tester) => filledDisconTest(tester, irmaBinding),
      );

      // Address from municipality where city hast to be Arnhem AND
      // Email address where domain has to be test.com
      testWidgets(
        'filled-specific-attribute-values-match',
        (tester) => filledSpecificAttributeValuesMatchTest(
          tester,
          irmaBinding,
        ),
      );

      // Email address where domain has to be test.com
      testWidgets(
        'filled-specific-attribute-values-no-match',
        (tester) => filledSpecificAttributeValuesNoMatchTest(
          tester,
          irmaBinding,
        ),
      );

      // Email address and optionally a mobile number
      testWidgets(
        'filled-optional-disjunction',
        (tester) => filledOptionalDisjunctionTest(
          tester,
          irmaBinding,
        ),
      );
    });

    group('special-scenarios', () {
      // Session with an optional attribute that cannot be null
      testWidgets(
        'nullables',
        (tester) => nullablesTest(
          tester,
          irmaBinding,
        ),
      );

      // Disclosure session and signing a message
      testWidgets(
        'signing',
        (tester) => signingTest(
          tester,
          irmaBinding,
        ),
      );

      // Issuance and disclosure in one session
      testWidgets(
        'combined-disclosure-issuance-session',
        (tester) => combinedDisclosureIssuanceSessionTest(
          tester,
          irmaBinding,
        ),
      );

      // Entering a session with a revoked credential
      testWidgets(
        'revocation',
        (tester) => revocationTest(
          tester,
          irmaBinding,
        ),
      );

      // Address from municipality with different attribute order
      testWidgets(
        'attribute-order',
        (tester) => attributeOrderTest(
          tester,
          irmaBinding,
        ),
      );

      // Disclosing stempas credential which is an unobtainable credential (no IssueURL) and contains a random blind attribute.
      testWidgets(
        'random-blind',
        (tester) => randomBlindTest(
          tester,
          irmaBinding,
        ),
      );
    });
  });
}
