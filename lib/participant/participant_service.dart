import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:uuid/uuid.dart';

class ParticipantService {
  final _db = FirebaseFirestore.instance;

  // Generate unique QR ID
  String generateGuestId() {
    return "GUEST-${const Uuid().v4()}";
  }

  // Create consistent document ID
  String _docId(String userId, String eventId) {
    return "${userId}_$eventId";
  }

  // JOIN EVENT (NO DUPLICATES + NULL SAFE)
  Future<String> joinEvent({
    required String userId,
    required String name,
    required String email,
    required String eventId,
  }) async {
    if (eventId.isEmpty) {
      throw Exception("Event id is missing or invalid");
    }

    final docRef = _db.collection('participants').doc(_docId(userId, eventId));
    final snapshot = await docRef.get();

    // If already exists
    if (snapshot.exists) {
      final data = snapshot.data();
      await FirebaseMessaging.instance.subscribeToTopic("participants");

      // data is null → recreate
      if (data == null) {
        final newGuestId = generateGuestId();

        await docRef.set({
          'userId': userId,
          'name': name,
          'email': email,
          'eventId': eventId,
          'guestId': newGuestId,
          'attendance': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return newGuestId;
      }

      final guestId = data['guestId'];

      // valid guestId → return
      if (guestId is String && guestId.isNotEmpty) {
        return guestId;
      }

      // guestId invalid → regenerate
      final newGuestId = generateGuestId();
      await docRef.update({'guestId': newGuestId});

      return newGuestId;
    }

    // New user → create document
    final guestId = generateGuestId();

    await docRef.set({
      'userId': userId,
      'name': name,
      'email': email,
      'eventId': eventId,
      'guestId': guestId,
      'attendance': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return guestId;
  }

  // ORIGINAL MARK ATTENDANCE (UNCHANGED)
  Future<void> markAttendance(
    String guestId, {
    required String userId,
    required String eventId,
  }) async {
    final docRef = _db.collection('participants').doc(_docId(userId, eventId));

    final doc = await docRef.get();

    if (!doc.exists) {
      throw Exception("Participant not found");
    }

    final data = doc.data();

    if (data == null) {
      throw Exception("Invalid participant data");
    }

    if (data['attendance'] == true) {
      throw Exception("Already checked in");
    }

    await docRef.update({
      'attendance': true,
      'checkInTime': FieldValue.serverTimestamp(),
    });
  }

  // ✅ NEW: MARK ATTENDANCE USING ONLY guestId (QR USE)
  Future<void> markAttendanceByGuestId(
    String guestId, {
    String? currentEventId, // optional validation
  }) async {
    // 1. Find participant using guestId
    final query = await _db
        .collection('participants')
        .where('guestId', isEqualTo: guestId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception("Participant not found");
    }

    final doc = query.docs.first;
    final data = doc.data();

    final userId = data['userId'];
    final eventId = data['eventId'];

    if (userId == null || eventId == null) {
      throw Exception("Invalid participant data");
    }

    // ✅ Optional: Event validation
    if (currentEventId != null && eventId != currentEventId) {
      throw Exception("Wrong event QR");
    }

    // 2. Call original function
    await markAttendance(guestId, userId: userId, eventId: eventId);
  }

  // GET PARTICIPANT (SAFE)
  Future<Map<String, dynamic>?> getParticipant({
    required String userId,
    required String eventId,
  }) async {
    final doc = await _db
        .collection('participants')
        .doc(_docId(userId, eventId))
        .get();

    if (!doc.exists) return null;

    return doc.data();
  }

  // DELETE PARTICIPANT (ONLY OWNER SAFE)
  Future<void> deleteParticipant({
    required String userId,
    required String eventId,
  }) async {
    final docRef = _db.collection('participants').doc(_docId(userId, eventId));
    final doc = await docRef.get();

    if (!doc.exists) {
      throw Exception("Participant not found");
    }

    final data = doc.data();

    if (data == null) {
      throw Exception("Invalid participant data");
    }

    if (data['userId'] != userId) {
      throw Exception("Unauthorized delete attempt");
    }

    await docRef.delete();
  }
}
