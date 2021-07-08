import 'dart:io';

import 'package:flutter/material.dart';
import 'package:zariz_app/ui/login_page.dart';
//import 'package:flutter/rendering.dart'; 
 class MyHttpOverrides extends HttpOverrides{
  @override
  HttpClient createHttpClient(SecurityContext context){
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
  }
}
void main()
{
  HttpOverrides.global = new MyHttpOverrides();
  //debugPaintSizeEnabled=true;
  runApp(new MyApp());
  WidgetsBinding.instance
        .addPostFrameCallback((_) {
          
        });
}



class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'זריז',
      theme: new ThemeData(

        primarySwatch: Colors.brown,
      ),
      home: new LoginPage(),
    );
  }
}