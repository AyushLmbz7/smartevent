import 'package:eventapp/qr/qr_page.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'participant_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ParticipantPage extends StatefulWidget {
  final String eventId;
  const ParticipantPage({super.key, required this.eventId});

  @override
  State<ParticipantPage> createState() => _ParticipantPageState();
}

class _ParticipantPageState extends State<ParticipantPage> {
  final service = ParticipantService();

  final nameController = TextEditingController();
  final emailController = TextEditingController();

  bool isJoined = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    checkJoined();
  }

  //CHECK garne aagadi nai JOINED vako xa ki xaina vanera
  Future<void> checkJoined() async {
    final user = FirebaseAuth.instance.currentUser!;

    final doc = await service.getParticipant(
      userId: user.uid,
      eventId: widget.eventId,
    );

    setState(() {
      isJoined = doc != null;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.amber.shade50),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 5,
            child: Column(
              children: [
                Text(
                  "Participant Details",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade600,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: "Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                const Gap(10),

                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: emailController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                const Gap(10),

                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: isJoined
                            ? Colors.grey
                            : Colors.teal.shade50,
                      ),

                      onPressed: (isJoined || isLoading)
                          ? null
                          : () async {
                              final user = FirebaseAuth.instance.currentUser;

                              if (user == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("User not logged in")),
                                );
                                return;
                              }

                              if (nameController.text.trim().isEmpty ||
                                  emailController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("All fields are required"),
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                isLoading = true;
                              });

                              try {
                                final guestId = await service.joinEvent(
                                  userId: user.uid,
                                  name: nameController.text,
                                  email: emailController.text,
                                  eventId: widget.eventId,
                                );

                                setState(() {
                                  isJoined = true;
                                  isLoading = false;
                                });

                                if (!mounted) return;

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => QRPage(data: guestId),
                                  ),
                                );
                              } catch (e) {
                                setState(() {
                                  isLoading = false;
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            },

                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(isJoined ? "Already Joined" : "Join Event"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Colors.brown.shade50,
    );
  }
}
