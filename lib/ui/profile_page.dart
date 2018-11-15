import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:utf/utf.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zariz_app/style/theme.dart' as ZarizTheme;
import 'package:zariz_app/utils/bubble_indication_painter.dart';
import 'package:zariz_app/utils/Services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import 'package:google_maps_webservice/places.dart';
import 'package:flutter/cupertino.dart';

import 'package:zariz_app/ui/page_carousel.dart';
import 'package:convert/convert.dart';

import 'package:location/location.dart' as LocationGPS;

import 'package:flutter/rendering.dart'; 

class CurrentLocation {
  String name = "Maor";
  double lat = 0.0;
  double lng = 0.0;
}

class WorkerDetails{
    String _firstName;
    String _lastName;
    double _wage;
    List<String> _lOccupationFieldListString;
    int _userID;
    String _photoAGCSPath;
    double _radius;
    String _place;
    double _lat;
    double _lng;
    Map<String, String> toJSON() => 
    {
      'firstName'     : _firstName,
      'lastName'      : _lastName,
      'wage'          : _wage.toString(),
      'userID'        : _userID.toString(),
      'photoAGCSPath' : _photoAGCSPath,
      'radius'        : _radius.toString(),
      'place'         : _place,
      'lat'           : _lat.toString(),
      'lng'           : _lng.toString()
    };
  }

class AppBarChoice {
  const AppBarChoice({this.title, this.icon});

  final String title;
  final IconData icon;
}

List<String> fixEncoding(String sIn) {
  String sEncoded = sIn.replaceAll(new RegExp(r"u|'|\[|\]"), "");
  List<String> lEncoded = sEncoded.split(',');
  List<String> lOut = new List<String>();                      
  lEncoded.forEach((e) {
      e = e.trim();
      var chars = e.split(new RegExp(r"\\| ")).skip(1).toList();
      var sOut = "";
      chars.forEach((c) {
        if ((c != " u'") && (!(c as String).contains("["))) {    
          if (c == "")
            sOut += " ";
          else
            sOut += decodeUtf16(hex.decode(c));
        }
      });
      lOut.add(sOut);
  });   
  return lOut;
}

List<AppBarChoice> choices = <AppBarChoice>[
  AppBarChoice(title: 'update', icon: Icons.check),
  AppBarChoice(title: 'logoff', icon: FontAwesomeIcons.signOutAlt),
  AppBarChoice(title: 'debug', icon: FontAwesomeIcons.bug),
  AppBarChoice(title: 'feed', icon: FontAwesomeIcons.solidBell),
];

class ProfilePage extends StatefulWidget {
  ProfilePage({Key key}) : super(key: key);

