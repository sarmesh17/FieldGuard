import 'package:fieldguard/core/responsive/responsive.dart';
import 'package:fieldguard/features/legal/legal_content.dart';
import 'package:flutter/material.dart';

// ─── Brand colours (match the app's green palette) ───────────────────────────
const _kDark = Color(0xff072A1C);
const _kPrimary = Color(0xff0E5A3B);
const _kMid = Color(0xff1D7A51);

/// Which document the [LegalScreen] should open on.
enum LegalTab { terms, privacy }

/// A single screen with two tabs — Terms & Conditions and Privacy Policy.
///
/// Push it with [initialTab] to land on the relevant document. Content lives in
/// `legal_content.dart` so the text can be revised without touching the UI.
class LegalScreen extends StatefulWidget {
  final LegalTab initialTab;
  const LegalScreen({super.key, this.initialTab = LegalTab.terms});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == LegalTab.privacy ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          _Header(tabController: _tabController),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _DocumentView(
                  intro:
                      'Please read these Terms & Conditions carefully before '
                      'using FieldGuard.',
                  sections: kTermsSections,
                ),
                _DocumentView(
                  intro:
                      'This Privacy Policy explains how we handle your data '
                      'under the laws of Nepal.',
                  sections: kPrivacySections,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header with back button, title and tabs ─────────────────────────────────
class _Header extends StatelessWidget {
  final TabController tabController;
  const _Header({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kDark, _kPrimary, _kMid],
          stops: [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x330E5A3B),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                SizeConfig.scale(8),
                SizeConfig.scale(8),
                SizeConfig.scale(16),
                SizeConfig.scale(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: SizeConfig.scale(24),
                    ),
                  ),
                  Text(
                    'Legal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: SizeConfig.scaledFontSize(20),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: TextStyle(
                fontSize: SizeConfig.scaledFontSize(13),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: SizeConfig.scaledFontSize(13),
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Terms & Conditions'),
                Tab(text: 'Privacy Policy'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── A single rendered document ──────────────────────────────────────────────
class _DocumentView extends StatelessWidget {
  final String intro;
  final List<LegalSection> sections;
  const _DocumentView({required this.intro, required this.sections});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.scale(20),
        SizeConfig.scale(20),
        SizeConfig.scale(20),
        SizeConfig.scale(40),
      ),
      children: [
        Text(
          'Last updated: $kLegalLastUpdated',
          style: TextStyle(
            fontSize: SizeConfig.scaledFontSize(12),
            color: const Color(0xff9CA3AF),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: SizeConfig.scale(10)),
        Text(
          intro,
          style: TextStyle(
            fontSize: SizeConfig.scaledFontSize(14),
            color: const Color(0xff4B5563),
            height: 1.5,
          ),
        ),
        SizedBox(height: SizeConfig.scale(20)),
        for (final section in sections) ...[
          _SectionTitle(section.title),
          SizedBox(height: SizeConfig.scale(8)),
          for (final node in section.body) ...[
            _LegalNodeView(node),
            SizedBox(height: SizeConfig.scale(10)),
          ],
          SizedBox(height: SizeConfig.scale(14)),
        ],
        const _Disclaimer(),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: SizeConfig.scale(4)),
          width: SizeConfig.scale(4),
          height: SizeConfig.scale(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kPrimary, _kMid],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(SizeConfig.scale(4)),
          ),
        ),
        SizedBox(width: SizeConfig.scale(10)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: SizeConfig.scaledFontSize(16),
              fontWeight: FontWeight.w800,
              color: const Color(0xff111827),
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _LegalNodeView extends StatelessWidget {
  final LegalNode node;
  const _LegalNodeView(this.node);

  @override
  Widget build(BuildContext context) {
    final node = this.node;
    if (node is LegalParagraph) {
      return Text(
        node.text,
        style: TextStyle(
          fontSize: SizeConfig.scaledFontSize(13.5),
          color: const Color(0xff374151),
          height: 1.6,
        ),
      );
    }
    if (node is LegalBullets) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in node.items)
            Padding(
              padding: EdgeInsets.only(bottom: SizeConfig.scale(6)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: SizeConfig.scale(7)),
                    child: Container(
                      width: SizeConfig.scale(5),
                      height: SizeConfig.scale(5),
                      decoration: const BoxDecoration(
                        color: _kMid,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  SizedBox(width: SizeConfig.scale(10)),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: SizeConfig.scaledFontSize(13.5),
                        color: const Color(0xff374151),
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.scale(14)),
      decoration: BoxDecoration(
        color: const Color(0xffFFF7E6),
        borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
        border: Border.all(color: const Color(0xffFFE0A3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: const Color(0xffB7791F),
            size: SizeConfig.scale(18),
          ),
          SizedBox(width: SizeConfig.scale(10)),
          Expanded(
            child: Text(
              'This document references the principal laws of Nepal applicable '
              'to this service. It is provided for general information and is '
              'not legal advice.',
              style: TextStyle(
                fontSize: SizeConfig.scaledFontSize(11.5),
                color: const Color(0xff92722A),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
