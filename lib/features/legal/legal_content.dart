// ─────────────────────────────────────────────────────────────────────────────
// Legal content — Terms & Conditions and Privacy Policy for FieldGuard.
//
// IMPORTANT: This text is a good-faith template that references the principal
// Nepali statutes governing a field-force tracking / data-processing app. It is
// NOT a substitute for legal advice. Before publishing to production, have a
// licensed advocate in Nepal review and adapt it, and replace every
// [bracketed placeholder] with your real entity details.
//
// Principal laws referenced:
//   • Constitution of Nepal, 2072 (2015) — Art. 28 (Right to Privacy)
//   • Individual Privacy Act, 2075 (2018) & Individual Privacy Regulation,
//     2077 (2020)
//   • Electronic Transactions Act, 2063 (2008)
//   • Consumer Protection Act, 2075 (2018)
//   • Labour Act, 2074 (2017)
//   • Companies Act, 2063 (2006)
// ─────────────────────────────────────────────────────────────────────────────

/// The date the documents were last revised. Update whenever the text changes.
const String kLegalLastUpdated = '31 May 2026';

/// A single block inside a legal section — either a paragraph or a bulleted list.
sealed class LegalNode {
  const LegalNode();
}

/// A run of prose.
class LegalParagraph extends LegalNode {
  final String text;
  const LegalParagraph(this.text);
}

/// A bulleted list of points.
class LegalBullets extends LegalNode {
  final List<String> items;
  const LegalBullets(this.items);
}

/// A titled section of a legal document.
class LegalSection {
  final String title;
  final List<LegalNode> body;
  const LegalSection({required this.title, required this.body});
}

// ─── Terms & Conditions ───────────────────────────────────────────────────────

