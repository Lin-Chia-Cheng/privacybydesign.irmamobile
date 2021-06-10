import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/language.dart';
import 'package:irmamobile/src/widgets/disclosure/carousel_attributes.dart';
import 'package:irmamobile/src/widgets/disclosure/unsatisfiable_credential_details.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';
import 'package:irmamobile/src/widgets/translated_text.dart';

import 'models/disclosure_credential.dart';

class Carousel extends StatefulWidget {
  final DisCon<Attribute> candidatesDisCon;
  final ValueChanged<int> onCurrentPageUpdate;
  final bool showObtainButton;
  final Function() onIssue;
  final List<Credential> credentials;

  const Carousel({
    @required this.candidatesDisCon,
    @required this.onCurrentPageUpdate,
    @required this.credentials,
    this.onIssue,
    this.showObtainButton = true,
  });

  @override
  _CarouselState createState() => _CarouselState();
}

class _CarouselState extends State<Carousel> {
  final GlobalKey _keyStackedIndex = GlobalKey();
  final _animationDuration = 250;
  final _footerColumnWidth = 60.0;
  int _currentPage = 0;

  double height;

  int get currentPage => _currentPage;
  set currentPage(int val) {
    _currentPage = val;
    widget.onCurrentPageUpdate(val);
  }

  final _controller = PageController();

  Function() _createOnRefreshCredential(CredentialType type) {
    return () {
      if (widget.onIssue != null) {
        widget.onIssue();
      }
      IrmaRepository.get().openIssueURL(context, type.fullId);
    };
  }

  // Determining size of widget as described here:
  // https://medium.com/@diegoveloper/flutter-widget-size-and-position-b0a9ffed9407

  Size _getSize() {
    final RenderBox renderBoxStackedIndex = _keyStackedIndex.currentContext.findRenderObject() as RenderBox;
    return renderBoxStackedIndex.size;
  }

