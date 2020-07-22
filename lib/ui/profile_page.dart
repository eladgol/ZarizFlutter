import 'dart:async';
import 'dart:io';
import 'dart:convert';
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
import 'package:zariz_app/ui/Job_confirmResignDialog.dart';
import 'package:zariz_app/ui/Job_confirmCanceledDialog.dart';
import 'package:zariz_app/ui/mapWidget.dart';
import 'package:latlong/latlong.dart';

import 'dart:math';

import 'package:flutter_typeahead/flutter_typeahead.dart';

class CurrentLocation {
  double lat = 0.0;
  double lng = 0.0;
  String name = "Maor";
}

class BossDetails {
  String _buisnessName;
  String _firstName;
  String _lastName;
  double _lat;
  double _lng;
  String _photoAGCSPath;
  String _place;
  int _userID;
  String get buisnessName {
    return _buisnessName;
  }
  String get firstName {
    return _firstName;
  }
  String get lastName {
    return _lastName;
  }
  Map<String, String> toJSON() => {
        'firstName': _firstName,
        'lastName': _lastName,
        'buisnessName': _buisnessName.toString(),
        'userID': _userID.toString(),
        'photoAGCSPath': _photoAGCSPath,
        'place': _place,
        'lat': _lat.toString(),
        'lng': _lng.toString()
      };
}

class JobsContext {
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

class JobsUI {
  TextEditingController conDiscription;
  TextEditingController connOccupationList;
  TextEditingController conPlace;
  TextEditingController conWage;
  FocusNode fnDiscription;
  AlwaysDisabledFocusNode fnnOccupationList;
  FocusNode fnPlace;
  FocusNode fnWage;

  JobsUI(JobsDetails jd) {
    this.fnDiscription = new FocusNode();
    this.fnPlace = new FocusNode();
    this.fnWage = new FocusNode();
    this.fnnOccupationList = new AlwaysDisabledFocusNode();

    this.conDiscription = new TextEditingController(
        text: (jd._discription != null ? jd._discription.toString() : ""));
    this.conWage = new TextEditingController(
        text: (jd._wage != null ? jd._wage.toString() : "29.12"));
    this.conPlace = new TextEditingController(
        text: (jd._place != null ? jd._place.toString() : ""));
    this.connOccupationList = new TextEditingController(
        text: (jd._lOccupationFieldListString.length > 0
            ? jd._lOccupationFieldListString[0].toString()
            : ""));
  }
}

class JobsDetails {

  String _discription;
  String _jobId = "-1";
  double _lat;
  double _lng;
  List<String> _lOccupationFieldListString = [];
  String _place;
  double _wage;
  bool bDetailsUpdated = false;
  String get discription {
    return _discription;
  }
  String get jobId {
    return _jobId;
  }
  double get lat {
    return _lat;
  }
  double get lng {
    return _lng;
  }
  double get wage {
    return _wage;
  }
  String get place {
    return _place;
  }
  Map<String, String> toJSON() => {
        'discription': _discription,
        'wage': _wage.toString(),
        'jobID': _jobId.toString(),
        'place': _place,
        'lat': _lat.toString(),
        'lng': _lng.toString(),
        'lOccupationFieldListString': _lOccupationFieldListString.length > 0
            ? _lOccupationFieldListString[0]
            : ""
      };

}

class JobDetailsForWorkerUI {
  double _angle = 0;
  AnimationController _angleController;
  bool bIsExpanded = false;
  JobDetailsForWorkerUI(_ProfilePageState t) {
    _angleController =
        AnimationController(vsync: t, duration: Duration(milliseconds: 500));
    _angleController.addListener(() {
      t.setState(() {
        _angle = _angleController.value * 180 / 360 * 2 * pi;
      });
    });
  }
}

class JobDetailsForWorker {
  JobsDetails jd;
  BossDetails bd;
  bool bAuthorized = false;
  bool bResponded = false;
  bool bHired = false;
  JobDetailsForWorkerUI ui;
  JobDetailsForWorker(_ProfilePageState t) {
    ui = new JobDetailsForWorkerUI(t);
  }
}

class WorkerDetails {
  String _firstName;
  String _lastName;
  double _lat;
  double _lng;
  List<String> _lOccupationFieldListString;
  String _photoAGCSPath;
  String _place;
  //double _radius;
  int _userID;
  double _wage;

  Map<String, String> toJSON() => {
        'firstName': _firstName,
        'lastName': _lastName,
        'wage': _wage.toString(),
        'userID': _userID.toString(),
        'photoAGCSPath': _photoAGCSPath,
        //'radius': _radius.toString(),
        'place': _place,
        'lat': _lat.toString(),
        'lng': _lng.toString(),
        'lOccupationFieldListString': _lOccupationFieldListString == null
            ? ""
            : fixDecoding(_lOccupationFieldListString)
      };
}

String fixDecoding(List<String> sIn) {
  String sOut = "[";
  int i = 0;
  sIn.forEach((s) {
    if (i == 0) {
      sOut += s;
    } else {
      sOut += "," + s;
    }
    i += 1;
  });
  sOut += "]";
  return sOut;
}

class AppBarChoice {
  const AppBarChoice({this.title, this.icon});

  final IconData icon;
  final String title;
}

// List<String> fixEncoding(String sIn) {
//   String sEncoded = sIn.replaceAll(new RegExp(r"u|'|\[|\]"), "");
//   List<String> lEncoded = sEncoded.split(',');
//   List<String> lOut = new List<String>();
//   lEncoded.forEach((e) {
//     e = e.trim();
//     var chars = e.split(new RegExp(r"\\| ")).skip(1).toList();
//     var sOut = "";
//     chars.forEach((c) {
//       if ((c != " u'") && (!c.contains("["))) {
//         if (c == "")
//           sOut += " ";
//         else
//           sOut += decodeUtf16([
//             int.parse(c.substring(0, 2), radix: 16),
//             int.parse(c.substring(2, 4), radix: 16)
//           ]);
//         //sOut += decodeUtf16(hex.decode(c));
//       }
//     });
//     lOut.add(sOut);
//   });
//   return lOut;
// }

List<String> fixEncoding(String sIn) {
  String sEncoded = sIn.replaceAll(new RegExp(r"u|'|\[|\]"), "");
  List<String> lEncoded = sEncoded.split(',');
  List<String> lOut = new List<String>();
  lEncoded.forEach((e) {
    lOut.add(e.trim());
  });
  return lOut;
}
enum eChoice {updateDetails, logoff}
List<AppBarChoice> choices = <AppBarChoice>[
  //AppBarChoice(title: 'update', icon: Icons.check),
  //AppBarChoice(title: 'jobs', icon: FontAwesomeIcons.screwdriver),
  AppBarChoice(title: 'עדכן פרטים', icon: FontAwesomeIcons.pencilAlt),
  AppBarChoice(title: 'יציאה', icon: FontAwesomeIcons.signOutAlt),
  //AppBarChoice(title: 'debug', icon: FontAwesomeIcons.bug),
  //AppBarChoice(title: 'feed', icon: FontAwesomeIcons.solidBell),
];

class ProfilePage extends StatefulWidget {
  ProfilePage({Key key}) : super(key: key);

  @override
  _ProfilePageState createState() => new _ProfilePageState();
}

enum SortType {DistFromLocation, DistFromAddress, Wage, LastName, FirstName}
final List<String> _sSortTypes = [
  'מיין לפי מרחק ממיקום נוכחי',
  'מיין לפי מרחק מכתובת העסק',
  'מיין לפי שכר',
  'מיין לפי שם משפחה',
  'מיין לפי שם פרטי',
];

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  static final checkedColor = ZarizTheme.Colors.zarizGradientEnd.withAlpha(240);
  static double hDefault = 775.0;
  static final String kGoogleApiKey = "AIzaSyCKbtYyIOqIe1mmCIPIp_wezViTi2JHiC0";
  static final uncheckedColor =
      ZarizTheme.Colors.zarizGradientEnd.withAlpha(64);

  int iCs = 0;
  Color left = Colors.black;
  final FocusNode myFocusNodeBossBuisnessName = FocusNode();
  final FocusNode myFocusNodeBossFirstName = FocusNode();
  final FocusNode myFocusNodeBossLastName = FocusNode();
  final FocusNode myFocusNodeBossPlace = FocusNode();
  final FocusNode myFocusNodeFirstName = FocusNode();
  final FocusNode myFocusNodeLastName = FocusNode();
  final FocusNode myFocusNodePlace = FocusNode();
  //final FocusNode myFocusNodeRadius = FocusNode();
  final FocusNode myFocusNodeWage = FocusNode();
  Color right = Colors.white;

  static final List<String> _lDefaultPossibleOccupation = [
    "א",
    "ב",
    "ג",
    "ד",
    "ה",
    "ו",
    "ז",
    "ח",
    "ט",
    "י",
    "כ",
    "ל",
    "מ",
    "נ",
    "ס",
    "ע",
    "פ",
    "צ",
    "ק",
    "ר",
    "ש",
    "ת"
  ];
  double _h;
  double _w;

  AndroidDeviceInfo _androidInfo;
  bool _bBossMode = false;
  
  bool _bIsLoadingPlaces = false;
  bool _bJobMenu = true; // we start from job menu unless the details are not full
  bool _bMapView = false;
  BossDetails _bossDetails = new BossDetails();
  bool _bShrinkJobMenu = true; 
  bool _bUpdatingDetails = false;
  bool _bWorkerIsUpdated = true;
  bool _bWorkerDetailsAreFull = false;
  bool _bBossDetailsAreFull = false;
  List<Color> _colorOccupation = new List<Color>.filled(
      _lDefaultPossibleOccupation.length, uncheckedColor);
  TextEditingController _controllerBossBuisnessName =
      new TextEditingController();
  TextEditingController _controllerBossPlace = new TextEditingController();
  TextEditingController _controllerWorkerFirstName =
      new TextEditingController();
  TextEditingController _controllerWorkerLastName = new TextEditingController();
  TextEditingController _controllerWorkerPlace = new TextEditingController();
  //TextEditingController _controllerWorkerRadius = new TextEditingController();
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
  Image _image = new Image.asset('assets/img/no_portrait.png',
      fit: BoxFit.scaleDown, width: 250.0, height: 191.0);
  String _imageFileBase64Data = "";

  var _jobPlaceText = "בחר תחום";
  List<JobsContext> _lJobs = [];
  List<DropdownMenuItem<String>> _lJobsDropDownList = [
    new DropdownMenuItem<String>(
      value: "מאור",
      child: new Text("מאור"),
    )
  ];

  List<String> _lJobsIDsMarkedForDeletion = [];
  List<DropdownMenuItem<String>> _lOccupationDropDown = [];
  List<DropdownMenuItem<String>> _lPlacesBossDropDownList = [
    new DropdownMenuItem<String>(
      value: "מאור",
      child: new Text("מאור"),
    )
  ];

  List<DropdownMenuItem<String>> _lPlacesWorkerDropDownList = [
    new DropdownMenuItem<String>(
      value: "מאור",
      child: new Text("מאור"),
    )
  ];

  List<String> _lPossibleOccupation = _lDefaultPossibleOccupation;
  PageController _pageController;
  List<Widget> _pages;
  GoogleMapsPlaces _placesAPI = new GoogleMapsPlaces(apiKey: kGoogleApiKey);
  final String _titleBossProfile = "פרופיל מעסיק";
  final String _titleBossJobsWorkersList = "עבודות מעסיק - רשימת עובדים";
  final String _titleBossJobsWorkDetails = "עבודות מעסיק - עריכת פרטי עבודה";
  final String _titleWorkerJobsMapView = "עבודות מעסיק - תצוגת מפה";
  final String _titleWorkerProfile = "פרופיל עובד";
  final String _titleWorkerJobsList = "עבודות עובד - רשימת עבודות";
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  List<bool> _selectedOccupation =
      new List<bool>.filled(_lDefaultPossibleOccupation.length, false);
  Services _services = new Services();

  AnimationController _switchAnimController;

  Animation<double> _switchAnimCurve;

  TabIndicationPainterNoPageControllerListener
      _tabIndicationPainterNoPageControllerListener =
      new TabIndicationPainterNoPageControllerListener(iPos: 0, nPages: 2);
  int _tLength = 2;
  double _widthSwitch = hDefault * 0.5;
  WorkerDetails _workerDetails = new WorkerDetails();

  int _sortTypeWorkersForJob = 0;
  int _sortTypeJobsForWorker = 0;
  bool _bSortAsscendingWorkersForJob = true;
  bool _bSortAsscendingJobsForWorker = true;

  Color _zarizGradientColorAnimation;
  var _angle = 0.0;

  OverlayEntry _overlayEntry;

