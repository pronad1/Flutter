import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final String? imageUrl;   // Supabase public URL
  final String? imagePath;  // Supabase storage path (for delete/replace)
  final String? category;
  final String? condition;  // New/Good/Used/etc
  final String? pickupAddress;  // Pickup location address
  final bool available;
  final Timestamp createdAt;

  Item({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    this.imageUrl,
    this.imagePath,
    this.category,
    this.condition,
    this.pickupAddress,
    required this.available,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'imagePath': imagePath,
      'category': category,
      'condition': condition,
      'pickupAddress': pickupAddress,
      'available': available,
      'createdAt': createdAt,
    };
  }

  factory Item.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Item(
      id: doc.id,
      ownerId: d['ownerId'] ?? '',
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      imageUrl: d['imageUrl'],
      imagePath: d['imagePath'],
      category: d['category'],
      condition: d['condition'],
      pickupAddress: d['pickupAddress'],
      available: (d['available'] as bool?) ?? true,
      createdAt: (d['createdAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }
}
