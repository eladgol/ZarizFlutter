import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const IP = "192.168.1.13";
const PORT = 8080;


Future<Map<String, dynamic>> performLogin(username, password) async {
  var res = postServer("/localLogin/", {"localPassword" : password,
      "localUser": username});
      
  res.then((jResponse) {
        if (jResponse["success"] == true) {
            Singleton().persistentState.setString("user", username);
            Singleton().persistentState.setString("password", password);
        }
  });

  return res;
}
Future<Map<String, dynamic>>  performSignUp(username, email, password) async
{  
  var res = postServer("/signUp/", {"localPassword" : password,
      "localUser": username, "localEmail" : email});
      
  res.then((jResponse) {
        if (jResponse["success"] == true) {
            Singleton().persistentState.setString("user", username);
            Singleton().persistentState.setString("password", password);
        }
  });
  
  return res;
}

Future<Map<String, dynamic>>  postServer(relativeUrl, bodyMap) async
{
  var basicUrl = IP + ":" + PORT.toString();
  var url = "http://" + basicUrl + relativeUrl;
  var uri = new Uri.http(basicUrl, "");
  final response = await http.post(url, body : bodyMap);

  List<Cookie> lCookies = [];

  if (response.headers["set-cookie"] != null) {
    var sCookieSplit =  response.headers["set-cookie"];
    var lsCookie = sCookieSplit.split(";");
    var l = lsCookie[0].split("=");
    lCookies.add(new Cookie(l[0], l[1]));  
    
    Singleton().cj.saveFromResponse(uri, lCookies);
  }

  var t = Singleton().cj.loadForRequest(uri);
  var jResponse;
  if (response.statusCode >= 400)
  {
      jResponse = {"success" : false, "error" : "no connection"};
  } else {
      jResponse = json.decode(response.body);
  }
  print(jResponse.toString());
  return jResponse;
}
class Singleton {
  static final Singleton _singleton = new Singleton._internal();

  factory Singleton() {
    return _singleton;
  }
  CookieJar cj; 
  SharedPreferences persistentState;
  Singleton._internal();
}
Future<Map<String, dynamic>>  getLastDetails()
{
  final  prefs = SharedPreferences.getInstance();
    prefs.then((o){
          retreivePersistentState(o);
    });
}
void retreivePersistentState(SharedPreferences o) async {
  Singleton().persistentState = o;
  o.getString("user");
  Directory tempDir = await getTemporaryDirectory();
  String tempPath = tempDir.path;
  Singleton().cj = new PersistCookieJar(tempPath);
}