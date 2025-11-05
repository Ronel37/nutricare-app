import 'package:flutter/material.dart';

class AdminHelpPage extends StatelessWidget {
  const AdminHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black,
              Color(0xFF0A3D00),
              Colors.black,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Help Center',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find answers to your questions and get support',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildWelcomeSection(),
                  const SizedBox(height: 25),
                  _buildFAQSection(),
                  const SizedBox(height: 25),
                  _buildTermsSection(),
                  const SizedBox(height: 25),
                  _buildContactSection(context),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: 10),
              const Text(
                'Welcome to the Help Page',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'If you need assistance, you can find answers to common questions here, or contact our support team for more help.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 12),
          child: Row(
            children: [
              const Icon(
                Icons.question_answer,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        _buildFAQItem(
          'How do I add or manage administrators?',
          'Go to Admin Dashboard → Users/Administrators and use Add, Edit, or Disable to manage accounts. Ensure role assignments follow least-privilege access.',
          Icons.admin_panel_settings,
        ),
        const SizedBox(height: 10),
        _buildFAQItem(
          'How can I contact support?',
          'Use the Contact Support button below. Our team responds Monday–Friday, 9:00–17:00. Typical response time is within 1 business day.',
          Icons.contact_support,
        ),
        const SizedBox(height: 10),
        _buildFAQItem(
          'How do I review growth analytics (BMI, HAZ, WAZ, WHZ)?',
          'Open Analytics → Professional Dashboard. Use filters (age/sex) to refine cohorts. Charts show distributions and pediatric indicators for ≤5 years.',
          Icons.track_changes,
        ),
        const SizedBox(height: 10),
        _buildFAQItem(
          'Can I export reports or summaries?',
          'Yes. In Analytics, use Export/Print to generate a professional PDF including distributions, pediatric tables, and at‑risk summaries.',
          Icons.picture_as_pdf,
        ),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(
            icon,
            color: Colors.green,
          ),
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          collapsedIconColor: Colors.white,
          iconColor: Colors.green,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[300],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.policy,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: 10),
              const Text(
                'Terms & Policies',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFAQItem(
            'Medical Disclaimer',
            'The app provides analytics and guidance for educational and programmatic support only and does not replace professional medical advice, diagnosis, or treatment.',
            Icons.healing,
          ),
          const SizedBox(height: 10),
          _buildFAQItem(
            'Data Privacy & Security',
            'We store data securely and restrict access based on roles. Do not upload sensitive data beyond what is necessary. Report incidents immediately to the system administrator.',
            Icons.privacy_tip,
          ),
          const SizedBox(height: 10),
          _buildFAQItem(
            'Consent and Children’s Data',
            'For children (≤5 years), ensure appropriate consent from parents/guardians and comply with applicable child-protection and privacy regulations.',
            Icons.child_care,
          ),
          const SizedBox(height: 10),
          _buildFAQItem(
            'Acceptable Use',
            'Use data only for authorized program objectives. Do not attempt to re-identify anonymized data or share outside approved channels.',
            Icons.rule,
          ),
          const SizedBox(height: 10),
          _buildFAQItem(
            'Contact and Governance',
            'Questions about terms, privacy, or data requests should be directed to the designated data controller or support contact listed below.',
            Icons.gavel,
          ),
          const SizedBox(height: 8),
          Text(
            'Last updated: ${DateTime.now().year}',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.support_agent,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: 10),
              const Text(
                'Contact Support',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'If your issue is not addressed here, feel free to contact our support team. We are here to help!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.grey[850],
                    title: const Text(
                      'Contact Support',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.email, color: Colors.green,),
                            const SizedBox(width: 10),
                            Text(
                              'mronelven@gmail.com',
                              style: TextStyle(color: Colors.grey[300]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            const Icon(Icons.phone, color: Colors.green,),
                            const SizedBox(width: 10),
                            Text(
                              '09509715411',
                              style: TextStyle(color: Colors.grey[300]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.green,),
                            const SizedBox(width: 10),
                            Text(
                              'Mon-Fri, 9AM - 5PM',
                              style: TextStyle(color: Colors.grey[300]),
                            ),
                          ],
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Close',
                          style: TextStyle(color: Color(0xFF0A3D00),),
                        ),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'CONTACT US',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 20,
                color: Colors.grey[400],
              ),
              const SizedBox(width: 8),
              Text(
                'Live chat available during business hours',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}