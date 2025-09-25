import 'package:flutter/material.dart';

class CalculationPage extends StatefulWidget {
  @override
  _CalculationPageState createState() => _CalculationPageState();
}

class _CalculationPageState extends State<CalculationPage> {
  final TextEditingController _thicknessController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();

  // ✅ dynamically available lengths (1 to 99)
  final availableLengths = List<int>.generate(99, (index) => index + 1);

  // ✅ dynamically selected lengths
  List<int> selectedLengths = [];

  // ✅ controllers for each length -> {"6": {"pcs": controller, "ton": controller}}
  final Map<int, Map<String, TextEditingController>> lengthControllers = {};

  double _convertedLength = 0.0;
  int _pcsPerTon = 0;
  double _totalCost = 0.0;

  @override
  void initState() {
    super.initState();
    _thicknessController.addListener(_updateInfo);
    _rateController.addListener(_calculateCost);
  }

  double _getCL(double thickness, double length) {
    if (thickness >= 130 && thickness <= 260) {
      if (length == 7) return 7.021;
      if (length == 8) return 8.019;
      if (length == 10) return 10.012;
      return length;
    } else if (thickness >= 320 && thickness <= 360) {
      if (length == 9) return 9.020;
      if (length == 10) return 10.030;
      return length;
    } else if (thickness >= 420 && thickness <= 510) {
      if (length == 8) return 8.020;
      if (length == 9) return 8.970;
      return length;
    }
    return length;
  }

  int _getPCSPerTon(double thickness, int length) {
    if (thickness >= 130 && thickness <= 260) {
      switch (length) {
        case 6:
          return 282;
        case 7:
          return 241;
        case 8:
          return 211;
        case 9:
          return 188;
        case 10:
          return 169;
      }
    } else if (thickness >= 320 && thickness <= 360) {
      switch (length) {
        case 6:
          return 224;
        case 7:
          return 192;
        case 8:
          return 168;
        case 9:
          return 149;
        case 10:
          return 134;
      }
    } else if (thickness >= 420 && thickness <= 510) {
      switch (length) {
        case 6:
          return 175;
        case 7:
          return 150;
        case 8:
          return 131;
        case 9:
          return 117;
        case 10:
          return 105;
      }
    }
    return 0;
  }

  void _updateInfo() {
    final thickness = double.tryParse(_thicknessController.text);

    if (thickness != null) {
      for (var length in selectedLengths) {
        _convertedLength = _getCL(thickness, length.toDouble());
        _pcsPerTon = _getPCSPerTon(thickness, length);

        if (lengthControllers[length]!["pcs"]!.text.isNotEmpty) {
          _onPcsChanged(length);
        } else if (lengthControllers[length]!["ton"]!.text.isNotEmpty) {
          _onTonChanged(length);
        }
      }
    }
  }

  void _onPcsChanged(int length) {
    if (_pcsPerTon == 0) return;

    final pcs = int.tryParse(lengthControllers[length]!["pcs"]!.text) ?? 0;
    final tons = pcs / _pcsPerTon;

    lengthControllers[length]!["ton"]!
        .removeListener(() => _onTonChanged(length));
    lengthControllers[length]!["ton"]!.text = tons.toStringAsFixed(3);
    lengthControllers[length]!["ton"]!
        .addListener(() => _onTonChanged(length));

    _calculateCost();
  }

  void _onTonChanged(int length) {
    if (_pcsPerTon == 0) return;

    final tons =
        double.tryParse(lengthControllers[length]!["ton"]!.text) ?? 0.0;
    final pcs = (tons * _pcsPerTon).round();

    lengthControllers[length]!["pcs"]!.removeListener(() => _onPcsChanged(length));
    lengthControllers[length]!["pcs"]!.text = pcs.toString();
    lengthControllers[length]!["pcs"]!.addListener(() => _onPcsChanged(length));

    _calculateCost();
  }

  void _calculateCost() {
    double totalTons = 0.0;
    for (var length in selectedLengths) {
      totalTons += double.tryParse(lengthControllers[length]!["ton"]!.text) ?? 0.0;
    }

    final rate = double.tryParse(_rateController.text) ?? 0.0;
    setState(() {
      _totalCost = totalTons * rate;
    });
  }

  void _clearAll() {
    _thicknessController.clear();
    _rateController.clear();

    for (var length in selectedLengths) {
      lengthControllers[length]!["pcs"]!.clear();
      lengthControllers[length]!["ton"]!.clear();
    }

    setState(() {
      _convertedLength = 0.0;
      _pcsPerTon = 0;
      _totalCost = 0.0;
    });
  }

  @override
  void dispose() {
    for (var length in selectedLengths) {
      lengthControllers[length]!["pcs"]!.dispose();
      lengthControllers[length]!["ton"]!.dispose();
    }
    _thicknessController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Calculation Page")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: _thicknessController,
                decoration: InputDecoration(labelText: "Thickness"),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _rateController,
                decoration: InputDecoration(labelText: "Rate per Ton"),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              // ✅ Length selector chips (1 to 99)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: availableLengths.map((len) {
                    final isSelected = selectedLengths.contains(len);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: ChoiceChip(
                        label: Text("$len'"),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedLengths.add(len);
                              lengthControllers[len] = {
                                "pcs": TextEditingController(),
                                "ton": TextEditingController(),
                              };
                              lengthControllers[len]!["pcs"]!
                                  .addListener(() => _onPcsChanged(len));
                              lengthControllers[len]!["ton"]!
                                  .addListener(() => _onTonChanged(len));
                            } else {
                              selectedLengths.remove(len);
                              lengthControllers[len]!["pcs"]!.dispose();
                              lengthControllers[len]!["ton"]!.dispose();
                              lengthControllers.remove(len);
                            }
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 20),
              // ✅ dynamic Ton + Pcs inputs
              ...selectedLengths.map((length) {
                return Row(
                  children: [
                    Expanded(flex: 1, child: Text("$length'")),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: lengthControllers[length]!["pcs"],
                        decoration: InputDecoration(labelText: "Pcs"),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: lengthControllers[length]!["ton"],
                        decoration: InputDecoration(labelText: "Ton"),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                );
              }).toList(),
              SizedBox(height: 20),
              Text("Total Cost: $_totalCost"),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _clearAll,
                child: Text("Clear All"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
