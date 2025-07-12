// Screens/dashboard.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';
import '../widgets.dart';


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final TextEditingController _slNoController = TextEditingController();
  final TextEditingController _supplierPartyController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _thicknessController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _pcsController = TextEditingController();
  final TextEditingController _tnController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();

  // Dropdown values
  String? _selectedColor;
  String? _selectedType;

  final List<String> _colors = [
    'CNG',
    'BLUE',
    'RED',
    'PARROT',
    'M-GREEN',
    'WHITE',
    'GREEN',
    'SILVER',
  ];
  final List<String> _types = [
    'CHERRY',
    'CHERRY 10/11',
    'CHERRY 11/12',
    'BORO',
    'BORO 10/11',
    'BORO 11/12',
    'PROFILE',
    'INDSL. PROFILE',
    'GP SHEET',
    'B. TALLY',
    'TUA',
    'BABY COIL',
    'COIL',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFFCDF5FD),
        automaticallyImplyLeading: false, // Removes back button
        title: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo space - replace with your uploaded logo
              Container(
                width: 40,
                height: 40,
                margin: EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                // Add your logo here:
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                ),
              ),

              // Text
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'আলিফ স্টিল মিলস লিঃ',
                    style: TextStyle(
                      color: Color(0xFF3A0050),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'ALIF STEEL MILLS LTD.',
                    style: TextStyle(
                      color: const Color(0xFF156132),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
      PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.black),
      onSelected: (value) {
        if (value == 'logout') {
          FirebaseAuth.instance.signOut();
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout), Text(' Logout')])),
      ],
    ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // SL NO
                buildTextField(
                  controller: _slNoController,
                  label: 'SL. NO',
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),

                // Supplier Party Name
                buildTextField(
                  controller: _supplierPartyController,
                  label: 'Enter Party Name',
                ),
                SizedBox(height: 16),

                // Enter Address
                buildTextField(
                  controller: _addressController,
                  label: 'Enter Address',
                  maxLines: 2,
                ),
                SizedBox(height: 16),

                // Phone Number
                buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number (optional)',
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 50),

                // Thickness
                buildTextField(
                  controller: _thicknessController,
                  label: 'Thickness (mm)',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 16),

                // Color Dropdown
                buildDropdown(
                  label: 'Color',
                  value: _selectedColor,
                  items: _colors,
                  onChanged: (value) {
                    setState(() {
                      _selectedColor = value;
                    });
                  },
                ),
                SizedBox(height: 16),

                // Width
                buildTextField(
                  controller: _widthController,
                  label: 'Width (inch)',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 16),

                // Type Dropdown
                buildDropdown(
                  label: 'P. Type',
                  value: _selectedType,
                  items: _types,
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                    });
                  },
                ),
                SizedBox(height: 16),

                // Length
                buildTextField(
                  controller: _lengthController,
                  label: 'Length (ft)',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 16),

                // PCS
                buildTextField(
                  controller: _pcsController,
                  label: 'PCS',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 16),

                // PCS TN
                buildTextField(
                  controller: _tnController,
                  label: 'PCS TN',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 16),

                // Rate
                buildTextField(
                  controller: _rateController,
                  label: 'Rate (TK)',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 16),

                // Discount
                buildTextField(
                  controller: _discountController,
                  label: 'Discount',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Submit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _printForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Print',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Add Another Order Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addAnotherOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Add Another Order',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Handle form submission
      print('Form submitted');
      print('SL NO: ${_slNoController.text}');
      print('Supplier: ${_supplierPartyController.text}');
      print('Address: ${_addressController.text}');
      print('Phone: ${_phoneController.text}');
      print('Thickness: ${_thicknessController.text}');
      print('Color: $_selectedColor');
      print('Width: ${_widthController.text}');
      print('Type: $_selectedType');
      print('Length: ${_lengthController.text}');
      print('PCS: ${_pcsController.text}');
      print('PCS TN: ${_tnController.text}');
      print('Rate: ${_rateController.text}');
      print('Discount: ${_discountController.text}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order submitted successfully!'),
          backgroundColor: Colors.green[700],
        ),
      );
    }
  }

  void _printForm() {
    print('Print functionality');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Print functionality will be implemented'),
        backgroundColor: Colors.blue[700],
      ),
    );
  }

  void _addAnotherOrder() {
    // Clear only product-specific fields, keep customer info
    // Don't clear: SL NO, Supplier Party Name, Address, Phone Number
    _thicknessController.clear();
    _widthController.clear();
    _lengthController.clear();
    _pcsController.clear();
    _tnController.clear();
    _rateController.clear();
    _discountController.clear();

    setState(() {
      _selectedColor = null;
      _selectedType = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Form cleared for new order - Customer info preserved'),
        backgroundColor: Colors.orange[700],
      ),
    );
  }
}
