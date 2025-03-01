import 'package:cloud_firestore/cloud_firestore.dart';

class Vaccination {
  final String id;
  final String name;
  final String type;
  final DateTime date;
  final bool completed;
  final DateTime createdAt;
  final String userId;

  Vaccination({
    required this.id,
    required this.name,
    required this.type,
    required this.date,
    required this.completed,
    required this.createdAt,
    required this.userId,
  });

  factory Vaccination.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Vaccination(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      completed: data['completed'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'date': Timestamp.fromDate(date),
      'completed': completed,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
    };
  }
} 