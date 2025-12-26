import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // BLUE UNICEF HEADER
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.unicefBlue,
        title: const Text(
          "About",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // APP LOGO / ICON (optional placeholder)
            Center(
              child: Icon(
                Icons.people_alt_rounded,
                size: 90,
                color: AppTheme.unicefBlue,
              ),
            ),

            const SizedBox(height: 25),

            // APP TITLE
            Center(
              child: Text(
                "Beneficiary Management System",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.unicefBlueSwatch.shade700,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Center(
              child: Text(
                "Version 1.0.0",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ABOUT THE APP SECTION
            const Text(
              "About This App",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "This application allows field staff, managers, and administrators "
              "to record, review, and synchronize beneficiary data seamlessly "
              "between offline storage and the central server.\n\n"
              "It provides offline-first data collection, auto-syncing, queue "
              "processing for slow networks, and flexible beneficiary management "
              "tools designed for humanitarian and development programs.",
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.grey.shade800,
              ),
            ),

            const SizedBox(height: 30),

            // FEATURES SECTION
            const Text(
              "Key Features",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            _featureItem(Icons.offline_bolt, "Offline-first data collection"),
            _featureItem(Icons.sync, "Automatic & manual data synchronization"),
            _featureItem(Icons.security, "Secure user authentication"),
            _featureItem(Icons.storage, "Local Hive database storage"),
            _featureItem(Icons.search, "Fast search & filtering"),
            _featureItem(
                Icons.app_registration, "Add, edit, and manage beneficiaries"),
            _featureItem(Icons.history, "Queue monitor & sync log viewer"),

            const SizedBox(height: 30),

            // CONTACT
            const Text(
              "Support",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "For support or feedback, please contact your system administrator "
              "or the ICT unit.",
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.grey.shade800,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _featureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.unicefBlue, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
