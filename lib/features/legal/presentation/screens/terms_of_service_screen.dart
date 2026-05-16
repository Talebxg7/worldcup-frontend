import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Terms and Conditions', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            const Text(
              'Welcome to Who Will Win. Please read these Terms and Conditions carefully before using the application. By accessing or using the app, you agree to comply with and be bound by the following terms.\n\n'
              '1. About the Application\n\n'
              'Who Will Win is a sports prediction platform that allows users to participate in match predictions, view sports-related content, and interact with information related to teams, tournaments, and sporting events.\n\n'
              '2. Acceptance of Terms\n\n'
              'By using the application or creating an account, you confirm that you have read, understood, and agreed to these Terms and Conditions. If you do not agree with any part of these terms, you must not use the application.\n\n'
              '3. Nature of the Service\n\n'
              '- The application is provided for entertainment and informational purposes only.\n'
              '- Predictions available on the platform do not constitute betting, gambling, financial advice, or guaranteed outcomes.\n'
              '- The application does not guarantee the accuracy of any predictions, scores, or match results.\n\n'
              '4. Intellectual Property and Third-Party Rights\n\n'
              '- We are the owner of all intellectual property rights in our site, and in the material published on it. Those works are protected by copyright laws and treaties around the world. All such rights are reserved to us. As a visitor to our site, you may download a single copy of the material for your own non-commercial, private viewing purposes only. No copying or distribution for any commercial or business use is permitted without our prior written consent.\n'
              '- All trademarks, logos, team names, league names, images, graphics, and other related content displayed within the application are the property of their respective owners.\n'
              '- Who Will Win does not claim ownership of any third-party trademarks, logos, or copyrighted materials appearing within the app.\n'
              '- Such materials are used strictly for descriptive, informational, identification, or promotional purposes only.\n'
              '- If any copyright owner or trademark holder believes that their rights have been infringed, they may contact us for review and appropriate action.\n\n'
              '5. User Accounts\n\n'
              '- Users are responsible for maintaining the confidentiality of their account information.\n'
              '- Users agree to provide accurate and complete information when registering.\n'
              '- The application reserves the right to suspend or terminate accounts that violate these Terms and Conditions.\n\n'
              '6. Prohibited Use\n\n'
              'Users agree not to:\n'
              '- Use the application for unlawful purposes.\n'
              '- Upload or share offensive, abusive, or harmful content.\n'
              '- Attempt to hack, disrupt, or damage the application or its servers.\n'
              '- Transmit, or procure the sending of, any unsolicited or unauthorized advertising or promotional material or any other form of similar solicitation (spam).\n'
              '- Knowingly transmit any data, send or upload any material that contains viruses, Trojan horses, worms, time-bombs, keystroke loggers, spyware, adware or any other harmful programs or similar computer code designed to adversely affect the operation of any computer software or hardware.\n'
              '- Impersonate another person or entity.\n'
              '- Misuse any content or features available within the application.\n'
              '- Breach any applicable local, national or international law.\n\n'
              '7. Advertisements and External Links\n\n'
              'The application may contain advertisements, sponsored content, or links to third-party websites and services. We are not responsible for the content, policies, or practices of any external websites or third parties.\n\n'
              '8. Disclaimer of Warranties\n\n'
              'The application is provided on an “as is” and “as available” basis without warranties of any kind, whether express or implied. We do not guarantee uninterrupted access, error-free operation, or the reliability, correctness or completeness of any content within the app.\n\n'
              '9. Limitation of Liability\n\n'
              'To the fullest extent permitted by law, Who Will Win shall not be liable for any direct, indirect, incidental, consequential, or special damages resulting from the use of, or inability to use, the application.\n\n'
              '10. Indemnity\n\n'
              'You agree to indemnify us and our affiliates and our respective directors, officers, employees and agents, as well as their licensors and suppliers, from and against any and all claims, actions, suits or proceedings, as well as any and all losses, liabilities, damages, costs and expenses (including reasonable legal fees) arising out of:\n'
              '1. Any misrepresentation, act or omission made by you in connection with your use of our site;\n'
              '2. Any non-compliance by you with these terms of use; and\n'
              '3. Claims brought by third parties arising from or related to your access or use of our site, including without limitation the Message Features or other information made available by you to our site.\n\n'
              '11. Changes to the Terms\n\n'
              'We reserve the right to modify or update these Terms and Conditions at any time without prior notice. Continued use of the application after changes are posted constitutes acceptance of the revised terms.\n\n'
              '12. Termination\n\n'
              'We reserve the right to suspend or terminate user access to the application at our sole discretion if these Terms and Conditions are violated.\n\n'
              '13. Contact Information\n\n'
              '- Email: Predict.game433@gmail.com\n\n'
              '14. Governing Law\n\n'
              'These Terms and Conditions shall be governed and interpreted in accordance with the laws of Jordan, and any disputes shall be subject to the exclusive jurisdiction of the competent courts in that jurisdiction.',
            ),
          ],
        ),
      ),
    );
  }
}
