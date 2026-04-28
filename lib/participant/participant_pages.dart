import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:eventapp/auth/login_page.dart';
import 'package:eventapp/event/event_details.dart';
import 'package:eventapp/event/event_service.dart';
import 'package:eventapp/participant/participant_service.dart';
import 'package:eventapp/qr/qr_page.dart';
import 'package:eventapp/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class ParticipantPages extends StatefulWidget {
  const ParticipantPages({super.key});

  @override
  State<ParticipantPages> createState() => _ParticipantPagesState();
}

class _ParticipantPagesState extends State<ParticipantPages> {
  int currentIndex = 0;
  final service = EventService();
  final authService = AuthService();
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  //SEARCH FEATURES
  String searchText = "";
  List<String> locations = [
    "All",
    "Kathmandu",
    "Pokhara",
    "Lalitpur",
    "Bhaktapur",
    "Dharan",
    "Itahari",
    "Biratnagar",
    "Birtamod",
  ];
  String selectedLocation = "All";

  void showLocation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Select Location"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: locations.map((loc) {
                return ListTile(
                  title: Text(loc),
                  onTap: () {
                    setState(() {
                      selectedLocation = loc;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  DateTime? safeDate(dynamic dateField) {
    if (dateField == null) return null;
    if (dateField is Timestamp) return dateField.toDate();
    if (dateField is String) return DateTime.tryParse(dateField);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: [buildHomePage(), showQr(), buildProfile()],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        height: 60,
        color: Colors.black,
        buttonBackgroundColor: Colors.tealAccent,
        backgroundColor: Colors.transparent,
        items: [
          Icon(Icons.home, color: Colors.white),
          Icon(Icons.qr_code, color: Colors.white),
          Icon(Icons.person_4_sharp, color: Colors.white),
        ],
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
      backgroundColor: Color(0xFFF1EDE5),
    );
  }

  // FOR HOME PAGE
  Widget buildHomePage() {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Event List"),
          backgroundColor: Colors.blue.shade200,
          actions: [
            //TITLE SEARCH
            // SizedBox(
            //   height: 45,
            //   width: 150,
            //   child: TextField(
            //     onChanged: (value) {
            //       setState(() {
            //         searchText = value.toLowerCase();
            //       });
            //     },
            //     decoration: InputDecoration(
            //       hintText: "Search title",
            //       suffixIcon: Icon(Icons.search),
            //       border: OutlineInputBorder(
            //         borderRadius: BorderRadius.circular(10),
            //       ),
            //     ),
            //   ),
            // ),
            Gap(8),

            //LOCATION SEARCH
            SizedBox(
              height: 45,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  side: BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: Icon(Icons.location_on),
                label: Text(selectedLocation),
                onPressed: () {
                  showLocation();
                },
              ),
            ),

            Gap(8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("notifications")
                  //.where("userId", isEqualTo: user!.uid)
                  .orderBy("time", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.notifications, color: Colors.black),
                  );
                }
                print(snapshot.data?.docs.length);
                final docs = snapshot.data!.docs;

                //int count = docs.length;
                int count = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data["isRead"] == false;
                }).length;

                return Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) {
                            return AlertDialog(
                              title: Text("Notifications"),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: ListView(
                                  shrinkWrap: true,
                                  children: docs.map((doc) {
                                    return ListTile(
                                      title: Text(doc["title"] ?? ""),
                                      subtitle: Text(doc["body"] ?? ""),
                                      onTap: () async {
                                        await FirebaseFirestore.instance
                                            .collection("notifications")
                                            .doc(doc.id)
                                            .update({"isRead": true});

                                        //get eventId from notification
                                        final eventId = doc["eventId"];
                                        // event ko data line
                                        final eventDoc = await FirebaseFirestore
                                            .instance
                                            .collection("events")
                                            .doc(eventId)
                                            .get();
                                        if (!eventDoc.exists) return;
                                        final eventData = eventDoc.data()!;
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EventDetailsPage(
                                              eventData: eventData,
                                              eventDate: null,
                                              eventId: eventId,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      icon: Icon(Icons.notifications, color: Colors.black),
                    ),

                    if (count > 0)
                      Positioned(
                        right: 5,
                        top: 5,
                        child: Container(
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            "$count",
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),

        // STREAM + FILTER
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: service.getEvents(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final filteredDocs = snapshot.data!.docs.where((doc) {
              final data = doc.data();

              final title = (data['title'] ?? "").toString().toLowerCase();
              final venue = (data['venue'] ?? "").toString().toLowerCase();

              final matchTitle = searchText.isEmpty
                  ? true
                  : title.contains(searchText) || venue.contains(searchText);
              final matchLocation = selectedLocation == "All"
                  ? true
                  : venue.contains(selectedLocation.toLowerCase());

              return matchTitle && matchLocation;
            }).toList();

            // if (filteredDocs.isEmpty) {
            //   return const Center(child: Text("No matching events"));
            // }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    height: 45,
                    width: double.infinity,
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) {
                        setState(() {
                          searchText = value.trim().toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search title",
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  searchController.clear();
                                  setState(() {
                                    searchText = "";
                                  });
                                },
                                icon: Icon(Icons.clear),
                              )
                            : Icon(Icons.search, color: Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredDocs.isEmpty
                      ? Center(child: Text("No matching events"))
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: filteredDocs.map((doc) {
                            final data = doc.data();
                            final eventDate = safeDate(data['date']);

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.event,
                                  color: Colors.blue,
                                ),
                                title: Text(data['title'] ?? ''),
                                subtitle: Text(data['venue'] ?? ''),
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
                              ),
                            );
                          }).toList(),
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

  //FOR QR PAGE
  Widget showQr() {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final participantService = ParticipantService();

    return SafeArea(
      child: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('participants')
            .where('userId', isEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No participant found"));
          }

          return ListView(
            children: docs.map((doc) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  child: ListTile(
                    title: Text(doc['name'] ?? ''),
                    subtitle: Text(doc['email'] ?? ''),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // for qr
                        IconButton(
                          icon: Icon(Icons.qr_code),
                          onPressed: () {
                            final data = doc.data();

                            final userId = data['userId'] ?? '';
                            final eventId = data['eventId'] ?? '';
                            final guestId = data['guestId'] ?? '';

                            if (userId.isEmpty ||
                                eventId.isEmpty ||
                                guestId.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Invalid QR data")),
                              );
                              return;
                            }

                            //final qrData = "$userId|$eventId|$guestId";
                            final qrData = guestId;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QRPage(data: qrData),
                              ),
                            );
                          },
                        ),
                        // delete button
                        IconButton(
                          onPressed: () async {
                            final confirm = await showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text("Delete your QR"),
                                content: Text(
                                  "Are you sure you want to delete?",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text("Delete"),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              try {
                                await participantService.deleteParticipant(
                                  userId: doc['userId'],
                                  eventId: doc['eventId'],
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Deleted Successfully"),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            }
                          },
                          icon: Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  //FOR PROFILE
  Widget buildProfile() {
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
                      MaterialPageRoute(builder: (_) => LoginPage()),
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
