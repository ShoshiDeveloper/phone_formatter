import 'package:flutter/material.dart';
import 'package:phone_formatter/phone_formatter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final controller = TextEditingController();
  final focusNode = FocusNode();
  final formatter = PhoneFormatter.array(
    configVariants: [
      PhoneFormatterConfig(mask: '(###) ### ##-##', countryCode: '+7'),
      PhoneFormatterConfig(mask: '### ### ####', countryCode: '+1'),
      PhoneFormatterConfig(mask: '### ### ####', countryCode: '+92'),
    ],
  );

  @override
  void initState() {
    // for mandatory mask variant
    controller.value = formatter.formatEditUpdate(TextEditingValue.empty, TextEditingValue.empty);

    // for any mask variant
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        controller.selection = TextSelection.collapsed(
          offset: formatter.getFirstUnderline(controller.text),
        );
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextFormField(controller: controller, focusNode: focusNode, inputFormatters: [formatter]),
          ElevatedButton(
            onPressed: () {
              focusNode.unfocus();
            },
            child: Text('data'),
          ),
        ],
      ),
    );
  }
}
