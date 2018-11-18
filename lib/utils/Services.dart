import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;


const sDefaultIP = "192.168.1.13";
const sDefaultPORT = 8080;

typedef Future<bool> HttpAuthenticationCallback(
      Uri uri, String scheme, String realm);

class Services {

  String ip = sDefaultIP;
  int port = sDefaultPORT;

  void setIP(String __ip, int __port){
    ip = __ip;
    port = __port;
  }
  Future<Map<String, dynamic>> updateInputForm(Map<String, dynamic> fields) async {
    var res = postServer("/updateAllInputsForm/", fields);
        
    res.then((jResponse) {
          if (jResponse["success"] == true) {
            if (jResponse.containsKey("Error") && jResponse["Error"] == "no change") {

            } else {
              var jResponse2 = new Map<String, dynamic>.from(jResponse);
              jResponse2.remove("success");
              // toDo: update the occupation list and picture 
              Singleton().persistentState.setString("WorkerDetails", jResponse2.toString());
            }
          }
    });

    return res;
  }
  Future<Map<String, dynamic>> getOccupationDetails() async {
    var res = postServer("/occupationDetails/", {});
        
    res.then((jResponse) {
          if (jResponse["success"] == true) {
              var jResponse2 = new Map<String, String>.from(jResponse);
              jResponse2.remove("success");
              Singleton().persistentState.setString("WorkerOccupation", jResponse2.toString());
          }
    });

    return res;
  }
  Future<Map<String, dynamic>> getFieldDetails() async {
    var res = postServer("/getFieldDetails/", {});
        
    res.then((jResponse) {
          if (jResponse["success"] == true) {
              var jResponse2 = new Map<String, String>.from(jResponse);
              jResponse2.remove("success");
              Singleton().persistentState.setString("details", jResponse.toString());
          }
    });

    return res;
  }
  Future<Map<String, dynamic>> performLogin(username, password) async {
    print("performing login for $username, $password for ${(port==443)?'https':'http'}://$ip:$port/localLogin");
    var res = postServer("/localLogin/", {"localPassword" : password,
        "localUser": username}, false);
        
    res.then((jResponse) {
          print("performing login received ${jResponse.toString()}");
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

  Future<Map<String, dynamic>>  postServer(relativeUrl, bodyMap, [bAddHeader=true]) async
  {
    var basicUrl = ip + ":" + port.toString();
    var url = "http://" + basicUrl + relativeUrl;
    var uri = new Uri.http(basicUrl, "");
    if (port == 443) {
      url = "https://" + basicUrl + relativeUrl;
      uri = new Uri.https(basicUrl, "");
    }

   
    var response;
    try {
        if (bAddHeader) {
            var username = Singleton().persistentState.getString("user");
            var password = Singleton().persistentState.getString("password");

            if ( (username != null) && (password != null)) {
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

    Singleton().cj.loadForRequest(uri);
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
void retreivePersistentState(SharedPreferences o) async {
  Singleton().persistentState = o;
  o.getString("user");
  Directory tempDir = await getTemporaryDirectory();
  String tempPath = tempDir.path;
  Singleton().cj = new PersistCookieJar(tempPath);
}
Future<String> saveImage( List<int> imageBytes, String ext) async {
  String sDir = (await getApplicationDocumentsDirectory()).path;
  String sFileName = sDir + "/profilePic." + ext;
  if (await File(sFileName).exists()) {
      await File(sFileName).delete();
  }
  await new File(sFileName).writeAsBytes(imageBytes);
  Singleton().persistentState.setString("profilePic", sFileName);
  return sFileName;
}   