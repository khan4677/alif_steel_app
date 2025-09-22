class OrderItem {
  final String particular;
  final String width;
  final String thickness;
  final String lengthValue;
  final Map<int, int> lengthPcs;
  final String totalPTon;
  final String totalWTon;
  final String pricePerTon;

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
  String clientName; // <-- changed to clientName
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
    required this.clientName,
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
    'client_name': clientName, // <- Firestore key
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
    clientName: map['client_name'] ?? '',
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
