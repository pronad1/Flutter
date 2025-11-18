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
  final double? price;          // Price for selling items (null for donations)
  final bool isSelling;         // True if item is for sale, false if donation
  final bool isSpecialDeal;     // True if brand new item with attractive price

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
    this.price,
    this.isSelling = false,
    this.isSpecialDeal = false,
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
      'price': price,
      'isSelling': isSelling,
      'isSpecialDeal': isSpecialDeal,
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
      price: (d['price'] as num?)?.toDouble(),
      isSelling: (d['isSelling'] as bool?) ?? false,
      isSpecialDeal: (d['isSpecialDeal'] as bool?) ?? false,
    );
  }
}
