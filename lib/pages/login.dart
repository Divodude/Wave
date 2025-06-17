import 'package:flutter/material.dart';

import 'package:spotify_clone/pages/main_page.dart';
import 'package:spotify_clone/authservice.dart';
class Login_Page extends StatefulWidget {
  const Login_Page({super.key});

  @override
  State<Login_Page> createState() => _Login_PageState();
}

class _Login_PageState extends State<Login_Page> {
  TextEditingController emailAddress = TextEditingController();
  TextEditingController password = TextEditingController();

  bool isLoading = false;

Future<void> loginUser(String email, String password) async {
  setState(() => isLoading = true);
  final success = await AuthService().login(email, password);

  setState(() => isLoading = false);
  if (success) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Main_Page()),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Invalid email or password")),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 41, 21, 86),
              Color.fromARGB(255, 16, 99, 138),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 50),
            const Text(
              "Login Now!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: Card(
                    elevation: 100,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: const [
                              Text(
                                "Signup",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                              Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 50),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Email",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          TextField(
                            controller: emailAddress,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              hintText: "Enter your email",
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Password",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          TextField(
                            controller: password,
                            obscureText: true,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              hintText: "Enter your password",
                            ),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      String email = emailAddress.text.trim();
                                      String pass = password.text.trim();
                                      if (email.isNotEmpty && pass.isNotEmpty) {
                                        loginUser(email, pass);
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content:
                                              Text("Please fill in all fields"),
                                        ));
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 15),
                                elevation: 5,
                                shadowColor: const Color.fromARGB(255, 21, 136, 231)
                                    .withOpacity(0.3),
                                minimumSize: const Size(150, 50),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "LOGIN",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
