import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/unicef_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(30),
          constraints: const BoxConstraints(maxWidth: 350),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/unicef_logo.png", height: 80),
              const SizedBox(height: 20),
              Text("Beneficiary System",
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 30),
              TextField(
                controller: userCtrl,
                decoration: const InputDecoration(labelText: "Username"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child:
                      Text(error!, style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 20),
              loading
                  ? const CircularProgressIndicator()
                  : UnicefButton(
                      text: "Login",
                      icon: Icons.login,
                      onPressed: () async {
                        setState(() => loading = true);
                        final msg = await auth.login(
                            userCtrl.text.trim(), passCtrl.text.trim());
                        setState(() => loading = false);

                        if (msg != null) {
                          setState(() => error = msg);
                        }
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