const List<LegalSection> kTermsSections = [
  LegalSection(
    title: '1. Introduction & Acceptance',
    body: [
      LegalParagraph(
        'These Terms & Conditions ("Terms") govern your access to and use of '
        'the FieldGuard mobile application and related services ("the App"), '
        'operated by [Company Legal Name], a company registered in Nepal under '
        'the Companies Act, 2063 (2006) ("we", "us", "our"). By creating an '
        'account or using the App, you confirm that you have read, understood '
        'and agree to be bound by these Terms.',
      ),
      LegalParagraph(
        'Under the Electronic Transactions Act, 2063 (2008), your acceptance '
        'in electronic form — including tapping "Agree", registering an '
        'account, or continuing to use the App — has the same legal effect as '
        'a hand-written signature and constitutes a binding agreement.',
      ),
    ],
  ),
  LegalSection(
    title: '2. Eligibility',
    body: [
      LegalParagraph(
        'You must be at least 18 years of age and legally competent to enter '
        'into a contract under the laws of Nepal. If you use the App on behalf '
        'of a company or organisation, you represent that you are authorised '
        'to bind that organisation to these Terms.',
      ),
    ],
  ),
  LegalSection(
    title: '3. Accounts, Registration & KYC',
    body: [
      LegalParagraph(
        'To use the App, a company administrator must register and provide '
        'verification documents, which may include the company registration '
        'certificate, PAN/VAT details and the administrator\'s citizenship '
        'proof. You confirm that all information and documents you submit are '
        'true, accurate and lawfully provided.',
      ),
      LegalParagraph(
        'You are responsible for maintaining the confidentiality of your login '
        'credentials and for all activity that occurs under your account. '
        'Notify us immediately of any unauthorised access. Accessing another '
        'person\'s account or data without authorisation is an offence under '
        'the Electronic Transactions Act, 2063 (2008).',
      ),
    ],
  ),
  LegalSection(
    title: '4. Location Tracking & Employee Monitoring',
    body: [
      LegalParagraph(
        'The App provides live GPS location tracking, geofencing and field '
        'activity monitoring of field representatives. These features collect '
        'and process precise location data while a tracking session or '
        'geofence service is active.',
      ),
      LegalParagraph(
        'If you are an employer using the App to monitor employees, you are '
        'responsible — as the data controller — for obtaining the informed '
        'consent of each monitored person before tracking begins, and for '
        'complying with the Individual Privacy Act, 2075 (2018) and the Labour '
        'Act, 2074 (2017). Monitoring must be limited to working hours and '
        'legitimate business purposes. We provide the tool; you are responsible '
        'for lawful use of it.',
      ),
    ],
  ),
  LegalSection(
    title: '5. Acceptable Use',
    body: [
      LegalParagraph('You agree that you will not:'),
      LegalBullets([
        'Use the App for any unlawful purpose or in violation of any law of Nepal;',
        'Track, surveil or collect data about any person without a lawful basis and their consent;',
        'Upload false, forged or misleading documents or information;',
        'Attempt to gain unauthorised access to, interfere with, or disrupt the App, its servers or other users\' data;',
        'Reverse-engineer, copy, resell or commercially exploit the App except as expressly permitted.',
      ]),
    ],
  ),
  LegalSection(
    title: '6. Payment & Collection Records',
    body: [
      LegalParagraph(
        'Where the App records payments, cheques or collections, these are '
        'record-keeping features only. We are not a bank, payment service '
        'provider or financial institution, and the App does not process or '
        'settle funds. You remain responsible for the accuracy of financial '
        'records and for compliance with applicable tax and financial laws of '
        'Nepal.',
      ),
    ],
  ),
  LegalSection(
    title: '7. Intellectual Property',
    body: [
      LegalParagraph(
        'The App, including its software, design, logos and content, is owned '
        'by [Company Legal Name] and is protected under the laws of Nepal, '
        'including the Copyright Act, 2059 (2002). You are granted a limited, '
        'non-exclusive, non-transferable licence to use the App for your '
        'internal business purposes. The data you enter remains yours.',
      ),
    ],
  ),
  LegalSection(
    title: '8. Service Availability & Disclaimers',
    body: [
      LegalParagraph(
        'The App is provided on an "as is" and "as available" basis. We do not '
        'warrant that the service will be uninterrupted, error-free, or that '
        'location data will be accurate at all times — GPS accuracy depends on '
        'the device, network and environment. We may suspend or modify the '
        'service for maintenance or other reasons.',
      ),
    ],
  ),
  LegalSection(
    title: '9. Limitation of Liability',
    body: [
      LegalParagraph(
        'To the maximum extent permitted by the laws of Nepal, we shall not be '
        'liable for any indirect, incidental or consequential loss arising '
        'from your use of, or inability to use, the App, or from any unlawful '
        'use of the monitoring features by you or your personnel. Nothing in '
        'these Terms limits any liability that cannot be excluded under '
        'applicable law, including the Consumer Protection Act, 2075 (2018).',
      ),
    ],
  ),
  LegalSection(
    title: '10. Termination',
    body: [
      LegalParagraph(
        'We may suspend or terminate your access if you breach these Terms or '
        'use the App unlawfully. You may stop using the App and request '
        'deletion of your account at any time by contacting us. On '
        'termination, we will retain or delete data in accordance with our '
        'Privacy Policy and applicable law.',
      ),
    ],
  ),
  LegalSection(
    title: '11. Governing Law & Jurisdiction',
    body: [
      LegalParagraph(
        'These Terms are governed by and construed in accordance with the laws '
        'of Nepal. Any dispute arising out of or relating to these Terms or the '
        'App shall be subject to the exclusive jurisdiction of the competent '
        'courts of Nepal.',
      ),
    ],
  ),
  LegalSection(
    title: '12. Changes to These Terms',
    body: [
      LegalParagraph(
        'We may update these Terms from time to time. Material changes will be '
        'notified within the App. Your continued use after changes take effect '
        'constitutes acceptance of the revised Terms.',
      ),
    ],
  ),
  LegalSection(
    title: '13. Contact',
    body: [
      LegalParagraph(
        'For any questions about these Terms, contact us at:\n'
        '[Company Legal Name]\n'
        '[Registered Address, Nepal]\n'
        'Email: [contact email]\n'
        'Phone: [contact phone]',
      ),
    ],
  ),
];

// ─── Privacy Policy ───────────────────────────────────────────────────────────

