import 'package:eventapp/auth/register_page.dart';
import 'package:eventapp/participant/participant_pages.dart';
import 'package:eventapp/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../event/event_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isClick = false;
  final _loginKey = GlobalKey<FormState>();
  bool isToggle = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(backgroundColor: Colors.amber.shade50),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            height: 490,
            child: Card(
              elevation: 5,
              child: Form(
                key: _loginKey,
                child: Column(
                  children: [
                    Text(
                      "Login Your Account",
                      // style: GoogleFonts.playfairDisplay(
                      //   fontSize: 24,
                      //   fontWeight: FontWeight.bold,

                      //   color: Colors.indigo.shade600,
                      // ),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade600,
                      ),
                    ),
                    Gap(10),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: emailController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: "Email",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Email is required";
                          }
                          if (!value.contains("@")) {
                            return "Enter a valid email";
                          }
                          return null;
                        },
                      ),
                    ),
                    Gap(15),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: passwordController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: "Password",
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                isToggle = !isToggle;
                              });
                            },
                            icon: Icon(
                              isToggle
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                          border: OutlineInputBorder(),
                        ),
                        obscureText: isToggle,
                        obscuringCharacter: "*",
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Password is required";
                          }
                          if (value.length < 8) {
                            return "Password must be at least 8 characters";
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 3,
                          ),
                          onPressed: () async {
                            if (_loginKey.currentState!.validate()) {
                              final auth = ref.read(authProvider);

                              final user = await auth.login(
                                emailController.text,
                                passwordController.text,
                              );

                              final role = await auth.getRole(user!.uid);

                              if (role == 'admin') {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EventPage(),
                                  ),
                                );
                              } else {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ParticipantPages(),
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Login Successful",
                                      style: TextStyle(
                                        color: Colors.green.shade400,
                                      ),
                                    ),
                                    behavior:
                                        SnackBarBehavior.floating, // important
                                    margin: EdgeInsets.only(
                                      top: 20,
                                      left: 10,
                                      right: 10,
                                    ),
                                    elevation: 5,
                                    backgroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                          child: Text("Login"),
                        ),
                      ),
                    ),
                    Gap(20),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: isClick,
                                onChanged: (bool? value) {
                                  setState(() {
                                    isClick = value ?? false;
                                  });
                                },
                              ),
                              const Text("Remember me"),
                            ],
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text("Forget Password?"),
                          ),
                        ],
                      ),
                    ),
                    Gap(20),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RegisterPage()),
                        );
                      },
                      child: Text("Don't have account? Register here"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.brown.shade50,
      //backgroundColor: Color(0xFFFFEACF),
    );
  }
}
