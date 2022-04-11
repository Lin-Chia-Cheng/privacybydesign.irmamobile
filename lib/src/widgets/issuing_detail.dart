import 'package:flutter/material.dart';

import '../models/credentials.dart';
import '../theme/theme.dart';
import 'credential_card/irma_credentials_card.dart';

class IssuingDetail extends StatelessWidget {
  final List<Credential> credentials;

  const IssuingDetail(this.credentials);

  @override
  Widget build(BuildContext context) {
    return Column(children: _buildCards(context));
  }

  List<Widget> _buildCards(BuildContext context) {
    return credentials.map((credential) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: IrmaTheme.of(context).defaultSpacing,
        ),
        child: IrmaCredentialsCard.fromCredential(
          credential: credential,
          expanded: true,
          showWarnings: false,
        ),
      );
    }).toList();
  }
}
