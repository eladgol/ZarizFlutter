import 'package:http/http.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';

const IP = "192.168.1.13";
const PORT = 8080;

Future<Map<String, dynamic>> getFieldDetails() async {
  var res = postServer("/getFieldDetails/", {});
      
  res.then((jResponse) {
        if (jResponse["success"] == true) {
            var j = jResponse.remove("success");
            Singleton().persistentState.setString("details", jResponse.toString());
        }
  });

  return res;
}
Future<Map<String, dynamic>> performLogin(username, password) async {
  var res = postServer("/localLogin/", {"localPassword" : password,
      "localUser": username}, false);
      
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
      "localUser": username, "localEmail" : email}, false);
      
  res.then((jResponse) {
        if (jResponse["success"] == true) {
            Singleton().persistentState.setString("user", username);
            Singleton().persistentState.setString("password", password);
        }
  });
  
  return res;
}

typedef Future<bool> HttpAuthenticationCallback(
    Uri uri, String scheme, String realm);

HttpAuthenticationCallback _basicAuthenticationCallback(
        HttpClient client, HttpClientCredentials credentials) =>
    (Uri uri, String scheme, String realm) {
      client.addCredentials(uri, realm, credentials);
      return new Future.value(true);
    };

BaseClient createBasicAuthenticationIoHttpClient(
    String userName, String password) {
  final credentials = new HttpClientBasicCredentials(userName, password);

  final client = new HttpClient();
  client.authenticate = _basicAuthenticationCallback(client, credentials);
  return new IOClient(client);
}

Future<Map<String, dynamic>>  postServer(relativeUrl, bodyMap, [bAddHeader=true]) async
{
  var basicUrl = IP + ":" + PORT.toString();
  var url = "http://" + basicUrl + relativeUrl;
  var uri = new Uri.http(basicUrl, "");
  var client = new HttpClient();
  var http = new IOClient(client);
  var response;
  try {
      if (bAddHeader) {
          var username = Singleton().persistentState.getString("user");
          var password = Singleton().persistentState.getString("password");

          if ( (username != null) && (password != null)) {
              String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
              var lCookies = Singleton().cj.loadForRequest(uri);
              var headers = new Map<String,String>();//{HttpHeaders.authorizationHeader: basicAuth};
              var sCookie = "";
              var s = lCookies.map((i) => (i.name + "=" + i.value));
              sCookie = s.join(";");

              headers["Cookie"] = sCookie;

              response = await http.post(url, body : bodyMap, headers: headers);
          } else {
              response = await http.post(url, body : bodyMap);
          }
      } else {
          response = await http.post(url, body : bodyMap);
      }
      
  } catch (e) {
      final jResponse = {"success" : false, "error" : e.toString()};
      return jResponse;
  }
  List<Cookie> lCookies = [];

  if (response.headers["set-cookie"] != null) {
    var sCookieSplit =  response.headers["set-cookie"];
    var lsCookie = sCookieSplit.split(new RegExp(r',|;'));

    lsCookie.forEach((e) {
      if (e[0] != " ") {
          var l = e.split("=");
          lCookies.add(new Cookie(l[0], l[1]));          
      }
    });
    
    Singleton().cj.saveFromResponse(uri, lCookies);
  }

  var t = Singleton().cj.loadForRequest(uri);
  var jResponse;
  if (response.statusCode >= 400)
  {
      jResponse = {"success" : false, "error" : "no connection"};
  } else {
      
      jResponse = json.decode(response.body);
      if (!jResponse.containsKey("success")) {
          jResponse["success"] = true;
      }
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