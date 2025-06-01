import 'package:flutter/material.dart';

class DisplayScreen extends StatefulWidget {
  const DisplayScreen({super.key});

  @override
  State<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen> {

  int itemCount = 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          MediaQuery.of(context).size.width > 1500 ? Row(
            children: [
              Column(
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                      height: 70,
                      child: Text("Now Serving", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700))),
                  Container(
                    padding: EdgeInsets.all(20),
                    height: MediaQuery.of(context).size.height - 340,
                    width: MediaQuery.of(context).size.width * 3/4,
                    child: GridView.builder(gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
                        itemCount: itemCount,
                        itemBuilder: (context, i) {
                      return Padding(
                        padding: const EdgeInsets.all(5),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(30.0),
                            child: Column(
                              children: [
                                Text("P101", style: TextStyle(fontSize: 30)),
                                Text("Teller #1", style: TextStyle(fontSize: 30)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),

              Container(
                width: MediaQuery.of(context).size.width * 1/4,
                child: Center(child: Text("Ombudsman")),
              ),
            ],
          ) : Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Expand Window to Display Queue", style: TextStyle(fontSize: 50), textAlign: TextAlign.center),
                  Text("This display only supports TV Display use", style: TextStyle(fontSize: 30, color: Colors.grey), textAlign: TextAlign.center),
                ],
              ))
        ],
      ),
    );
  }
}