  @override
  _ProfilePageState createState() => new _ProfilePageState();
}
class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();


  final FocusNode myFocusNodeEmail = FocusNode();
  final FocusNode myFocusNodeFirstName = FocusNode();
  final FocusNode myFocusNodeLastName = FocusNode();
  final FocusNode myFocusNodeWage = FocusNode();
  final FocusNode myFocusNodePlace = FocusNode();
  final FocusNode myFocusNodeRadius = FocusNode();
  
  bool _obscureTextProfile = true;
  bool _obscureTextSignup = true;
  bool _obscureTextSignupConfirm = true;
  
  bool _bHasChangedUpdate = false;
  PageController _pageController;

  Color left = Colors.black;
  Color right = Colors.white;

  bool _bProfileEnabled = true;
  bool _bSignUpEnabled = true;
  AppBarChoice _selectedChoice = choices[0];

  WorkerDetails _workerDetails;
  Services _services = new Services();

  TextEditingController _controllerFirstName = new TextEditingController();
  TextEditingController _controllerLastName = new TextEditingController();
  TextEditingController _controllerWage = new TextEditingController();
  TextEditingController _controllerPlace = new TextEditingController();
  TextEditingController _controllerRadius = new TextEditingController();

  List<DropdownMenuItem<String>> _lPlacesDropDownList =[new DropdownMenuItem<String>(
                                          value: "מאור",
                                          child: new Text("מאור"),
                                      )];
                                      
  List<Prediction> _lPlacesList =[];                         

  String _imageFileBase64Data = "";

  static final List<String> _lDefaultPossibleOccupation = ["א","ב","ג","ד","ה","ו","ז","ח","ט","י","כ","ל","מ","נ","ס","ע","פ","צ","ק","ר","ש","ת"];
  List<String> _lPossibleOccupation = _lDefaultPossibleOccupation;
  List<Color> _colorOccupation =  new List<Color>.filled(_lDefaultPossibleOccupation.length, uncheckedColor);
  List<bool> _selectedOccupation = new List<bool>.filled(_lDefaultPossibleOccupation.length, false);
  void _select(AppBarChoice choice) {
    // Causes the app to rebuild with the new _selectedChoice.
    setState(() {
      _selectedChoice = choice;
      if (choice.title == "update") {
          print(_workerDetails.toString());
          _workerDetails._photoAGCSPath = _imageFileBase64Data;
          _services.updateInputForm(_workerDetails.toJSON());
      }
      if (choice.title == "debug") {
          print(_workerDetails.toString());
          debugDumpApp();
          debugDumpRenderTree();
      }
    });
  }

  static final String kGoogleApiKey = "AIzaSyCKbtYyIOqIe1mmCIPIp_wezViTi2JHiC0";
  GoogleMapsPlaces _placesAPI = new GoogleMapsPlaces(kGoogleApiKey);

  void setPlaceLatLng(String sPlace) {
    _placesAPI.searchByText(sPlace).then((a) {
       if (a.results.length > 0) {
        setState(() {
          _workerDetails._lat = a.results[0].geometry.location.lat;
          _workerDetails._lng = a.results[0].geometry.location.lng;
          _workerDetails._place = a.results[0].name;
          _bHasChangedUpdate = true;
        });
       }
    });
  }
  Image _image = new Image.asset('assets/img/no_portrait.png', fit: BoxFit.scaleDown, width: 250.0, height: 191.0);

  Future getImage() async {
    ImageSource _source;
    showModalBottomSheet<void>(context:context, builder: (BuildContext context) {
      return new Theme(
                                        data: new ThemeData(
                                          fontFamily: "WorkSansSemiBold", 
                                          canvasColor: ZarizTheme.Colors.zarizGradientStart, //my custom color
                                        ),
                                        child: new Container( decoration: new BoxDecoration(
                    gradient: new LinearGradient(
                        colors: [
                          ZarizTheme.Colors.zarizGradientStart,
                          ZarizTheme.Colors.zarizGradientEnd
                        ],
                        begin: const FractionalOffset(0.0, 0.0),
                        end: const FractionalOffset(1.0, 1.0),
                        stops: [0.0, 1.0],
                        tileMode: TileMode.clamp),
                  ),child: new Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
        new IconButton(icon: Icon(FontAwesomeIcons.camera), onPressed: (){_source = ImageSource.camera;imagePick(_source);}),
        new IconButton(icon: Icon(FontAwesomeIcons.fileImage), onPressed: (){_source = ImageSource.gallery;imagePick(_source);}),
        ])));
    });
  }
  getResolution(Image image) {
    Completer<ImageInfo> completer = new Completer<ImageInfo>();
    image.image
      .resolve(new ImageConfiguration())
      .addListener((ImageInfo info, bool _) => completer.complete(info));
    return completer.future;
  }
  Image getAdjustedImageFromFile(File img, ImageInfo info) {
    
    var w = _heightImage *  info.image.width / info.image.height ;
    return (Image.file(img , fit: BoxFit.fill, width: w, height: _heightImage));           
  }
  void imagePick(ImageSource _source) {
    ImagePicker.pickImage(source: _source).then((img){
        var res = getResolution(Image.file(img));
        res.then((info) {
            Image image = getAdjustedImageFromFile(img, info);
            var prefix = img.path.split('.')[img.path.split('.').length-1];
            List<int> imageBytes = img.readAsBytesSync();
            saveImage(imageBytes, "jpg").then((sFileName){
              
            });
            setState(() {
                _imageFileBase64Data = 'data:image/$prefix;base64,' + base64.encode(imageBytes);
                _image = image;
            });
            Navigator.pop(context);
        });
    });
  }


  static double hDefault = 775.0;
  double _heightImage = hDefault * 0.15;
  double _heightSwitch = hDefault * 0.05;
  double _heightCard = hDefault * 0.5;
  double _heightButton = hDefault * 0.1;

  CurrentLocation _currLocation = new CurrentLocation();
 
  //@override
  // Widget build(BuildContext context) {
  //   return new Directionality(
  //     textDirection: TextDirection.rtl,
      
  //     child : new Scaffold(
        
  //       body: NotificationListener<OverscrollIndicatorNotification>(
  //         onNotification: (overscroll) {
  //           overscroll.disallowGlow();
  //         },
          
          
  //           child: new Container(
  //             width: MediaQuery.of(context).size.width,
  //             height:  MediaQuery.of(context).size.height * 0.9,
  //             child: new SingleChildScrollView(
  //               child: _buildCarousel(context),
  //               )
  //           )
  //       )
  //     )
  //   );
  // }
  Widget build(BuildContext context) {
    return new Directionality(
      textDirection: TextDirection.rtl,
        child : new Scaffold(
        appBar: AppBar(
        title: Text('פרופיל'),
        actions: <Widget>[
              IconButton(
                icon: new Icon(Icons.check),
                onPressed: () {
                  _select(choices[0]);
                  
                },
                color: _bHasChangedUpdate ? Colors.red: Colors.green,
              ),
              // action button
              IconButton(
                icon: Icon(FontAwesomeIcons.signOutAlt),
                onPressed: () {
                  _select(choices[1]);
                },
              ),
              IconButton(
                icon: Icon(FontAwesomeIcons.bug),
                onPressed: () {
                  _select(choices[2]);
                },
              ),
              PopupMenuButton<AppBarChoice>(
                onSelected: _select,
                itemBuilder: (BuildContext context) {
                  return choices.skip(2).map((AppBarChoice choice) {
                    return PopupMenuItem<AppBarChoice>(
                      value: choice,
                      child: Text(choice.title),
                    );
                  }).toList();
                },
              ),
            ],

        ),
        key: _scaffoldKey,
        body: NotificationListener<OverscrollIndicatorNotification>(
          onNotification: (overscroll) {
            overscroll.disallowGlow();
          },
          child: SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height >= hDefault
                      ? MediaQuery.of(context).size.height
                      : hDefault,
                  decoration: new BoxDecoration(
                    gradient: new LinearGradient(
                        colors: [
                          ZarizTheme.Colors.zarizGradientStart,
                          ZarizTheme.Colors.zarizGradientEnd
                        ],
                        begin: const FractionalOffset(0.0, 0.0),
                        end: const FractionalOffset(1.0, 1.0),
                        stops: [0.0, 1.0],
                        tileMode: TileMode.clamp),
                  ),
                  child: Column(
                    children: <Widget>[
                      
                      Padding(
                        padding: EdgeInsets.only(top: 1.0),
                        child: new FlatButton(
                          onPressed: onImagePressed,
                          child:  new ClipRRect(
                            borderRadius: new BorderRadius.circular(2.0),
                            child: _image,
                            
                          ),
                        ),   
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 5.0, bottom: 5.0),
                        child: _buildMenuBar(context),
                      ),
                      
                      Flexible(
                        flex: 2,
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (i) {
                            if (i == 0) {
                              setState(() {
                                right = Colors.white;
                                left = Colors.black;
                              });
                            } else if (i == 1) {
                              setState(() {
                                right = Colors.black;
                                left = Colors.white;
                              });
                            }
                          },
                          children: <Widget>[
                            new SingleChildScrollView(
                              //constraints: const BoxConstraints.expand(),
                              child: _buildCarousel(context),
                              primary: false,
                            ),
                            new ConstrainedBox(
                              constraints: const BoxConstraints.expand(),
                              child: _buildBossDetails(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ),
      ),
    );
  }
  static final uncheckedColor = ZarizTheme.Colors.zarizGradientEnd.withAlpha(64);
  static final checkedColor = ZarizTheme.Colors.zarizGradientEnd.withAlpha(240);


  void onImagePressed(){
      getImage();
  }
  @override
  void dispose() {
    myFocusNodeEmail.dispose();
    myFocusNodeFirstName.dispose();
    myFocusNodeLastName.dispose();
    myFocusNodeWage.dispose();
    myFocusNodePlace.dispose();
    myFocusNodeRadius.dispose();
    _pageController?.dispose();
    super.dispose();
  }
  int _tLength = 2;
  @override
  void initState() {
    super.initState();
    setState(() {
          _placesMenuVisible = false;
        });

    var resFuture = _services.getFieldDetails();
    resFuture.then((res){
        if ((res["success"] == "true") || (res["success"] == true)) {
          _workerDetails = new WorkerDetails();
          _workerDetails._firstName = res["firstName"];
          _workerDetails._lastName = res["lastName"];
          _workerDetails._lat = res["lat"];
          _workerDetails._lng = res["lng"];
          _workerDetails._photoAGCSPath = res["photoAGCSPath"];
          _workerDetails._radius = res["radius"];
          _workerDetails._wage = res["wage"];
          _workerDetails._place = res["place"];
          
          _controllerFirstName.text = _workerDetails._firstName;
          _controllerLastName.text  = _workerDetails._lastName;
          _controllerPlace.text     = _workerDetails._place;
          _controllerWage.text      =  _workerDetails._wage.toString();
          _controllerRadius.text    = _workerDetails._radius.toString();


          _controllerFirstName.addListener((){
            setState(() {
              _workerDetails._firstName = _controllerFirstName.text;
              _bHasChangedUpdate = true;
            });
          }); 
          _controllerLastName.addListener((){
            setState(() {
              _workerDetails._lastName = _controllerLastName.text;
              _bHasChangedUpdate = true;
            });
          });
          _controllerWage.addListener((){
            setState(() {
              _workerDetails._wage = double.parse(_controllerWage.text) ;
              _bHasChangedUpdate = true;
            });
          });
          _controllerRadius.addListener((){
            setState(() {
              _workerDetails._radius = double.parse(_controllerRadius.text) ;
              _bHasChangedUpdate = true;
            });
          });
          _controllerPlace.addListener((){
            _textForAutoCompleteChanged();
            setState(() {
              _bHasChangedUpdate = true;
            });
          });            
        }
    });
    var resFuture2 = _services.getOccupationDetails();
    resFuture2.then((res){
        if ((res["success"] == "true") || (res["success"] == true)) {
          setState(() {
            _lPossibleOccupation = fixEncoding(res["possibleFields"]);
            var lSelectedOccupation = fixEncoding(res["pickedFields"]);
            _colorOccupation = new List<Color>.filled(_lPossibleOccupation.length, uncheckedColor);
            _selectedOccupation = new List<bool>.filled(_lPossibleOccupation.length, false);
            lSelectedOccupation.forEach((e) {
                int i = _lPossibleOccupation.indexOf(e);
                if (i >= 0) {
                  _selectedOccupation[i] = true;
                  _colorOccupation[i] = checkedColor;
                }

            });
            
          });
        }
    });
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _pageController = PageController();

    final  prefs = SharedPreferences.getInstance();
    prefs.then((o){         
          retreivePersistentState(o);
          setState(() {
                      
                    });
    });
    var currentLocation = <String, double>{};

    var location = new LocationGPS.Location();

    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      var c = location.getLocation();
      c.then((l){
          print(l.toString());
          var lat = l["latitude"];
          var lng = l["longitude"];
          var loc = new Location(lat, lng);
          var res = _placesAPI.searchNearbyWithRadius(loc, 1000.0);
          res.then((v){
            print(v.toString());
            if (v.status == "OK") {
              setState(() {
                _currLocation.name = v.results[0].name;
                _currLocation.lat = v.results[0].geometry.location.lat;
                _currLocation.lng = v.results[0].geometry.location.lng;
                _lPlacesDropDownList =[new DropdownMenuItem<String>(
                                          value: _currLocation.name ,
                                          child: new Text(_currLocation.name ),
                                      )];  

              });
            }
          });
      }).catchError((e) {
          print(e.toString());
        }
      );

      

    } catch (e){
      currentLocation = null;
    }
    
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
           var h = MediaQuery.of(context).size.height;
           var w = _heightImage * _image.width / _image.height;
           setState(() {
                        
          
          _heightImage = h * 0.15;
          _heightSwitch = h * 0.05;
          _heightCard = h * 0.5;
          _heightButton = h * 0.05;
          });
          String fileName = Singleton().persistentState.getString('profilePic');
          
          if (fileName == null){
            _image = new Image.asset('assets/img/no_portrait.png', fit: BoxFit.scaleDown, width: w, height: _heightImage);     
          } else {
            _image = Image.file(File(fileName), fit: BoxFit.scaleDown, width: w, height: _heightImage);
          }
          
        });
  }
  _textForAutoCompleteChanged() {
    
    String t = "${_controllerPlace.text}";
    if ((t.length > 2) && (t.length > _tLength)) {
        setState(() {
          _placesMenuVisible = true;
          _bIsLoadingPlaces = true;
        });
        Location nearL = new Location(_currLocation.lat, _currLocation.lng);
        _placesAPI.queryAutocomplete(t, location: nearL, radius: 300000.0).then((res){   
           setState(() { 
            _lPlacesDropDownList.clear();
           });
          for (var i=0; i < res.predictions.length; i++ ) {
            setState(() {
            _lPlacesDropDownList.add(new DropdownMenuItem<String>(
                                          value: res.predictions[i].description,
                                          child: new Text(res.predictions[i].description),
                                      ));
            });
            
          }
          setState(() 
          {
            _bIsLoadingPlaces = false;
          });
        }).catchError((e){
          print(e.toString());
        });
        
    } else {
        setState(() {
           _placesMenuVisible = false;       
           _bIsLoadingPlaces = false;
        });
    }
    _tLength = t.length;

  }

  void showInSnackBar(String value) {
    FocusScope.of(context).requestFocus(new FocusNode());
    _scaffoldKey.currentState?.removeCurrentSnackBar();
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: new Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
            color: Colors.white,
            fontSize: 16.0,
            fontFamily: "WorkSansSemiBold"),
      ),
      backgroundColor: Color(0xFF6aa1c),
      duration: Duration(seconds: 3),
    ));
  }
  bool _placesMenuVisible = false;
  Widget _buildMenuBar(BuildContext context) {
    var widthSwitch = _heightSwitch * 10.0;
    return Container(
      width: widthSwitch,
      height: _heightSwitch,
      decoration: BoxDecoration(
        color: Color(0x552B2B2B),
        borderRadius: BorderRadius.all(Radius.circular(25.0)),
      ),
      child: CustomPaint(
        painter: TabIndicationPainter(dxTarget : (widthSwitch/2), radius : (_heightSwitch/2), dy : (_heightSwitch/2), dxEntry : 0.0, color: ZarizTheme.Colors.zarizGradientEnd.value, pageController: _pageController),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Expanded(
              child: FlatButton(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onPressed: _onWorkerButtonPress,
                child: Text(
                  "עובד",
                  style: TextStyle(
                      color: left,
                      fontSize: 16.0,
                      fontFamily: "WorkSansSemiBold"),
                ),
              ),
            ),
            //Container(height: 33.0, width: 1.0, color: Colors.white),
            Expanded(
              child: FlatButton(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onPressed: _onBossButtonPress,
                child: Text(
                  "מעביד",
                  style: TextStyle(
                      color: right,
                      fontSize: 16.0,
                      fontFamily: "WorkSansSemiBold"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onWorkerButtonPress() {
    _pageController.animateToPage(0,
        duration: Duration(milliseconds: 500), curve: Curves.decelerate);
  }
  bool _bIsLoadingPlaces = false;
  void _onBossButtonPress() {
    _pageController?.animateToPage(1,
        duration: Duration(milliseconds: 500), curve: Curves.decelerate);
  }
  Widget _buildWorkerDetails1(BuildContext context) {
      return new Directionality(
        textDirection: TextDirection.rtl,
        child : new Container(
          decoration: new BoxDecoration(
                  gradient: new LinearGradient(
                      colors: [
                        ZarizTheme.Colors.zarizGradientStart,
                        ZarizTheme.Colors.zarizGradientEnd
                      ],
                      begin: const FractionalOffset(0.0, 0.0),
                      end: const FractionalOffset(1.0, 1.0),
                      stops: [0.0, 1.0],
                      tileMode: TileMode.clamp),
                ),
          padding: EdgeInsets.only(top: 23.0),
          child: Column(
            children: <Widget>[
              Stack(
                alignment: Alignment.topCenter,
                overflow: Overflow.visible,
                children: <Widget>[
                  Card(
                    elevation: 2.0,
                    color: Colors.white54,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Container(
                      //width: MediaQuery.of(context).size.width * 5 / 6,
                      //height: MediaQuery.of(context).size.height * 2,
                      child: new Column( children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(
                                top: 20.0, bottom: 20.0, left: 25.0, right: 25.0),
                            child: 
                            new Row(
                              children:<Widget>
                              [ 
                                new Flexible(child: TextField(
                                focusNode: myFocusNodeFirstName,
                                controller: _controllerFirstName,
                                keyboardType: TextInputType.emailAddress,
                                
                                style: TextStyle(
                                  fontFamily: "WorkSansSemiBold",
                                  fontSize: 16.0,
                                  color: Colors.black),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    icon: Icon(
                                      FontAwesomeIcons.userAlt,
                                      color: Colors.black87,
                                      size: 22.0,
                                    ),
                                    hintText: "פרטי",
                                    hintStyle: TextStyle(
                                        fontFamily: "WorkSansSemiBold", fontSize: 17.0
                                    ),
                                  ),
                                ),
                                ),
                                new Flexible(
                                child: TextField(
                                  focusNode: myFocusNodeLastName,
                                  controller: _controllerLastName,
                                  keyboardType: TextInputType.emailAddress,
                                
                                  style: TextStyle(
                                    fontFamily: "WorkSansSemiBold",
                                    fontSize: 16.0,
                                    color: Colors.black
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    icon: Icon(
                                      FontAwesomeIcons.users,
                                      color: Colors.black87,
                                      size: 22.0,
                                    ),
                                    hintText: "משפחה",
                                    hintStyle: TextStyle(
                                    fontFamily: "WorkSansSemiBold", fontSize: 17.0),
                                  ),
                                ),
                              ),
                              ]
                            ),
                          ),
                          Container(
                            width: 250.0,
                            height: 1.0,
                            color: Colors.grey[400],
                          ),

                          
                          //_placesMenuVisible ?
                           
                          new Row(
                            children:<Widget>
                            [ 
                              new Flexible(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      top: 20.0, bottom: 20.0, left: 25.0, right: 25.0),
                                  child: TextField(
                                    focusNode: myFocusNodePlace,
                                    controller: _controllerPlace,
                                    keyboardType: TextInputType.text,
                                    style: TextStyle(
                                        fontFamily: "WorkSansSemiBold",
                                        fontSize: 16.0,
                                        color: Colors.black),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      icon: Icon(
                                        FontAwesomeIcons.mapMarker,
                                        size: 22.0,
                                        color: Colors.black87,
                                      ),
                                      hintText: "מקום",
                                      hintStyle: TextStyle(
                                          fontFamily: "WorkSansSemiBold", fontSize: 17.0),
                                      
                                    ),
                                  ),
                                ),
                              ),
                              _bIsLoadingPlaces ? new CircularProgressIndicator():new Container(),
                              new Flexible(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                        top: 20.0, bottom: 20.0, left: 25.0, right: 25.0),
                                    child: new SingleChildScrollView
                                    (
                                      child: new Theme(
                                        data: new ThemeData(
                                          fontFamily: "WorkSansSemiBold", 
                                          canvasColor: Colors.white54, //my custom color
                                        ),
                                        child: 
                                            new DropdownButton(
                                              iconSize: 30.0,
                                              items: _lPlacesDropDownList,
                                              onChanged: ((s)
                                              {
                                                _controllerPlace.text = s;
                                                _bHasChangedUpdate = true;
                                                setPlaceLatLng(s);
                                              }),
                                              )
                                        
                                    ),
                                    scrollDirection: Axis.horizontal,
                                      
                                  )
                                )
                              )
                            ]
                          ),
                          //))) : Container(),
                          Container(
                            width: 250.0,
                            height: 1.0,
                            color: Colors.grey[400],
                          ),

                          Padding(
                            padding: EdgeInsets.only(
                                top: 20.0, bottom: 20.0, left: 25.0, right: 25.0),
                            child: TextField(
                              focusNode: myFocusNodeRadius,
                              controller: _controllerRadius,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                  fontFamily: "WorkSansSemiBold",
                                  fontSize: 16.0,
                                  color: Colors.black),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                icon: Icon(
                                  FontAwesomeIcons.route,
                                  size: 22.0,
                                  color: Colors.black87,
                                ),
                                hintText: "מרחק",
                                hintStyle: TextStyle(
                                    fontFamily: "WorkSansSemiBold", fontSize: 17.0),
                                
                              ),
                            ),
                          ),
                          Container(
                            width: 250.0,
                            height: 1.0,
                            color: Colors.grey[400],
                          ),
 
                          Padding(
                            padding: EdgeInsets.only(
                                top: 20.0, bottom: 20.0, left: 25.0, right: 25.0),
                            child: TextField(
                              focusNode: myFocusNodeWage,
                              controller: _controllerWage,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                  fontFamily: "WorkSansSemiBold",
                                  fontSize: 16.0,
                                  color: Colors.black),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                icon: Icon(
                                  FontAwesomeIcons.shekelSign,
                                  size: 22.0,
                                  color: Colors.black87,
                                ),
                                hintText: "שכר",
                                hintStyle: TextStyle(
                                    fontFamily: "WorkSansSemiBold", fontSize: 17.0),
                                
                              ),
                            ),
                          ),
                          Container(
                            width: 250.0,
                            height: 1.0,
                            color: Colors.grey[400],
                          ),

                      ]))),
                  
                ],
              ),
            ],
          ),
        ),
              
      );
    }
  Widget _buildWorkerDetails2(BuildContext context) {
      return new Directionality(
        textDirection: TextDirection.rtl,
        child : new Container(
          decoration: new BoxDecoration(
                  gradient: new LinearGradient(
                      colors: [
                        ZarizTheme.Colors.zarizGradientStart,
                        ZarizTheme.Colors.zarizGradientEnd
                      ],
                      begin: const FractionalOffset(0.0, 0.0),
                      end: const FractionalOffset(1.0, 1.0),
                      stops: [0.0, 1.0],
                      tileMode: TileMode.clamp),
                ),
          //padding: EdgeInsets.only(top: 23.0),
          child:
                  
                      new SingleChildScrollView(scrollDirection: Axis.vertical,
                      child:createMultiGridView())

                  
                
              )    
          
          );
             
      
    }
  
  final ScrollController _scrollController = ScrollController();

  GridView createMultiGridView(){
    var gridView = new GridView.builder(
        controller: _scrollController,
        itemCount: _lPossibleOccupation.length,
        shrinkWrap: true,
        gridDelegate:
            new SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        itemBuilder: (BuildContext context, int index) {
          var s = _lPossibleOccupation[index];
          return new GestureDetector(
            child: new Card(
              elevation: (_selectedOccupation[index])?6.0:2.0,
                  color: Colors.white54,
                  shape: RoundedRectangleBorder(
                    side: new BorderSide(color: _colorOccupation[index], width: (_selectedOccupation[index])?6.0:12.0),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
              
                child: new Text('$s', textAlign: TextAlign.center,style: TextStyle(
                                fontFamily: "WorkSansSemiBold",
                                fontSize: 16.0,
                                color: Colors.black)),
              ),
            
            onTap: () {
              setState(() {
                _selectedOccupation[index] = !_selectedOccupation[index];
                if (_selectedOccupation[index]) {
                  _colorOccupation[index] = checkedColor;//.Colors.zarizGradientEnd.withAlpha(10);
                } else {
                  _colorOccupation[index] = uncheckedColor;//ZarizTheme.Colors.zarizGradientEnd.withAlpha(240);
                }

                _bHasChangedUpdate = true;
                _workerDetails._lOccupationFieldListString = [];
                for (var i=0; i < _selectedOccupation.length; i++ ) {
                  if (_selectedOccupation[i]) {
                      _workerDetails._lOccupationFieldListString.add(_lPossibleOccupation[i]);
                  }

                }  
              });
            },
          );
        });
        return gridView;
  }

  Widget _buildCarousel(BuildContext context) {
    var c = new CarosuelState(pages : <Widget>[
      new ConstrainedBox(
      constraints: const BoxConstraints.expand(),
      child: _buildWorkerDetails2(context),
    ),new ConstrainedBox(
      constraints: const BoxConstraints.expand(),
      child: _buildWorkerDetails1(context),
    ),]);
    return c.buildCarousel(context);
  }
  Widget _buildBossDetails(BuildContext context) {
    return new Directionality(
      textDirection: TextDirection.rtl,
      child : new Container(
        padding: EdgeInsets.only(top: 23.0),
        child: Column(
          children: <Widget>[
            Stack(
              alignment: Alignment.topCenter,
              overflow: Overflow.visible,
              children: <Widget>[
                Card(
                  elevation: 2.0,
                  color: Colors.white54,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Container(
                    width: 300.0,
                    height: 360.0,
                    child: Column(
                      children: <Widget>[

                        
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
}