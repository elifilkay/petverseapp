import 'package:flutter/material.dart';

enum VaccinationStatus {
  upcoming,
  completed,
  missed
}

class VaccinationCard extends StatelessWidget {
  final String petName;
  final String vaccineName;
  final String date;
  final String time;
  final String veterinary;
  final VaccinationStatus status;

  const VaccinationCard({
    super.key,
    required this.petName,
    required this.vaccineName,
    required this.date,
    required this.time,
    required this.veterinary,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vaccineName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      petName,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                _buildStatusChip(),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$date • $time',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.medical_services, size: 20),
                const SizedBox(width: 8),
                Text(
                  veterinary,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            if (status == VaccinationStatus.upcoming) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      // TODO: İptal et
                    },
                    child: const Text('İptal Et'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Düzenle
                    },
                    child: const Text('Düzenle'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    late Color color;
    late String text;

    switch (status) {
      case VaccinationStatus.upcoming:
        color = Colors.blue;
        text = 'Yaklaşan';
        break;
      case VaccinationStatus.completed:
        color = Colors.green;
        text = 'Tamamlandı';
        break;
      case VaccinationStatus.missed:
        color = Colors.red;
        text = 'Kaçırıldı';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}