import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:utf/utf.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zariz_app/style/theme.dart' as ZarizTheme;
import 'package:zariz_app/utils/bubble_indication_manual_painter.dart';
import 'package:zariz_app/utils/Services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import 'package:google_maps_webservice/places.dart';
import 'package:flutter/cupertino.dart';
import 'package:zariz_app/ui/page_carousel.dart';
//import 'package:convert/convert.dart';

import 'package:location/location.dart' as LocationGPS;

import 'package:flutter/rendering.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info/device_info.dart';
import 'package:zariz_app/ui/uiUtils.dart';
import 'package:zariz_app/ui/Job_confirmDialog.dart';
import 'package:zariz_app/ui/Job_confirmHireDialog.dart';
import 'package:zariz_app/ui/Job_confirmFiredDialog.dart';
import 'package:latlong/latlong.dart';

final Map<String, Item> _items = <String, Item>{};
Item _itemForMessage(Map<String, dynamic> message) {
  final String itemId = message['data']['id'];
  final Item item = _items.putIfAbsent(itemId, () => Item(itemId: itemId))
    ..status = message['data']['status'];
  return item;
}

class Item {
  Item({this.itemId});

  static final Map<String, Route<void>> routes = <String, Route<void>>{};

  final String itemId;

  StreamController<Item> _controller = StreamController<Item>.broadcast();
  String _status;

  Stream<Item> get onChanged => _controller.stream;

  String get status => _status;

  set status(String value) {
    _status = value;
    _controller.add(this);
  }

  Route<void> get route {
    final String routeName = '/detail/$itemId';
    return routes.putIfAbsent(
      routeName,
      () => MaterialPageRoute<void>(
            settings: RouteSettings(name: routeName),
            builder: (BuildContext context) => DetailPage(itemId),
          ),
    );
  }
}
class DetailPage extends StatefulWidget {
  DetailPage(this.itemId);

  final String itemId;

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  Item _item;
  StreamSubscription<Item> _subscription;

