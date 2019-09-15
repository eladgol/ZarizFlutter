import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:core';
import 'dart:async';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zariz_app/style/theme.dart' as Theme;
import 'package:zariz_app/utils/bubble_indication_painter.dart';
import 'package:zariz_app/utils/Services.dart';
import 'package:zariz_app/ui/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info/device_info.dart';
import 'package:zariz_app/style/theme.dart' as ZarizTheme;

Widget createTextField(String hintText, FocusNode focusNode, TextEditingController controller, IconData iconData, {keyboardType=TextInputType.text, maxLines = 1, validator=null, textSize=16.0, bCenter =false, onTapFunction=null, enableEdit=true}) {
    return new Padding(
      padding: bCenter? EdgeInsets.only(top:10.0, bottom:10.0) :
        EdgeInsets.only(top: 10.0, bottom: 10.0, left: 25.0, right: 25.0),
      child: TextField(
        enabled: enableEdit,
        focusNode: focusNode,
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        inputFormatters: validator==null?null:[validator],
        onTap: onTapFunction==null?null:onTapFunction,
        textAlign: bCenter?TextAlign.center:TextAlign.start,
        style: TextStyle(
            fontFamily: "WorkSansSemiBold",
            fontSize: textSize,
            color: Colors.black),
        decoration: InputDecoration(
          border: InputBorder.none,
          focusedBorder : InputBorder.none,
          icon: Icon(
            iconData,
            size: 22.0,
            color: Colors.black87,
          ),
          hintText: hintText,
          hintStyle: TextStyle(
              fontFamily: "WorkSansSemiBold", fontSize: textSize),
          
        ),
      ),
    );
  }
  Widget createTextWithIcon(String hintText, IconData iconData) {
    return new Padding(
      padding: EdgeInsets.only(top: 10.0, bottom: 10.0, left: 25.0, right: 25.0),
      child: new Row(
        mainAxisAlignment : MainAxisAlignment.start,
        children: <Widget>[
          
          new Icon(iconData, size: 22.0,
            color: Colors.black87,),
          new Padding(
      padding: EdgeInsets.only(top: 10.0, bottom: 10.0, left: 25.0, right: 25.0),
      child: new Text(hintText,textAlign: TextAlign.start,
        style: TextStyle(
            fontFamily: "WorkSansSemiBold",
            fontSize: 16.0,
            color: Colors.black),))]));
      
  }
Widget createTitle(String sTitle, {IconData icon, textSize=16.0, bCenter =false})
{
  return new Padding(
      padding: bCenter? EdgeInsets.only(top:1.0, bottom:1.0) :
        EdgeInsets.only(top: 1.0, bottom: 1.0, left: 25.0, right: 25.0),
      child: Text(sTitle,
        style: TextStyle(
          fontFamily: "WorkSansSemiBold",
          fontSize: textSize,
          color: Colors.black),
        textAlign: bCenter?TextAlign.center:TextAlign.start,
        textDirection: TextDirection.rtl,
      )
    );
}