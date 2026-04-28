import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventService {
  final _db = FirebaseFirestore.instance;

  // Delete Event
  Future<void> deleteEvent(String id) async {
    final user = FirebaseAuth.instance.currentUser;

    final doc = await _db.collection('events').doc(id).get();

    if (doc.data()?['organizerId'] != user?.uid) {
      throw Exception("You are not allowed to delete this event");
    }

    await _db.collection('events').doc(id).delete();
  }

  // Update Event
  Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;

    final doc = await _db.collection('events').doc(id).get();

    if (doc.data()?['organizerId'] != user?.uid) {
      throw Exception("You are not allowed to edit this event");
    }

    await _db.collection('events').doc(id).update(data);
  }

  // CREATE EVENT
  Future<String> createEvent(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }
    // Ensure 'date' is a Timestamp
    final eventDate = data['date'];
    Timestamp finalDate;

    if (eventDate is String) {
      finalDate = Timestamp.fromDate(DateTime.parse(eventDate));
    } else if (eventDate is DateTime) {
      finalDate = Timestamp.fromDate(eventDate);
    } else if (eventDate is Timestamp) {
      finalDate = eventDate;
    } else {
      throw Exception("Invalid date format");
    }
    final docRef = await _db.collection('events').add({
      ...data, // all fields from UI
      'date': finalDate,
      'createdAt': Timestamp.now(),
      'organizerId': user.uid,
    });
    await FirebaseFirestore.instance.collection("notifications").add({
      "title": "New Event Created",
      "body": data['title'] ?? "Event added",
      "time": FieldValue.serverTimestamp(),
      "isRead": false,
      "eventId": docRef.id,
    });
    return docRef.id;
  }

  // READ EVENTS
  Stream<QuerySnapshot<Map<String, dynamic>>> getEvents() {
    return _db
        .collection('events')
        .orderBy('date', descending: false) // sort by event date
        .snapshots();
  }
}
