import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gap/gap.dart';
import 'event_service.dart';

class EventCreatePage extends StatefulWidget {
  final Map<String, dynamic>? eventData;
  final String? docId;

  const EventCreatePage({super.key, this.eventData, this.docId});

  @override
  State<EventCreatePage> createState() => _EventCreatePageState();
}

class _EventCreatePageState extends State<EventCreatePage> {
  final service = EventService();

  final titleController = TextEditingController();
  final organizerController = TextEditingController();
  final organizationController = TextEditingController();
  final venueController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  String? editingEventId;

  // Convert Firestore date safely
  DateTime? safeDate(dynamic dateField) {
    if (dateField == null) return null;
    if (dateField is Timestamp) return dateField.toDate();
    if (dateField is String) return DateTime.tryParse(dateField);
    return null;
  }

  // Pick Date
  void pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  // Pick Time
  void pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  // Helper: Format TimeOfDay as 12-hour with AM/PM
  String formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return "$hour:$minute $period";
  }

  // Fill form when editing
  void fillForm(Map<String, dynamic> data, String docId) {
    setState(() {
      editingEventId = docId;
      titleController.text = data['title'] ?? '';
      organizerController.text = data['organizer'] ?? '';
      organizationController.text = data['organization'] ?? '';
      venueController.text = data['venue'] ?? '';
      selectedDate = safeDate(data['date']);

      // Safe parsing for time
      if (data['time'] != null) {
        try {
          final timeString = data['time']
              .toString(); // convert to string just in case
          final parts = timeString.split(':');
          if (parts.length >= 2) {
            final hour = int.tryParse(parts[0]) ?? 0;
            final minute = int.tryParse(parts[1]) ?? 0;
            selectedTime = TimeOfDay(hour: hour, minute: minute);
          }
        } catch (e) {
          selectedTime = null; // fallback if parsing fails
        }
      }
    });
  }

  // Submit Event
  void submitEvent() {
    if (titleController.text.isEmpty ||
        organizerController.text.isEmpty ||
        venueController.text.isEmpty ||
        selectedDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    final data = {
      "title": titleController.text,
      "organizer": organizerController.text,
      "organization": organizationController.text,
      "venue": venueController.text,
      "date": Timestamp.fromDate(selectedDate!),
      //time lai store gareko in safe 24 hour format
      "time":
          "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}",
    };

    if (editingEventId != null) {
      service.updateEvent(editingEventId!, data);
      editingEventId = null;
    } else {
      service.createEvent(data);
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Event Save successfully")));

    // Clear form
    titleController.clear();
    organizerController.clear();
    organizationController.clear();
    venueController.clear();
    setState(() {
      selectedDate = null;
      selectedTime = null;
    });
    Navigator.pop(context); //previous page ma janxa
  }

  @override
  void initState() {
    super.initState();
    if (widget.eventData != null && widget.docId != null) {
      fillForm(widget.eventData!, widget.docId!);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    organizerController.dispose();
    organizationController.dispose();
    venueController.dispose();
    super.dispose();
  }

  Widget buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(editingEventId != null ? "Update Event" : "Create Event"),
        backgroundColor: Colors.teal.shade300,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                buildTextField(titleController, "Event Title", Icons.event),
                const Gap(10),
                buildTextField(organizerController, "Organizer", Icons.person),
                const Gap(10),
                buildTextField(
                  organizationController,
                  "Organization",
                  Icons.business,
                ),
                const Gap(10),
                buildTextField(venueController, "Venue", Icons.location_on),
                const Gap(15),

                // Date & Time
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.calendar_today,
                            color: Colors.indigo,
                          ),
                          title: Text(
                            selectedDate == null
                                ? "Select Date"
                                : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                          ),
                          onTap: pickDate,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.access_time,
                            color: Colors.indigo,
                          ),
                          title: Text(
                            selectedTime == null
                                ? "Select Time"
                                : formatTimeOfDay(
                                    selectedTime!,
                                  ), // : selectedTime!.format(context),
                          ),
                          onTap: pickTime,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.teal.shade300,
                    ),
                    onPressed: submitEvent,
                    icon: const Icon(Icons.save),
                    label: Text(
                      editingEventId != null ? "Update Event" : "Create Event",
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
