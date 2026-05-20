import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class homepage extends StatefulWidget {
  const homepage({super.key});

  @override
  State<homepage> createState() => _homepageState();
}

class _homepageState extends State<homepage> {
  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Container(
            alignment: Alignment.centerLeft,
            height: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                    onTap: (){
          
                    },
                    child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            width: 2.0
                          )
                        ),
                        child: Icon(Icons.brush,size: 35,))),
                Container(
                    decoration: BoxDecoration(
                      border: Border.all(width: 2.0)
                    ),
                    child: Icon(Icons.safety_check_rounded,size: 35,)),
                Container(
                    decoration: BoxDecoration(
                      border: Border.all(width: 2.0)
                    ),
                    child: Icon(Icons.search,size: 35,)),
                Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 2.0
                      )
                    ),
                    child: Icon(Icons.circle_outlined,size: 35,)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