  @override
  void dispose() {
    myFocusNodeFirstName.dispose();
    myFocusNodeLastName.dispose();
    myFocusNodeWage.dispose();
    myFocusNodePlace.dispose();
    //myFocusNodeRadius.dispose();
    myFocusNodeBossFirstName.dispose();
    myFocusNodeBossLastName.dispose();
    myFocusNodeBossBuisnessName.dispose();
    myFocusNodeBossPlace.dispose();
    for (var j in _jobDetailsForWorkerList) {
      j?.ui?._angleController?.dispose();
    }
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
    )
      ..addListener(() {
        this.setState(() {});
      })
      ..addStatusListener((status) {
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
          0.0,
          1.0,
          curve: Curves.easeInOut,
        ),
      ),
    );
    //_switchAnim = _switchAnimCurve.animate(_switchAnimController);
    _switchAnimController.forward();

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    deviceInfo.androidInfo.then((v) {
      _androidInfo = v;
      print(
          'DeviceInfo - brand ${v.brand}, model ${v.model}, phisical device ${v.isPhysicalDevice}, id ${v.id}');
    });
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        if (message["data"]["message_status"] == "Offer") {
          String sMsg = "${message["data"]["discription"]} \n";
          sMsg +=
              "\nהצעת עבודה מ${message["data"]["firstName"]} ${message["data"]["lastName"]} \n";
          sMsg += "שכר ${message["data"]["wage"]}\n";
          sMsg += "מיקום ${message["data"]["place"]}\n";
          final res = Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => JobConfirmPage(
                      sTitle: sMsg,
                      jobID: message["data"]["jobID"],
                    )),
          );
          res.then((s) {
            print("Offer job before refresh");
            var res2 = refreshJobs();
          });
        } else if (message["data"]["message_status"] == "Canceled") {
          String sMsg = "${message["data"]["discription"]} \n";
          sMsg +=
              "\nהעבודה בוטלה${message["data"]["firstName"]} ${message["data"]["lastName"]} \n";
          sMsg += "שכר ${message["data"]["wage"]}\n";
          sMsg += "מיקום ${message["data"]["place"]}\n";
          final res = Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => JobConfirmCanceledPage(
                      sTitle: sMsg,
                      jobID: message["data"]["jobID"],
                    )),
          );
          res.then((s) {
            print("Canceled job before refresh");
            var res2 = refreshJobs();
          });
        } else if (message["data"]["message_status"] == "Accepted") {
          String sMsg = "${message["data"]["discription"]} \n";
          sMsg +=
              "\vהתעניינות בעבודה מ ${message["data"]["firstName"]} ${message["data"]["lastName"]} \n";
          sMsg += "שכר ${message["data"]["wage"]}\n";
          sMsg += "מיקום ${message["data"]["place"]}\n";
          final res = Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => JobConfirmPage(
                      sTitle: sMsg,
                      jobID: message["data"]["jobID"],
                    )),
          );
          res.then((s) {
            print("Accepted job before refresh");
            var res2 = refreshJobs();
          });
        } else if (message["data"]["message_status"] == "Hired") {
          String sMsg = "${message["data"]["discription"]} \n";
          sMsg +=
              "\n התקבלת לעבודה על ידי ${message["data"]["firstName"]} ${message["data"]["lastName"]} \n";
          sMsg += "שכר ${message["data"]["wage"]}\n";
          sMsg += "מיקום ${message["data"]["place"]}\n";
          final res = Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => JobConfirmHirePage(
                      sTitle: sMsg,
                      jobID: message["data"]["jobID"],
                      workerID: message["data"]["workerID"],
                    )),
          );
          res.then((s) {
            print("hire job before refresh");
            var res2 = refreshJobs();
          });
        } else if (message["data"]["message_status"] == "Fired") {
          var resUpdateFired = _services.confirmHire(
              message["data"]["jobID"], message["data"]["workerID"], false);
          resUpdateFired.then((s) {
            print("fired job status updated");
          });
          String sMsg = "${message["data"]["discription"]} \n";
          sMsg +=
              "\n הוחלט שלא להעסיק אותך! ${message["data"]["firstName"]} ${message["data"]["lastName"]} \n";
          sMsg += "שכר ${message["data"]["wage"]}\n";
          sMsg += "מיקום ${message["data"]["place"]}\n";
          final res = Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => JobConfirmFiredPage(
                      sTitle: sMsg,
                      jobID: message["data"]["jobID"],
                      workerID: message["data"]["workerID"],
                    )),
          );
          res.then((s) {
            print("fired job before refresh");
            var res2 = refreshJobs();
          });
        } else if (message["data"]["message_status"] == "Resigned") {
          var resUpdateFired = _services.confirmHire(
              message["data"]["jobID"], message["data"]["workerID"], false);
          resUpdateFired.then((s) {
            print("resigned job status updated");
          });
          String sMsg = "${message["data"]["discription"]} \n";
          sMsg +=
              "\n הודעת התפטרות! ${message["data"]["firstName"]} ${message["data"]["lastName"]} \n";
          sMsg += "שכר ${message["data"]["wage"]}\n";
          sMsg += "מיקום ${message["data"]["place"]}\n";
          final res = Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => JobConfirmResignPage(
                      sTitle: sMsg,
                      jobID: message["data"]["jobID"],
                      workerID: message["data"]["workerID"],
                    )),
          );
          res.then((s) {
            print("resigned job before refresh");
            var res2 = refreshJobs();
          });
        }
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
        if (message["data"]["message_status"] == "Offer") {
          String sMsg = "${message["data"]["discription"]} \n";
          sMsg +=
              "\nהצעת עבודה מ${message["data"]["firstName"]} ${message["data"]["lastName"]} \n";
          sMsg += "שכר ${message["data"]["wage"]}\n";
          sMsg += "מיקום ${message["data"]["place"]}\n";
          final res = Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => JobConfirmPage(
                    sTitle: sMsg, jobID: message["data"]["jobID"])),
          );
          res.then((s) {
            print("confirm job before refresh");
            var res2 = refreshJobs();
          });
        } else if (message["data"]["message_status"] == "Canceled") {
          String sMsg = "${message["data"]["discription"]} \n";
          sMsg +=
              "\nהעבודה בוטלה${message["data"]["firstName"]} ${message["data"]["lastName"]} \n";
          sMsg += "שכר ${message["data"]["wage"]}\n";
          sMsg += "מיקום ${message["data"]["place"]}\n";
          final res = Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => JobConfirmCanceledPage(
                      sTitle: sMsg,
                      jobID: message["data"]["jobID"],
                    )),
          );
          res.then((s) {
            print("Canceled job before refresh");
            var res2 = refreshJobs();
          });
        } else if (message["data"]["message_status"] == "Hired") {
          String sMsg = "${message["data"]["discription"]} \n";
          sMsg +=
              "\nהתקבלת לעבודה על ידי ${message["data"]["firstName"]} ${message["data"]["lastName"]} \n";
          sMsg += "שכר ${message["data"]["wage"]}\n";
          sMsg += "מיקום ${message["data"]["place"]}\n";
          final res = Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => JobConfirmHirePage(
                      sTitle: sMsg,
                      jobID: message["data"]["jobID"],
                      workerID: message["data"]["workerID"],
                    )),
          );
          res.then((s) {
            print("hire job before refresh");
            var res2 = refreshJobs();
          });
        } else if (message["data"]["message_status"] == "Fired") {
          String sMsg = "${message["data"]["discription"]} \n";
          sMsg +=
              "\nהוחלט שלא להעסיק אותך! ${message["data"]["firstName"]} ${message["data"]["lastName"]} \n";
          sMsg += "שכר ${message["data"]["wage"]}\n";
          sMsg += "מיקום ${message["data"]["place"]}\n";
          final res = Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => JobConfirmFiredPage(
                      sTitle: sMsg,
                      jobID: message["data"]["jobID"],
                      workerID: message["data"]["workerID"],
                    )),
          );
          res.then((s) {
            print("fired job before refresh");
            var res2 = refreshJobs();
          });
        } else if (message["data"]["message_status"] == "Resigned") {
          var resUpdateFired = _services.confirmHire(
              message["data"]["jobID"], message["data"]["workerID"], false);
          resUpdateFired.then((s) {
            print("resigned job status updated");
          });
          String sMsg = "${message["data"]["discription"]} \n";
          sMsg +=
              "\n הודעת התפטרות! ${message["data"]["firstName"]} ${message["data"]["lastName"]} \n";
          sMsg += "שכר ${message["data"]["wage"]}\n";
          sMsg += "מיקום ${message["data"]["place"]}\n";
          final res = Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => JobConfirmResignPage(
                      sTitle: sMsg,
                      jobID: message["data"]["jobID"],
                      workerID: message["data"]["workerID"],
                    )),
          );
          res.then((s) {
            print("resigned job before refresh");
            var res2 = refreshJobs();
          });
        }
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
        if (message["data"]["message_status"] == "Offer") {
          String sMsg = "${message["data"]["discription"]} \n";
          sMsg +=
              "\nהצעת עבודה מ${message["data"]["firstName"]} ${message["data"]["lastName"]} \n";
          sMsg += "שכר ${message["data"]["wage"]}\n";
          sMsg += "מיקום ${message["data"]["place"]}\n";
          final res = Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => JobConfirmPage(
                      sTitle: sMsg,
                      jobID: message["data"]["jobID"],
                    )),
          );
          res.then((s) {
            print("confirm job before refresh");
            var res2 = refreshJobs();
          });
        } else if (message["data"]["message_status"] == "Canceled") {
          String sMsg = "${message["data"]["discription"]} \n";
          sMsg +=
              "\nהעבודה בוטלה${message["data"]["firstName"]} ${message["data"]["lastName"]} \n";
          sMsg += "שכר ${message["data"]["wage"]}\n";
          sMsg += "מיקום ${message["data"]["place"]}\n";
          final res = Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => JobConfirmCanceledPage(
                      sTitle: sMsg,
                      jobID: message["data"]["jobID"],
                    )),
          );
          res.then((s) {
            print("Canceled job before refresh");
            var res2 = refreshJobs();
          });
        } else if (message["data"]["message_status"] == "Hired") {
          String sMsg = "${message["data"]["discription"]} \n";
          sMsg +=
              "\nהתקבלת לעבודה על ידי ${message["data"]["firstName"]} ${message["data"]["lastName"]} \n";
          sMsg += "שכר ${message["data"]["wage"]}\n";
          sMsg += "מיקום ${message["data"]["place"]}\n";
          final res = Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => JobConfirmHirePage(
                      sTitle: sMsg,
                      jobID: message["data"]["jobID"],
                      workerID: message["data"]["workerID"],
                    )),
          );
          res.then((s) {
            print("hire job before refresh");
            var res2 = refreshJobs();
          });
        } else if (message["data"]["message_status"] == "Fired") {
          String sMsg = "${message["data"]["discription"]} \n";
          sMsg +=
              "\nהוחלט שלא להעסיק אותך! ${message["data"]["firstName"]} ${message["data"]["lastName"]} \n";
          sMsg += "שכר ${message["data"]["wage"]}\n";
          sMsg += "מיקום ${message["data"]["place"]}\n";
          final res = Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => JobConfirmFiredPage(
                      sTitle: sMsg,
                      jobID: message["data"]["jobID"],
                      workerID: message["data"]["workerID"],
                    )),
          );
          res.then((s) {
            print("fired job before refresh");
            var res2 = refreshJobs();
          });
        } else if (message["data"]["message_status"] == "Resigned") {
          var resUpdateFired = _services.confirmHire(
              message["data"]["jobID"], message["data"]["workerID"], false);
          resUpdateFired.then((s) {
            print("resigned job status updated");
          });
          String sMsg = "${message["data"]["discription"]} \n";
          sMsg +=
              "\n הודעת התפטרות! ${message["data"]["firstName"]} ${message["data"]["lastName"]} \n";
          sMsg += "שכר ${message["data"]["wage"]}\n";
          sMsg += "מיקום ${message["data"]["place"]}\n";
          final res = Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => JobConfirmResignPage(
                      sTitle: sMsg,
                      jobID: message["data"]["jobID"],
                      workerID: message["data"]["workerID"],
                    )),
          );
          res.then((s) {
            print("resigned job before refresh");
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
        //_workerDetails._radius = res["radius"];
        _workerDetails._wage = res["wage"];
        _workerDetails._place = res["place"];
        _bWorkerDetailsAreFull = res["detailsFull"];
        if (_workerDetails._photoAGCSPath != '') {
          getImageFromNetwork(_workerDetails._photoAGCSPath).then((f) {
            var res = getResolution(Image.file(f));
            res.then((info) {
              Image image = getAdjustedImageFromFile(f, info);
              setState(() {
                _image = image;
              });
            });
          });
        }
        _controllerWorkerFirstName.text = _workerDetails._firstName;
        _controllerWorkerLastName.text = _workerDetails._lastName;
        _controllerWorkerPlace.text = _workerDetails._place;
        _controllerWorkerWage.text = _workerDetails._wage.toString();
        //_controllerWorkerRadius.text = _workerDetails._radius.toString();

        _controllerWorkerFirstName.addListener(() {
          setState(() {
            _workerDetails._firstName = _controllerWorkerFirstName.text;
            _bWorkerIsUpdated = false;
          });
        });
        _controllerWorkerLastName.addListener(() {
          setState(() {
            _workerDetails._lastName = _controllerWorkerLastName.text;
            _bWorkerIsUpdated = false;
          });
        });
        _controllerWorkerWage.addListener(() {
          setState(() {
            _workerDetails._wage = double.parse(_controllerWorkerWage.text);
            _bWorkerIsUpdated = false;
          });
        });
        // _controllerWorkerRadius.addListener(() {
        //   setState(() {
        //     _workerDetails._radius = double.parse(_controllerWorkerRadius.text);
        //     _bWorkerIsUpdated = false;
        //   });
        // });
        _controllerWorkerPlace.addListener(() {
          _textForAutoCompleteWorkerChanged();
          setState(() {
            _bWorkerIsUpdated = false;
        //     this._overlayEntry = this._createOverlayEntry();
        // Overlay.of(context).insert(this._overlayEntry);
          });
        });
        
        if (!areDetailsFull()) {
          setState((){
           _bJobMenu = false;
          });
        }
        
      } else if (res["error"] == "no connection") {
         Navigator.pop(this.context, "הקשר לשרת נכשל, אנא נסה שוב מאוחר יותר");
      }
      
    });

    if (_bWorkerIsUpdated == false) {
      _updatingDetails();
    }
    var res2 = refreshJobs();
    // res2.then((bSuccess){
    //   if (bSuccess)
    //   {
    //     setState((){});
    //   }
    // });

    var resFuture2 = _services.getOccupationDetails();
    resFuture2.then((res) {
      if ((res["success"] == "true") || (res["success"] == true)) {
        setState(() {
          _lPossibleOccupation = fixEncoding(res["possibleFields"]);
          _workerDetails._lOccupationFieldListString =
              fixEncoding(res["pickedFields"]);
          _colorOccupation = new List<Color>.filled(
              _lPossibleOccupation.length, uncheckedColor);
          _selectedOccupation =
              new List<bool>.filled(_lPossibleOccupation.length, false);
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
    if (_overlayEntry!=null) {
    OverlayState s = Overlay.of(context);
    s.insert(this._overlayEntry);
    }
    var resFutureBoss = _services.getBossFieldDetails();
    resFutureBoss.then((res) {
      if ((res["success"] == "true") || (res["success"] == true)) {
        _bossDetails._firstName = res["firstName"];
        _bossDetails._lastName = res["lastName"];
        _bossDetails._buisnessName = res["buisnessName"];
        _bossDetails._lat = res["lat"];
        _bossDetails._lng = res["lng"];
        _bossDetails._photoAGCSPath = res["photoAGCSPath"];
        _bossDetails._place = res["place"];

        _controllerWorkerFirstName.text = _bossDetails._firstName;
        _controllerWorkerLastName.text = _bossDetails._lastName;
        _controllerBossBuisnessName.text = _bossDetails._buisnessName;

        _controllerBossPlace.text = _bossDetails._place;
        _bBossDetailsAreFull = res["detailsFull"];
        _controllerWorkerFirstName.addListener(() {
          setState(() {
            _bossDetails._firstName = _controllerWorkerFirstName.text;
            _bWorkerIsUpdated = false;
          });
        });
        _controllerWorkerLastName.addListener(() {
          setState(() {
            _bossDetails._lastName = _controllerWorkerLastName.text;
            _bWorkerIsUpdated = false;
          });
        });
        _controllerBossBuisnessName.addListener(() {
          setState(() {
            _bossDetails._buisnessName = _controllerBossBuisnessName.text;
            _bWorkerIsUpdated = false;
          });
        });
        _controllerBossPlace.addListener(() {
          _textForAutoCompleteBossChanged();
          setState(() {
            _bWorkerIsUpdated = false;
          });
        });
      }
    //   myFocusNodePlace.addListener(() {
    //   if (myFocusNodePlace.hasFocus) {

    //     this._overlayEntry = this._createOverlayEntry();
    //     Overlay.of(context).insert(this._overlayEntry);

    //   } else {
    //     this._overlayEntry.remove();
    //   }
    // });
      if (!areDetailsFull()) {
          setState((){
           _bJobMenu = false;
          });
        }
    });

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _pageController = PageController();

    final prefs = SharedPreferences.getInstance();
    prefs.then((o) {
      retreivePersistentState(o);
      setState(() {});
    });
    var location = new LocationGPS.Location();

    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      var c = location.getLocation();
      c.then((l) {
        print(l.toString());
        var lat = l.latitude;
        var lng = l.longitude;
        var loc = new Location(lat, lng);
        var res =
            _placesAPI.searchNearbyWithRadius(loc, 1000.0, language: "iw");
        res.then((v) {
          print(v.toString());
          if (v.status == "OK") {
            setState(() {
              _currLocation.name = v.results[0].name;
              _currLocation.lat = v.results[0].geometry.location.lat;
              _currLocation.lng = v.results[0].geometry.location.lng;
              _lPlacesWorkerDropDownList = [
                new DropdownMenuItem<String>(
                  value: _currLocation.name,
                  child: new Text(_currLocation.name),
                )
              ];
              _lPlacesBossDropDownList = [
                new DropdownMenuItem<String>(
                  value: _currLocation.name,
                  child: new Text(_currLocation.name),
                )
              ];
            });
          }
        });
      }).catchError((e) {
        print(e.toString());
        setState(() {
          _currLocation.name = 'מאור';
          _currLocation.lat = 32.423924;
          _currLocation.lng = 35.006394;
          _lPlacesWorkerDropDownList = [
            new DropdownMenuItem<String>(
              value: _currLocation.name,
              child: new Text(_currLocation.name),
            )
          ];
          _lPlacesBossDropDownList = [
            new DropdownMenuItem<String>(
              value: _currLocation.name,
              child: new Text(_currLocation.name),
            )
          ];
        });
      });

    } catch (e) {}

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _h = MediaQuery.of(context).size.height;
      _w = _heightImage * _image.width / _image.height;
      setState(() {
        _heightImage = _h * 0.15;
        _heightSwitch = _h * 0.05;
        _widthSwitch = _heightSwitch * 10;
        _heightMain = _h * 0.75;
      });
      String fileName;
      try {
        fileName = Singleton().persistentState.getString('profilePic');
      } catch (e) {}
      var bNotExists = (fileName==null) ? false : await File(fileName).exists();
      if (bNotExists) {
        if (fileName!=null) {
          Singleton().persistentState.remove('profilePic');
        }
        _image = new Image.asset('assets/img/no_portrait.png',
            fit: BoxFit.cover, width: _w, height: _heightImage);
      } else {
        try {
          _image = Image.file(File(fileName),
            fit: BoxFit.cover, width: _w, height: _heightImage);
            
        } catch (e) {
            print("addPostFrameCallback, File error - $e");
        }
        
      }
      WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
    
    });
    
  }

  Map<String, dynamic> areJobDetailsFull(JobsContext j) {
    
    String errMsg = "None";
    bool success = false;
    //WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
    var focusNode = j.ui.fnDiscription;
    if ((j.details?.discription ?? "") == "") {
      errMsg = "הוסף תיאור לעבודה";
      focusNode = j.ui.fnDiscription;
    } else if ((j.details?.lat ?? -1 )< 0 || (j.details.lng  ?? -1) < 0) {
      errMsg = "יש לבחור מיקום";
      focusNode = j.ui.fnPlace;
    } else if ((j.details?.place ?? "" ) == "") {
      errMsg = "יש לבחור מיקום";
      focusNode = j.ui.fnPlace;
    } else if ((j.details?.wage ?? -1) < 0) {
      errMsg = "שכר לא תקין";
      focusNode = j.ui.fnWage;
    } else if (j.details._lOccupationFieldListString.length == 0) {
      focusNode = j.ui.fnnOccupationList;
      errMsg = "יש לבחור תחום עיסוק";
    } else  {
      success = true;
    }
    if (!success) {
      setState(() {
        showInSnackBar(errMsg);
        focusNode.requestFocus();
      });
    }
    
    return {"success" : success, "errMsg" : errMsg};

  } 
  void _updatingDetails() {
    _bUpdatingDetails = true;
        if (!_bWorkerIsUpdated) {
          print(_workerDetails.toJSON());

          _workerDetails._photoAGCSPath = _imageFileBase64Data;
          _services.updateInputForm(_workerDetails.toJSON()).then((res) {
            
            if (res.containsKey("success") &&
                ((res["success"] == "true") || (res["success"] == true))) {
              setState(() {
                _bWorkerIsUpdated = true;
                _bUpdatingDetails = false;
                _bWorkerDetailsAreFull = res["detailsFull"];
              });
            }
          });
          _services.updateBossInputForm(_bossDetails.toJSON()).then((res) {
            if (res.containsKey("success") &&
                ((res["success"] == "true") || (res["success"] == true))) {
              _bBossDetailsAreFull = res["detailsFull"];
              setState(() {
                _bWorkerIsUpdated = true;
                _bUpdatingDetails = false;
              });
            }
          });
        } else {
          _bUpdatingDetails = false;
        }
        if (_iJobIsUpdated != -1) {
          if (_idJobIsUpdated == "-1") {
            var r = areJobDetailsFull(_lJobs[_iJobIsUpdated]);
            if (!r["success"]) {
              return;
            }
            _services
                .updateJobAsBoss(_lJobs[_iJobIsUpdated].details.toJSON())
                .then((res) {
              if (res.containsKey("success") &&
                  ((res["success"] == "true") || (res["success"] == true))) {
                setState(() {
                  _lJobs[_iJobIsUpdated].details._jobId = res['jobID'];
                  _lJobs[_iJobIsUpdated].details.bDetailsUpdated = true;
                  _iJobIsUpdated = -1;
                  _idJobIsUpdated = "";
                  _bUpdatingDetails = false;
                });
              }
            });
          } else {
            _lJobs.forEach((j) {
              if (_lJobsIDsMarkedForDeletion.contains(_idJobIsUpdated)) {
                _services.deleteJobAsBoss(_idJobIsUpdated).then((res) {
                  if (res.containsKey("success") &&
                      ((res["success"] == "true") ||
                          (res["success"] == true))) {
                    setState(() {
                      _iJobIsUpdated = -1;
                      _idJobIsUpdated = "";
                      _lJobsIDsMarkedForDeletion.remove(_idJobIsUpdated);
                      _bUpdatingDetails = false;
                    });
                  }
                });
              } else if (j.details._jobId == _idJobIsUpdated) {
                _services.updateJobAsBoss(j.details.toJSON()).then((res) {
                  if (res.containsKey("success") &&
                      ((res["success"] == "true") ||
                          (res["success"] == true))) {
                    setState(() {
                      _lJobs[_iJobIsUpdated].details._jobId = res['jobID'];
                      _lJobs[_iJobIsUpdated].details.bDetailsUpdated = true;
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
          res2.then((bSuccess) {
            if (bSuccess) {
              setState(() {
                _bUpdatingDetails = false;
              });
            }
          });
          
        }
  }
  void _select(AppBarChoice choice) {
    // Causes the app to rebuild with the new _selectedChoice.
      if (choices.indexOf(choice) == eChoice.updateDetails.index) {
        setState(() {
          _bJobMenu = false;
        });
      } else if (choices.indexOf(choice) == eChoice.logoff.index) {

      }
      // if (choice.title == "update") {
      //   _updatingDetails();
      // }
      // if (choice.title == "jobs") {
      //   setState(() {
      //     _bJobMenu = !_bJobMenu;
      //     if (_bJobMenu) {
      //       var res2 = refreshJobs();
      //       res2.then((bSuccess) {
      //         if (bSuccess) {
      //           setState(() {
      //             _bUpdatingDetails = false;
      //             _updatingDetails();
      //           });
      //         }
      //       });
      //     }
      //   });
      // }
      // if (choice.title == "debug") {
      //     print(_workerDetails.toString());
      //     debugDumpApp();
      //     debugDumpRenderTree();
      // }

    //});
  }

  void setPlaceLatLng(String sPlace, {String jobId = ""}) {
    _placesAPI.searchByText(sPlace, language: "iw").then((a) {
      if (a.results.length > 0) {
        setState(() {
          if (_bBossMode) {
            if (jobId != "") {
              int jobIndex = _lJobs.indexWhere((j) => (j.details.jobId == jobId));
              _lJobs[jobIndex].details._lat =
                  a.results[0].geometry.location.lat;
              _lJobs[jobIndex].details._lng =
                  a.results[0].geometry.location.lng;
              _lJobs[jobIndex].details._place = a.results[0].name;
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
    showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          return new Theme(
              data: new ThemeData(
                fontFamily: "WorkSansSemiBold",
                canvasColor:
                    ZarizTheme.Colors.zarizGradientStart, //my custom color
              ),
              child: new Container(
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
                  child: new Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        new IconButton(
                            icon: Icon(FontAwesomeIcons.camera),
                            onPressed: () {
                              _source = ImageSource.camera;
                              imagePick(_source);
                            }),
                        new IconButton(
                            icon: Icon(FontAwesomeIcons.fileImage),
                            onPressed: () {
                              _source = ImageSource.gallery;
                              imagePick(_source);
                            }),
                      ])));
        });
  }

  getResolution(Image image) {
    Completer<ImageInfo> completer = new Completer<ImageInfo>();
    image.image.resolve(new ImageConfiguration()).addListener(
        new ImageStreamListener(
            (ImageInfo info, bool _) => completer.complete(info)));
    return completer.future;
  }

  Image getAdjustedImageFromFile(File img, ImageInfo info) {
    var _w = _heightImage * info.image.width / info.image.height;
    return (Image.file(img, fit: BoxFit.fill, width: _w, height: _heightImage));
  }

  void imagePick(ImageSource _source) {
    ImagePicker.pickImage(source: _source, maxHeight: 240, maxWidth:352).then((img) {
      var res = getResolution(Image.file(img));
      res.then((info) {
        Image image = getAdjustedImageFromFile(img, info);
        var prefix = img.path.split('.')[img.path.split('.').length - 1];
        List<int> imageBytes = img.readAsBytesSync();
        saveImage(imageBytes, "jpg").then((sFileName) {});
        setState(() {
          _imageFileBase64Data =
              'data:image/$prefix;base64,' + base64.encode(imageBytes);
          _image = image;
        });
        Navigator.pop(context);
      });
    });
  }

  //Animation<Color> _zarizGradientColorAnimation;
  Decoration decorationBossWorker(BuildContext context, bool bIsWorker) {
    try {
      //setState(() {
      //_controllerAnimation = AnimationController(
      //vsync: this,
      //duration: Duration(
      //seconds: 5),);;
      _zarizGradientColorAnimation = bIsWorker
          ? ZarizTheme.Colors.zarizGradientStart2
          : ZarizTheme.Colors.zarizGradientStart1;
      // ColorTween(
      //   begin: bIsWorker?ZarizTheme.Colors.zarizGradientStart1:ZarizTheme.Colors.zarizGradientStart2,
      //   end: bIsWorker?ZarizTheme.Colors.zarizGradientStart2:ZarizTheme.Colors.zarizGradientStart1).
      //   animate(_controllerAnimation);
      //});
    } catch (e) {
      print(e);
      // This is a hack to fix the exception - setState() or markNeedsBuild() called during build.
      // This is due to it always failing when a message is arrived at the same time the job live page is built.
      (Future<Decoration>.delayed(new Duration(milliseconds: 500), (() {
        return decorationBossWorker(context, bIsWorker);
      }))).then((d) {
        return d;
      });
    }

    return new BoxDecoration(
      gradient: new LinearGradient(
          colors: [
            _zarizGradientColorAnimation == null
                ? (bIsWorker
                    ? ZarizTheme.Colors.zarizGradientStart2
                    : ZarizTheme.Colors.zarizGradientStart1)
                : _zarizGradientColorAnimation,
            ZarizTheme.Colors.zarizGradientEnd
          ],
          begin: const FractionalOffset(0.0, 0.0),
          end: const FractionalOffset(1.0, 1.0),
          stops: [0.0, 1.0],
          tileMode: TileMode.clamp),
    );
  }

  Widget buildInternal(BuildContext context) {
    _pages = [
      new AnimatedCrossFade(
        firstChild: _buildWorkerJobTileList(context),
        secondChild: _buildWorkerDetails1(context),
        duration: const Duration(milliseconds: 500),
        crossFadeState:
            _bJobMenu ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      ),
      new AnimatedCrossFade(
        firstChild: _buildBossJobsCarousel(context),
        secondChild: _buildBossDetails1(context),
        duration: const Duration(milliseconds: 500),
        crossFadeState:
            _bJobMenu ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      ),
    ];
    return new Flexible(
        child: AnimatedCrossFade(
      firstChild: _pages[0],
      secondChild: _pages[1],
      duration: const Duration(milliseconds: 500),
      crossFadeState:
          _bBossMode ? CrossFadeState.showSecond : CrossFadeState.showFirst,
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
    OverlayEntry _createOverlayEntry() {

    RenderBox renderBox = context.findRenderObject();
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 5.0,
        width: size.width,
        child: Material(
          elevation: 4.0,
          child: ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children: <Widget>[
              ListTile(
                title: Text('Syria'),
              ),
              ListTile(
                title: Text('Lebanon'),
              )
            ],
          ),
        ),
      )
    );
  }
  Future<bool>  jobStatusPopUpMenu(String sName, bool bAuthorized, bool bResponded, bool bHired, bool bAsWorker )  {
    String sTitle = "אתה בטוח שאתה רוצה לפטר את $sName?";
    if (!bAsWorker) {
      if (!bHired) {
        if (bResponded) {
          sTitle = "אתה בטוח שאתה רוצה להעסיק את $sName?";
        }
      }
    } else {
      if (bHired) {
        sTitle = "אתה בטוח שאתה רוצה להתפטר מ $sName?";
      } else if (!bResponded) {
        sTitle = "אתה בטוח שאתה מעניין ב $sName?";
      } else {
        sTitle = "אתה בטוח שאתה לא מעוניין ב $sName?";
      }
    }
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
    //      return Dialog()
      return Dialog(
    // context: context,Dialog(
  backgroundColor: Colors.transparent,
  insetPadding: EdgeInsets.all(10),
  child: Stack(
    overflow: Overflow.visible,
    alignment: Alignment.center,
    children: <Widget>[
      Container(
        width: double.infinity,
        height: 5 * _heightSwitch,
        decoration: BoxDecoration(borderRadius: new BorderRadius.all(
                 const Radius.circular(40.0),
               
              ), gradient: new LinearGradient(colors:   [
                      ZarizTheme.Colors.zarizGradientStart2,
                      ZarizTheme.Colors.zarizGradientEnd
                    ],)),
        padding: EdgeInsets.fromLTRB(20, 75, 20, 5),
        child: Directionality(textDirection: TextDirection.rtl, child: Column(children: [
                        createTitle(sTitle, textSize: 18.0, color: Colors.black),
                        Center(child: Row(crossAxisAlignment: CrossAxisAlignment.start,mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                        FlatButton(child: createTitle("כן"), color:Colors.green, onPressed: () => Navigator.of(context).pop(true)),
                        FlatButton(child: createTitle("לא"), color:Colors.red,onPressed: () => Navigator.of(context).pop(false)),
                        ])),
                      ],)),
        ),
    
      Positioned(
        top: -50,
        child: Card(shape: CircleBorder(), child: Icon(FontAwesomeIcons.question, color: Colors.red[300], size: 100), color: Colors.brown, elevation: 2.0)

      )
    ],
  )
);}
    );
    // return showDialog<bool>(
    // context: context,
    // builder: (BuildContext context) {
    //      return AlertDialog(
    //        shape: CircleBorder(),
    //        titleTextStyle: TextStyle(),
    //        backgroundColor: Colors.brown.withOpacity(1.0),
    //        elevation: 2.0,
    //         title: Center(child: Text("פיטורים", style: TextStyle(color: Colors.white54),)),
    //         content: Text("?אתה בטוח שאתה רוצה לפטר את $sName"),
    //         actionsPadding: EdgeInsets.fromLTRB(20, 50, 20, 20),
    //         actions: <Widget>[
    //             FlatButton(child: createTitle("כן"), onPressed: () => Navigator.of(context).pop(true)),
    //             FlatButton(child: createTitle("לא"), onPressed: () =>  Navigator.of(context).pop(false))
    //         ],
    //       );
    //     });
  }
  bool areDetailsFull() {
    return (_bBossMode && _bBossDetailsAreFull) ||
        (!_bBossMode && _bWorkerDetailsAreFull);
  }
  Widget buildFrame(BuildContext context, Widget internalWidget,
      GlobalKey<ScaffoldState> scaffoldKey, actionButtonWidget) {
    bool bDetailsAreFull = areDetailsFull();
    
    return new Directionality(
      textDirection: TextDirection.rtl,
      child: new Scaffold(
        appBar: AppBar(
          title: FittedBox(
            child: Text(_bBossMode
                ? (_bJobMenu ? (_bShrinkJobMenu ? _titleBossJobsWorkersList : _titleBossJobsWorkDetails) : _titleBossProfile) :  
                (_bJobMenu ? (_bMapView ?  _titleWorkerJobsMapView : _titleWorkerJobsList) : _titleWorkerProfile)),
            fit: BoxFit.scaleDown,
          ),
          actions: <Widget>[
            // LayoutBuilder(builder: (context, constraint) {
            //   return new IconButton(
            //     icon: new Icon(FontAwesomeIcons.check,
            //         size: constraint.biggest.height * 0.51),
            //     onPressed: () {
            //       _select(choices[0]);
            //     },
            //     color: (_bWorkerIsUpdated && _iJobIsUpdated == -1)
            //         ? Colors.green
            //         : Colors.red,
            //     tooltip: (_bWorkerIsUpdated && _iJobIsUpdated == -1)
            //         ? "מעודכן"
            //         : "עדכן",
            //   );
            // }),
            // action button
            // LayoutBuilder(builder: (context, constraint) {
            //   return new IconButton(
            //     icon: _bJobMenu
            //         ? Icon(FontAwesomeIcons.pencilAlt,
            //             size: constraint.biggest.height * 0.45,
            //             color: Colors.white54)
            //         : Icon(FontAwesomeIcons.hammer,
            //             size: constraint.biggest.height * 0.45,
            //             color: bDetailsAreFull
            //                 ? ZarizTheme.Colors.zarizGradientStart
            //                 : Colors.grey),
            //     disabledColor: Colors.grey,
            //     tooltip: _bJobMenu ? "עריכת פרטים" : "הצגת עבודות",
            //     onPressed: () {  
            //       bDetailsAreFull
            //           ? _select(choices[1])
            //           : showInSnackBar("הפרטים לא מלאים");
            //     },
            //   );
            // }),
            PopupMenuButton<AppBarChoice>(
              color: Colors.brown,
              onSelected: _select,
              itemBuilder: (BuildContext context) {
                //return choices.skip(2).map((AppBarChoice choice) {
                return choices.map((AppBarChoice choice) {
                  return PopupMenuItem<AppBarChoice>(
                    value: choice,
                    child: Text(choice.title),
                    textStyle: TextStyle(color: Colors.white),
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
            duration: new Duration(milliseconds: 500),
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height >= hDefault
                ? MediaQuery.of(context).size.height
                : hDefault,
            decoration: decorationBossWorker(context, _bBossMode),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 2.0),
                  child: new FlatButton(
                    onPressed: onImagePressed,
                    child: new ClipRRect(
                      child: _image,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 2.0, bottom: 5.0),
                  child: _buildSwitchBar(context),
                ),
                (_bIsLoadingPlaces || _bUpdatingDetails)
                    ? new CircularProgressIndicator(
                        backgroundColor: ZarizTheme.Colors.zarizGradientStart)
                    : new Container(),
                internalWidget,
                Padding(child: Align(child: actionButtonWidget, alignment: Alignment.bottomCenter), padding: EdgeInsets.only(top: _heightSwitch / 4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget pickActionButtonWidget() {
    
    //return Container();
    if (_bJobMenu) {
      if (_bBossMode) {
        //return Container();
        return addJobWidgetActionButton();
      } else {
        //return Container();
        return addWorkerJobActionButton();
      }
    } else {
        return addUpdateDetailsWidgetActionButton(true);
    }
  }
  Widget build(BuildContext context) {
    return buildFrame(context, buildInternal(context), _scaffoldKey, pickActionButtonWidget());
  }

  Future<bool> refreshJobs() async {
    _services.getAllJobsAsWorker().then((res) { 
      if (res["success"] == "true" || res["success"] == true) {
        _jobDetailsForWorkerList = [];
        for (int i = 0; i < (res.length - 1); i++) {
          var resJ = res[i.toString()];
          var j = resJ["JobDetails"];
          JobsDetails jd = new JobsDetails()
            .._place = j["place"]
            .._jobId = j["jobID"]
            .._discription = j["discription"]
            .._lat = j["lat"]
            .._lng = j["lng"]
            .._wage = j["wage"]
            .._lOccupationFieldListString = [j["occupationFieldListString"]]
            ..bDetailsUpdated = resJ["detailsFull"];
          var b = resJ["BossDetails"];
          BossDetails bd = new BossDetails()
            .._buisnessName = b["buisnessName"]
            .._firstName = b["firstName"]
            .._lastName = b["lastName"]
            .._lat = b["lat"]
            .._lng = b["lng"]
            .._photoAGCSPath = b["photoAGCSPath"]
            .._place = b["place"];
          JobDetailsForWorker jdw = new JobDetailsForWorker(this)
            ..bd = bd
            ..jd = jd
            ..bResponded = resJ["bResponded"]
            ..bAuthorized = resJ["bAuthorized"]
            ..bHired = resJ["bHired"];
          _jobDetailsForWorkerList.add(jdw);
        }
        setState(() {});
      }
    });
    _services.getAllJobsAsBoss().then((res) {
      if (res["success"] == "true" || res["success"] == true) {
        _lJobs = [];
        for (int i = 0; i < (res.length - 1); i++) {
          var j = res[i.toString()];
          _lJobs.add(new JobsContext(new JobsDetails()
            .._place = j["place"]
            .._jobId = j["jobID"]
            .._discription = j["discription"]
            .._lat = j["lat"]
            .._lng = j["lng"]
            .._wage = j["wage"]
            .._lOccupationFieldListString = [j["occupationFieldListString"]]
            ..bDetailsUpdated = j["detailsFull"]));
          j["workerID_responded"].forEach((workers) {
            var resFuture = _services.getWorkerDetailsForID(workers);
            resFuture.then((res) {
              if ((res["success"] == "true") || (res["success"] == true)) {
                try {
                  var oldVal = _lJobs[i]
                      .lWorkersResponded
                      ?.firstWhere((a) => a._userID == res["userID"]);
                  _lJobs[i].lWorkersResponded.remove(oldVal);
                } catch (e) {}
                _lJobs[i].lWorkersResponded.add(new WorkerDetails()
                  .._firstName = res["firstName"]
                  .._lastName = res["lastName"]
                  .._lat = res["lat"]
                  .._lng = res["lng"]
                  .._photoAGCSPath = res["_photoAGCSPath"]
                  // .._radius = res["radius"]
                  .._wage = res["wage"]
                  .._place = res["place"]
                  .._userID = res["userID"]);
              } else {
                return false;
              }
              setState(() {
                _lJobs[i].lWorkersResponded = _lJobs[i].lWorkersResponded;
              });
            });
          });
          j["workerID_sentNotification"].forEach((workers) {
            var resFuture = _services.getWorkerDetailsForID(workers);
            resFuture.then((res) {
              if ((res["success"] == "true") || (res["success"] == true)) {
                try {
                  var oldVal = _lJobs[i]
                      .lWorkersNotified
                      ?.firstWhere((a) => a._userID == res["userID"]);
                  _lJobs[i].lWorkersNotified.remove(oldVal);
                } catch (e) {}
                _lJobs[i].lWorkersNotified.add(new WorkerDetails()
                  .._firstName = res["firstName"]
                  .._lastName = res["lastName"]
                  .._lat = res["lat"]
                  .._lng = res["lng"]
                  .._photoAGCSPath = res["_photoAGCSPath"]
                  // .._radius = res["radius"]
                  .._wage = res["wage"]
                  .._place = res["place"]
                  .._userID = res["userID"]);
              } else {
                return false;
              }
              setState(() {
                _lJobs[i].lWorkersNotified = _lJobs[i].lWorkersNotified;
              });
              return true;
            });
          });
          j["workerID_authorized"].forEach((workers) {
            var resFuture = _services.getWorkerDetailsForID(workers);
            resFuture.then((res) {
              if ((res["success"] == "true") || (res["success"] == true)) {
                try {
                  var oldVal = _lJobs[i]
                      .lWorkersAuthorized
                      ?.firstWhere((a) => a._userID == res["userID"]);
                  _lJobs[i].lWorkersAuthorized.remove(oldVal);
                } catch (e) {}
                _lJobs[i].lWorkersAuthorized.add(new WorkerDetails()
                  .._firstName = res["firstName"]
                  .._lastName = res["lastName"]
                  .._lat = res["lat"]
                  .._lng = res["lng"]
                  .._photoAGCSPath = res["_photoAGCSPath"]
                  // .._radius = res["radius"]
                  .._wage = res["wage"]
                  .._place = res["place"]
                  .._userID = res["userID"]);
              } else {
                return false;
              }
              setState(() {
                _lJobs[i].lWorkersAuthorized = _lJobs[i].lWorkersAuthorized;
              });
              return true;
            });
          });
          j["workerID_hired"].forEach((workers) {
            var resFuture = _services.getWorkerDetailsForID(workers);
            resFuture.then((res) {
              if ((res["success"] == "true") || (res["success"] == true)) {
                try {
                  var oldVal = _lJobs[i]
                      .lWorkersHired
                      ?.firstWhere((a) => a._userID == res["userID"]);
                  _lJobs[i].lWorkersHired.remove(oldVal);
                } catch (e) {}
                _lJobs[i].lWorkersHired.add(new WorkerDetails()
                  .._firstName = res["firstName"]
                  .._lastName = res["lastName"]
                  .._lat = res["lat"]
                  .._lng = res["lng"]
                  .._photoAGCSPath = res["_photoAGCSPath"]
                  // .._radius = res["radius"]
                  .._wage = res["wage"]
                  .._place = res["place"]
                  .._userID = res["userID"]);
              } else {
                return false;
              }
              setState(() {
                _lJobs[i].lWorkersHired = _lJobs[i].lWorkersHired;
              });
              return true;
            });
          });

          print(
              "refreshJobs, !!!!!!!!!! job #$i - _lJobs[i].lWorkersNotified.length ${_lJobs[i].lWorkersNotified.length}");
        }
      }
    });
    return true;
  }

  void onImagePressed() {
    getImage();
  }

  _textForAutoCompleteChanged(
      String t, List<DropdownMenuItem<String>> l) {
    if ((t.length > 2) && (t.length > _tLength)) {
      setState(() {
        _bIsLoadingPlaces = true;
      });
      Location nearL = new Location(_currLocation.lat, _currLocation.lng);
      _placesAPI
          .queryAutocomplete(t,
              location: nearL, radius: 300000.0, language: "iw")
          .then((res) {
        setState(() {
          l.clear();
        });
        for (var i = 0; i < res.predictions.length; i++) {
          setState(() {
            l.add(new DropdownMenuItem<String>(
              value: res.predictions[i].description,
              child: new Text(res.predictions[i].description),
            ));
          });
        }
        setState(() {
          _bIsLoadingPlaces = false;
        });
      }).catchError((e) {
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
    _textForAutoCompleteChanged(_controllerBossPlace.text, _lPlacesBossDropDownList);
  }

  _textForAutoCompleteWorkerChanged() {
    _textForAutoCompleteChanged(
        _controllerWorkerPlace.text, _lPlacesWorkerDropDownList);
      setState(() {
        
      
    // this._overlayEntry = this._createOverlayEntry();
    });
  }

  void showInSnackBar(String value) {
    FocusScope.of(context).requestFocus(new FocusNode());
    _scaffoldKey.currentState?.removeCurrentSnackBar();
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: new Directionality(
          textDirection: TextDirection.rtl,
          child: new Card(
              child: new Text(
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
    double delta = 0.1 * _widthSwitch;
    //double switchAnimCurveValue_ = _switchAnimCurve.value * 2 - 1.0 + (_widthSwitch/2)/MediaQuery.of(context).size.width;
    double switchAnimCurveValue_Boss_Pos =
        -1.0 + (_widthSwitch + delta) / MediaQuery.of(context).size.width;
    double switchAnimCurveValue_Worker_Pos = 1.0;
    double pos = _switchAnimCurve.value * switchAnimCurveValue_Boss_Pos +
        (1 - _switchAnimCurve.value) * switchAnimCurveValue_Worker_Pos -
        1.0;
    //print("pos - $pos org - ${_switchAnimCurve.value}");
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
      child: new Stack(fit: StackFit.expand,
          //             alignment: Alignment.topCenter,
          //             overflow: Overflow.visible,
          children: <Widget>[
            new FractionallySizedBox(
                heightFactor: 1.0,
                widthFactor: 0.2,
                alignment: new Alignment(switchAnimCurveValue(), 0.0),
                //PositionedTransition(rect: switchAnimation,
                child: new CustomPaint(
                  painter: TabIndicationPainterNoPageController(
                      dxTarget: 0.0,
                      radius: (_heightSwitch / 2),
                      dy: (_heightSwitch / 2),
                      dxEntry: (_widthSwitch / 2),
                      color: ZarizTheme.Colors.zarizGradientEnd.value,
                      listener: _tabIndicationPainterNoPageControllerListener),
                )),
            Row(
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
    setState(() {
      _bBossMode = false;
      if (areDetailsFull()) {
        _bJobMenu = true;
      } else {
        _bJobMenu = false;
      }

      _tabIndicationPainterNoPageControllerListener.iPos = 0;
      _switchAnimController.forward();
    });
    //_pageController .jumpToPage(0);

    // _pageController.animateToPage(0,
    //     duration: Duration(milliseconds: 500), curve: Curves.decelerate);
  }

  void _onBossButtonPress() {
    setState(() {
      _bBossMode = true;
      
      if (areDetailsFull()) {
        _bJobMenu = true;
      } else {
        _bJobMenu = false;
      }
      _switchAnimController.reverse();
    });
    _tabIndicationPainterNoPageControllerListener.iPos = 1;
    //_pageController?.animateToPage(1,
    //    duration: Duration(milliseconds: 500), curve: Curves.decelerate);
  }
    
  Widget _createAutoCompleteTextField(TextEditingController controller, String labeltext, {String jobId = ""}) {
    
    return Padding(padding: EdgeInsets.only(top: 10.0, bottom: 10.0, left: 25.0, right: 25.0), 
    child: TypeAheadField(
      direction: AxisDirection.up,
      noItemsFoundBuilder: ((context) {return Container();}),//Text("לא נמצאו תוצאות", textAlign: TextAlign.start, textDirection: TextDirection.rtl,);}),
      suggestionsBoxDecoration: SuggestionsBoxDecoration(
                    hasScrollbar: true,
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    color: Colors.white54,
                    constraints: BoxConstraints(maxHeight: 200, maxWidth: 400),
                    
                    
      ),
  textFieldConfiguration: TextFieldConfiguration(
    textDirection: TextDirection.rtl,
    textAlign: TextAlign.right,
    controller: controller,
    autofocus: true,
    style: TextStyle(
              fontFamily: "WorkSansSemiBold", fontSize: 16.0),
    decoration: InputDecoration(
      //contentPadding: EdgeInsets.only(top: 10.0, bottom: 10.0, left: 25.0, right: 25.0),
      border: InputBorder.none,
          focusedBorder : InputBorder.none,
      hintStyle: TextStyle(
              fontFamily: "WorkSansSemiBold", fontSize: 12.0),
      labelText: labeltext,
      
      icon: Icon(
            FontAwesomeIcons.mapMarker,
            size: 22.0,
            color: Colors.black87,
          ),
      hintText: labeltext
    )
  ),
  suggestionsCallback: (pattern) async {
    Location nearL = new Location(_currLocation.lat, _currLocation.lng);
    List<String> places = [];
    var res = await _placesAPI.queryAutocomplete(pattern, location: nearL, radius: 300000.0, language: "iw");
    for (var i = 0; i < res.predictions.length; i++) {
      places.add(res.predictions[i].description);
      print("pattern $pattern, predictions ${res.predictions[i].description}");
    }
    return places;
  },
  itemBuilder: (context, suggestion) {
    return ListTile(
      // leading: Icon(Icons.shopping_cart),
      title: Text(suggestion),
      // subtitle: Text('\$${suggestion['price']}'),
    );
  },
  onSuggestionSelected: (suggestion) {
    setPlaceLatLng(suggestion, jobId: jobId);
    setState((){
      controller.text = suggestion;
      });
    
    
  },
));
  }




  //   RenderBox renderBox = context.findRenderObject();
  //   var size = renderBox.size;
  //   var offset = renderBox.localToGlobal(Offset.zero);

  //   return OverlayEntry(
  //     builder: (context) => Positioned(
  //       left: offset.dx,
  //       top: offset.dy + size.height + 5.0,
  //       width: size.width,
  //       child: Material(
  //         child: ListView(
  //           padding: EdgeInsets.zero,
  //           shrinkWrap: true,
  //           children: <Widget>[
  //             ListTile(
  //               title: Text('Syria'),
  //             ),
  //             ListTile(
  //               title: Text('Lebanon'),
  //             )
  //           ],
  //         ),
  //       ),
  //     )
  //   );
  // }


  Widget _buildWorkerDetails1(BuildContext context) {
    return new Directionality(
      textDirection: TextDirection.rtl,
      child: new AnimatedContainer(
        duration: new Duration(milliseconds: 500),
        decoration: decorationBossWorker(context, false),
        padding: EdgeInsets.only(top: 23.0),
        child: Card(
            elevation: 2.0,
            color: Colors.white54,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: SingleChildScrollView(
                //width: MediaQuery.of(context).size.width * 5 / 6,
                //height: MediaQuery.of(context).size.height * 2,
                child: new  Column(children: <Widget>[
              Padding(
                padding: EdgeInsets.only(
                    top: 5.0, bottom: 5.0, left: 25.0, right: 25.0),
                child: new Row(children: <Widget>[
                  new Flexible(
                      child: createTextField(
                          "פרטי",
                          myFocusNodeFirstName,
                          _controllerWorkerFirstName,
                          FontAwesomeIcons.userAlt)),
                  new Flexible(
                      child: createTextField("משפחה", myFocusNodeLastName,
                          _controllerWorkerLastName, FontAwesomeIcons.users)),
                ]),
              ),
              Container(
                width: 250.0,
                height: 1.0,
                color: Colors.grey[400],
              ),
              new Row(children: <Widget>[
                new Flexible(
                    // child: createTextField("מקום (הכנס 2 תווים ובחר מהרשימה)", myFocusNodePlace,
                    //     _controllerWorkerPlace, FontAwesomeIcons.mapMarker),
                        child: _createAutoCompleteTextField(_controllerWorkerPlace, "(מקום (הכנס 2 תווים ובחר מהרשימה)"))
              ]),
              
              //))) : Container(),
              Container(
                width: 250.0,
                height: 1.0,
                color: Colors.grey[400],
              ),
              // createTextField("מרחק", myFocusNodeRadius,
              //     _controllerWorkerRadius, FontAwesomeIcons.route,
              //     keyboardType: TextInputType.number),
              // Container(
              //   width: 250.0,
              //   height: 1.0,
              //   color: Colors.grey[400],
              // ),
              createTextField("שכר", myFocusNodeWage, _controllerWorkerWage,
                  FontAwesomeIcons.shekelSign,
                  keyboardType: TextInputType.number,
                  direction: TextDirection.ltr),
              Container(
                width: 250.0,
                height: 1.0,
                color: Colors.grey[400],
              ),
              occupationChipsBuild(),
            ]))),
      ),
    );
  }



  Iterable<Widget> get occupationWidget sync* {
    final Color uncheckedColor =
        ZarizTheme.Colors.zarizGradientEnd2.withAlpha(60);
    for (String occupation in _lPossibleOccupation) {
      yield Padding(
        padding: const EdgeInsets.all(4.0),
        child: FilterChip(
          shape: RoundedRectangleBorder(
            side: new BorderSide(
                color: _workerDetails == null
                    ? uncheckedColor
                    : _workerDetails._lOccupationFieldListString == null
                        ? uncheckedColor
                        : _workerDetails._lOccupationFieldListString
                                .contains(occupation)
                            ? checkedColor
                            : uncheckedColor,
                width: 6.0),
            borderRadius: BorderRadius.circular(8.0),
          ),
          label: Text(occupation),
          selected: (_workerDetails == null)
              ? false
              : (_workerDetails._lOccupationFieldListString == null)
                  ? false
                  : _workerDetails._lOccupationFieldListString
                      .contains(occupation),
          backgroundColor: ZarizTheme.Colors.zarizGradientEnd2.withAlpha(60),
          selectedColor: ZarizTheme.Colors.zarizGradientEnd2.withAlpha(60),
          onSelected: (bool value) {
            setState(() {
              if (value) {
                _workerDetails._lOccupationFieldListString.add(occupation);
              } else {
                _workerDetails._lOccupationFieldListString
                    .removeWhere((String name) {
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

  GridView createMultiGridView() {
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
              elevation: (_selectedOccupation[index]) ? 6.0 : 2.0,
              color: Colors.white54,
              shape: RoundedRectangleBorder(
                side: new BorderSide(
                    color: _colorOccupation[index],
                    width: (_selectedOccupation[index]) ? 6.0 : 12.0),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: new Text('$s',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: "WorkSansSemiBold",
                      fontSize: 16.0,
                      color: Colors.black)),
            ),
            onTap: () {
              setState(() {
                _selectedOccupation[index] = !_selectedOccupation[index];
                if (_selectedOccupation[index]) {
                  _colorOccupation[index] =
                      checkedColor; //.Colors.zarizGradientEnd.withAlpha(10);
                } else {
                  _colorOccupation[index] =
                      uncheckedColor; //ZarizTheme.Colors.zarizGradientEnd.withAlpha(240);
                }

                _bWorkerIsUpdated = false;
                _workerDetails._lOccupationFieldListString = [];
                for (var i = 0; i < _selectedOccupation.length; i++) {
                  if (_selectedOccupation[i]) {
                    _workerDetails._lOccupationFieldListString
                        .add(_lPossibleOccupation[i]);
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
  Widget addUpdateDetailsWidgetActionButton(bool bIsEmpty) {
    return new Column(children: [
      RawMaterialButton(
        constraints: //bIsEmpty ? 
            BoxConstraints.loose(Size(_widthSwitch / 8, _heightSwitch)),
            //: BoxConstraints.loose(Size(88.0, 36.0)),
        fillColor: Colors.green[300],
        splashColor: Colors.white,
        child: new Container(
          decoration: new BoxDecoration(
            shape: BoxShape
                .circle, // You can use like this way or like the below line
            //borderRadius: new BorderRadius.circular(30.0),
            color: Colors.green[300],
          ),
          child: new Icon(Icons.check, size: _widthSwitch / 8),
        ),
        onPressed: (() {
          setState(() {
            _updatingDetails();
            _bJobMenu = true;
            _bShrinkJobMenu =true;
          });
        }),
        shape: new CircleBorder(),
      ),
      bIsEmpty
          ? Text(
              'עדכן פרטים',
              textScaleFactor: 1.5,
              style: TextStyle(color: Colors.white))
          : Text('עדכן פרטים', style: TextStyle(color: Colors.white)),
    ]);
    //return Container();
  }
  Widget addWorkerJobActionButton()
  { 
    return Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    
                                    
                                      // child: new Card(
                                      //     elevation: 6.0,
                                      //     color: Colors.white54,
                                      //     shape: RoundedRectangleBorder(
                                      //       borderRadius:
                                      //           BorderRadius.circular(4.0),
                                      //     ),
                                          child: Column( children: [RawMaterialButton(
                                            // constraints:  BoxConstraints.loose(Size(_widthSwitch, _heightSwitch)),
            // : BoxConstraints.loose(Size(88.0, 36.0)),
      fillColor: Colors.blue[300],
      splashColor: Colors.white,
      //shape: new CircleBorder(),
      child: new Container(
        width : _widthSwitch / 8,
        height : _widthSwitch / 8,
        decoration: new BoxDecoration(
         shape: BoxShape.circle,
         //borderRadius: new BorderRadius.circular(30.0),
           // You can use like this way or like the below line
          //borderRadius: new BorderRadius.circular(30.0),
          color: Colors.blue[300],
        ),
        child: new Icon(
            _bMapView ?
                FontAwesomeIcons.list : FontAwesomeIcons.mapMarked,
              size: _widthSwitch / 12,
              ),
      ),
      onPressed: ((){setState(() {
            _bMapView = !_bMapView;
          });}),
          shape: CircleBorder()
    ),
    _bMapView ? Text('רשימת עבודות', style: TextStyle(color: Colors.white)) : Text('תצוגת מפה', style: TextStyle(color: Colors.white)),
    ])));
    //return Container();
  }
  Widget addJobWidgetActionButton() {
    // if (_idJobIsUpdated != "-1" && _idJobIsUpdated != "") {
      return addJobWidgetWorkersActionButton();
    // } else {
    //   return addJobWidgetAddActionButton(false, _lJobs.length == 0);
    // }
    //return Container();
  }
  Widget addJobWidgetBossShrinkActionButton(JobsContext job, bool bShrink) {
    return new Column(children: [
                RawMaterialButton(
                  fillColor: job.details.bDetailsUpdated ? Colors.blue[300] : Colors.grey[500],
                  splashColor: Colors.white,
                  child: new Container(
                    width : _widthSwitch / 8,
                    height: _widthSwitch / 8,
                    decoration: new BoxDecoration(
                      shape: BoxShape
                          .circle, // You can use like this way or like the below line
                      //borderRadius: new BorderRadius.circular(30.0),
                      color: job.details.bDetailsUpdated ? Colors.blue[300] : Colors.grey[500],
                    ),
                    child: new Icon(bShrink ?
                        FontAwesomeIcons.pencilAlt : FontAwesomeIcons.users, size: _widthSwitch / 12),
                  ),
                  onPressed: (() {
                    WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
                    if (bShrink) {
                      _updatingDetails();
                      setState(() {
                        _bUpdatingDetails = true;
                      });
                    } else {
                      print("index - $_iJobIsUpdated");
                      
                    }
                    _bShrinkJobMenu = !_bShrinkJobMenu;
                    _currentJobId =
                        job.details._jobId;
                    _services
                        .queryJob(
                            job.details._jobId)
                        .then((res) {
                      if ((res["success"] ==
                              "true") ||
                          (res["success"] ==
                              true)) {
                        setState(() {
                         
                              _bUpdatingDetails =
                            false;
                        });
                      }
                    });
                    
                  }),
                  shape: new CircleBorder(),
                ),
                Text(bShrink
                    ? 'עריכת עבודה'
                    : 'הצג עובדים', style: TextStyle(color: Colors.white)),
              ]);
  }
  Widget addJobWidgetWorkersActionButton() {
    var len = _lJobs?.length ?? 0;
    var job = new JobsContext(JobsDetails());
    bool bisEmpty = (len == 0);
    if (!bisEmpty) {
    var index = _lJobs.indexWhere((element) => (element.details.jobId == _idJobIsUpdated));
      if (index == -1) {
        print("addJobWidgetWorkersActionButton, error - job id $_idJobIsUpdated not found");
        job = _lJobs[0];
        _iJobIsUpdated = 0;
      } else {
        job = _lJobs[index]; 
      }
      _idJobIsUpdated = job.details.jobId;
    } 
    bool bShrink = _bShrinkJobMenu && job.details.bDetailsUpdated;
    if (bShrink) {
      WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
    }
    Widget w = bisEmpty ?  addJobWidgetAddActionButton(false, true)  : !job.details.bDetailsUpdated ? addUpdateDetailsWidgetActionButton(bisEmpty) :
    Container(
    child: (_lJobs.last.details.jobId == "-1") ? Center(child: addJobWidgetBossShrinkActionButton(job, bShrink)) : new Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          //(_lJobs.last.details.jobId == "-1") ? Spacer() : Spacer(flex: 0),
              addJobWidgetBossShrinkActionButton(job, bShrink),
          (_lJobs.last.details.jobId == "-1")  ? SizedBox() : addJobWidgetAddActionButton(false, _lJobs.length == 0)]));
    return w;
    // return Container();
  }
  Widget addJobWidgetAddActionButton(bool bIsUpdated, bool bIsEmpty) {
    // return Container();
    return new Column(children: [
      RawMaterialButton(
        // constraints: bIsEmpty
        //     ? BoxConstraints.loose(Size(_widthSwitch / 4, _heightSwitch ))
        //     : BoxConstraints.loose(Size(88.0, 36.0)),
        fillColor: Colors.green[300],
        splashColor: Colors.white,
        child: new Container(
          width: _widthSwitch / 8,
          height: _widthSwitch / 8,
          decoration: new BoxDecoration(
            shape: BoxShape
                .circle, // You can use like this way or like the below line
            //borderRadius: new BorderRadius.circular(30.0),
            color: Colors.green[300],
          ),
          child: bIsEmpty
              ? new Icon(Icons.add, size: _widthSwitch / 8)
              : Icon(Icons.add, size: _widthSwitch / 8),
        ),
        onPressed: (() {
          setState(() {
            _lJobs.add(new JobsContext(new JobsDetails()));
            _cs.setPage(_cs.getNumberOfPages() + 1);
            _bShrinkJobMenu = false;
            _iJobIsUpdated+=1;
          });
          var a = _cs.getNumberOfPages();
          _cs.setPage(a);
        }),
        shape: new CircleBorder(),
      ),
      bIsEmpty
          ? Text(
              'הוסף עבודה',
              textScaleFactor: 1.5,
              style: TextStyle(color: Colors.white))
          : Text('הוסף עבודה', style: TextStyle(color: Colors.white)),
    ]);
  }
  Widget jobBossPage(BuildContext context, int index) {
    // w = 
    // (_lJobs.length == 0)
    //                         ? createTitle("אין עבודות")
    //                         : createTitle(
    //                             "עבודה ${index + 1} מתוך ${_lJobs.length}")
    // if  (_lJobs.length != 0) {
    //   var w = createTitle("עבודה ${index + 1} מתוך ${_lJobs.length}");
      
    // }
    //return Container();
    //return jobBossCard(context, index);
    return new Stack( children: <Widget>[
       jobBossCard(context, index),
      Positioned(child: removeWorkButton(index, false), top: 0.0, left : 0.0),
    ]);
  }
  Widget jobBossCard(BuildContext context, int index) {
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
      job.ui.conPlace.addListener(() {
        _textForAutoCompleteChanged(job.ui.conPlace.text, _lJobsDropDownList);
       
          _iJobIsUpdated = index;
          _idJobIsUpdated = job.details._jobId;
          if (_lJobs[index].details._place != job.ui.conPlace.text)
          { 
             setState(() {
            _lJobs[index].details.bDetailsUpdated = false;
            _lJobs[index].details._place = job.ui.conPlace.text;
            });
          }
          
        
      });
      job.ui.conDiscription.addListener(() {
        
          
          _idJobIsUpdated = job.details._jobId;
          _iJobIsUpdated = index;
          if (_lJobs[index].details._discription != job.ui.conDiscription.text) {
            setState(() {
            _lJobs[index].details.bDetailsUpdated = false;
            _lJobs[index].details._discription = job.ui.conDiscription.text;
          });
          }
          
           
        
      });
      job.ui.conWage.addListener(() {
       
          
          _idJobIsUpdated = job.details._jobId;
          _iJobIsUpdated = index;
          if (job.ui.conWage.text == "") {
              job.ui.conWage.text = _lJobs[index].details._wage.toString();
          }
          double val = double.parse(job.ui.conWage.text);
          _lJobs[index].details?._wage = _lJobs[index].details?._wage ?? 29.12;
          if (val != _lJobs[index].details?._wage){
             setState(() {
              job.ui.conWage.text =  _lJobs[index].details._wage.toString();
            _lJobs[index].details.bDetailsUpdated = false;
            });
          }
        
      });
      
      job.ui.connOccupationList.addListener(() {
        setState(() {
          _lJobs[index].details._lOccupationFieldListString = [];
          _lJobs[index]
              .details
              ._lOccupationFieldListString
              .add(job.ui.connOccupationList.text);
          _idJobIsUpdated = job.details._jobId;
          _iJobIsUpdated = index;
           _lJobs[index].details.bDetailsUpdated = false;
        });
      });
    }

    _lOccupationDropDown = [];
    _lPossibleOccupation
        .forEach((f) => _lOccupationDropDown.add(new DropdownMenuItem<String>(
              value: f.toString(),
              child: new Text(f.toString()),
            )));

    var _dropDownButtonOccupation = new DropdownButton(
        iconSize: 30.0,
        isExpanded: true,
        items: _lOccupationDropDown,
        hint: createTextWithIcon(
            job.details._lOccupationFieldListString.length > 0
                ? job.details._lOccupationFieldListString[0]
                : _jobPlaceText,
            FontAwesomeIcons.hammer),
        style: TextStyle(
            fontFamily: "WorkSansSemiBold",
            fontSize: 16.0,
            color: Colors.black),
        onChanged: ((s) {
          job.ui.connOccupationList.text = s;
          _iJobIsUpdated = index;
          _idJobIsUpdated = job.details._jobId;
          setState(() {
            _jobPlaceText = s;
          });
        }));

    bool bShrink = _bShrinkJobMenu && job.details.bDetailsUpdated;
    return new ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: new SingleChildScrollView(
            child: new Directionality(
                textDirection: TextDirection.rtl,
                child: new AnimatedContainer(
                    duration: new Duration(milliseconds: 500),
                    decoration: decorationBossWorker(context, true),
                    padding: EdgeInsets.only(top: 5.0),
                    //child: new SingleChildScrollView (
                    child: new Stack(children: [
                      Column(children: <Widget>[
                        // _lJobs.length == 0
                        //     ? createTitle("אין עבודות")
                        //     : createTitle("עבודה ${index + 1} מתוך ${_lJobs.length}"),
                        AnimatedContainer(
                            duration: new Duration(milliseconds: 500),
                            curve: Curves.elasticInOut,
                            height: bShrink
                                ? MediaQuery.of(context).size.height * 0.12
                                : MediaQuery.of(context).size.height * 0.55,
                            child: bShrink
                                ?  Card(
                                elevation: 2.0,
                                color: Colors.white54,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: createTitle(job.details._discription)) :
                                 Card(
                                elevation: 2.0,
                                color: Colors.white54,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: new SingleChildScrollView(
                                    child: bIsEmptyEntry
                                        ? new Container()
                                        : new Column(children: [
                                          
                                            Container(
                                              width: 250.0,
                                              height: 1.0,
                                              color: Colors.grey[400],
                                            ),
                                            new Container(
                                                child: createTextField(
                                                    "תאור מפורט של העבודה בכמה מילים",
                                                    job.ui.fnDiscription,
                                                    job.ui.conDiscription,
                                                    Icons.edit,
                                                    keyboardType:
                                                        TextInputType.multiline,
                                                    maxLines: 3)),
                                            Container(
                                              width: 250.0,
                                              height: 1.0,
                                              color: Colors.grey[400],
                                            ),
                                            new Row(children: <Widget>[
                                              new Flexible(child: 
                                                _createAutoCompleteTextField(job.ui.conPlace, "(מקום (הכנס 2 תווים ובחר מהרשימה)", jobId: job.details.jobId))
                  
                                                  // child: createTextField(
                                                  //     "מקום",
                                                  //     job.ui.fnPlace,
                                                  //     job.ui.conPlace,
                                                  //     FontAwesomeIcons
                                                  //         .mapMarker)),
                                              // new Flexible(
                                              //     child: Padding(
                                              //         padding: EdgeInsets.only(
                                              //             top: 10.0,
                                              //             bottom: 10.0),
                                              //         child:
                                              //             new SingleChildScrollView(
                                              //           child: new Theme(
                                              //               data: new ThemeData(
                                              //                 fontFamily:
                                              //                     "WorkSansSemiBold",
                                              //                 canvasColor: Colors
                                              //                     .white54, //my custom color
                                              //               ),
                                              //               child:
                                              //                   new DropdownButton(
                                              //                 iconSize: 30.0,
                                              //                 items:
                                              //                     _lJobsDropDownList,
                                              //                 onChanged: ((s) {
                                              //                   setState(() {
                                              //                     job
                                              //                         .ui
                                              //                         .conPlace
                                              //                         .text = s;
                                              //                     setPlaceLatLng(
                                              //                         s,
                                              //                         jobIndex:
                                              //                             index);
                                              //                     _idJobIsUpdated =
                                              //                         job.details
                                              //                             ._jobId;
                                              //                     _iJobIsUpdated =
                                              //                         index;
                                              //                   });
                                              //                 }),
                                              //               )),
                                              //           scrollDirection:
                                              //               Axis.horizontal,
                                              //         )))
                                            ]),
                                            Container(
                                              width: 250.0,
                                              height: 1.0,
                                              color: Colors.grey[400],
                                            ),
                                            createTextField(
                                                "שכר",
                                                job.ui.fnWage,
                                                job.ui.conWage,
                                                FontAwesomeIcons.shekelSign,
                                                keyboardType:
                                                    TextInputType.number,
                                                direction: TextDirection.ltr),
                                            new SingleChildScrollView(
                                              child: new Theme(
                                                data: new ThemeData(
                                                  fontFamily:
                                                      "WorkSansSemiBold",
                                                  canvasColor: Colors
                                                      .white54, //my custom color
                                                ),
                                                child:
                                                    _dropDownButtonOccupation,
                                              ),
                                            ),
                                            // createTextField(
                                            //     "מספר עובדים",
                                            //     job.ui.fnnWorkers,
                                            //     job.ui.connWorkers,
                                            //     FontAwesomeIcons.peopleCarry,
                                            //     keyboardType:
                                            //         TextInputType.number,
                                            //     validator:
                                            //         new BlacklistingTextInputFormatter(
                                            //             new RegExp(
                                            //                 '[\\.|\\,|\\-|\\ ]'))),
                                          
                      ])))),
                        _bShrinkJobMenu
                            ? _buildBossJobsLivePage(
                                context, job.details._jobId)
                            : new Container(),
                        Container(
                          height: 50.0,
                        ),
                      ]),
                      //),
                    ]) //)
                    ))));
  }
  Widget removeWorkButton(int index, bool bIsEmptyEntry) {
    if (_lJobs.length == 0)
      return Container();
    return new Column(children: [
      RawMaterialButton(
        fillColor:
            _lJobsIDsMarkedForDeletion
                    .contains(
                        _lJobs[index]
                            .details
                            ._jobId)
                ? Colors.red[300]
                : Colors.grey[300],
        splashColor: Colors.white,
        child: new Container(
          decoration: new BoxDecoration(
            shape: BoxShape
                .circle, // You can use like this way or like the below line
            //borderRadius: new BorderRadius.circular(30.0),
            color:
                _lJobsIDsMarkedForDeletion
                        .contains(
                            _lJobs[index]
                                .details
                                ._jobId)
                    ? Colors.red[300]
                    : Colors.grey[300],
          ),
          child: new Icon(Icons.cancel),
              // FontAwesomeIcons
              //     .trashAlt),
        ),
        onPressed: (() {
          if ((_idJobIsUpdated == "-1" || _idJobIsUpdated == "") && !_lJobs[index].details.bDetailsUpdated) { // this means this is a new job not yet updated to server
              setState(() {
                _lJobs.removeAt(index);
              });
          } else {
          setState(() {
            if (_lJobsIDsMarkedForDeletion
                .contains(_lJobs[index]
                    .details
                    ._jobId)) {
              _lJobsIDsMarkedForDeletion
                  .remove(_lJobs[index]
                      .details
                      ._jobId);
            } else {
              _lJobsIDsMarkedForDeletion
                  .add(_lJobs[index]
                      .details
                      ._jobId);
              
            }
            //_lJobs.removeAt(index);
            _idJobIsUpdated =
                _lJobs[index]
                    .details
                    ._jobId;
            _iJobIsUpdated = index;
            _updatingDetails();
          });
        }}),
        shape: new CircleBorder(),
      ),
      // bIsEmptyEntry
      //     ? Container()
      //     : Text('מחק עבודה'),
    ]);
  }
  Widget _buildJobsCarousel(BuildContext context, List<Widget> jbl) {
    if (_lJobs.length == 0) {
      jbl.add(jobBossPage(context, 0));
    } else {
      for (int i = 0; i < _lJobs.length; i++) {
        jbl.add(jobBossPage(context, i));
      }
    }
    if (_cs != null) {
      iCs = (_cs.getCurrentPage(context)).round();
    } else {
      iCs = 0;
    }
    _cs = new CarosuelState(pages: jbl);
    var carousel = _cs.buildCarousel(context, _heightMain);
    //_cs.setPage(0);
    return carousel;
  }

  List<JobDetailsForWorker> _jobDetailsForWorkerList;
  Widget _buildWorkerJobTileList(BuildContext context) {
    return _buildJobsAsWorkerPanel();
  }

  Widget buildWorkerJobTileWithButton(JobDetailsForWorker item) {
    return new Card(
        elevation: 2.0,
        color: Colors.white54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: new Container(
            child: new Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
          RawMaterialButton(
            fillColor: item.bHired
                ? Color.fromRGBO(212, 175, 55, 1)
                : (item.bAuthorized
                    ? Colors.green
                    : (item.bResponded ? Colors.red : Colors.grey)),
            splashColor: Colors.white,
            child: new Container(
              width: _widthSwitch / 4,
              decoration: new BoxDecoration(
                shape: BoxShape.rectangle,
                color: item.bHired
                    ? Color.fromRGBO(212, 175, 55, 1)
                    : (item.bAuthorized
                        ? Colors.green
                        : (item.bResponded ? Colors.red : Colors.grey)),
              ),
              child: new Column (children: [ item.bHired
                  ? new Icon(FontAwesomeIcons.handshake)
                  : item.bAuthorized
                      ? new Icon(FontAwesomeIcons.check)
                      : (item.bResponded
                          ? Icon(FontAwesomeIcons.exclamation)
                          : Icon(FontAwesomeIcons.question)),
                    item.bHired ? createTitle("נסגר") : 
                    item.bAuthorized
                      ? createTitle("מעוניין")
                      : (item.bResponded
                          ? createTitle("לא")
                          : createTitle("לא הגיב", textSize: 15.0)),
              ])),
            onPressed: (()  {
              jobStatusPopUpMenu(item.jd._discription, item.bAuthorized, item.bResponded, item.bHired, true).then((bYes)
              {
                if (bYes) {
                if (!item.bAuthorized) {
                  _services.confirmJob(item.jd._jobId, true).then((res) {
                    if (res.containsKey("success") &&
                        ((res["success"] == "true") ||
                            (res["success"] == true))) {
                      var res2 = refreshJobs();
                      res2.then((bSuccess) {
                        if (bSuccess) {
                          setState(() {});
                        }
                      });
                    }
                  });
                } else {
                  _services.confirmJob(item.jd._jobId, false).then((res) {
                    if (res.containsKey("success") &&
                        ((res["success"] == "true") ||
                            (res["success"] == true))) {
                      var res2 = refreshJobs();
                      res2.then((bSuccess) {
                        if (bSuccess) {
                          setState(() {});
                        }
                      });
                    }
                  });
                }
               }
             });
            }),
            shape: new CircleBorder(),
          ),
          new Expanded(child: createTitle(item.jd._discription)),
          new Align(
              alignment: Alignment.centerRight,
              child: Transform.rotate(
                  angle: item.ui._angle,
                  child: new Icon(
                    Icons.arrow_downward,
                    size: 24.0,
                  ))),
        ])));
  }

  Widget _buildTileHeaderJobsAsWorkerPanel(JobDetailsForWorker item) {
    return Row(children: <Widget>[
      new Expanded(
          child: new Container(
              child: new GestureDetector(
        child: buildWorkerJobTileWithButton(item),
        onTap: () {
          setState(() {
            if (item.ui._angleController.status == AnimationStatus.completed) {
              item.ui._angleController.reverse();
            } else {
              item.ui._angleController.forward();
            }
            item.ui.bIsExpanded = !item.ui.bIsExpanded;
          });
        },
      )))
    ]);
  }

  Widget createSortLine(Widget sortText, VoidCallback sortTextCallback,  VoidCallback sortArrowCallback, bool bArrowUp, double _w, double _h)
  {
    return new Align(
                                  alignment: Alignment.center,
                                  child: Container(
                                      //width: (l[0].left - l[0].right)*2,
                                      width: _w ,
                                      height: _h,
                                      child: new Card(
                                          elevation: 6.0,
                                          color: ZarizTheme.Colors.zarizGradientEnd2,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(500.0),

                                          ),
                                          child: new Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              textDirection: TextDirection.rtl,
                                              children: <Widget>[
                                                new Flexible(
                                                    child: Container(
                                      //width: (l[0].left - l[0].right)*2,
                                      width: _w ,
                                      height: _h,
                                      child: new InkWell(
                                                        child: Align(
                                                            alignment: Alignment.center,
                                                            child: sortText),
                                                        onTap: sortTextCallback,
                                                        ))),
                                                new Flexible(
                                                  child: Container(
                                      width: _w * 0.1 ,
                                      height: _h,
                                                    child: IconButton(
                                                  icon: Icon(
                                                     
                                                      bArrowUp
                                                          ? FontAwesomeIcons
                                                              .arrowUp
                                                          : FontAwesomeIcons
                                                              .arrowDown,
                                                      size: 12.0),
                                                       color: ZarizTheme.Colors.zarizGradientStart2,
                                                  onPressed: sortArrowCallback,
                                                ))),
                                                
                                              ]))));
  }
   void sortWorkersForJobTextCallback() {
    setState(() {
      _sortTypeWorkersForJob++;
      _sortTypeWorkersForJob =
          _sortTypeWorkersForJob %
              _sSortTypes
                  .length;
    });
  }
  void sortWorkersForJobArrowCallback() {
    setState(() {
      _bSortAsscendingWorkersForJob =
          !_bSortAsscendingWorkersForJob;
    });
  }
                
  void sortJobsForWorkerTextCallback() {
    setState(() {
      _sortTypeJobsForWorker++;
      _sortTypeJobsForWorker =
          _sortTypeJobsForWorker %
              _sSortTypes
                  .length;
    });
  }
  void sortJobsForWorkerArrowCallback() {
    setState(() {
      _bSortAsscendingJobsForWorker =
          !_bSortAsscendingJobsForWorker;
    });
  }

  Widget buildJobsAsWorkerList(List<JobDetailsForWorker> jobsToShow, Widget sortText) 
  {
    _w = MediaQuery.of(context).size.width;
    _h = MediaQuery.of(context).size.height;
    return new Column(children: <Widget>[
                                 createSortLine(sortText, sortJobsForWorkerTextCallback, sortJobsForWorkerArrowCallback, _bSortAsscendingJobsForWorker, _w * 0.8, _h / 24),
                                              
                              
                              for (var item in jobsToShow)
                                !item.ui.bIsExpanded
                                    ? AnimatedContainer(
                                        duration:
                                            new Duration(milliseconds: 500),
                                        decoration:
                                            decorationBossWorker(context, true),
                                        padding: EdgeInsets.only(top: 5.0),
                                        child:
                                            _buildTileHeaderJobsAsWorkerPanel(
                                                item))
                                    : AnimatedContainer(
                                        duration:
                                            new Duration(milliseconds: 500),
                                        decoration:
                                            decorationBossWorker(context, true),
                                        padding: EdgeInsets.only(top: 5.0),
                                        child: new Column(children: <Widget>[
                                          _buildTileHeaderJobsAsWorkerPanel(
                                              item),
                                          ListTile(
                                              title: createTitle(
                                                  "שם העסק ${item.bd._buisnessName} \nשם המעסיק ${item.bd._firstName} ${item.bd._lastName}\nשכר ${item.jd._wage}\nמיקום ${item.jd._place}\n"),
                                              // subtitle: Text(
                                              //     'To delete this Panel, tap the trash can icon'),
                                              //trailing: IconButton(icon: Icon(Icons.delete), onPressed: (){

                                              //},),
                                              onTap: () {
                                                setState(() {
                                                  item.ui.bIsExpanded =
                                                      !item.ui.bIsExpanded;
                                                });
                                              })
                                        ]))]);
  }

  void onTapInfoWorker(String jobId) {
    setState(() {
      for (var j in _jobDetailsForWorkerList) {
        if (j.jd.jobId == jobId) {
           j.ui.bIsExpanded = true;
        } else {
          j.ui.bIsExpanded = false;
        }
       
      }
      _bMapView = false;
    });
    

  }                                        
  Widget _buildJobsAsWorkerPanel() {
    if (_jobDetailsForWorkerList == null) {
      return new Container(child: createTitle("אין עבודות"));
    }
    List<JobDetailsForWorker> jobsToShowTemp =
        new List.from(_jobDetailsForWorkerList);
    List<JobDetailsForWorker> jobsToShow = [];
    jobsToShowTemp.forEach((j) {
      try {
        if (!j.bAuthorized && !j.bHired && j.bResponded) {
          jobsToShow.add(j);
        } else {
          jobsToShow.add(j);
        }
      } catch (e) {}
    });
    if (_sortTypeJobsForWorker == SortType.LastName.index) {
      //SortType.LastName.index) {
      jobsToShow.sort((a, b) {
        return (_bSortAsscendingJobsForWorker ? a : b)
            .bd
            ._lastName
            .toString()
            .toLowerCase()
            .compareTo((_bSortAsscendingJobsForWorker ? b : a)
                .bd
                ._lastName
                .toString()
                .toLowerCase());
      });
    } else if (_sortTypeJobsForWorker == SortType.FirstName.index) {
      //SortType.FirstName.index) {
      jobsToShow.sort((a, b) {
        return (_bSortAsscendingJobsForWorker ? a : b)
            .bd
            ._firstName
            .toString()
            .toLowerCase()
            .compareTo((_bSortAsscendingJobsForWorker ? b : a)
                .bd
                ._firstName
                .toString()
                .toLowerCase());
      });
    } else if (_sortTypeJobsForWorker == SortType.DistFromAddress.index) {
      //SortType.DistFromAddress.index) {
      jobsToShow.sort((a, b) {
        final Distance distance = new Distance();
        final double meterA = distance(new LatLng(a.jd._lat, a.jd._lng),
            new LatLng(_workerDetails._lat, _workerDetails._lng));
        final double meterB = distance(new LatLng(b.jd._lat, b.jd._lng),
            new LatLng(_workerDetails._lat, _workerDetails._lng));
        final int dist = meterA > meterB ? 1 : -1;
        return (_bSortAsscendingJobsForWorker ? dist : (dist * -1));
      });
    } else if (_sortTypeJobsForWorker == SortType.DistFromLocation.index) {
      //SortType.DistFromLocation.index) {
      jobsToShow.sort((a, b) {
        final Distance distance = new Distance();
        final double meterA = distance(new LatLng(a.jd._lat, a.jd._lng),
            new LatLng(_currLocation.lat, _currLocation.lng));
        final double meterB = distance(new LatLng(b.jd._lat, b.jd._lng),
            new LatLng(_currLocation.lat, _currLocation.lng));
        final int dist = meterA > meterB ? 1 : -1;
        return (_bSortAsscendingJobsForWorker ? dist : (dist * -1));
      });
      } else if (_sortTypeJobsForWorker == SortType.Wage.index) {
      //SortType.DistFromLocation.index) {
      jobsToShow.sort((a, b) {
        return (_bSortAsscendingJobsForWorker ? a : b)
            .jd._wage
            .compareTo((_bSortAsscendingJobsForWorker ? b : a)
                .jd._wage);
      });
    }
    _w = MediaQuery.of(context).size.width;
    _h = MediaQuery.of(context).size.height;
    if (_bJobMenu && !_bBossMode) {
      WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
    }
    Widget sortText = createTitleNoPadding(_sSortTypes[_sortTypeJobsForWorker],
        textSize: 10.0, bCenter: true, color:  ZarizTheme.Colors.zarizGradientStart2);

    return (jobsToShow == null || jobsToShow.length == 0)
        ? Container(child: createTitle("אין עבודות"))
        : new SingleChildScrollView(
            child: new Container(
                decoration: decorationBossWorker(context, true),
                child: Theme(
                    data: Theme.of(context).copyWith(
                        cardColor: ZarizTheme.Colors.zarizGradientStart),
                    child: new Directionality(
                        textDirection: TextDirection.rtl,
                        child: new AnimatedContainer(
                            duration: new Duration(milliseconds: 500),
                            decoration: decorationBossWorker(context, true),
                            padding: EdgeInsets.only(top: 5.0),
                            child: new Column(children: <Widget>[
                                 _bMapView ? Container(height: _h * 0.6, width: _w, child: buildMapWidgetJobsForWorker(jobsToShow, _workerDetails,_currLocation, onTapInfoWorker)) : buildJobsAsWorkerList(jobsToShow, sortText),
                                        
                            ])))))
                          );
  }

  Widget _buildBossJobsCarousel(BuildContext context) {
    List<Widget> jbl = [];
    return _buildJobsCarousel(context, jbl);
  }

  Widget _buildBossDetails1(BuildContext context) {
    return (new Directionality(
        textDirection: TextDirection.rtl,
        child:  Stack(children: [new AnimatedContainer(
            duration: new Duration(milliseconds: 500),
            decoration: decorationBossWorker(context, true),
            padding: EdgeInsets.only(top: 23.0),
            child:
            Card(
                elevation: 2.0,
                color: Colors.white54,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: SingleChildScrollView(
                    //   //width: MediaQuery.of(context).size.width * 5 / 6,
                    //   //height: MediaQuery.of(context).size.height * 2,
                    child: new Column(children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(
                        top: 10.0, bottom: 10.0, left: 25.0, right: 25.0),
                    child: new Row(children: <Widget>[
                      new Flexible(
                          child: createTextField(
                              "פרטי",
                              myFocusNodeBossFirstName,
                              _controllerWorkerFirstName,
                              FontAwesomeIcons.userAlt)),
                      new Flexible(
                          child: createTextField(
                              "משפחה",
                              myFocusNodeBossLastName,
                              _controllerWorkerLastName,
                              FontAwesomeIcons.users)),
                    ]),
                  ),
                  Container(
                    width: 250.0,
                    height: 1.0,
                    color: Colors.grey[400],
                  ),
                  new SingleChildScrollView(
                    child: createTextField(
                        "שם העסק",
                        myFocusNodeBossBuisnessName,
                        _controllerBossBuisnessName,
                        FontAwesomeIcons.userAlt),
                  ),
                  Container(
                    width: 250.0,
                    height: 1.0,
                    color: Colors.grey[400],
                  ),
                  _createAutoCompleteTextField(_controllerBossPlace, "(מקום (הכנס 2 תווים ובחר מהרשימה)"),
                  // new Row(children: <Widget>[
                  //   new Flexible(
                  //       child: createTextField("מקום", myFocusNodeBossPlace,
                  //           _controllerBossPlace, FontAwesomeIcons.mapMarker)),
                  //   new Flexible(
                  //       child: Padding(
                  //           padding: EdgeInsets.only(
                  //               top: 10.0,
                  //               bottom: 10.0,
                  //               left: 25.0,
                  //               right: 25.0),
                  //           child: new SingleChildScrollView(
                  //             child: new Theme(
                  //                 data: new ThemeData(
                  //                   fontFamily: "WorkSansSemiBold",
                  //                   canvasColor:
                  //                       Colors.white54, //my custom color
                  //                 ),
                  //                 child: new DropdownButton(
                  //                   iconSize: 30.0,
                  //                   items: _lPlacesBossDropDownList,
                  //                   onChanged: ((s) {
                  //                     _controllerBossPlace.text = s;
                  //                     _bWorkerIsUpdated = false;
                  //                     setPlaceLatLng(s);
                  //                   }),
                  //                 )),
                  //             scrollDirection: Axis.horizontal,
                  //           )))
                  // ]),
                  Container(
                    width: 250.0,
                    height: 1.0,
                    color: Colors.grey[400],
                  )
                ])))),])));
        
  }

  Widget _buildBossJobsLivePage(BuildContext context, String jobID) {

    JobsContext job;
    if (jobID == "-1")
      return Container();
    _lJobs.forEach((j) {
      if (j.details._jobId == jobID) {
        job = j;
      }
    });
    var len = job?.lWorkersNotified?.length ?? 0;
    print(
        "_buildBossJobsLivePage, !!!!Shrink job $_bShrinkJobMenu job.lWorkersNotified.length $len for $jobID");
    if (job == null || (job?.lWorkersNotified ?? []) == [])
      return new Directionality(
          textDirection: TextDirection.rtl,
          child: createTitle("לא נמצאו עובדים"));
    // remove declined workers
    List<WorkerDetails> lWorkersDeclined = [];
    job.lWorkersResponded.forEach((_w) {
      job.lWorkersHired.firstWhere((wHired) => wHired._userID == _w._userID,
          orElse: (() {
        job.lWorkersAuthorized.firstWhere((wAuth) => wAuth._userID == _w._userID,
            orElse: (() {
          lWorkersDeclined.add(_w);
        }));
      }));
    });
    List<WorkerDetails> lWorkersToShow = new List.from(job.lWorkersNotified);
    lWorkersDeclined.forEach((_w) {
      try {
        var oldVal = lWorkersToShow.firstWhere((a) => a._userID == _w._userID);
        lWorkersToShow.remove(oldVal);
      } catch (e) {}
    });
    if (_sortTypeWorkersForJob == SortType.LastName.index) {
      //SortType.LastName.index) {
      lWorkersToShow.sort((a, b) {
        return (_bSortAsscendingWorkersForJob ? a : b)
            ._lastName
            .toString()
            .toLowerCase()
            .compareTo((_bSortAsscendingWorkersForJob ? b : a)
                ._lastName
                .toString()
                .toLowerCase());
      });
    } else if (_sortTypeWorkersForJob == SortType.FirstName.index) {
      //SortType.FirstName.index) {
      lWorkersToShow.sort((a, b) {
        return (_bSortAsscendingWorkersForJob ? a : b)
            ._firstName
            .toString()
            .toLowerCase()
            .compareTo((_bSortAsscendingWorkersForJob ? b : a)
                ._firstName
                .toString()
                .toLowerCase());
      });
    } else if (_sortTypeWorkersForJob == SortType.DistFromAddress.index) {
      //SortType.DistFromAddress.index) {
      lWorkersToShow.sort((a, b) {
        final Distance distance = new Distance();
        final double meterA = distance(new LatLng(a._lat, a._lng),
            new LatLng(_bossDetails._lat, _bossDetails._lng));
        final double meterB = distance(new LatLng(b._lat, b._lng),
            new LatLng(_bossDetails._lat, _bossDetails._lng));
        final int dist = meterA > meterB ? 1 : -1;
        return (_bSortAsscendingWorkersForJob ? dist : (dist * -1));
      });
    } else if (_sortTypeWorkersForJob == SortType.DistFromLocation.index) {
      //SortType.DistFromLocation.index) {
      lWorkersToShow.sort((a, b) {
        final Distance distance = new Distance();
        final double meterA = distance(new LatLng(a._lat, a._lng),
            new LatLng(_currLocation.lat, _currLocation.lng));
        final double meterB = distance(new LatLng(b._lat, b._lng),
            new LatLng(_currLocation.lat, _currLocation.lng));
        final int dist = meterA > meterB ? 1 : -1;
        return (_bSortAsscendingWorkersForJob ? dist : (dist * -1));
      });
    } else if (_sortTypeWorkersForJob == SortType.Wage.index) {
      //SortType.DistFromLocation.index) {
      lWorkersToShow.sort((a, b) {
        return (_bSortAsscendingWorkersForJob ? a : b)
            ._wage
            .compareTo((_bSortAsscendingWorkersForJob ? b : a)
                ._wage);
      });
    }

    var _w = MediaQuery.of(context).size.width;
    var _h = MediaQuery.of(context).size.height;

    Widget sortText = createTitleNoPadding(_sSortTypes[_sortTypeWorkersForJob],
        textSize: 10.0, bCenter: true, color:  ZarizTheme.Colors.zarizGradientStart2);

    return new Directionality(
      textDirection: TextDirection.rtl,
      child: new Column(children: <Widget>[
        createSortLine(sortText, sortWorkersForJobTextCallback, sortWorkersForJobArrowCallback, _bSortAsscendingWorkersForJob, _w * 0.8, _h / 24),
        SingleChildScrollView(
            child: new ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.only(
                    top: 0.0, bottom: 20.0, right: 25.0, left: 25.0),
                itemCount: lWorkersToShow.length,
                itemBuilder: (BuildContext context, int index) {
                  bool bNotified = false;
                  for (var _w in job.lWorkersNotified) {
                    if (lWorkersToShow[index]._userID == _w._userID) {
                      bNotified = true;
                      break;
                    }
                  }
                  bool bResponded = false;
                  for (var _w in job.lWorkersResponded) {
                    if (lWorkersToShow[index]._userID == _w._userID) {
                      bResponded = true;
                      break;
                    }
                  }
                  bool bAuthorized = false;
                  for (var _w in job.lWorkersAuthorized) {
                    if (lWorkersToShow[index]._userID == _w._userID) {
                      bAuthorized = true;
                      break;
                    }
                  }
                  bool bHired = false;
                  for (var _w in job.lWorkersHired) {
                    if (lWorkersToShow[index]._userID == _w._userID) {
                      bHired = true;
                      break;
                    }
                  }
                  return Card(
                      elevation: 2.0,
                      color: Colors.white54,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: new Container(
                          child: new Row( mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        createTitle(
                            '${lWorkersToShow[index]._firstName} ${lWorkersToShow[index]._lastName}'),
                         RawMaterialButton(
                          fillColor: bHired
                              ? Color.fromRGBO(212, 175, 55, 1)
                              : (bAuthorized
                                  ? Colors.green
                                  : (bResponded ? Colors.red : Colors.grey)),
                          splashColor: Colors.white,
                          child: new Container(
                width: _widthSwitch / 4,
                decoration: new BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: bHired
                      ? Color.fromRGBO(212, 175, 55, 1)
                      : (bAuthorized
                          ? Colors.green
                          : (bResponded ? Colors.red : Colors.grey)),
                ),
                child: new Column (children: [ bHired
                    ? new Icon(FontAwesomeIcons.handshake)
                    : bAuthorized
                        ? new Icon(FontAwesomeIcons.check)
                        : (bResponded
                            ? Icon(FontAwesomeIcons.exclamation)
                            : Icon(FontAwesomeIcons.question)),
                      bHired ? createTitle("נסגר") : 
                      bAuthorized
                        ? createTitle("מעוניין")
                        : (bResponded
                            ? createTitle("לא")
                            : createTitle("לא הגיב", textSize: 15.0)),
                  ])
                ),
                          onPressed: (() {
                            jobStatusPopUpMenu('${lWorkersToShow[index]._firstName} ${lWorkersToShow[index]._lastName}', bAuthorized, bResponded, bHired, false).then((bYes)
              {if (!bYes)
                  return;
                            if (!bAuthorized) {
                              // re-send notification

                            } else {
                              _services
                                  .hire(jobID, lWorkersToShow[index]._userID,
                                      !bHired)
                                  .then((res) {
                                if (res.containsKey("success") &&
                                    ((res["success"] == "true") ||
                                        (res["success"] == true))) {
                                  var res2 = refreshJobs();
                                  res2.then((bSuccess) {
                                    if (bSuccess) {
                                      setState(() {});
                                    }
                                  });
                                }
                              });
                            }
                          });}),
                          shape: new CircleBorder(),
                        ),
                        
                      ])));
                })),
      ]),
    );

    //,new GlobalKey<ScaffoldState>());
    //,_scaffoldKey);
  }

  Widget _buildWorkersJobsLivePage(
    BuildContext context,
  ) {
    return new Directionality(
        textDirection: TextDirection.rtl,
        child: new AnimatedContainer(
            duration: new Duration(milliseconds: 500),
            decoration: decorationBossWorker(context, false),
            padding: EdgeInsets.only(top: 23.0),
            child: Column(children: <Widget>[
              Stack(
                alignment: Alignment.topCenter,
                overflow: Overflow.visible,
                children: <Widget>[
                  Stack(children: [
                    SingleChildScrollView(
                        child: new ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.only(
                                top: 20.0,
                                bottom: 20.0,
                                right: 25.0,
                                left: 25.0),
                            itemCount: _lJobs.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Card(
                                  elevation: 2.0,
                                  color: Colors.white54,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: new Container(
                                      height: 120.0,
                                      child: new Row(children: <Widget>[
                                        RawMaterialButton(
                                          fillColor: index != _lJobs.length
                                              ? Colors.green[300]
                                              : Colors.red[300],
                                          splashColor: Colors.white,
                                          child: new Container(
                                            decoration: new BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.green,
                                            ),
                                            child: index != _lJobs.length
                                                ? new Icon(Icons.add)
                                                : new Icon(
                                                    FontAwesomeIcons.trashAlt),
                                          ),
                                          onPressed: (() {}),
                                          shape: new CircleBorder(),
                                        ),
                                        createTitle(
                                            '${_lJobs[index].details._discription}'),
                                      ])));
                            })),
                  ]),
                  //),
                ],
              )
            ])));
  }
}

String numberValidator(String value) {
  if (value == null) {
    return null;
  }
  try {
    final num = int.parse(value, onError: (value) => null);
    if (num <= 0) {
      return '"$value" is not a valid number';
    }
    if (num == null) {
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
