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
//import 'package:convert/convert.dart';

import 'package:location/location.dart' as LocationGPS;

import 'package:flutter/rendering.dart'; 

class CurrentLocation {
  String name = "Maor";
  double lat = 0.0;
  double lng = 0.0;
}
class BossDetails{
    String _firstName;
    String _lastName;
    String _buisnessName;
    
    List<String> _lOccupationFieldListString;
    int _userID;
    String _photoAGCSPath;

    String _place;
    double _lat;
    double _lng;
    Map<String, String> toJSON() => 
    {
      'firstName'     : _firstName,
      'lastName'      : _lastName,
      'buisnessName'  : _buisnessName.toString(),
      'userID'        : _userID.toString(),
      'photoAGCSPath' : _photoAGCSPath,
      'place'         : _place,
      'lat'           : _lat.toString(),
      'lng'           : _lng.toString()
    };
  }
class JobsContext{
  JobsDetails details;
  JobsUI ui;
  JobsContext(JobsDetails details) {
    this.details = details;
    this.ui = new JobsUI(this.details);
  }
}
class JobsUI{
  FocusNode fnDiscription;
  FocusNode fnWage;
  FocusNode fnPlace;
  FocusNode fnnWorkers;
  AlwaysDisabledFocusNode fnnOccupationList;
  
  TextEditingController conDiscription;
  TextEditingController conWage;
  TextEditingController conPlace;
  TextEditingController connWorkers;
  TextEditingController connOccupationList;

  JobsUI(JobsDetails jd) {
    this.fnDiscription = new FocusNode();
    this.fnPlace = new FocusNode();
    this.fnWage = new FocusNode();
    this.fnnWorkers = new FocusNode();
    this.fnnOccupationList = new AlwaysDisabledFocusNode();
    
    this.conDiscription = new TextEditingController(text:(jd._discription!=null?jd._discription.toString():""));
    this.conWage = new TextEditingController(text:(jd._wage!=null?jd._wage.toString():""));
    this.conPlace = new TextEditingController(text:(jd._place!=null?jd._place.toString():""));
    this.connOccupationList = new TextEditingController(text:(jd._lOccupationFieldListString.length>0?jd._lOccupationFieldListString[0].toString():""));
    this.connWorkers = new TextEditingController(text:(jd.nWorkers!=null?jd.nWorkers.toString():""));
  }
}
class JobsDetails{
    String _jobId = "-1";
    String _discription;
    List<String> _lOccupationFieldListString = [];
    double _wage;
    String _place;
    double _lat;
    double _lng;
    int nWorkers;

    Map<String, String> toJSON() => 
    {
      'discription'     : _discription,
      'wage'          : _wage.toString(),
      'jobID'        : _jobId.toString(),
      'place'         : _place,
      'lat'           : _lat.toString(),
      'lng'           : _lng.toString(),
      'nWorkers'      : nWorkers.toString(),
      'lOccupationFieldListString' : _lOccupationFieldListString.length>0?_lOccupationFieldListString[0]:""
    };
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
      'lng'           : _lng.toString(),
      'lOccupationFieldListString' : fixDecoding(_lOccupationFieldListString)
    };
  }