  void _afterLayout(_) {
    final newHeight = _getSize().height;
    if (newHeight != height) {
      setState(() {
        height = _getSize().height;
      });
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(_afterLayout);
    super.initState();
  }

  // getChangedPageAndMoveBar and dotsIndicator from
  // https://medium.com/aubergine-solutions/create-an-onboarding-page-indicator-in-3-minutes-in-flutter-a2bd97ceeaff
  void getChangedPageAndMoveBar(int page) {
    setState(() {
      currentPage = page % widget.candidatesDisCon.length;
    });
  }

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          /* An offstage IndexedStack is used because an IndexedStack always has
          the height of the highest element. The height is then used to determine
          the height of a PageViewer (who needs to be in an element of pre-determined height).
          FUTURE: implement a more elegant solution */
          Offstage(
            offstage: true,
            child: IndexedStack(
                key: _keyStackedIndex,
                index: currentPage,
                children: widget.candidatesDisCon.map((con) => _buildCarouselWidget(con, isOffstage: true)).toList()),
          ),
          _buildPageViewer(),
        ],
      );

  Widget _buildPageViewer() => height == null
      ? Container()
      : Column(
          children: <Widget>[
            Container(
              height: height,
              child: PageView.builder(
                itemCount: widget.candidatesDisCon.length,
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _controller,
                onPageChanged: (int page) {
                  getChangedPageAndMoveBar(page);
                },
                itemBuilder: (BuildContext context, int index) {
                  return _buildCarouselWidget(widget.candidatesDisCon[index % widget.candidatesDisCon.length]);
                },
              ),
            ),
            if (widget.candidatesDisCon.length > 1) _buildNavBar(),
          ],
        );

  Widget _buildNavBar() => Container(
        height: 60.0,
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: <Widget>[
            Positioned(
              left: 0,
              child: _buildArrowButton(
                icon: IrmaIcons.chevronLeft,
                semanticLabel: "disclosure.previous",
                isVisible: currentPage > 0,
                delta: -1,
                size: widget.candidatesDisCon.length,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Spacer(flex: 15),
                Row(
                  children: <Widget>[
                    const Spacer(),
                    ...List.generate(
                        widget.candidatesDisCon.length, (i) => _buildDotsIndicator(isActive: i == currentPage)),
                    const Spacer(),
                  ],
                ),
                const Spacer(flex: 3),
                Center(
                  child: TranslatedText(
                    'disclosure.choices',
                    translationParams: {"choices": widget.candidatesDisCon.length.toString()},
                    style: IrmaTheme.of(context)
                        .textTheme
                        .body1
                        .copyWith(color: IrmaTheme.of(context).grayscale40, fontSize: 12),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
            Positioned(
              right: 0,
              child: _buildArrowButton(
                icon: IrmaIcons.chevronRight,
                semanticLabel: "disclosure.next",
                isVisible: currentPage < widget.candidatesDisCon.length - 1,
                delta: 1,
                size: widget.candidatesDisCon.length,
              ),
            ),
          ],
        ),
      );

  Widget _buildDotsIndicator({bool isActive}) => AnimatedContainer(
        duration: Duration(milliseconds: _animationDuration),
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        height: 5,
        width: 5,
        decoration: BoxDecoration(
          color: isActive ? IrmaTheme.of(context).grayscale40 : IrmaTheme.of(context).grayscale80,
          borderRadius: const BorderRadius.all(
            Radius.circular(3),
          ),
        ),
      );

  Widget _buildArrowButton({IconData icon, String semanticLabel, bool isVisible, int delta, int size}) =>
      AnimatedOpacity(
        opacity: isVisible ? 1 : 0,
        duration: Duration(milliseconds: _animationDuration),
        child: IconButton(
          icon: Icon(icon,
              color: IrmaTheme.of(context).interactionInformation,
              semanticLabel: FlutterI18n.translate(context, semanticLabel)),
          iconSize: 20.0,
          splashColor: isVisible ? const Color(0xffcccccc) : const Color(0x00000000),
          onPressed: () {
            setState(
              () {
                if (currentPage + delta >= 0 && currentPage + delta <= size - 1) {
                  currentPage += delta;
                  _controller.animateToPage(
                    currentPage,
                    duration: Duration(milliseconds: _animationDuration),
                    curve: Curves.easeInOut,
                  );
                }
              },
            );
          },
        ),
      );

  Widget _buildGetButton(DisclosureCredential cred) {
    final label = cred.attributes.first.credentialHash == ""
        ? FlutterI18n.translate(context, 'disclosure.obtain')
        : FlutterI18n.translate(context, 'disclosure.refresh');
    return Padding(
      padding: EdgeInsets.symmetric(vertical: IrmaTheme.of(context).defaultSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          IrmaButton(
            label: label,
            size: IrmaButtonSize.small,
            onPressed: _createOnRefreshCredential(cred.attributes.first.credentialInfo.credentialType),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialFooter(DisclosureCredential cred) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: IrmaTheme.of(context).smallSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: _footerColumnWidth,
                child: Opacity(
                  opacity: 0.5,
                  child: Text(
                    FlutterI18n.translate(context, 'disclosure.credential_name'),
                    style: IrmaTheme.of(context)
                        .textTheme
                        .body1
                        .copyWith(color: IrmaTheme.of(context).grayscale40, fontSize: 12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: IrmaTheme.of(context).smallSpacing),
                  child: Text(
                    getTranslation(context, cred.credentialInfo.credentialType.name),
                    style: IrmaTheme.of(context)
                        .textTheme
                        .body1
                        .copyWith(color: IrmaTheme.of(context).grayscale40, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: _footerColumnWidth,
                child: Opacity(
                  opacity: 0.5,
                  child: Text(
                    FlutterI18n.translate(context, 'disclosure.issuer'),
                    style: IrmaTheme.of(context)
                        .textTheme
                        .body1
                        .copyWith(color: IrmaTheme.of(context).grayscale40, fontSize: 12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: IrmaTheme.of(context).smallSpacing),
                  child: Text(
                    getTranslation(context, cred.issuer),
                    style: IrmaTheme.of(context)
                        .textTheme
                        .body1
                        .copyWith(color: IrmaTheme.of(context).grayscale40, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildUnsatisfiableCredential(DisclosureCredential missingCred, {bool isOffstage = false}) => <Widget>[
        UnsatisfiableCredentialDetails(
          presentCredentials:
              widget.credentials.where((cred) => cred.info.fullId == missingCred.credentialInfo.fullId).toList(),
          unsatisfiableCredential: missingCred,
          isOffstage: isOffstage,
        ),
        _buildCredentialFooter(missingCred),
        if (missingCred.obtainable) _buildGetButton(missingCred),
      ];

  List<Widget> _buildCredential(DisclosureCredential cred) => <Widget>[
        CarouselAttributes(attributes: cred.attributes),
        _buildCredentialFooter(cred),
      ];

  bool _group(List<List<Attribute>> list, Attribute attr) {
    if (list.isEmpty) {
      return false;
    }
    return list.last.last.credentialInfo.fullId == attr.credentialInfo.fullId;
  }

  Widget _buildCarouselWidget(Con<Attribute> candidatesCon, {bool isOffstage = false}) {
    // Handle empty conjunctions (if chosen, nothing is disclosed)
    if (candidatesCon.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            FlutterI18n.translate(context, 'disclosure.nothing_selected'),
            style:
                IrmaTheme.of(context).textTheme.body1.copyWith(color: IrmaTheme.of(context).grayscale40, fontSize: 14),
          ),
        ],
      );
    }

    // Transform candidatesCon into a list where attributes of the same issuer
    // are grouped together. This assumes those attributes are always
    // adjacent within the specified con, which is guaranteed by irmago.
    final grouped = candidatesCon.fold(
      <List<Attribute>>[],
      (List<List<Attribute>> list, attr) => _group(list, attr) ? (list..last.add(attr)) : (list..add([attr])),
    ).toList();
    final credentials = grouped
        .asMap()
        .map(
          (i, list) => MapEntry(i, DisclosureCredential(attributes: Con(list), isLast: i == grouped.length - 1)),
        )
        .values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: credentials
          .map((cred) => <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).mediumSpacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: cred.satisfiable
                        ? _buildCredential(cred)
                        : _buildUnsatisfiableCredential(cred, isOffstage: isOffstage),
                  ),
                ),
                if (!cred.isLast)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: IrmaTheme.of(context).smallSpacing),
                    child: Container(
                      color: IrmaTheme.of(context).grayscale80,
                      height: 1,
                    ),
                  ),
              ])
          .expand((f) => f)
          .toList(),
    );
  }
}
