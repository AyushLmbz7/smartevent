import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:eventapp/auth/login_page.dart';
import 'package:eventapp/event/event_create_page.dart';
import 'package:eventapp/event/event_details.dart';
import 'package:eventapp/event/event_service.dart';
import 'package:eventapp/qr/qr_scanner_page.dart';
import 'package:eventapp/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gap/gap.dart';

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  final service = EventService();
  final authService = AuthService();

  int currentIndex = 0;

  // Safe Firestore date conversion
  DateTime? safeDate(dynamic dateField) {
    if (dateField == null) return null;
    if (dateField is Timestamp) return dateField.toDate();
    if (dateField is String) return DateTime.tryParse(dateField);
    return null;
  }

  //Convert Firestore "HH:mm" string to TimeOfDay
  TimeOfDay? parseTime(String? timeString) {
    if (timeString == null || !timeString.contains(':')) return null;
    final parts = timeString.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  //Format TimeOfDay to 12-hour with AM/PM
  String formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return "$hour:$minute $period";
  }

  @override
  Widget build(BuildContext context) {
    String? selectedEventId;
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: [
          buildEventList(),
          buildAnalytics(),
          QRScannerPage(eventId: selectedEventId ?? ''),
          buildProfilePage(),
        ],
      ),

      // Curved Bottom Nav
      bottomNavigationBar: CurvedNavigationBar(
        index: currentIndex,
        height: 65,
        backgroundColor: Colors.transparent,
        color: Colors.black87,
        buttonBackgroundColor: Colors.lightBlueAccent,
        animationDuration: const Duration(milliseconds: 400),
        items: const [
          Icon(Icons.list, color: Colors.white, semanticLabel: "Event"),
          Icon(Icons.bar_chart_sharp, color: Colors.white),
          Icon(Icons.qr_code_scanner_sharp, color: Colors.white),
          Icon(Icons.person_3_sharp, color: Colors.white),
        ],
        onTap: (index) {
          setState(() => currentIndex = index);
        },
      ),

      backgroundColor: Colors.brown.shade50,
    );
  }

  //EVENT LIST
  Widget buildEventList() {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Event List"),
          backgroundColor: Colors.blueGrey.shade400,
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: service.getEvents(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(20), // avoid FAB overlap
                  children: docs.map((doc) {
                    final data = doc.data();
                    final eventDate = safeDate(data['date']);

                    final currentUser = FirebaseAuth.instance.currentUser;
                    final isOwner = currentUser?.uid == data['organizerId'];

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: InkWell(
                        onTap: () {
                          final eventId = doc.id;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventDetailsPage(
                                eventData: data,
                                eventDate: eventDate,
                                eventId: eventId,
                              ),
                            ),
                          );
                        },
                        child: ListTile(
                          leading: const Icon(
                            Icons.event,
                            color: Colors.indigo,
                          ),
                          title: Text(data['title'] ?? ''),
                          subtitle: Text(
                            [
                                  data['venue'] ?? '',
                                  // eventDate != null
                                  //     ? "${eventDate.day}-${eventDate.month}-${eventDate.year}"
                                  //     : '',
                                  // data['time'] != null
                                  //     ? formatTimeOfDay(parseTime(data['time'])!)
                                  //     : '',
                                ]
                                .where(
                                  (element) => element.isNotEmpty,
                                ) // remove empty values
                                .join(' • '), // join with separator
                          ),
                          trailing: isOwner
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: Colors.green,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EventCreatePage(
                                              eventData: data,
                                              docId: doc.id,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        service.deleteEvent(doc.id);
                                      },
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // FloatingActionButton to create new event
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EventCreatePage(eventData: null, docId: null),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, color: Colors.black),
                    label: const Text(
                      "Create Event",
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.greenAccent.shade200,
                  ),
                ),
              ],
            );
          },
        ),
        backgroundColor: Colors.brown.shade50,
      ),
    );
  }

  // Analytics Page
  Widget buildAnalytics() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                elevation: 3,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(Icons.add_chart),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Designing the Analytics is going to be very soon!",
                      ),
                    ),
                  ],
                ),
              ),
              Card(
                elevation: 3,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(Icons.hourglass_empty_sharp),
                    ),
                    Gap(10),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("Let's patient!"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // PROFILE PAGE
  Widget buildProfilePage() {
    final uid = authService.currentUserId;
    return SafeArea(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data();
          if (data == null) {
            return Center(child: Text("No user found"));
          }
          final name = data['name'] ?? "User";
          final email = data['email'] ?? "No Email";

          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    const Text(
                      "Profile Page",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Adding profile content
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.teal,
                          radius: 20,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : "U",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Gap(10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(email, style: TextStyle(color: Colors.blue)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.extended(
                  onPressed: () async {
                    await authService.logout();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) {
                          return LoginPage();
                        },
                      ),
                      (route) => false,
                    );
                  },
                  label: Text("Log out", style: TextStyle(color: Colors.red)),
                  icon: Icon(Icons.login_outlined, color: Colors.red),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
