import 'package:cloud_firestore/cloud_firestore.dart';

void checkFirestoreConnection() async {
  try {
    // Firestore'dan veri okuma
    var snapshot = await FirebaseFirestore.instance.collection('users').get();

    // Veriyi başarılı şekilde okuma
    if (snapshot.docs.isNotEmpty) {
      print("Firestore'a başarıyla bağlanıldı ve veri alındı.");
    } else {
      print("Veri bulunamadı.");
    }
  } catch (e) {
    print("Firestore'a bağlanırken hata oluştu: $e");
  }
}
