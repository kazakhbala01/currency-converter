import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Currency Converter',
      theme: ThemeData.dark().copyWith(
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: CurrencyConverter(),
    );
  }
}

class CurrencyConverter extends StatefulWidget {
  @override
  _CurrencyConverterState createState() => _CurrencyConverterState();
}

class _CurrencyConverterState extends State<CurrencyConverter> {
  final fromCurrencyController = TextEditingController();
  final toCurrencyController = TextEditingController();
  String fromCurrency = 'USD';
  String toCurrency = 'EUR';
  double? conversionRate;
  double? amountForOne;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchConversionRate();
  }

  @override
  void dispose() {
    fromCurrencyController.dispose();
    toCurrencyController.dispose();
    super.dispose();
  }

  Future<void> fetchConversionRate() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(
          'https://api.exchangerate-api.com/v4/latest/$fromCurrency'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          conversionRate = data['rates'][toCurrency].toDouble();
          amountForOne = conversionRate;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        showErrorSnackbar('Failed to load, check your internet connection!');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showErrorSnackbar('Failed to load, check your internet connection!');
    }
  }

  void showErrorSnackbar(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void convertCurrency() {
    if (fromCurrencyController.text.isEmpty || conversionRate == null) return;
    final inputAmount = double.parse(fromCurrencyController.text);
    final outputAmount = inputAmount * conversionRate!;
    toCurrencyController.text = outputAmount.toStringAsFixed(2);
  }

  void swapCurrencies() {
    setState(() {
      String temp = fromCurrency;
      fromCurrency = toCurrency;
      toCurrency = temp;
      fromCurrencyController.clear();
      toCurrencyController.clear();
      fetchConversionRate(); // Update conversion rate after swapping currencies
    });
  }

  Widget currencyDropdown(String currency, ValueChanged<String?> onChanged) {
    return DropdownButton<String>(
      value: currency,
      onChanged: onChanged,
      items: <String>['USD', 'EUR', 'GBP', 'INR', 'JPY', 'KZT', 'RUB']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Row(
            children: [
              Image.asset(
                'assets/${value.toLowerCase()}.png',
                width: 24,
                height: 24,
              ),
              SizedBox(width: 8),
              Text(value),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Currency Converter'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: fromCurrencyController,
                decoration: InputDecoration(
                  labelText: 'From Currency',
                  border: OutlineInputBorder(),

                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              currencyDropdown(fromCurrency, (value) {
                setState(() {
                  fromCurrency = value!;
                });
                fetchConversionRate(); // Update conversion rate when changing from currency
              }),
              SizedBox(height: 20),
              Text(
                '1 $fromCurrency = ${amountForOne?.toStringAsFixed(2) ?? ''} $toCurrency',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              TextField(
                controller: toCurrencyController,
                decoration: InputDecoration(
                  labelText: 'To Currency',
                  border: OutlineInputBorder(),

                ),
                readOnly: true,
              ),
              SizedBox(height: 10),
              currencyDropdown(toCurrency, (value) {
                setState(() {
                  toCurrency = value!;
                });
                fetchConversionRate(); // Update conversion rate when changing to currency
              }),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  convertCurrency();
                },
                child: isLoading
                    ? CircularProgressIndicator(
                  color: Colors.white,
                )
                    : Text('Convert'),
                style: ButtonStyle(
                  padding: MaterialStateProperty.all<EdgeInsets>(
                    EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: swapCurrencies,
                icon: Icon(Icons.swap_horiz),
                label: Text('Swap Currencies'),
                style: ButtonStyle(
                  padding: MaterialStateProperty.all<EdgeInsets>(
                    EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
