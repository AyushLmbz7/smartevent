import 'package:eventapp/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  String role = "participant"; //default selected role
  bool showRoleOptions = false; //track toggle
  final _formKey = GlobalKey<FormState>();
  bool isHidden = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.amber.shade50),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Container(
              // height: 656,
              child: Card(
                elevation: 5,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        "Register Your Account",
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
                          controller: nameController,
                           textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: "Enter your Name",
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Name is required";
                            }
                            return null;
                          },
                        ),
                      ),
                      Gap(15),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: emailController,
                           textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: "Enter your Email",
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
                            labelText: "Enter your Password",
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  isHidden = !isHidden;
                                });
                              },
                              icon: Icon(
                                isHidden
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                            border: OutlineInputBorder(),
                          ),
                          obscureText: isHidden,
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
                      SizedBox(height: 15),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: confirmController,
                           textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: "Confirm Password",
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  isHidden = !isHidden;
                                });
                              },
                              icon: Icon(
                                isHidden
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                            border: OutlineInputBorder(),
                          ),
                          obscureText: isHidden,
                          obscuringCharacter: "*",
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Confirm Password is required";
                            }
                            if (value != passwordController.text) {
                              return "Password do not match";
                            }
                            return null;
                          },
                        ),
                      ),
                      Gap(15),

                      // Role selection card
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          children: [
                            Card(
                              elevation: 3,
                              child: ListTile(
                                title: Text(
                                  role.isEmpty
                                      ? "Select Role"
                                      : role[0].toUpperCase() +
                                            role.substring(1),
                                ),
                                trailing: Icon(
                                  showRoleOptions
                                      ? Icons.arrow_drop_up
                                      : Icons.arrow_drop_down,
                                ),
                                onTap: () {
                                  setState(() {
                                    showRoleOptions =
                                        !showRoleOptions; // toggle dropdown
                                  });
                                },
                              ),
                            ),
                            if (showRoleOptions)
                              Card(
                                elevation: 3,
                                child: RadioGroup<String>(
                                  groupValue: role,
                                  onChanged: (value) {
                                    setState(() {
                                      role = value!;
                                      showRoleOptions = false; // close dropdown
                                    });
                                  },
                                  child: Column(
                                    children: [
                                      RadioMenuButton<String>(
                                        value: "admin",
                                        groupValue: role,
                                        onChanged: (value) {
                                          setState(() {
                                            role = value!;
                                            showRoleOptions = false;
                                          });
                                        },
                                        child: const Text("Admin"),
                                      ),
                                      RadioMenuButton<String>(
                                        value: "participant",
                                        groupValue: role,
                                        onChanged: (value) {
                                          setState(() {
                                            role = value!;
                                            showRoleOptions = false;
                                          });
                                        },
                                        child: const Text("Participant"),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
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
                              if (_formKey.currentState!.validate()) {
                                print(
                                  "EMAIL SENT: '${emailController.text.trim()}'",
                                );
                                final auth = ref.read(authProvider);

                                try {
                                  await auth.register(
                                    nameController.text.trim(),
                                    emailController.text.trim(),
                                    passwordController.text.trim(),
                                    confirmController.text.trim(),
                                    role,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Register Successful",
                                        style: TextStyle(
                                          color: Colors.green.shade400,
                                        ),
                                      ),
                                      behavior: SnackBarBehavior
                                          .floating, // important
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
                                  Navigator.pop(context);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Error: $e")),
                                  );
                                }
                              }
                            },
                            child: Text("Register"),
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
      ),
      backgroundColor: Colors.brown.shade50,
    );
  }
}
