// Screens/order_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Orders")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading orders"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return const Center(child: Text("No orders yet"));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final data = orders[index].data() as Map<String, dynamic>;
              final rows = data["rows"] as List<dynamic>;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ExpansionTile(
                  title: Text(
                      "${data['client_name']} | ${data['order_id']} | ${data['date']}"),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Table(
                        border: TableBorder.all(width: 0.5, color: Colors.grey),
                        columnWidths: const {
                          0: FlexColumnWidth(3),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1),
                          3: FlexColumnWidth(1),
                          4: FlexColumnWidth(1),
                          5: FlexColumnWidth(1),
                        },
                        children: [
                          // Table Header
                          TableRow(
                            decoration:
                            BoxDecoration(color: Colors.grey.shade200),
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Text("Particular (Colour) Width",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(4.0),
                                child:
                                Text("Thickness", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(4.0),
                                child:
                                Text("Length", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(4.0),
                                child:
                                Text("PCS", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(4.0),
                                child:
                                Text("Tons", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(4.0),
                                child:
                                Text("Rate", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          // Table Rows
                          ...rows.map((row) {
                            return TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Text("${row['particular']} ${row['width']}"),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Text("${row['thickness']}"),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Text("${row['lengthValue']}"),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Text(
                                    row['lengthPcs'] != null && row['lengthPcs'].isNotEmpty
                                        ? row['lengthPcs'].values.first.toString()
                                        : '-',
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Text("${row['totalPTon']}"),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Text("${row['pricePerTon']}"),
                                ),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("Grand Total: ${data['total_amount']} tk",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