const List<LegalSection> kPrivacySections = [
  LegalSection(
    title: '1. Our Commitment to Your Privacy',
    body: [
      LegalParagraph(
        'This Privacy Policy explains how [Company Legal Name] ("we", "us") '
        'collects, uses, stores and protects personal data when you use the '
        'FieldGuard application. We process personal data in accordance with '
        'the right to privacy guaranteed by Article 28 of the Constitution of '
        'Nepal, 2072 (2015), the Individual Privacy Act, 2075 (2018), the '
        'Individual Privacy Regulation, 2077 (2020), and the Electronic '
        'Transactions Act, 2063 (2008).',
      ),
    ],
  ),
  LegalSection(
    title: '2. Information We Collect',
    body: [
      LegalParagraph('We collect the following categories of personal data:'),
      LegalBullets([
        'Account & company data — names, email addresses, phone numbers, roles and company details;',
        'KYC / verification documents — company registration certificate, PAN/VAT details and citizenship proof;',
        'Location data — precise GPS coordinates, route history and geofence events of field representatives, collected while tracking is active (including in the background where enabled);',
        'Operational data — shops, tasks, routes, attendance and payment/collection records you enter;',
        'Device & usage data — device identifiers, app version, log and diagnostic data.',
      ]),
    ],
  ),
  LegalSection(
    title: '3. Legal Basis & Consent',
    body: [
      LegalParagraph(
        'Under the Individual Privacy Act, 2075 (2018), personal data may only '
        'be collected and processed with the consent of the person concerned '
        'or as otherwise permitted by law. By using the App you consent to the '
        'processing described in this Policy. Where you collect data about your '
        'employees or third parties through the App, you are responsible for '
        'obtaining their informed consent.',
      ),
    ],
  ),
  LegalSection(
    title: '4. How We Use Location Data',
    body: [
      LegalParagraph(
        'Location data is central to the App and deserves special mention. We '
        'use it solely to provide the service: showing live position on the '
        'map, recording visited shops and routes, triggering geofence entry/'
        'exit events, and producing field-activity reports for the employer.',
      ),
      LegalParagraph(
        'Location is collected only while a tracking session or geofence '
        'monitoring service is active. We do not sell location data, and we do '
        'not use it for advertising. Each monitored person should be clearly '
        'informed, by their employer, that tracking is taking place.',
      ),
    ],
  ),
  LegalSection(
    title: '5. How We Use Other Data',
    body: [
      LegalBullets([
        'To create and administer accounts and verify company registration;',
        'To operate the App\'s features and keep operational records;',
        'To secure the service and detect or prevent fraud and unauthorised access;',
        'To provide support and respond to your requests;',
        'To comply with legal obligations and lawful requests from authorities.',
      ]),
    ],
  ),
  LegalSection(
    title: '6. Sharing & Disclosure',
    body: [
      LegalParagraph(
        'We do not sell your personal data. We share it only as necessary:',
      ),
      LegalBullets([
        'With service providers who help us operate the App (for example, map and routing providers such as Mapbox, and cloud hosting), bound by confidentiality and data-protection obligations;',
        'With your own organisation — an employer can access the data of personnel it manages through the App;',
        'With government authorities or courts where disclosure is required by the laws of Nepal or a valid legal order.',
      ]),
    ],
  ),
  LegalSection(
    title: '7. Data Retention',
    body: [
      LegalParagraph(
        'We retain personal data only for as long as necessary to provide the '
        'service and to meet legal, accounting or reporting requirements under '
        'the laws of Nepal. When data is no longer required, we securely delete '
        'or anonymise it. You may request deletion of your account data, '
        'subject to records we are legally required to keep.',
      ),
    ],
  ),
  LegalSection(
    title: '8. Data Security',
    body: [
      LegalParagraph(
        'As required by the Individual Privacy Act, 2075 (2018) and the '
        'Electronic Transactions Act, 2063 (2008), we apply reasonable '
        'technical and organisational safeguards — including encryption in '
        'transit and access controls — to protect personal data against '
        'unauthorised access, loss or disclosure. No system is completely '
        'secure, and we cannot guarantee absolute security.',
      ),
    ],
  ),
  LegalSection(
    title: '9. Your Rights',
    body: [
      LegalParagraph(
        'Under the Individual Privacy Act, 2075 (2018), you have the right to:',
      ),
      LegalBullets([
        'Know what personal data we hold about you and how it is used;',
        'Request correction of inaccurate or incomplete data;',
        'Withdraw consent and request deletion of your data, subject to legal retention requirements;',
        'Object to processing that is not permitted by law.',
      ]),
      LegalParagraph(
        'To exercise these rights, contact us using the details below. We will '
        'respond within a reasonable time as required by law.',
      ),
    ],
  ),
  LegalSection(
    title: '10. Third-Party Services & Cross-Border Processing',
    body: [
      LegalParagraph(
        'The App relies on third-party services (such as map/routing providers '
        'and cloud hosting) that may process data on servers located outside '
        'Nepal. We take reasonable steps to ensure such providers maintain '
        'appropriate data-protection standards. Their use of data is governed '
        'by their own privacy policies.',
      ),
    ],
  ),
  LegalSection(
    title: '11. Children',
    body: [
      LegalParagraph(
        'The App is intended for business use by adults and is not directed at '
        'children. We do not knowingly collect personal data of anyone under '
        '18 years of age.',
      ),
    ],
  ),
  LegalSection(
    title: '12. Changes to This Policy',
    body: [
      LegalParagraph(
        'We may update this Privacy Policy from time to time. Material changes '
        'will be notified within the App, and the "Last updated" date below '
        'will be revised.',
      ),
    ],
  ),
  LegalSection(
    title: '13. Grievances & Contact',
    body: [
      LegalParagraph(
        'For any privacy questions, requests or complaints, contact our data '
        'protection contact:\n'
        '[Company Legal Name]\n'
        '[Registered Address, Nepal]\n'
        'Email: [contact email]\n'
        'Phone: [contact phone]',
      ),
    ],
  ),
];
