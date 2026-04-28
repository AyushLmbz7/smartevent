import 'package:eventapp/participant/participant_page.dart';
import 'package:eventapp/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class EventDetailsPage extends StatelessWidget {
  final Map<String, dynamic> eventData;
  final DateTime? eventDate;
  final String eventId;

  const EventDetailsPage({
    super.key,
    required this.eventData,
    this.eventDate,
    required this.eventId,
  });

  // Convert "HH:mm" string to TimeOfDay
  TimeOfDay? parseTime(String? timeString) {
    if (timeString == null || !timeString.contains(':')) return null;
    final parts = timeString.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  // Format TimeOfDay
  String formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return "$hour:$minute $period";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser; //current user
    if (user == null) {
      return Scaffold(body: Center(child: Text("User no logged in")));
    }
    final authService = AuthService(); //service

    final time = parseTime(eventData['time']);

    return Scaffold(
      appBar: AppBar(
        title: Text('Event Details'),
        backgroundColor: Colors.indigo.shade100,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //EVENT CARD
            Card(
              elevation: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      eventData['title'] ?? '',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Gap(16),

                  // Organizer
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Colors.indigo),
                        SizedBox(width: 8),
                        Text(eventData['organizer'] ?? ''),
                      ],
                    ),
                  ),
                  Gap(8),

                  // Organization
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(Icons.business, color: Colors.indigo),
                        SizedBox(width: 8),
                        Text(eventData['organization'] ?? ''),
                      ],
                    ),
                  ),
                  Gap(8),

                  // Venue
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.indigo),
                        SizedBox(width: 8),
                        Text(eventData['venue'] ?? ''),
                      ],
                    ),
                  ),
                  Gap(8),

                  // Date & Time
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.indigo),
                        SizedBox(width: 8),
                        Text(
                          eventDate != null
                              ? "${eventDate!.day}-${eventDate!.month}-${eventDate!.year}"
                              : '',
                        ),
                        Gap(16),
                        Icon(Icons.access_time, color: Colors.indigo),
                        Gap(8),
                        // Text(
                        //   parseTime(eventData['time']) != null
                        //       ? formatTimeOfDay(parseTime(eventData['time'])!)
                        //       : '',
                        // ),
                        Text(time != null ? formatTimeOfDay(time) : ''),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // ROLE-BASED BUTTON
            FutureBuilder<String>(
              future: authService.getRole(user.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final role = snapshot.data;

                // ONLY for PARTICIPANT CAN SEE
                if (role == "participant") {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) {
                              return ParticipantPage(
                                eventId: eventId,
                                // eventId: eventData['eventId'], //passing event id
                              );
                            },
                          ),
                        );
                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   SnackBar(content: Text("Joined Successfully")),
                        // );
                      },
                      child: Text("APPLY EVENT"),
                    ),
                  );
                }

                return SizedBox(); //organizer → no button
              },
            ),
          ],
        ),
      ),
    );
  }
}
