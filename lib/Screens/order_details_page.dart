import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart' as models;

class OrderDetailsPage extends StatelessWidget {
  final String orderId;
  const OrderDetailsPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseFirestore.instance.collection('orders').doc(orderId);

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: FutureBuilder<DocumentSnapshot>(
        future: docRef.get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (!snapshot.data!.exists) return const Center(child: Text('Order not found'));

          final order = models.Order.fromMap(orderId, snapshot.data!.data() as Map<String, dynamic>);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer: ${order.customerName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Date: ${order.date}'),
                const SizedBox(height: 8),
                Text('Phone: ${order.phone.isNotEmpty ? order.phone : "-"}'),
                const SizedBox(height: 16),
                const Text('Items:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ...order.items.map((item) => ListTile(
                  title: Text(item.particular),
                  subtitle: Text('Width: ${item.width}, PTon: ${item.totalPTon}, Price: ${item.pricePerTon}'),
                ))
              ],
            ),
          );
        },
      ),
    );
  }
}