  @override
  void initState() {
    super.initState();
    _item = _items[widget.itemId];
    _subscription = _item.onChanged.listen((Item item) {
      if (!mounted) {
        _subscription.cancel();
      } else {
        setState(() {
          _item = item;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Item ${_item.itemId}"),
      ),
      body: Material(
        child: Center(child: Text("Item status: ${_item.status}")),
      ),
    );
  }
}
class CurrentLocation {
  double lat = 0.0;
  double lng = 0.0;
  String name = "Maor";
}
class BossDetails{
    String _buisnessName;
    String _firstName;
    String _lastName;
    double _lat;
    double _lng;
    List<String> _lOccupationFieldListString;
    String _photoAGCSPath;
    String _place;
    int _userID;

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
  List<WorkerDetails> lWorkersAuthorized;
  List<WorkerDetails> lWorkersHired;
  List<WorkerDetails> lWorkersNotified;
  List<WorkerDetails> lWorkersResponded;
  JobsUI ui;

  JobsContext(JobsDetails details) {
    this.details = details;
    this.ui = new JobsUI(this.details);
    print("lWorkersNotified Cleared");
    this.lWorkersNotified = [];
    this.lWorkersAuthorized = [];
    this.lWorkersResponded = [];
    this.lWorkersHired = [];
  }
}
class JobsUI{
  TextEditingController conDiscription;
  TextEditingController connOccupationList;
  TextEditingController connWorkers;
  TextEditingController conPlace;
  TextEditingController conWage;
  FocusNode fnDiscription;
  AlwaysDisabledFocusNode fnnOccupationList;
  FocusNode fnnWorkers;
  FocusNode fnPlace;
  FocusNode fnWage;

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
    int nWorkers;

    String _discription;
    String _jobId = "-1";
    double _lat;
    double _lng;
    List<String> _lOccupationFieldListString = [];
    String _place;
    double _wage;

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
    double _lat;
    double _lng;
    List<String> _lOccupationFieldListString;
    String _photoAGCSPath;
    String _place;
    double _radius;
    int _userID;
    double _wage;

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
      'lOccupationFieldListString' : _lOccupationFieldListString==null?"":fixDecoding(_lOccupationFieldListString)
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

  final IconData icon;
  final String title;
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
  AppBarChoice(title: 'jobs', icon: FontAwesomeIcons.screwdriver),
  AppBarChoice(title: 'logoff', icon: FontAwesomeIcons.signOutAlt),
  AppBarChoice(title: 'debug', icon: FontAwesomeIcons.bug),
  AppBarChoice(title: 'feed', icon: FontAwesomeIcons.solidBell),
];

class ProfilePage extends StatefulWidget {
  ProfilePage({Key key}) : super(key: key);

  @override
  _ProfilePageState createState() => new _ProfilePageState();
}

//enum SortType {LastName, FirstName, DistFromLocation, DistFromAddress}
final List<String> _sSortWorkersForJob = ['מיין לפי שם משפחה', 'מיין לפי שם פרטי', 'מיין לפי מרחק ממיקום נוכחי', 'מיין לפי מרחק מכתובת העסק'];

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  static final checkedColor = ZarizTheme.Colors.zarizGradientEnd.withAlpha(240);
  static double hDefault = 775.0;
  static final String kGoogleApiKey = "AIzaSyCKbtYyIOqIe1mmCIPIp_wezViTi2JHiC0";
  static final uncheckedColor = ZarizTheme.Colors.zarizGradientEnd.withAlpha(64);

  int iCs = 0;
  Color left = Colors.black;
  final FocusNode myFocusNodeBossBuisnessName = FocusNode();
  final FocusNode myFocusNodeBossFirstName    = FocusNode();
  final FocusNode myFocusNodeBossLastName     = FocusNode();
  final FocusNode myFocusNodeBossPlace        = FocusNode();
  final FocusNode myFocusNodeEmail = FocusNode();
  final FocusNode myFocusNodeFirstName = FocusNode();
  final FocusNode myFocusNodeLastName = FocusNode();
  final FocusNode myFocusNodePlace = FocusNode();
  final FocusNode myFocusNodeRadius = FocusNode();
  final FocusNode myFocusNodeWage = FocusNode();
  Color right = Colors.white;

  static final List<String> _lDefaultPossibleOccupation = ["א","ב","ג","ד","ה","ו","ז","ח","ט","י","כ","ל","מ","נ","ס","ע","פ","צ","ק","ר","ש","ת"];
  


  AndroidDeviceInfo _androidInfo;
  bool _bBossMode = false;
  bool _bExpandOccupation = false;
  bool _bIsLoadingPlaces = false;
  bool _bJobMenu = false;
  BossDetails _bossDetails = new BossDetails();
  bool _bShrinkJobMenu = false;
  bool _bUpdatingDetails = false;
  bool _bWorkerIsUpdated = true;
  List<Color> _colorOccupation =  new List<Color>.filled(_lDefaultPossibleOccupation.length, uncheckedColor);
  TextEditingController _controllerBossBuisnessName = new TextEditingController();
  TextEditingController _controllerBossPlace = new TextEditingController();
  TextEditingController _controllerWorkerFirstName = new TextEditingController();
  TextEditingController _controllerWorkerLastName = new TextEditingController();
  TextEditingController _controllerWorkerPlace = new TextEditingController();
  TextEditingController _controllerWorkerRadius = new TextEditingController();
  TextEditingController _controllerWorkerWage = new TextEditingController();
  CarosuelState _cs;
  String _currentJobId = "";
  CurrentLocation _currLocation = new CurrentLocation();
  List<String> _filters = <String>[];
  String _firebase_token = "";
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  double _heightImage = hDefault * 0.15;
  double _heightMain = hDefault * 0.7;
  double _heightSwitch = hDefault * 0.05;
  String _homeScreenText = "Waiting for token...";
  String _idJobIsUpdated = "";
  int _iJobIsUpdated = -1;
  Image _image = new Image.asset('assets/img/no_portrait.png', fit: BoxFit.scaleDown, width: 250.0, height: 191.0);
  String _imageFileBase64Data = "";
  Item _item;
  int _iTest =0;
  var _jobPlaceText="בחר תחום";
  List<JobsContext> _lJobs = [];
  List<DropdownMenuItem<String>> _lJobsDropDownList =[new DropdownMenuItem<String>(
        value: "מאור",
        child: new Text("מאור"),
    )]; 

  List<String> _lJobsIDsMarkedForDeletion = [];
  List<GlobalKey> _lKeyForJobDiscription;
  List<DropdownMenuItem<String>> _lOccupationDropDown = [];
  List<DropdownMenuItem<String>> _lPlacesBossDropDownList =[new DropdownMenuItem<String>(
                                          value: "מאור",
                                          child: new Text("מאור"),
                                      )];     

  List<DropdownMenuItem<String>> _lPlacesWorkerDropDownList =[new DropdownMenuItem<String>(
                                          value: "מאור",
                                          child: new Text("מאור"),
                                      )];                    

  List<String> _lPossibleOccupation = _lDefaultPossibleOccupation;
  PageController _pageController;
  List<Widget> _pages;
  GoogleMapsPlaces _placesAPI = new GoogleMapsPlaces(apiKey:kGoogleApiKey);
  String _profileTitleBoss = "פרופיל מעסיק";
  String _profileTitleBossJobs = "עבודות מעסיק";
  String _profileTitleWorker = "פרופיל עובד";
  String _profileTitleWorkerJobs = "עבודות עובד";
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  List<bool> _selectedOccupation = new List<bool>.filled(_lDefaultPossibleOccupation.length, false);
  Services _services = new Services();
  StreamSubscription<Item> _subscription;
  Animation _switchAnim;
  AnimationController _switchAnimController;
  //CurvedAnimation _switchAnimCurve;
  Animation<double> _switchAnimCurve;

  TabIndicationPainterNoPageControllerListener _tabIndicationPainterNoPageControllerListener = new TabIndicationPainterNoPageControllerListener(iPos:0, nPages:2);
  int _tLength = 2;
  double _widthSwitch = hDefault * 0.5;
  WorkerDetails _workerDetails = new WorkerDetails();
  
  int _sortTypeWorkersForJob=0;
  bool _bSortAsscending = true;
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
  //AnimationController _controllerAnimation;
  Color _zarizGradientColorAnimation;

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
    _switchAnimController.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _switchAnimController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    )..addListener((){
        this.setState(() {});
      })..addStatusListener((status){
        // if (status == AnimationStatus.completed) {
        //   _switchAnimController.reverse();
        // } else if (status == AnimationStatus.dismissed) {
        //   _switchAnimController.forward();
        // }
    });
    
    _switchAnimCurve = new Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _switchAnimController,
          curve: Interval(
            0.0, 1.0,
          curve: Curves.easeInOut,
        ),
      ),
    );
    //_switchAnim = _switchAnimCurve.animate(_switchAnimController);
    _switchAnimController.forward(); 

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    deviceInfo.androidInfo.then((v){
      _androidInfo=v;
      print('DeviceInfo - brand ${v.brand}, model ${v.model}, phisical device ${v.isPhysicalDevice}, id ${v.id}');
    });
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message" );
        if (message["data"]["message_status"] == "Offer")
        {
          String sMsg = "${message["data"]["discription"]} \n";
          sMsg+= "\nהצעת עבודה מ${message["data"]["firstName"]} ${message["data"]["lastName"]} \n";
          sMsg+="שכר ${message["data"]["wage"]}\n";
          sMsg+="מיקום ${message["data"]["place"]}\n";
          final res = Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => JobConfirmPage(sTitle:sMsg, jobID: message["data"]["jobID"],)),
          );
          res.then((s){
              print("confirm job before refresh");
              var res2 = refreshJobs();
          }); 
        }
        else  if (message["data"]["message_status"] == "Hired") {
          String sMsg = "${message["data"]["discription"]} \n";
          sMsg+= "\n התקבלת לעבודה על ידי ${message["data"]["firstName"]} ${message["data"]["lastName"]} \n";
          sMsg+="שכר ${message["data"]["wage"]}\n";
          sMsg+="מיקום ${message["data"]["place"]}\n";
          final res = Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => JobConfirmHirePage(sTitle:sMsg, jobID: message["data"]["jobID"], workerID :  message["data"]["workerID"],)),
          );
          res.then((s){
              print("hire job before refresh");
              var res2 = refreshJobs();
          });
        }
        else  if (message["data"]["message_status"] == "Fired") {
          
          var resUpdateFired = _services.confirmHire(message["data"]["jobID"], message["data"]["workerID"], false);
          resUpdateFired.then((s){
              print("fired job status updated");
          });
          String sMsg = "${message["data"]["discription"]} \n";
          sMsg+= "\n הוחלט שלא להעסיק אותך! ${message["data"]["firstName"]} ${message["data"]["lastName"]} \n";
          sMsg+="שכר ${message["data"]["wage"]}\n";
          sMsg+="מיקום ${message["data"]["place"]}\n";
          final res = Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => JobConfirmFiredPage(sTitle:sMsg, jobID: message["data"]["jobID"], workerID :  message["data"]["workerID"],)),
          );
          res.then((s){
              print("fired job before refresh");
              var res2 = refreshJobs();
          });
        }
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
        if (message["data"]["message_status"] == "Offer")
        {
          String sMsg = "${message["data"]["discription"]} \n";
          sMsg+= "\nהצעת עבודה מ${message["data"]["firstName"]} ${message["data"]["lastName"]} \n";
          sMsg+="שכר ${message["data"]["wage"]}\n";
          sMsg+="מיקום ${message["data"]["place"]}\n";
          final res = Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => JobConfirmPage(sTitle:sMsg, jobID: message["data"]["jobID"])),
          );
          res.then((s){
              print("confirm job before refresh");
              var res2 = refreshJobs();
          }); 
        }
        else  if (message["data"]["message_status"] == "Hired") {
          String sMsg = "${message["data"]["discription"]} \n";
          sMsg+= "\nהתקבלת לעבודה על ידי ${message["data"]["firstName"]} ${message["data"]["lastName"]} \n";
          sMsg+="שכר ${message["data"]["wage"]}\n";
          sMsg+="מיקום ${message["data"]["place"]}\n";
          final res = Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => JobConfirmHirePage(sTitle:sMsg, jobID: message["data"]["jobID"], workerID :  message["data"]["workerID"],)),
          );
          res.then((s){
              print("hire job before refresh");
              var res2 = refreshJobs();
          });
        }
        else  if (message["data"]["message_status"] == "Fired") {
          String sMsg = "${message["data"]["discription"]} \n";
          sMsg+= "\nהוחלט שלא להעסיק אותך! ${message["data"]["firstName"]} ${message["data"]["lastName"]} \n";
          sMsg+="שכר ${message["data"]["wage"]}\n";
          sMsg+="מיקום ${message["data"]["place"]}\n";
          final res = Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => JobConfirmFiredPage(sTitle:sMsg, jobID: message["data"]["jobID"], workerID :  message["data"]["workerID"],)),
          );
          res.then((s){
              print("fired job before refresh");
              var res2 = refreshJobs();
          });
        }
       
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
        if (message["data"]["message_status"] == "Offer")
        {
          String sMsg = "${message["data"]["discription"]} \n";
          sMsg+= "\nהצעת עבודה מ${message["data"]["firstName"]} ${message["data"]["lastName"]} \n";
          sMsg+="שכר ${message["data"]["wage"]}\n";
          sMsg+="מיקום ${message["data"]["place"]}\n";
          final res = Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => JobConfirmPage(sTitle:sMsg, jobID: message["data"]["jobID"],)),
          );
          res.then((s){
              print("confirm job before refresh");
              var res2 = refreshJobs();
          }); 
        }
        else  if (message["data"]["message_status"] == "Hired") {
          String sMsg = "${message["data"]["discription"]} \n";
          sMsg+= "\nהתקבלת לעבודה על ידי ${message["data"]["firstName"]} ${message["data"]["lastName"]} \n";
          sMsg+="שכר ${message["data"]["wage"]}\n";
          sMsg+="מיקום ${message["data"]["place"]}\n";
          final res = Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => JobConfirmHirePage(sTitle:sMsg, jobID: message["data"]["jobID"], workerID :  message["data"]["workerID"],)),
          );
          res.then((s){
              print("hire job before refresh");
              var res2 = refreshJobs();
          });
        }
        else  if (message["data"]["message_status"] == "Fired") {
          String sMsg = "${message["data"]["discription"]} \n";
          sMsg+= "\nהוחלט שלא להעסיק אותך! ${message["data"]["firstName"]} ${message["data"]["lastName"]} \n";
          sMsg+="שכר ${message["data"]["wage"]}\n";
          sMsg+="מיקום ${message["data"]["place"]}\n";
          final res = Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => JobConfirmFiredPage(sTitle:sMsg, jobID: message["data"]["jobID"], workerID :  message["data"]["workerID"],)),
          );
          res.then((s){
              print("fired job before refresh");
              var res2 = refreshJobs();
          });
        }
      },
    );
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
    _firebaseMessaging.getToken().then((String token) {
      assert(token != null);
      setState(() {
        _homeScreenText = "Push Messaging token: $token";
        _firebase_token = token;
        _services.registerDevice(_androidInfo.model, 'Android', _androidInfo.id, token);
      });
      print(_homeScreenText);
    });

    //_switchAnimCurve = CurvedAnimation(parent: _switchAnimController, curve: Curves.elasticInOut);
    var resFuture = _services.getFieldDetails();
    resFuture.then((res) {
      if ((res["success"] == "true") || (res["success"] == true)) {
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
    
    var res2 = refreshJobs();
          // res2.then((bSuccess){ 
          //   if (bSuccess)
          //   {
          //     setState((){});
          //   }
          // }); 
    
    var resFuture2 = _services.getOccupationDetails();
    resFuture2.then((res){
        if ((res["success"] == "true") || (res["success"] == true)) {
          setState(() {
            _lPossibleOccupation = fixEncoding(res["possibleFields"]);
            _workerDetails._lOccupationFieldListString = fixEncoding(res["pickedFields"]);
            _colorOccupation = new List<Color>.filled(_lPossibleOccupation.length, uncheckedColor);
            _selectedOccupation = new List<bool>.filled(_lPossibleOccupation.length, false);
            _workerDetails._lOccupationFieldListString.forEach((e) {
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
          var res = _placesAPI.searchNearbyWithRadius(loc, 1000.0, language: "iw");
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
        setState(() {
        _currLocation.name = 'מאור';
        _currLocation.lat  = 32.423924;
        _currLocation.lng  = 35.006394;
         _lPlacesWorkerDropDownList =[new DropdownMenuItem<String>(
                                          value: _currLocation.name ,
                                          child: new Text(_currLocation.name ),
                                      )];  
                _lPlacesBossDropDownList =[new DropdownMenuItem<String>(
                                          value: _currLocation.name ,
                                          child: new Text(_currLocation.name ),
                                      )];  
        });
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
          _widthSwitch = _heightSwitch*10;
          _heightMain = h * 0.75;
          });
          String fileName;
          try {
            String fileName = Singleton().persistentState.getString('profilePic');
          } catch (e) {
            
          }
          
          
          if (fileName == null){
            _image = new Image.asset('assets/img/no_portrait.png', fit: BoxFit.cover, width: w, height: _heightImage);     
          } else {
            _image = Image.file(File(fileName), fit: BoxFit.cover, width: w, height: _heightImage);
          }
          
        });
  }

  void _select(AppBarChoice choice) {
    // Causes the app to rebuild with the new _selectedChoice.
    setState(() {
      if (choice.title == "update") {
        _bUpdatingDetails = true;
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
          if (_idJobIsUpdated=="-1") {
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
          var res2 = refreshJobs();
          res2.then((bSuccess){ 
            if (bSuccess)
            {
              setState((){_bUpdatingDetails=false;});
            }
          });
        } 
      }
      if (choice.title == "jobs") {
          setState(() {
            _bJobMenu=!_bJobMenu;
          });
      }
      // if (choice.title == "debug") {
      //     print(_workerDetails.toString());
      //     debugDumpApp();
      //     debugDumpRenderTree();
      // }
    });
  }

  void setPlaceLatLng(String sPlace, bool bIsBoss, {int jobIndex=-1}) {
    _placesAPI.searchByText(sPlace, language : "iw").then((a) {
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
      .addListener(new ImageStreamListener((ImageInfo info, bool _) => completer.complete(info)));
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

  //Animation<Color> _zarizGradientColorAnimation;
  Decoration decorationBossWorker(BuildContext context, bool bIsWorker)  {
    try {
      setState(() {
      //_controllerAnimation = AnimationController(
      //vsync: this,
      //duration: Duration(
      //seconds: 5),);;
        _zarizGradientColorAnimation = bIsWorker?ZarizTheme.Colors.zarizGradientStart2:ZarizTheme.Colors.zarizGradientStart1;
    // ColorTween(
    //   begin: bIsWorker?ZarizTheme.Colors.zarizGradientStart1:ZarizTheme.Colors.zarizGradientStart2,
    //   end: bIsWorker?ZarizTheme.Colors.zarizGradientStart2:ZarizTheme.Colors.zarizGradientStart1).
    //   animate(_controllerAnimation);
      });
    } catch (e) {
      print(e);
      // This is a hack to fix the exception - setState() or markNeedsBuild() called during build.
      // This is due to it always failing when a message is arrived at the same time the job live page is built.
      (Future<Decoration>.delayed(new Duration(milliseconds: 500), (()  {return decorationBossWorker(context, bIsWorker);}))).then((d) {return d;});
    }
    
    
    return new BoxDecoration(
          gradient: new LinearGradient(
          colors: [
            _zarizGradientColorAnimation==null?(bIsWorker?ZarizTheme.Colors.zarizGradientStart2:ZarizTheme.Colors.zarizGradientStart1):
              _zarizGradientColorAnimation,
            ZarizTheme.Colors.zarizGradientEnd
          ],
          begin: const FractionalOffset(0.0, 0.0),
          end: const FractionalOffset(1.0, 1.0),
          stops: [0.0, 1.0],
          tileMode: TileMode.clamp),
    );
  }

  Widget buildInternal(BuildContext context) {
    _pages =  [new AnimatedCrossFade(
                  firstChild: _buildMainJobsCarousel(context),
                  secondChild: _buildWorkerDetails1(context),
                  duration: const Duration(milliseconds: 500),
                  crossFadeState: _bJobMenu? CrossFadeState.showFirst : CrossFadeState.showSecond,
                ),
                new AnimatedCrossFade(
                  firstChild: _buildMainJobsCarousel(context),
                  secondChild: _buildBossDetails1(context),
                  duration: const Duration(milliseconds: 500),
                  crossFadeState: _bJobMenu? CrossFadeState.showFirst : CrossFadeState.showSecond,
                ),
              ];
    return new Flexible(
      child: AnimatedCrossFade(
                  firstChild: _pages[0],
                  secondChild: _pages[1],
                  duration: const Duration(milliseconds: 500),
                  crossFadeState: _bBossMode ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                ));
     // flex: 2,
    //   child: PageView(
    //     controller: _pageController,
    //     onPageChanged: (i) {
    //       if (i == 0) {
    //         setState(() {
    //           right = Colors.white;
    //           left = Colors.black;
    //         });
    //       } else if (i == 1) {
    //         setState(() {
    //           right = Colors.black;
    //           left = Colors.white;
    //         });
    //       }
    //     },
    //     children: 
    //       _pages,
        
    //   ),
    // );
  }

  Widget buildFrame(BuildContext context, Widget internalWidget, GlobalKey<ScaffoldState> scaffoldKey)
  {
    return new Directionality(
      textDirection: TextDirection.rtl,
        child : new Scaffold(
        appBar: AppBar(
        title: FittedBox(
          child: Text(_bBossMode?(_bJobMenu?_profileTitleBossJobs:_profileTitleBoss):(_bJobMenu?_profileTitleWorkerJobs:_profileTitleWorker)),
          fit: BoxFit.scaleDown,
        ),
        actions: <Widget>[
              LayoutBuilder(builder: (context, constraint) {
                return new IconButton(
                  icon: new Icon(FontAwesomeIcons.check, size:constraint.biggest.height*0.5),
                  onPressed: () {
                    _select(choices[0]); 
                  },
                  color: (_bWorkerIsUpdated && _iJobIsUpdated == -1) ? Colors.green: Colors.red,
                  tooltip: (_bWorkerIsUpdated && _iJobIsUpdated == -1) ? "מעודכן":"עדכן",
                 
                );
              }),
              // action button
              LayoutBuilder(builder: (context, constraint) {
                return new IconButton(
                  icon: _bJobMenu?
                    Icon(FontAwesomeIcons.pencilAlt, size:constraint.biggest.height*0.45, color: ZarizTheme.Colors.zarizGradientStart2):
                    Icon(FontAwesomeIcons.hammer, size:constraint.biggest.height*0.45, color: ZarizTheme.Colors.zarizGradientStart),
                  tooltip: _bJobMenu? "עריכת פרטים":"הצגת עבודות",
                  onPressed: () {
                    _select(choices[1]);
                  },
                );
              }),
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
        key: scaffoldKey,
        body: NotificationListener<OverscrollIndicatorNotification>(
          onNotification: (overscroll) {
            overscroll.disallowGlow();
            return false;
          },

                child: AnimatedContainer(
                  duration: new Duration(milliseconds:500),
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height >= hDefault
                      ? MediaQuery.of(context).size.height
                      : hDefault,
                  
                  decoration: decorationBossWorker(context,_bBossMode),
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(top: 2.0),
                        child: new FlatButton(
                          onPressed: onImagePressed,
                          child:  new ClipRRect(
                            child: _image,
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                        ),   
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 2.0, bottom: 5.0),
                        child: _buildSwitchBar(context),
                      ),
                      (_bIsLoadingPlaces || _bUpdatingDetails) ? new CircularProgressIndicator(backgroundColor: ZarizTheme.Colors.zarizGradientStart):new Container(),
                      internalWidget,
                    ],
                  ),
                ),

        ),
      ),
    );
  }

  Widget build(BuildContext context) {
    return buildFrame(context, buildInternal(context), _scaffoldKey);
  }

  Future<bool> refreshJobs() async {

    _services.getAllJobsAsBoss().then((res){
    if (res["success"] == "true" || res["success"] == true)
     {

        _lJobs = [];
        for (int i=0;i<(res.length - 1);i++) 
        {
          var j=res[i.toString()];
          _lJobs.add(new JobsContext(new JobsDetails()..nWorkers=j["nWorkers"].._place=j["place"].._jobId=j["jobID"].._discription=j["discription"].._lat=j["lat"].._lng=j["lng"].._wage=j["wage"].._lOccupationFieldListString=[j["occupationFieldListString"]]));
          _lJobs[i].details.nWorkers = j["nWorkers"];
          j["workerID_responded"].forEach((workers)
          {
            var resFuture = _services.getWorkerDetailsForID(workers);
            resFuture.then((res)
            {
              if ((res["success"] == "true") || (res["success"] == true)) {
                try {
                      var oldVal = _lJobs[i].lWorkersResponded.firstWhere((a) => a._userID == res["userID"]);
                      _lJobs[i].lWorkersResponded.remove(oldVal);
                    } catch (e){

                    }
                _lJobs[i].lWorkersResponded.add(new WorkerDetails().._firstName=res["firstName"].._lastName=res["lastName"].._lat=res["lat"]..
                  _lng=res["lng"].._photoAGCSPath=res["_photoAGCSPath"].._radius = res["radius"].._wage = res["wage"].._place = res["place"].._userID=res["userID"]);
              }
              else
              {
                return false;
              }
              setState(() {
                    _lJobs[i].lWorkersResponded=_lJobs[i].lWorkersResponded;
                  });
            });
          });
            j["workerID_sentNotification"].forEach((workers)
            {
              var resFuture = _services.getWorkerDetailsForID(workers);
              resFuture.then((res) 
              {
                if ((res["success"] == "true") || (res["success"] == true))
                {
                  try {
                      var oldVal = _lJobs[i].lWorkersNotified.firstWhere((a) => a._userID == res["userID"]);
                      _lJobs[i].lWorkersNotified.remove(oldVal);
                    } catch (e){

                    }
                  _lJobs[i].lWorkersNotified.add(new WorkerDetails().._firstName=res["firstName"].._lastName=res["lastName"].._lat=res["lat"]..
                    _lng=res["lng"].._photoAGCSPath=res["_photoAGCSPath"].._radius = res["radius"].._wage = res["wage"].._place = res["place"].._userID=res["userID"]);
                }
                else
                {
                  return false;
                }
                setState(() {
                    _lJobs[i].lWorkersNotified=_lJobs[i].lWorkersNotified;
                  });
              });
            });
              j["workerID_authorized"].forEach((workers)
              {
                var resFuture = _services.getWorkerDetailsForID(workers);
                resFuture.then((res) 
                {
                  if ((res["success"] == "true") || (res["success"] == true)) 
                  {
                    try {
                      var oldVal = _lJobs[i].lWorkersAuthorized.firstWhere((a) => a._userID == res["userID"]);
                      _lJobs[i].lWorkersAuthorized.remove(oldVal);
                    } catch (e){

                    }
                    _lJobs[i].lWorkersAuthorized.add(new WorkerDetails().._firstName=res["firstName"].._lastName=res["lastName"].._lat=res["lat"]..
                      _lng=res["lng"].._photoAGCSPath=res["_photoAGCSPath"].._radius = res["radius"].._wage = res["wage"].._place = res["place"].._userID=res["userID"]);
                  }
                  else
                  {
                    return false;
                  }
                  setState(() {
                    _lJobs[i].lWorkersAuthorized=_lJobs[i].lWorkersAuthorized;
                  });
                });
              });
              j["workerID_hired"].forEach((workers)
              {
                var resFuture = _services.getWorkerDetailsForID(workers);
                resFuture.then((res) 
                {
                  if ((res["success"] == "true") || (res["success"] == true)) 
                  {
                    try {
                      var oldVal = _lJobs[i].lWorkersHired.firstWhere((a) => a._userID == res["userID"]);
                      _lJobs[i].lWorkersHired.remove(oldVal);
                    } catch (e){

                    }
                    _lJobs[i].lWorkersHired.add(new WorkerDetails().._firstName=res["firstName"].._lastName=res["lastName"].._lat=res["lat"]..
                      _lng=res["lng"].._photoAGCSPath=res["_photoAGCSPath"].._radius = res["radius"].._wage = res["wage"].._place = res["place"].._userID=res["userID"]);
                  }
                  else
                  {
                    return false;
                  }
                  setState(() {
                    _lJobs[i].lWorkersHired=_lJobs[i].lWorkersHired;
                  });
                });
              });
        
          
          
          print("refreshJobs, !!!!!!!!!! job #$i - _lJobs[i].lWorkersNotified.length ${_lJobs[i].lWorkersNotified.length}");
        }

      }
    });
    return true;
  }

  void onImagePressed(){
      getImage();
  }

  _textForAutoCompleteChanged(TextEditingController controller, List<DropdownMenuItem<String>> l) {
    String t = "${controller.text}";
    if ((t.length > 2) && (t.length > _tLength)) {
        setState(() {
          _bIsLoadingPlaces = true;
        });
        Location nearL = new Location(_currLocation.lat, _currLocation.lng);
        _placesAPI.queryAutocomplete(t, location: nearL, radius: 300000.0, language : "iw").then((res){   
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
      content: new Directionality(
        textDirection: TextDirection.rtl,
        child : new Card(child: new Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
            color: Colors.white,
            fontSize: 16.0,
            fontFamily: "WorkSansSemiBold"),
      ))),
      backgroundColor: Color(0xFF6aa1c),
      duration: Duration(seconds: 3),
    ));
  }

  double switchAnimCurveValue() {
    double delta = 0.1*_widthSwitch;
    //double switchAnimCurveValue_ = _switchAnimCurve.value * 2 - 1.0 + (_widthSwitch/2)/MediaQuery.of(context).size.width;
    double switchAnimCurveValue_Boss_Pos  = -1.0 + (_widthSwitch + delta)/MediaQuery.of(context).size.width;
    double switchAnimCurveValue_Worker_Pos = 1.0;
    double pos = _switchAnimCurve.value*switchAnimCurveValue_Boss_Pos + (1-_switchAnimCurve.value)*switchAnimCurveValue_Worker_Pos - 1.0;
    print("pos - $pos org - ${_switchAnimCurve.value}"); 
    return pos;
    //print("switchAnimCurveValueModified - $switchAnimCurveValue_Boss org - ${_switchAnimCurve.value}");
    //return _bBossMode?switchAnimCurveValue_Boss: 0.0;
  }

  Widget _buildSwitchBar(BuildContext context) {
    
    return Container(
      width: _widthSwitch,
      height: _heightSwitch,
      decoration: BoxDecoration(
        color: Color(0x552B2B2B),
        borderRadius: BorderRadius.all(Radius.circular(25.0)),
      ),
      child: new Stack(
        fit:StackFit.expand,
  //             alignment: Alignment.topCenter,
  //             overflow: Overflow.visible,
              children: <Widget>[
                new FractionallySizedBox(
                  heightFactor: 1.0,
                  widthFactor: 0.2,
                  alignment: new Alignment(switchAnimCurveValue() , 0.0),
                 //PositionedTransition(rect: switchAnimation, 
                 child: new CustomPaint(
        painter: TabIndicationPainterNoPageController(
          dxTarget : 0.0,
          radius : (_heightSwitch/2), 
          dy : (_heightSwitch/2), 
          dxEntry : (_widthSwitch/2), 
          color: ZarizTheme.Colors.zarizGradientEnd.value,
          listener: _tabIndicationPainterNoPageControllerListener),
        
      )), Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Expanded(
              child: FlatButton(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onPressed: _onBossButtonPress,
                child: Text(
                  "מעסיק",
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
          ],
        ),
      //)
      ]),
    );
  }

  void _onWorkerButtonPress() {
    setState((){
      _bBossMode = false;
      _tabIndicationPainterNoPageControllerListener.iPos = 0;
      _switchAnimController.forward();
    });
    //_pageController .jumpToPage(0);

    // _pageController.animateToPage(0,
    //     duration: Duration(milliseconds: 500), curve: Curves.decelerate);
  }

  void _onBossButtonPress() {
    setState((){
      _bBossMode = true;
      _switchAnimController.reverse();
    });
     _tabIndicationPainterNoPageControllerListener.iPos = 1;
    //_pageController?.animateToPage(1,
    //    duration: Duration(milliseconds: 500), curve: Curves.decelerate);
  }

   void _showItemDialog(Map<String, dynamic> message) {
    showDialog<bool>(
      context: context,
      builder: (_) => _buildDialog(context, _itemForMessage(message)),
    ).then((bool shouldNavigate) {
      if (shouldNavigate == true) {
        _navigateToItemDetail(message);
      }
    });
  }

   Widget _buildDialog(BuildContext context, Item item) {
    return AlertDialog(
      content: Text("Item ${item.itemId} has been updated"),
      actions: <Widget>[
        FlatButton(
          child: const Text('CLOSE'),
          onPressed: () {
            Navigator.pop(context, false);
          },
        ),
        FlatButton(
          child: const Text('SHOW'),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ],
    );
  }

  void _navigateToItemDetail(Map<String, dynamic> message) {
    final Item item = _itemForMessage(message);
    // Clear away dialogs
    Navigator.popUntil(context, (Route<dynamic> route) => route is PageRoute);
    if (!item.route.isCurrent) {
      Navigator.push(context, item.route);
    }
  }

  Widget _buildWorkerDetails1(BuildContext context) {
      return new Directionality(
        textDirection: TextDirection.rtl,
        child : new AnimatedContainer(
          duration: new Duration(milliseconds:500),
          decoration: decorationBossWorker(context, false),
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
                        top: 5.0, bottom: 5.0, left: 25.0, right: 25.0),
                    child: 
                    new Row(
                      children:<Widget>
                      [ 
                        new Flexible(child: createTextField("פרטי", myFocusNodeFirstName, _controllerWorkerFirstName, FontAwesomeIcons.userAlt)),
                        new Flexible(child: createTextField("משפחה", myFocusNodeLastName, _controllerWorkerLastName, FontAwesomeIcons.users)),
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
                      new Flexible(child: createTextField("מקום", myFocusNodePlace, _controllerWorkerPlace, FontAwesomeIcons.mapMarker)),
                      new Flexible(
                          child: Padding(
                            padding: EdgeInsets.only(
                                top: 10.0, bottom: 10.0, left: 25.0, right: 25.0),
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
                  createTextField("מרחק", myFocusNodeRadius, _controllerWorkerRadius, FontAwesomeIcons.route, keyboardType: TextInputType.number),
                  Container(
                    width: 250.0,
                    height: 1.0,
                    color: Colors.grey[400],
                  ),
                  createTextField("שכר", myFocusNodeWage, _controllerWorkerWage, FontAwesomeIcons.shekelSign, keyboardType: TextInputType.number),
                  Container(
                    width: 250.0,
                    height: 1.0,
                    color: Colors.grey[400],
                  ),
                  occupationChipsBuild(),
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
      child : new AnimatedContainer(
        duration: new Duration(milliseconds:500),
        decoration: decorationBossWorker(context, false),
        //padding: EdgeInsets.only(top: 23.0),
        child:  new SingleChildScrollView(scrollDirection: Axis.vertical,
          child: createMultiGridView()
        )
      )    
        
    );
  }

  Iterable<Widget> get occupationWidget sync* {
    final Color uncheckedColor = ZarizTheme.Colors.zarizGradientEnd2.withAlpha(60);
    for (String occupation in _lPossibleOccupation) {
      yield Padding(
        padding: const EdgeInsets.all(4.0),
        child: FilterChip(
          shape:  RoundedRectangleBorder(
                    side: new BorderSide(
                      color: _workerDetails==null?uncheckedColor:_workerDetails._lOccupationFieldListString==null?uncheckedColor:
                          _workerDetails._lOccupationFieldListString.contains(occupation)?checkedColor:uncheckedColor, 
                      width: 6.0),
                      borderRadius: BorderRadius.circular(8.0),
            ),
          label: Text(occupation),
          selected: (_workerDetails==null)?false:(_workerDetails._lOccupationFieldListString==null)?false:_workerDetails._lOccupationFieldListString.contains(occupation),
          backgroundColor: ZarizTheme.Colors.zarizGradientEnd2.withAlpha(60),
          selectedColor: ZarizTheme.Colors.zarizGradientEnd2.withAlpha(60),
          onSelected: (bool value) {
            setState(() {
              if (value) {
                 _workerDetails._lOccupationFieldListString.add(occupation);
              } else {
                _workerDetails._lOccupationFieldListString.removeWhere((String name) {
                  return name == occupation;
                });
              }
              _bWorkerIsUpdated = false;
            });
          },
        ),
      );
    }
  }

  Widget occupationChipsBuild() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        createTitle("בחר תחומי עיסוק"),
        Wrap(
          children: occupationWidget.toList(),
        ),
      ],
    );
  }

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

  Size getSize(GlobalKey key) {
      final RenderBox renderBoxRed = key.currentContext.findRenderObject();
      return (renderBoxRed.size);
      
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

  Widget addJobWidget(bool bIsEmpty)
  {
     return new Column(children: [ 
                      RawMaterialButton(
                      constraints: bIsEmpty ? BoxConstraints.tight(Size(_widthSwitch/4, _heightSwitch*4)):BoxConstraints.tight(Size(88.0, 36.0)),
                      fillColor: Colors.green[300],
                      splashColor: Colors.white,
                      child: new Container(
                        decoration: new BoxDecoration(                          
                          shape: BoxShape.circle,// You can use like this way or like the below line
                          //borderRadius: new BorderRadius.circular(30.0),
                          color: Colors.green[300],
                        ),
                        child:  bIsEmpty ? new Icon(Icons.add, size:_widthSwitch/8) : Icon(Icons.add), 
                      ),                          
                      onPressed: ((){
                        setState((){
                          _lJobs.add(new JobsContext(new JobsDetails()));
                          _cs.setPage(_cs.getNumberOfPages()+1);
                        });
                      }),
                      shape: new CircleBorder(),
                                                
                    ),  
                    bIsEmpty ? Text('הוסף עבודה' ,textScaleFactor: 1.5,): Text('הוסף עבודה'),
                    ]);
                    
  }

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
    
    var _dropDownButtonOccupation = new DropdownButton(
                                      iconSize: 30.0,
                                      isExpanded: true,
                                      items: _lOccupationDropDown,
                                      hint: createTextWithIcon(_jobPlaceText, FontAwesomeIcons.hammer),
                                       style: TextStyle(
                                      fontFamily: "WorkSansSemiBold",
                                      fontSize: 16.0,
                                      color: Colors.black),
                                  
                                        onChanged: ((s)
                                      {
                                        job.ui.connOccupationList.text = s;
                                        _iJobIsUpdated = index;
                                        _idJobIsUpdated = job.details._jobId;
                                        setState(()
                                        { 
                                          _jobPlaceText = s;
                                          _bExpandOccupation=false;
                                        });
                                      })
                                    );
    _lKeyForJobDiscription[index]=new GlobalKey(debugLabel: "keyForJobDiscription_$index");
    return new ConstrainedBox(
       constraints: const BoxConstraints.expand(),
      child:new SingleChildScrollView(child: new Directionality(
        textDirection: TextDirection.rtl,
        child : new AnimatedContainer(
          duration: new Duration(milliseconds:500),
          decoration: decorationBossWorker(context, true),
          padding: EdgeInsets.only(top: 5.0),
          //child: new SingleChildScrollView (
            child: new Stack(
            children: 
            [
              Column(children: <Widget>[
              _lJobs.length==0 ?  createTitle("אין עבודות") :createTitle("עבודה ${index+1} מתוך ${_lJobs.length}"),
               AnimatedContainer(
                 duration: new Duration(milliseconds: 500),
                 curve: Curves.elasticInOut,
               height: _bShrinkJobMenu?MediaQuery.of(context).size.height*0.12:MediaQuery.of(context).size.height*0.55,
               child: Card(
                elevation: 2.0,
                color: Colors.white54,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: new SingleChildScrollView (
                  child: bIsEmptyEntry?new Container():new Column(
                    children: 
                    [
                      Container(
                        width: 250.0,
                        height: 1.0,
                        color: Colors.grey[400],
                      ),
                      new Container(child: createTextField("תאור מפורט של העבודה בכמה מילים",
                        job.ui.fnDiscription, job.ui.conDiscription, Icons.edit, keyboardType: TextInputType.multiline, maxLines: 3)),
                      Container(
                        width: 250.0,
                        height: 1.0,
                        color: Colors.grey[400],
                      ),
                      new Row(
                          children:<Widget> [ 
                            new Flexible(child: createTextField("מקום", job.ui.fnPlace, job.ui.conPlace, FontAwesomeIcons.mapMarker)),
                            new Flexible(
                              child: Padding(
                                padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
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
                      createTextField("שכר", job.ui.fnWage, job.ui.conWage, FontAwesomeIcons.shekelSign, keyboardType: TextInputType.number),
  new SingleChildScrollView (
                                  child: new Theme(
                                    data: new ThemeData(
                                      fontFamily: "WorkSansSemiBold", 
                                      canvasColor: Colors.white54, //my custom color
                                    ),
                                    child: _dropDownButtonOccupation,
                                  ),
                                ),
               
                      
                      createTextField("מספר עובדים", job.ui.fnnWorkers, job.ui.connWorkers, FontAwesomeIcons.peopleCarry, keyboardType: TextInputType.number, validator: new BlacklistingTextInputFormatter(new RegExp('[\\.|\\,|\\-|\\ ]'))),    
                    ]
                    
              ))
            )),
            _bShrinkJobMenu?_buildBossJobsLivePage(context, job.details._jobId):new Container(),
            Container(height: 50.0,),]), 
            
            Positioned(bottom:0.0, left:0.0, right:0.0, 
              child:
              bIsEmptyEntry? addJobWidget(bIsEmptyEntry):
              Container(child: new Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                  addJobWidget(bIsEmptyEntry),
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
                        if (_bShrinkJobMenu) {
                          setState(() {
                            _bShrinkJobMenu = false;
                          });
                        } else {
                        print("index - $index");
                        _currentJobId = job.details._jobId;
                        setState(() {
                           _bUpdatingDetails = true;
                        });
                       
                          _services.queryJob(job.details._jobId).then((res){
                            
                            if ((res["success"] == "true") || (res["success"] == true)) {
                              //Future.delayed(new Duration(seconds:4), () => 
                              //Navigator.push(
                              //  context,
                              //  MaterialPageRoute(builder: (context) => _buildBossJobsLivePage(context, _currentJobId)),
                              //);
                              //);
                              setState(() {
                                _bShrinkJobMenu = true;
                              });
                              
                            }    
                            setState(() {
                              _bUpdatingDetails = false;     
                            });        
                          });
                        }
                      }),
                      shape: new CircleBorder(),                          
                    ),  
                    Text(_bShrinkJobMenu ? 'פרטי עבודה':'עובדים'),
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

                  ])]))),//),
            ])//)  
          )
        ))
      );
  }

  Widget _buildJobsCarousel(BuildContext context, List<Widget> jbl) {
    _lKeyForJobDiscription = new List<GlobalKey>(_lJobs.length + 1);
    if (_lJobs.length == 0) {
      jbl.add(jobPage(context, 0));
    } else {
      for (int i=0; i < _lJobs.length; i++) {
        jbl.add(jobPage(context, i));
      }
    }
    if (_cs != null) {
      iCs = (_cs.getCurrentPage(context)).round();
    } else {
      iCs = 0;
    }
    _cs = new CarosuelState(pages : jbl);
    var carousel= _cs.buildCarousel(context, _heightMain);
    //_cs.setPage(0);
    return carousel;
  }

  Widget _buildBossCarousel(BuildContext context) {
    List<Widget> jbl = [];
    jbl.add(_buildBossDetails1(context));
    return _buildJobsCarousel(context, jbl);
  }

  Widget _buildMainJobsCarousel(BuildContext context) {
    List<Widget> jbl = [];
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
    return (new Directionality(
        textDirection: TextDirection.rtl,
        child : new AnimatedContainer(
          duration: new Duration(milliseconds:500),
          decoration: decorationBossWorker(context, true),
          padding: EdgeInsets.only(top: 23.0),
          child: Card(
            elevation: 2.0,
            color: Colors.white54,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
              child: SingleChildScrollView(
            //   //width: MediaQuery.of(context).size.width * 5 / 6,
            //   //height: MediaQuery.of(context).size.height * 2,
                child: new Column( children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(
                        top: 10.0, bottom: 10.0, left: 25.0, right: 25.0),
                    child: 
                    new Row(
                      children:<Widget>
                      [ 
                        new Flexible(child: createTextField("פרטי", myFocusNodeBossFirstName, _controllerWorkerFirstName, FontAwesomeIcons.userAlt)),
                        new Flexible(child: createTextField("משפחה", myFocusNodeBossLastName, _controllerWorkerLastName, FontAwesomeIcons.users)),
                        
                      ]
                    ),
                  ),
                  Container(
                    width: 250.0,
                    height: 1.0,
                    color: Colors.grey[400],
                  ),
                  new SingleChildScrollView(
                      child: createTextField("שם העסק", myFocusNodeBossBuisnessName, _controllerBossBuisnessName, FontAwesomeIcons.userAlt),
                  ),
                                          
                  new Row(
                    children:<Widget>
                    [ 
                      new Flexible(child: createTextField("מקום", myFocusNodeBossPlace, _controllerBossPlace, FontAwesomeIcons.mapMarker)),
                      new Flexible(
                        child: Padding(
                          padding: EdgeInsets.only(
                              top: 10.0, bottom: 10.0, left: 25.0, right: 25.0),
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
              ))
            )         
        )
      )
    );
  }
  Widget _buildBossJobsLivePage(BuildContext context, String jobID) {
    JobsContext job;
    _lJobs.forEach((j){
      if (j.details._jobId==jobID) {
        job=j;
      }
    });
    print("_buildBossJobsLivePage, !!!!Shrink job ${_bShrinkJobMenu} job.lWorkersNotified.length ${job.lWorkersNotified.length} for ${jobID}");
    if (job==null||job.lWorkersNotified==[])
      return new Directionality(
        textDirection: TextDirection.rtl,
        child: createTitle("לא נמצאו עובדים"));
    // remove declined workers
    List<WorkerDetails> lWorkersDeclined = [];
    job.lWorkersResponded.forEach((w){
       job.lWorkersHired.firstWhere((wHired) => wHired._userID == w._userID, orElse: ((){
         job.lWorkersAuthorized.firstWhere((wAuth) => wAuth._userID == w._userID, orElse: ((){
            lWorkersDeclined.add(w);
         }));
       }));
    });
    List<WorkerDetails> lWorkersToShow = new List.from(job.lWorkersNotified);
    lWorkersDeclined.forEach((w) {
      try { 
        var oldVal = lWorkersToShow.firstWhere((a) => a._userID == w._userID);
        lWorkersToShow.remove(oldVal);
      } catch (e) {

      }
      
    });
    if (_sortTypeWorkersForJob == 0) {//SortType.LastName.index) {
      lWorkersToShow.sort((a, b) {
        return (_bSortAsscending ? a : b)._lastName.toString().toLowerCase().compareTo((_bSortAsscending ? b : a)._lastName.toString().toLowerCase());   
      });
    } else if (_sortTypeWorkersForJob == 1) { //SortType.FirstName.index) {
      lWorkersToShow.sort((a, b) {
        
        return (_bSortAsscending ? a : b)._firstName.toString().toLowerCase().compareTo((_bSortAsscending ? b : a)._firstName.toString().toLowerCase());   
      });
    } else if (_sortTypeWorkersForJob == 2) { //SortType.DistFromAddress.index) {
      lWorkersToShow.sort((a, b) {
        final Distance distance = new Distance();
        final double meter =  distance(new LatLng(a._lat,a._lng),
        new LatLng(b._lat,b._lng));
        int iMeter  = (meter > 0) ? 1 : -1;
        return _bSortAsscending ? iMeter : iMeter*-1;
      });
    } else if (_sortTypeWorkersForJob == 3) {//SortType.DistFromLocation.index) {
      lWorkersToShow.sort((a, b) {
        final Distance distance = new Distance();
        final double meterA =  distance(new LatLng(a._lat,a._lng),
        new LatLng(_currLocation.lat, _currLocation.lng));
        final double meterB =  distance(new LatLng(b._lat,b._lng),
        new LatLng(_currLocation.lat, _currLocation.lng));
        final int dist = meterA > meterB ? 1 : -1;
        return (_bSortAsscending ?dist : (dist * -1));
      });
    }

    var w = MediaQuery.of(context).size.width;
    var h = MediaQuery.of(context).size.height;
    
    Widget sortText = createTitleNoPadding(_sSortWorkersForJob[_sortTypeWorkersForJob],textSize: 10.0, bLeft:true);
    

      return new Directionality(
      textDirection: TextDirection.rtl,

        child: new Column(
          
          children: <Widget>[
          Align(alignment: Alignment.centerLeft, child: Container(
            
            //width: (l[0].left - l[0].right)*2,
            width: w / 2,
            height: h / 15,
            
            child: new Card(
              elevation: 6.0,
                color: Colors.white54,
                
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0),
                ),child: new Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    textDirection: TextDirection.rtl,
                    children:<Widget>
                    [ 
                      
                      new Flexible(child:new GestureDetector(child: Padding(padding: EdgeInsets.only(right:2.0),child:sortText), onTap: () {
                        setState(() 
                          {
                            _sortTypeWorkersForJob++;
                            _sortTypeWorkersForJob = _sortTypeWorkersForJob % _sSortWorkersForJob.length;
                          });
                      })),
                      new  Flexible (child: IconButton(
                        icon: Icon(_bSortAsscending ? FontAwesomeIcons.arrowUp :   FontAwesomeIcons.arrowDown, size:12.0), 
                        onPressed: ()
                        {
                          setState(() 
                          {
                            _bSortAsscending = !_bSortAsscending;
                          });
                        },
                      )),
                    ]
                )))),
               
          SingleChildScrollView(child: new ListView.builder( 
            shrinkWrap: true,
            padding: EdgeInsets.only(
                  top: 0.0, bottom: 20.0, right: 25.0, left: 25.0),
            itemCount: lWorkersToShow.length,
            itemBuilder: (BuildContext context, int index) {
              bool bNotified = false;
              for(var w in job.lWorkersNotified) {
                if (lWorkersToShow[index]._userID == w._userID) {
                  bNotified = true;
                  break;
                }
              }
              bool bResponded = false;
              for(var w in job.lWorkersResponded) {
                if (lWorkersToShow[index]._userID == w._userID) {
                  bResponded = true;
                  break;
                }
              }
              bool bAuthorized = false;
              for(var w in job.lWorkersAuthorized) {
                if (lWorkersToShow[index]._userID == w._userID) {
                  bAuthorized = true;
                  break;
                }
              }
              bool bHired = false;
              for(var w in job.lWorkersHired) {
                if (lWorkersToShow[index]._userID == w._userID) {
                  bHired = true;
                  break;
                }
              }
              return   Card(elevation: 2.0,
                color: Colors.white54,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),child: new Container(child: new Row(children: <Widget>[
                RawMaterialButton(
                  fillColor: bHired ? Color.fromRGBO(212, 175, 55, 1) : (bAuthorized? Colors.green:(bResponded? Colors.red:Colors.grey)),
                  splashColor: Colors.white,
                  child: new Container(
                    decoration: new BoxDecoration(                          
                      shape: BoxShape.circle,
                      color: bHired ? Color.fromRGBO(212, 175, 55, 1) : (bAuthorized? Colors.green:(bResponded? Colors.red:Colors.grey)),
                  ),
                  child:  bHired ?  new Icon(FontAwesomeIcons.handshake): bAuthorized? new Icon(FontAwesomeIcons.check):(bResponded? Icon(FontAwesomeIcons.exclamation):Icon(FontAwesomeIcons.question)),
                  ), 
                  onPressed: ((){
                    if (!bAuthorized) {
                      // re-send notification

                    } else  {
                    
                      _services.hire(jobID, lWorkersToShow[index]._userID, !bHired).then((res) {
                        if (res.containsKey("success") && ((res["success"] == "true") || (res["success"] == true))) {
                          var res2 = refreshJobs();
                          res2.then((bSuccess){ 
                            if (bSuccess)
                            {
                              setState((){});
                            }
                          });
                          
                        }
                      });
                      
                    }
                    
                  }),
                  shape: new CircleBorder(),
                  
                ),
          
                createTitle('${lWorkersToShow[index]._firstName} ${lWorkersToShow[index]._lastName}'),
                
              ])));
            }
          )),        
        ]),
      );

    //,new GlobalKey<ScaffoldState>());
    //,_scaffoldKey);
  } 

  Widget _buildWorkersJobsLivePage(BuildContext context, ) {
    return new Directionality(
      textDirection: TextDirection.rtl,
      child : new AnimatedContainer(
          duration: new Duration(milliseconds:500),
        decoration: decorationBossWorker(context, false),
        padding: EdgeInsets.only(top: 23.0),
        child: Column(
          children: <Widget>[
            Stack(
              alignment: Alignment.topCenter,
              overflow: Overflow.visible,
              children: <Widget>[
                 Stack(
                    children: [
                      SingleChildScrollView(child: new 
                        ListView.builder( 
                          shrinkWrap: true,
                          padding: EdgeInsets.only(
                                top: 20.0, bottom: 20.0, right: 25.0, left: 25.0),
                          itemCount: _lJobs.length,
                          itemBuilder: (BuildContext context, int index) {
                            return   Card(elevation: 2.0,
                              color: Colors.white54,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),child: new Container(height:120.0, child: new Row(children: <Widget>[
                              RawMaterialButton(
                                fillColor: index!=_lJobs.length? Colors.green[300] :Colors.red[300],
                                splashColor: Colors.white,
                                child: new Container(
                                  decoration: new BoxDecoration(                          
                                    shape: BoxShape.circle,
                                    color: Colors.green,
                                ),
                                child:  index!=_lJobs.length? new Icon(Icons.add) : new Icon(FontAwesomeIcons.trashAlt), 
                                ), 
                                onPressed: ((){
                                }),
                                shape: new CircleBorder(),
                                
                              ),
                             
                              createTitle('${_lJobs[index].details._discription}'),
                              
                            ])));
                          }
                        )
                      ),
                    ]
                  ),
                //),  
              ],
            )
          ]
        )
      )
    );
  } 
}
/* class InvertedCircleClipper extends CustomClipper<Path> {
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
} */

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