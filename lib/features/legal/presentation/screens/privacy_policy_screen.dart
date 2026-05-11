import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Privacy Policy', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            const Text(
              'Welcome to Who Will Win. We are committed to protecting your personal information and your right to privacy. If you have any questions or concerns about this privacy notice or our practices with regard to your personal information, please contact us at Predict.game433@gmail.com.\n\n'
              '1. Information We Collect\n\n'
              'We collect personal information that you voluntarily provide to us when you register on the app, express an interest in obtaining information about us or our products and services, or when you contact us.\n\n'
              'The personal information that we collect depends on the context of your interactions with us and the app, the choices you make, and the products and features you use. The personal information we collect may include the following:\n'
              '- Account Data: Email addresses, usernames, and passwords.\n'
              '- Activity Data: Your predictions, scores, and interactions within the app.\n\n'
              '2. How We Use Your Information\n\n'
              'We use personal information collected via our app for a variety of business purposes described below. We process your personal information for these purposes in reliance on our legitimate business interests, in order to enter into or perform a contract with you, with your consent, and/or for compliance with our legal obligations.\n\n'
              '- To facilitate account creation and logon process.\n'
              '- To manage user accounts.\n'
              '- To deliver and facilitate delivery of services to the user.\n'
              '- To respond to user inquiries and offer support to users.\n\n'
              '3. Will Your Information Be Shared With Anyone?\n\n'
              'We only share information with your consent, to comply with laws, to provide you with services, to protect your rights, or to fulfill business obligations. We may process or share your data that we hold based on the following legal basis:\n'
              '- Consent: We may process your data if you have given us specific consent to use your personal information for a specific purpose.\n'
              '- Legitimate Interests: We may process your data when it is reasonably necessary to achieve our legitimate business interests.\n\n'
              '4. How Long Do We Keep Your Information?\n\n'
              'We will only keep your personal information for as long as it is necessary for the purposes set out in this privacy notice, unless a longer retention period is required or permitted by law (such as tax, accounting, or other legal requirements).\n\n'
              '5. How Do We Keep Your Information Safe?\n\n'
              'We have implemented appropriate technical and organizational security measures designed to protect the security of any personal information we process. However, despite our safeguards and efforts to secure your information, no electronic transmission over the Internet or information storage technology can be guaranteed to be 100% secure.\n\n'
              '6. What Are Your Privacy Rights?\n\n'
              'Depending on your location, you may have the right to request access to the personal information we collect from you, change that information, or delete it in some circumstances. To request to review, update, or delete your personal information, please use the account deletion options provided within the app or contact us directly.\n\n'
              '7. Updates To This Notice\n\n'
              'We may update this privacy notice from time to time. The updated version will be indicated by an updated "Revised" date and the updated version will be effective as soon as it is accessible. We encourage you to review this privacy notice frequently to be informed of how we are protecting your information.\n\n'
              '8. Contact Us\n\n'
              'If you have questions or comments about this notice, you may email us at:\n'
              '- Email: Predict.game433@gmail.com\n'
              '- Phone: +966 55 625 7109',
            ),
          ],
        ),
      ),
    );
  }
}
