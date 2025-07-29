import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Services/pdf_generator.dart';

class DeliveryFormPage extends StatefulWidget {
  @override
  _DeliveryFormPageState createState() => _DeliveryFormPageState();
}

class _DeliveryFormPageState extends State<DeliveryFormPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController dateController = TextEditingController();
  final TextEditingController partyNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController paymentDateController = TextEditingController();
  final TextEditingController paymentAmountController = TextEditingController();
  final TextEditingController outstandingController = TextEditingController();
  final TextEditingController totalBillController = TextEditingController();

  List<OrderItem> items = [];

  @override
  void initState() {
    super.initState();
    addNewItem(); // At least one item
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void addNewItem() {
    setState(() {
      items.add(OrderItem(
        particular: '',
        width: '',
        col6: '',
        col7: '',
        col8: '',
        col9: '',
        col10: '',
        totalPTon: '',
        totalWTon: '',
        pricePerTon: '',
      ));
    });
  }

  void generatePDF() async {
    if (!_formKey.currentState!.validate()) return;

    await PDFGeneratorService.generateDeliveryOrderPDF(
      date: dateController.text,
      customerName: partyNameController.text,
      address: addressController.text,
      items: items,
      paymentDate: paymentDateController.text,
      paymentAmount: paymentAmountController.text,
      outstanding: outstandingController.text,
      totalBill: totalBillController.text,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF Generated and Saved')),
    );
  }

  Widget buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
    );
  }

  Widget buildItemForm(int index) {
    final item = items[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Item ${index + 1}', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(labelText: 'Particulars'),
                initialValue: item.particular,
                onChanged: (val) => item.particular = val,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(labelText: 'Width'),
                initialValue: item.width,
                onChanged: (val) => item.width = val,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: List.generate(5, (i) {
            final labels = ['6\'', '7\'', '8\'', '9\'', '10\''];
            final keys = [item.col6, item.col7, item.col8, item.col9, item.col10];
            final onChanged = [
                  (val) => item.col6 = val,
                  (val) => item.col7 = val,
                  (val) => item.col8 = val,
                  (val) => item.col9 = val,
                  (val) => item.col10 = val,
            ];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: TextFormField(
                  decoration: InputDecoration(labelText: labels[i]),
                  initialValue: keys[i],
                  onChanged: onChanged[i],
                ),
              ),
            );
          }),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(labelText: 'Total P.Ton'),
                initialValue: item.totalPTon,
                onChanged: (val) => item.totalPTon = val,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(labelText: 'Total W.Ton'),
                initialValue: item.totalWTon,
                onChanged: (val) => item.totalWTon = val,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(labelText: 'Price/Pcs Ton'),
                initialValue: item.pricePerTon,
                onChanged: (val) => item.pricePerTon = val,
              ),
            ),
          ],
        ),
        Divider(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery Order Form'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTextField('Date', dateController),
              SizedBox(height: 10),
              buildTextField('Customer Name', partyNameController),
              SizedBox(height: 10),
              buildTextField('Address', addressController),
              SizedBox(height: 10),
              ...List.generate(items.length, buildItemForm),
              TextButton.icon(
                onPressed: addNewItem,
                icon: Icon(Icons.add),
                label: Text('Add Item'),
              ),
              SizedBox(height: 10),
              buildTextField('Payment Date', paymentDateController),
              SizedBox(height: 10),
              buildTextField('Payment Amount', paymentAmountController),
              SizedBox(height: 10),
              buildTextField('Outstanding', outstandingController),
              SizedBox(height: 10),
              buildTextField('Total Bill', totalBillController),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: generatePDF,
                icon: Icon(Icons.picture_as_pdf),
                label: Text('Generate PDF'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
