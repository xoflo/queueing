import 'package:flutter/material.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(itemBuilder: (context, i){
      return ElevatedButton(onPressed: () {

      }, child: Text(""));
    });
  }
}
