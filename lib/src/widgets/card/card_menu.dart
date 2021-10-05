// This code is not null safe yet.
// @dart=2.11

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/card/irma_card_theme.dart';

enum CardMenuOption {
  refresh,
  delete,
}

class CardMenu extends StatelessWidget {
  final IrmaCardTheme cardTheme;
  final Function() onRefreshCredential;
  final Function() onDeleteCredential;
  final bool allGood;

  const CardMenu({this.cardTheme, this.onRefreshCredential, this.onDeleteCredential, this.allGood});

  @override
  Widget build(BuildContext context) {
    // If the menu wouldn't have any options, don't show it at all
    if (onRefreshCredential == null && onDeleteCredential == null) {
      return Container();
    }
    return PopupMenuButton<CardMenuOption>(
      onSelected: (value) {
        if (value == CardMenuOption.refresh) {
          onRefreshCredential();
        } else if (value == CardMenuOption.delete) {
          onDeleteCredential();
        }
      },
      itemBuilder: (context) => [
        if (onRefreshCredential != null) ...[
          PopupMenuItem(
            value: CardMenuOption.refresh,
            child: Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.refresh,
                    color: IrmaTheme.of(context).primaryDark,
                  ),
                ),
                Text(
                  FlutterI18n.translate(context, 'card.refresh'),
                  style: IrmaTheme.of(context).textTheme.subtitle.copyWith(color: IrmaTheme.of(context).primaryDark),
                ),
              ],
            ),
          )
        ],
        if (onDeleteCredential != null) ...[
          PopupMenuItem(
            value: CardMenuOption.delete,
            child: Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.delete,
                    color: IrmaTheme.of(context).primaryDark,
                  ),
                ),
                Text(
                  FlutterI18n.translate(context, 'card.delete'),
                  style: IrmaTheme.of(context).textTheme.subtitle.copyWith(color: IrmaTheme.of(context).primaryDark),
                ),
              ],
            ),
          )
        ],
      ],
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.0),
      ),
      color: IrmaTheme.of(context).primaryLight,
      child: Transform.rotate(
        // TODO: replace icon in iconfont to a horizontalNav and remove this rotate
        angle: allGood ? 90 * math.pi / 180 : 0,
        child: Container(
          padding: const EdgeInsets.all(0.0),
          child: GestureDetector(
            child: Padding(
              padding: EdgeInsets.only(right: IrmaTheme.of(context).defaultSpacing, left: 14.0),
              child: allGood
                  ? Icon(IrmaIcons.verticalNav, size: 22.0, color: cardTheme.foregroundColor)
                  : Icon(IrmaIcons.warning, size: 16.0, color: cardTheme.foregroundColor),
            ),
          ),
        ),
      ),
    );
  }
}
