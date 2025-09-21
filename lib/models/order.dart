class OrderItem {
  final String particular;      // e.g., CHERRY, BORO, etc.
  final String width;           // Width in mm/inch
  final String thickness;       // Thickness in mm
  final String lengthValue;     // Length in ft
  final Map<int, int> lengthPcs; // {length: pcs}
  final String totalPTon;       // Tons
  final String totalWTon;       // Weight Tons (placeholder)
  final String pricePerTon;     // Rate per ton

  OrderItem({
    required this.particular,
    required this.width,
    required this.thickness,
    required this.lengthValue,
    required this.lengthPcs,
    required this.totalPTon,
    required this.totalWTon,
    required this.pricePerTon,
  });

  // Convert Firestore Map -> OrderItem
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      particular: map['particular'] ?? 'N/A',
      width: map['width'] ?? '-',
      thickness: map['thickness'] ?? '0',
      lengthValue: map['lengthValue'] ?? '0',
      lengthPcs: Map<int, int>.from(map['lengthPcs'] ?? {}),
      totalPTon: map['totalPTon'] ?? '0',
      totalWTon: map['totalWTon'] ?? '-',
      pricePerTon: map['pricePerTon'] ?? '0',
    );
  }

  // Convert OrderItem -> Map (for saving to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'particular': particular,
      'width': width,
      'thickness': thickness,
      'lengthValue': lengthValue,
      'lengthPcs': lengthPcs,
      'totalPTon': totalPTon,
      'totalWTon': totalWTon,
      'pricePerTon': pricePerTon,
    };
  }
}

class Order {
  String id;
  String customerName;
  String address;
  String phone;
  String date;
  String paymentDate;
  String paymentAmount;
  String outstanding;
  String totalBill;
  List<OrderItem> items;

  Order({
    required this.id,
    required this.customerName,
    required this.address,
    required this.phone,
    required this.date,
    required this.paymentDate,
    required this.paymentAmount,
    required this.outstanding,
    required this.totalBill,
    required this.items,
  });

  Map<String, dynamic> toMap() => {
    'customerName': customerName,
    'address': address,
    'phone': phone,
    'date': date,
    'paymentDate': paymentDate,
    'paymentAmount': paymentAmount,
    'outstanding': outstanding,
    'totalBill': totalBill,
    'items': items.map((x) => x.toMap()).toList(),
  };

  factory Order.fromMap(String id, Map<String, dynamic> map) => Order(
    id: id,
    customerName: map['customerName'] ?? '',
    address: map['address'] ?? '',
    phone: map['phone'] ?? '',
    date: map['date'] ?? '',
    paymentDate: map['paymentDate'] ?? '',
    paymentAmount: map['paymentAmount'] ?? '',
    outstanding: map['outstanding'] ?? '',
    totalBill: map['totalBill'] ?? '',
    items: (map['items'] as List<dynamic>? ?? [])
        .map((x) => OrderItem.fromMap(Map<String, dynamic>.from(x)))
        .toList(),
  );
}