String fixDecoding(List<String> sIn) {
  String sOut="[";
  int i=0;
  sIn.forEach((s){
    if (i==0) {
      sOut+=s;
    } else {
      sOut+=","+s;
    }
    i+=1;
    });
  sOut+="]";
  return sOut;
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
        if ((c != " u'") && (!c.contains("["))) {    
          if (c == "")
            sOut += " ";
          else
            sOut += decodeUtf16([int.parse(c.substring(0,2), radix:16), int.parse(c.substring(2,4), radix:16)]);
            //sOut += decodeUtf16(hex.decode(c));
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
class _ProfilePageState extends State<ProfilePage> {

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();


  final FocusNode myFocusNodeEmail = FocusNode();
  final FocusNode myFocusNodeFirstName = FocusNode();
  final FocusNode myFocusNodeLastName = FocusNode();
  final FocusNode myFocusNodeWage = FocusNode();
  final FocusNode myFocusNodePlace = FocusNode();
  final FocusNode myFocusNodeRadius = FocusNode();


  final FocusNode myFocusNodeBossFirstName    = FocusNode();
  final FocusNode myFocusNodeBossLastName     = FocusNode();
  final FocusNode myFocusNodeBossBuisnessName = FocusNode();
  final FocusNode myFocusNodeBossPlace        = FocusNode();

  
  bool _bWorkerIsUpdated = true;
  int _iJobIsUpdated = -1;
  String _idJobIsUpdated = "";
  PageController _pageController;

  Color left = Colors.black;
  Color right = Colors.white;

  WorkerDetails _workerDetails;
  BossDetails _bossDetails;

  List<JobsContext> _lJobs = [];
  List<String> _lJobsIDsMarkedForDeletion = [];
  Services _services = new Services();

  TextEditingController _controllerWorkerFirstName = new TextEditingController();
  TextEditingController _controllerWorkerLastName = new TextEditingController();
  TextEditingController _controllerWorkerWage = new TextEditingController();
  TextEditingController _controllerWorkerPlace = new TextEditingController();
  TextEditingController _controllerWorkerRadius = new TextEditingController();

  TextEditingController _controllerBossPlace = new TextEditingController();
  TextEditingController _controllerBossBuisnessName = new TextEditingController();


  List<DropdownMenuItem<String>> _lPlacesWorkerDropDownList =[new DropdownMenuItem<String>(
                                          value: "מאור",
                                          child: new Text("מאור"),
                                      )];                    
  List<DropdownMenuItem<String>> _lPlacesBossDropDownList =[new DropdownMenuItem<String>(
                                          value: "מאור",
                                          child: new Text("מאור"),
                                      )];     
  String _imageFileBase64Data = "";
  bool _bUpdatingDetails = false;

  static final List<String> _lDefaultPossibleOccupation = ["א","ב","ג","ד","ה","ו","ז","ח","ט","י","כ","ל","מ","נ","ס","ע","פ","צ","ק","ר","ש","ת"];
  List<String> _lPossibleOccupation = _lDefaultPossibleOccupation;
  List<Color> _colorOccupation =  new List<Color>.filled(_lDefaultPossibleOccupation.length, uncheckedColor);
  List<bool> _selectedOccupation = new List<bool>.filled(_lDefaultPossibleOccupation.length, false);
  void _select(AppBarChoice choice) {
    // Causes the app to rebuild with the new _selectedChoice.
    setState(() {
      _bUpdatingDetails = true;
      if (choice.title == "update") {
        if (!_bWorkerIsUpdated){
          print(_workerDetails.toJSON());
          
          _workerDetails._photoAGCSPath = _imageFileBase64Data;
          _services.updateInputForm(_workerDetails.toJSON()).then((res) {
              if (res.containsKey("success") && ((res["success"] == "true") || (res["success"] == true))) {
                setState(() {
                  _bWorkerIsUpdated = true;
                  _bUpdatingDetails = false;
                });
                  
              }
          });
          _services.updateBossInputForm(_bossDetails.toJSON()).then((res) {
              if (res.containsKey("success") && ((res["success"] == "true") || (res["success"] == true))) {
                setState(() {
                  _bWorkerIsUpdated = true;
                  _bUpdatingDetails = false;
                });
                  
              }
          });
        }
        if (_iJobIsUpdated != -1) {
          if (_idJobIsUpdated=="") {
            _services.updateJobAsBoss(_lJobs[_iJobIsUpdated].details.toJSON()).then((res) {
              if (res.containsKey("success") && ((res["success"] == "true") || (res["success"] == true))) {
                setState(() {
                  _lJobs[_iJobIsUpdated].details._jobId = res['jobID'];
                  _iJobIsUpdated = -1;
                  _idJobIsUpdated = "";
                  _bUpdatingDetails = false;
                });       
              }
            });
          } else {
            _lJobs.forEach((j){
              if (_lJobsIDsMarkedForDeletion.contains(_idJobIsUpdated)) {
                _services.deleteJobAsBoss(_idJobIsUpdated).then((res) {
                  if (res.containsKey("success") && ((res["success"] == "true") || (res["success"] == true))) {
                    setState(() {
                      _iJobIsUpdated = -1;
                      _idJobIsUpdated = "";
                      _lJobsIDsMarkedForDeletion.remove(_idJobIsUpdated);
                      _bUpdatingDetails = false;

                    });    
                  }
                });
              } else if (j.details._jobId==_idJobIsUpdated) {
                _services.updateJobAsBoss(j.details.toJSON()).then((res) {
                  if (res.containsKey("success") && ((res["success"] == "true") || (res["success"] == true))) {
                    setState(() {
                      _lJobs[_iJobIsUpdated].details._jobId = res['jobID'];
                      _iJobIsUpdated = -1;
                      _idJobIsUpdated = "";
                      _bUpdatingDetails = false;
                    });       
                  }
                });
              }
            
            });
          }
          refreshJobs();
        } 
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

  void setPlaceLatLng(String sPlace, bool bIsBoss, {int jobIndex=-1}) {
    _placesAPI.searchByText(sPlace).then((a) {
       if (a.results.length > 0) {
        setState(() {
          if (bIsBoss) {
            if (jobIndex != -1) {
              _lJobs[jobIndex].details._lat =  a.results[0].geometry.location.lat;
              _lJobs[jobIndex].details._lng =  a.results[0].geometry.location.lng;
              _lJobs[jobIndex].details._place =  a.results[0].name;
            } else {
              _bossDetails._lat = a.results[0].geometry.location.lat;
              _bossDetails._lng = a.results[0].geometry.location.lng;
              _bossDetails._place = a.results[0].name;      
            }    
          } else {
            _workerDetails._lat = a.results[0].geometry.location.lat;
            _workerDetails._lng = a.results[0].geometry.location.lng;
            _workerDetails._place = a.results[0].name; 
          }
          _bWorkerIsUpdated = false;
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
  double _heightMain = hDefault * 0.7;
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
  //               child: _buildWorkerCarousel(context),
  //               )
  //           )
  //       )
  //     )
  //   );
  // }
  
  Decoration decorationWorker(BuildContext context) {
    return new BoxDecoration(
          gradient: new LinearGradient(
          colors: [
            ZarizTheme.Colors.zarizGradientStart1,
            ZarizTheme.Colors.zarizGradientEnd
          ],
          begin: const FractionalOffset(0.0, 0.0),
          end: const FractionalOffset(1.0, 1.0),
          stops: [0.0, 1.0],
          tileMode: TileMode.clamp),
    );
  }
  Decoration decorationBoss(BuildContext context) {
    return new BoxDecoration(
          gradient: new LinearGradient(
          colors: [
            ZarizTheme.Colors.zarizGradientStart2,
            ZarizTheme.Colors.zarizGradientEnd
          ],
          begin: const FractionalOffset(0.0, 0.0),
          end: const FractionalOffset(1.0, 1.0),
          stops: [0.0, 1.0],
          tileMode: TileMode.clamp),
    );
  }
  String _profileTitleBoss = "פרופיל מעביד";
  String _profileTitleWorker = "פרופיל עובד";
  Widget build(BuildContext context) {
    return new Directionality(
      textDirection: TextDirection.rtl,
        child : new Scaffold(
        appBar: AppBar(
        title: Text(_bBossMode?_profileTitleBoss:_profileTitleWorker),
        actions: <Widget>[
              IconButton(
                icon: new Icon(Icons.check),
                onPressed: () {
                  _select(choices[0]);
                  
                },
                color: (_bWorkerIsUpdated || _iJobIsUpdated == -1) ? Colors.green: Colors.red,
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
                  decoration: _bBossMode?  decorationBoss(context) : decorationWorker(context),
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(top: 8.0),
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
                        child: _buildSwitchBar(context),
                      ),
                      (_bIsLoadingPlaces || _bUpdatingDetails) ? new CircularProgressIndicator(backgroundColor: ZarizTheme.Colors.zarizGradientStart):new Container(),
                      
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
                              child: _buildWorkerCarousel(context),
                              primary: false,
                            ),
                            new SingleChildScrollView(
                              child: _buildBossCarousel(context),
                              primary: false,
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

  void refreshJobs() {
    _services.getAllJobsAsBoss().then((res){
    if ((res["success"] == "true") || (res["success"] == true)) {
        setState(() {
          _lJobs = [];
          for (int i=0;i<(res.length - 1);i++) {
            var j=res[i.toString()];
            _lJobs.add(new JobsContext(new JobsDetails()..nWorkers=j["nWorkers"].._place=j["place"].._jobId=j["jobID"].._discription=j["discription"].._lat=j["lat"].._lng=j["lng"].._wage=j["wage"].._lOccupationFieldListString=[j["occupationFieldListString"]]));
            _lJobs[i].details.nWorkers = j["nWorkers"];
          } 
        });
    }});
  }

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
    myFocusNodeBossFirstName.dispose();
    myFocusNodeBossLastName.dispose();     
    myFocusNodeBossBuisnessName.dispose(); 
    myFocusNodeBossPlace.dispose();
    _pageController?.dispose();
    super.dispose();
  }
  int _tLength = 2;
  @override
  void initState() {
    super.initState();
    setState(() {
         
        });

    var resFuture = _services.getFieldDetails();
    resFuture.then((res) {
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
        
        _controllerWorkerFirstName.text = _workerDetails._firstName;
        _controllerWorkerLastName.text  = _workerDetails._lastName;
        _controllerWorkerPlace.text     = _workerDetails._place;
        _controllerWorkerWage.text      =  _workerDetails._wage.toString();
        _controllerWorkerRadius.text    = _workerDetails._radius.toString();


        _controllerWorkerFirstName.addListener((){
          setState(() {
            _workerDetails._firstName = _controllerWorkerFirstName.text;
            _bWorkerIsUpdated = false;
          });
        }); 
        _controllerWorkerLastName.addListener((){
          setState(() {
            _workerDetails._lastName = _controllerWorkerLastName.text;
            _bWorkerIsUpdated = false;
          });
        });
        _controllerWorkerWage.addListener((){
          setState(() {
            _workerDetails._wage = double.parse(_controllerWorkerWage.text) ;
            _bWorkerIsUpdated = false;
          });
        });
        _controllerWorkerRadius.addListener((){
          setState(() {
            _workerDetails._radius = double.parse(_controllerWorkerRadius.text) ;
            _bWorkerIsUpdated = false;
          });
        });
        _controllerWorkerPlace.addListener((){
          _textForAutoCompleteWorkerChanged();
          setState(() {
            _bWorkerIsUpdated = false;
          });
        });            
      }
    });
    
    refreshJobs();
    
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
    
    var resFutureBoss = _services.getBossFieldDetails();
    resFutureBoss.then((res){
        if ((res["success"] == "true") || (res["success"] == true)) {
          _bossDetails = new BossDetails();

          _bossDetails._firstName = res["firstName"];
          _bossDetails._lastName = res["lastName"];
          _bossDetails._buisnessName = res["buisnessName"];
          _bossDetails._lat = res["lat"];
          _bossDetails._lng = res["lng"];
          _bossDetails._photoAGCSPath = res["photoAGCSPath"];
          _bossDetails._place = res["place"];
          
          _controllerWorkerFirstName.text = _bossDetails._firstName;
          _controllerWorkerLastName.text  = _bossDetails._lastName;
          _controllerBossBuisnessName.text  = _bossDetails._buisnessName;
          
          _controllerBossPlace.text     = _bossDetails._place;
          

          _controllerWorkerFirstName.addListener((){
            setState(() {
              _bossDetails._firstName = _controllerWorkerFirstName.text;
              _bWorkerIsUpdated = false;
            });
          }); 
          _controllerWorkerLastName.addListener((){
            setState(() {
              _bossDetails._lastName = _controllerWorkerLastName.text;
              _bWorkerIsUpdated = false;
            });
          });
           _controllerBossBuisnessName.addListener((){
            setState(() {
              _bossDetails._buisnessName = _controllerBossBuisnessName.text;
              _bWorkerIsUpdated = false;
            });
          });
          _controllerBossPlace.addListener((){
            _textForAutoCompleteBossChanged();
            setState(() {
              _bWorkerIsUpdated = false;
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
                _lPlacesWorkerDropDownList =[new DropdownMenuItem<String>(
                                          value: _currLocation.name ,
                                          child: new Text(_currLocation.name ),
                                      )];  
                _lPlacesBossDropDownList =[new DropdownMenuItem<String>(
                                          value: _currLocation.name ,
                                          child: new Text(_currLocation.name ),
                                      )];  
              });
            }
          });
      }).catchError((e) {
        print(e.toString());
      });
    } catch (e){
    }
    
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
           var h = MediaQuery.of(context).size.height;
           var w = _heightImage * _image.width / _image.height;
           setState(() {
                        
          
          _heightImage = h * 0.15;
          _heightSwitch = h * 0.05;
          _heightMain = h * 0.8;
          });
          String fileName = Singleton().persistentState.getString('profilePic');
          
          if (fileName == null){
            _image = new Image.asset('assets/img/no_portrait.png', fit: BoxFit.scaleDown, width: w, height: _heightImage);     
          } else {
            _image = Image.file(File(fileName), fit: BoxFit.scaleDown, width: w, height: _heightImage);
          }
          
        });
  }
  _textForAutoCompleteChanged(TextEditingController controller, List<DropdownMenuItem<String>> l) {
    String t = "${controller.text}";
    if ((t.length > 2) && (t.length > _tLength)) {
        setState(() {
          _bIsLoadingPlaces = true;
        });
        Location nearL = new Location(_currLocation.lat, _currLocation.lng);
        _placesAPI.queryAutocomplete(t, location: nearL, radius: 300000.0).then((res){   
          setState(() { 
            l.clear();
          });
          for (var i=0; i < res.predictions.length; i++ ) {
            setState(() {
              l.add(new DropdownMenuItem<String>(
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
          _bIsLoadingPlaces = false;
        });
    }
    _tLength = t.length;
  }
  _textForAutoCompleteBossChanged() {
    _textForAutoCompleteChanged(_controllerBossPlace, _lPlacesBossDropDownList);
  }
  _textForAutoCompleteWorkerChanged() {
    _textForAutoCompleteChanged(_controllerWorkerPlace, _lPlacesWorkerDropDownList);
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

  Widget _buildSwitchBar(BuildContext context) {
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
                      color: right,
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
                      color: left,
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
  bool _bBossMode = false;
  void _onWorkerButtonPress() {
    setState((){
      _bBossMode = false;
    });
    _pageController.animateToPage(0,
        duration: Duration(milliseconds: 500), curve: Curves.decelerate);
  }
  bool _bIsLoadingPlaces = false;
  void _onBossButtonPress() {
    setState((){
      _bBossMode = true;
    });
    _pageController?.animateToPage(1,
        duration: Duration(milliseconds: 500), curve: Curves.decelerate);
  }
  Widget _createTextField(String hintText, FocusNode focusNode, TextEditingController controller, IconData iconData, {keyboardType=TextInputType.text, maxLines = 1, validator=null}) {
    return new Padding(
      padding: EdgeInsets.only(
          top: 20.0, bottom: 20.0, left: 25.0, right: 25.0),
      child: TextField(
        focusNode: focusNode,
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        inputFormatters: validator==null?null:[validator],
        style: TextStyle(
            fontFamily: "WorkSansSemiBold",
            fontSize: 16.0,
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
              fontFamily: "WorkSansSemiBold", fontSize: 17.0),
          
        ),
      ),
    );
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
          
          child : Card
          (
            elevation: 2.0,
            color: Colors.white54,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: SingleChildScrollView(
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
                        new Flexible(child: _createTextField("פרטי", myFocusNodeFirstName, _controllerWorkerFirstName, FontAwesomeIcons.userAlt)),
                        new Flexible(child: _createTextField("משפחה", myFocusNodeLastName, _controllerWorkerLastName, FontAwesomeIcons.users)),
                      ]
                    ),
                  ),
                  Container(
                    width: 250.0,
                    height: 1.0,
                    color: Colors.grey[400],
                  ),
                  new Row(
                    children:<Widget>
                    [ 
                      new Flexible(child: _createTextField("מקום", myFocusNodePlace, _controllerWorkerPlace, FontAwesomeIcons.mapMarker)),
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
                                      items: _lPlacesWorkerDropDownList,
                                      onChanged: ((s)
                                      {
                                        _controllerWorkerPlace.text = s;
                                        _bWorkerIsUpdated = false;
                                        setPlaceLatLng(s, false);
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
                  _createTextField("מרחק", myFocusNodeRadius, _controllerWorkerRadius, FontAwesomeIcons.route, keyboardType: TextInputType.number),
                  Container(
                    width: 250.0,
                    height: 1.0,
                    color: Colors.grey[400],
                  ),
                  _createTextField("שכר", myFocusNodeWage, _controllerWorkerWage, FontAwesomeIcons.shekelSign, keyboardType: TextInputType.number),
                  Container(
                    width: 250.0,
                    height: 1.0,
                    color: Colors.grey[400],
                  ),
              ]
            )
          )
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

                _bWorkerIsUpdated = false;
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

  Widget _buildWorkerCarousel(BuildContext context) {
    var c = new CarosuelState(pages : <Widget>[
      new ConstrainedBox(
      constraints: const BoxConstraints.expand(),
      child: _buildWorkerDetails2(context),
    ),new ConstrainedBox(
      constraints: const BoxConstraints.expand(),
      child: _buildWorkerDetails1(context),
    ),]);
    return c.buildCarousel(context, _heightMain);
  }

  List<DropdownMenuItem<String>> _lJobsDropDownList =[new DropdownMenuItem<String>(
        value: "מאור",
        child: new Text("מאור"),
    )]; 
  
  
  List<DropdownMenuItem<String>> _lOccupationDropDown = [];
    
  Widget jobPage(BuildContext context, int index) {
    //bool bIsEmptyEntry = index==_lJobs.length - 1;
    bool bIsEmptyEntry = _lJobs.length == 0;
    JobsContext job;
    if (bIsEmptyEntry) {
      job = new JobsContext(new JobsDetails());
    } else {
      job = _lJobs[index];
      
      // setState(){
      //   jobPlaceController.text = (jd._place!=null?jd._place.toString():"");
      // }
      job.ui.conPlace.addListener((){
        _textForAutoCompleteChanged(job.ui.conPlace, _lJobsDropDownList);
        setState(() {
          _iJobIsUpdated = index;
          _idJobIsUpdated = job.details._jobId;
          _lJobs[index].details._place = job.ui.conPlace.text;
        });
      });  
      job.ui.conDiscription.addListener((){
        setState(() {
          _lJobs[index].details._discription = job.ui.conDiscription.text;
          _idJobIsUpdated = job.details._jobId;
          _iJobIsUpdated = index;    
        });
      });
      job.ui.conWage.addListener((){
        setState(() {
          _lJobs[index].details._wage = job.ui.conWage.text==""?29.12:double.parse(job.ui.conWage.text);
          _idJobIsUpdated = job.details._jobId;
          _iJobIsUpdated = index;        
        });
      });
      job.ui.connWorkers.addListener((){
        setState(() {
          _lJobs[index].details.nWorkers = job.ui.connWorkers.text==""?1:int.parse(job.ui.connWorkers.text);
          _idJobIsUpdated = job.details._jobId;
          _iJobIsUpdated = index;        
        });
      });
      job.ui.connOccupationList.addListener((){
      setState(() {
        _lJobs[index].details._lOccupationFieldListString = [];
          _lJobs[index].details._lOccupationFieldListString.add(job.ui.connOccupationList.text);
          _idJobIsUpdated = job.details._jobId;
          _iJobIsUpdated = index;        
        });
      });
    }
    
    
    _lOccupationDropDown = [];
    _lPossibleOccupation.forEach((f) => _lOccupationDropDown.add(
      new DropdownMenuItem<String>(
        value: f.toString(),
        child: new Text(f.toString()),
      )
    ));
    return new ConstrainedBox(
       constraints: const BoxConstraints.expand(),
      child:new Directionality(
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
          child: new SingleChildScrollView (
            child: new Column(
            children: 
                [
            Card(
              elevation: 2.0,
              color: Colors.white54,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: new SingleChildScrollView (
                child: bIsEmptyEntry?new Container():new Column(
                children: 
                [
                  Text("עבודה ${index+1} מתוך ${_lJobs.length}"),
                  Container(
                    width: 250.0,
                    height: 1.0,
                    color: Colors.grey[400],
                  ),
                  _createTextField("תאור מפורט של העבודה בכמה מילים", job.ui.fnDiscription, job.ui.conDiscription, Icons.edit, keyboardType: TextInputType.multiline, maxLines: 3),
                  Container(
                    width: 250.0,
                    height: 1.0,
                    color: Colors.grey[400],
                  ),
                  new Row(
                      children:<Widget> [ 
                        new Flexible(child: _createTextField("מקום", job.ui.fnPlace, job.ui.conPlace, FontAwesomeIcons.mapMarker)),
                        new Flexible(
                          child: Padding(
                            padding: EdgeInsets.only(top: 20.0, bottom: 20.0, left: 25.0, right: 25.0),
                            child: new SingleChildScrollView (
                              child: new Theme(
                                data: new ThemeData(
                                  fontFamily: "WorkSansSemiBold", 
                                  canvasColor: Colors.white54, //my custom color
                                ),
                                child: new DropdownButton(
                                  iconSize: 30.0,
                                  items: _lJobsDropDownList,
                                  onChanged: ((s) {
                                    setState(() {
                                      job.ui.conPlace.text = s;
                                      setPlaceLatLng(s, true, jobIndex : index);
                                      _idJobIsUpdated = job.details._jobId;
                                      _iJobIsUpdated = index;
                                      
                                    }); 
                                  }),
                                )
                              ),
                              scrollDirection: Axis.horizontal,
                            ) 
                            
                          )
                        )
                      ]
                    ),
                    Container(
                    width: 250.0,
                    height: 1.0,
                    color: Colors.grey[400],
                  ),
                  _createTextField("שכר", job.ui.fnWage, job.ui.conWage, FontAwesomeIcons.shekelSign, keyboardType: TextInputType.number),
                  new Row(
                            children:<Widget>
                            [ 
                              new Flexible(child: _createTextField("בחר תחום", job.ui.fnnOccupationList, job.ui.connOccupationList, FontAwesomeIcons.hammer)),
                              new Flexible(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      top: 20.0, bottom: 20.0, left: 25.0, right: 25.0),
                                    
                                    
                                      child: new Theme(
                                        data: new ThemeData(
                                          fontFamily: "WorkSansSemiBold", 
                                          canvasColor: Colors.white54, //my custom color
                                        ),
                                        child: new DropdownButton(
                                          iconSize: 30.0,
                                          items: _lOccupationDropDown,
                                          onChanged: ((s)
                                          {
                                            job.ui.connOccupationList.text = s;
                                            _iJobIsUpdated = index;
                                            _idJobIsUpdated = job.details._jobId;
                                          }),
                                        )
                                      ),
                                      
                                  )
                                )
                            ]
                          ),
                  _createTextField("מספר עובדים", job.ui.fnnWorkers, job.ui.connWorkers, FontAwesomeIcons.peopleCarry, keyboardType: TextInputType.number, validator: new BlacklistingTextInputFormatter(new RegExp('[\\.|\\,|\\-|\\ ]'))),
                  
                ]
              ))
            ), 
            Container(child: new Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                    Column(children: [ 
                      RawMaterialButton(
                      fillColor: Colors.green[300],
                      splashColor: Colors.white,
                      child: new Container(
                        decoration: new BoxDecoration(
                                                  
                        shape: BoxShape.circle,// You can use like this way or like the below line
                        //borderRadius: new BorderRadius.circular(30.0),
                        color: Colors.green[300],
                        
                      ),
                      child:  new Icon(Icons.add), 
                      ),                          
                      onPressed: ((){
                        
                          setState((){
                            _lJobs.add(new JobsContext(new JobsDetails()));
                            _jbcIndex = _lJobs.length - 1;
                          });
                        
                      }),
                      shape: new CircleBorder(),                          
                    ),  
                    Text('הוסף עבודה' ),
                    ]),
                    bIsEmptyEntry? Container() : Column(children: [ 
                    RawMaterialButton(
                      fillColor: Colors.blue[300],
                      splashColor: Colors.white,
                      child: new Container(
                        decoration: new BoxDecoration(
                                                  
                        shape: BoxShape.circle,// You can use like this way or like the below line
                        //borderRadius: new BorderRadius.circular(30.0),
                        color: Colors.blue[300],
                        
                      ),
                      child:  new Icon(FontAwesomeIcons.users), 
                      ),                          
                      onPressed: ((){
                        
                          setState((){
                            _lJobs.add(new JobsContext(new JobsDetails()));
                            _jbcIndex = _lJobs.length - 1;
                          });
                        
                      }),
                      shape: new CircleBorder(),                          
                    ),  
                    Text('עובדים' ),
                    ]),
                    bIsEmptyEntry? Container() : Column(children: [ RawMaterialButton(
                      fillColor: _lJobsIDsMarkedForDeletion.contains(_lJobs[index].details._jobId)?Colors.red[300]:Colors.grey[300],
                      splashColor: Colors.white,
                      child: new Container(
                        decoration: new BoxDecoration(
                                                  
                        shape: BoxShape.circle,// You can use like this way or like the below line
                        //borderRadius: new BorderRadius.circular(30.0),
                        color:  _lJobsIDsMarkedForDeletion.contains(_lJobs[index].details._jobId)?Colors.red[300]:Colors.grey[300],
                        
                      ),
                      child:  new Icon(FontAwesomeIcons.trashAlt), 
                      ),                          
                      onPressed: ((){
                        
                          setState((){
                            if (_lJobsIDsMarkedForDeletion.contains(_lJobs[index].details._jobId)) {
                              _lJobsIDsMarkedForDeletion.remove(_lJobs[index].details._jobId);    
                            } else {
                              _lJobsIDsMarkedForDeletion.add(_lJobs[index].details._jobId);
                            }
                            //_lJobs.removeAt(index);
                            _idJobIsUpdated = _lJobs[index].details._jobId;
                            _iJobIsUpdated = index;
                          });
                          
                      }),
                      shape: new CircleBorder(),                          
                    ),  
                    bIsEmptyEntry? Container():Text('מחק עבודה'),                  

                  ])])),
            ]))  
          )
        )
      );
  }

  int _jbcIndex = 0;
  Widget _buildJobsCarousel(BuildContext context, List<Widget> jbl) {
    if (_lJobs.length == 0) {
      jbl.add(jobPage(context, 0));
    } else {
    for (int i=0; i < _lJobs.length; i++) {
            jbl.add(jobPage(context, i));
    }
    }
    var c = new CarosuelState(pages : jbl);
    return c.buildCarousel(context, _heightMain);
  }
  Widget _buildBossCarousel(BuildContext context) {
    List<Widget> jbl = [];
    jbl.add(_buildBossDetails1(context));
    return _buildJobsCarousel(context, jbl);
  }
  
  // Widget _buildJobsDetailsList(BuildContext context) {
  //   return new Directionality(
  //     textDirection: TextDirection.rtl,
  //     child : new Container(
  //       decoration: new BoxDecoration(
  //       gradient: new LinearGradient(
  //             colors: [
  //               ZarizTheme.Colors.zarizGradientStart,
  //               ZarizTheme.Colors.zarizGradientEnd
  //             ],
  //             begin: const FractionalOffset(0.0, 0.0),
  //             end: const FractionalOffset(1.0, 1.0),
  //             stops: [0.0, 1.0],
  //             tileMode: TileMode.clamp),
  //       ),
  //       padding: EdgeInsets.only(top: 23.0),
  //       child: Column(
  //         children: <Widget>[
  //           Stack(
  //             alignment: Alignment.topCenter,
  //             overflow: Overflow.visible,
  //             children: <Widget>[
  //               Card(
  //                 elevation: 2.0,
  //                 color: Colors.white54,
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(8.0),
  //                 ),
  //                 child: new Stack(
  //                   children: [
  //                     SingleChildScrollView(child: new 
  //                       ListView.builder( 
  //                         shrinkWrap: true,
  //                         padding: EdgeInsets.only(
  //                               top: 20.0, bottom: 20.0, left: 25.0),
  //                         itemCount: _lJobs.length,
  //                         itemBuilder: (BuildContext context, int index) {
  //                           return   Container(height:120.0, child: new Row(children: <Widget>[
  //                             RawMaterialButton(
  //                               fillColor: index!=_lJobs.length? Colors.green[300] :Colors.red[300],
  //                               splashColor: Colors.white,
  //                               child: new Container(
  //                                 decoration: new BoxDecoration(                          
  //                                   shape: BoxShape.circle,
  //                                   color: Colors.green,
  //                               ),
  //                               child:  index!=_lJobs.length? new Icon(Icons.add) : new Icon(FontAwesomeIcons.trashAlt), 
  //                               ), 
  //                               onPressed: ((){
  //                               }),
  //                               shape: new CircleBorder(),
                                
  //                             ),
                        
  //                             Text('${_lJobs[index].details._discription}'),
  //                           ]));
  //                         }
  //                       )
  //                     ),
  //                   ]
  //                 )
  //               ),  
  //             ],
  //           )
  //         ]
  //       )
  //     )
  //   );
  // }
  Widget _buildBossDetails1(BuildContext context) {
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
                    //   //width: MediaQuery.of(context).size.width * 5 / 6,
                    //   //height: MediaQuery.of(context).size.height * 2,
                       child: new Column( children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(
                                top: 20.0, bottom: 20.0, left: 25.0, right: 25.0),
                            child: 
                            new Row(
                              children:<Widget>
                              [ 
                                new Flexible(child: _createTextField("פרטי", myFocusNodeBossFirstName, _controllerWorkerFirstName, FontAwesomeIcons.userAlt)),
                                new Flexible(child: _createTextField("משפחה", myFocusNodeBossLastName, _controllerWorkerLastName, FontAwesomeIcons.users)),
                                
                              ]
                            ),
                          ),
                          Container(
                            width: 250.0,
                            height: 1.0,
                            color: Colors.grey[400],
                          ),
                          new SingleChildScrollView(
                             child: _createTextField("שם העסק", myFocusNodeBossBuisnessName, _controllerBossBuisnessName, FontAwesomeIcons.userAlt),
                          ),
                                                 
                          new Row(
                            children:<Widget>
                            [ 
                              new Flexible(child: _createTextField("מקום", myFocusNodeBossPlace, _controllerBossPlace, FontAwesomeIcons.mapMarker)),
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
                                        child: new DropdownButton(
                                          iconSize: 30.0,
                                          items: _lPlacesBossDropDownList,
                                          onChanged: ((s)
                                          {
                                            _controllerBossPlace.text = s;
                                            _bWorkerIsUpdated = false;
                                            setPlaceLatLng(s, true);
                                          }),
                                        )
                                      ),
                                      scrollDirection: Axis.horizontal, 
                                    )
                                  )
                                )
                            ]
                          ),
                          Container(
                            width: 250.0,
                            height: 1.0,
                            color: Colors.grey[400],
                          ),
                        ]
                      )
                    )
                  ),
                ],
              ),
            ],
          ),
        ),          
      );
  } 
}
class InvertedCircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return new Path()
      ..addOval(new Rect.fromCircle(
          center: new Offset(size.width / 2, size.height / 2),
          radius: size.width * 0.45))
      ..addRect(new Rect.fromLTWH(0.0, 0.0, size.width, size.height))
      ..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

String numberValidator(String value) {
  if(value == null) {
    return null;
  }
  try {
    final num = int.parse(value, onError: (value) => null);
    if (num <= 0) {
      return '"$value" is not a valid number';
    }
    if(num == null) {
      return '"$value" is not a valid number';
    }
  } catch (e) {
    return '"$value" is not a valid number';
  }
  
  return null;
}

class AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}