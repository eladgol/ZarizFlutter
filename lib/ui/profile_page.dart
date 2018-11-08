import 'dart:async';


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zariz_app/style/theme.dart' as Theme;
import 'package:zariz_app/utils/bubble_indication_painter.dart';
import 'package:zariz_app/utils/Services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter/cupertino.dart';

import 'package:zariz_app/ui/page_carousel.dart';

class Details{
    String _firstName;
    String _lastName;
    double _minWage;
    String _occupationFieldListString;
    int userID;
    String photoAGCSPath;
    double _radius;
    double _lat;
    double _lng;
    int _id;
  }

class Choice {
  const Choice({this.title, this.icon});

  final String title;
  final IconData icon;
}
const List<Choice> choices = const <Choice>[
  const Choice(title: 'צא', icon: FontAwesomeIcons.signOutAlt),
  const Choice(title: 'Bicycle', icon: Icons.directions_bike),
  const Choice(title: 'Boat', icon: Icons.directions_boat),
  const Choice(title: 'Bus', icon: Icons.directions_bus),
  const Choice(title: 'Train', icon: Icons.directions_railway),
  const Choice(title: 'Walk', icon: Icons.directions_walk),
];

class ProfilePage extends StatefulWidget {
  ProfilePage({Key key}) : super(key: key);

  @override
  _ProfilePageState createState() => new _ProfilePageState();
}
class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final FocusNode myFocusNodeEmailProfile = FocusNode();
  final FocusNode myFocusNodePasswordProfile = FocusNode();

  final FocusNode myFocusNodePassword = FocusNode();
  final FocusNode myFocusNodeEmail = FocusNode();
  final FocusNode myFocusNodeName = FocusNode();

  TextEditingController profileEmailController = new TextEditingController();
  TextEditingController profilePasswordController = new TextEditingController();

  bool _obscureTextProfile = true;
  bool _obscureTextSignup = true;
  bool _obscureTextSignupConfirm = true;

  TextEditingController signupEmailController = new TextEditingController();
  TextEditingController signupNameController = new TextEditingController();
  TextEditingController signupPasswordController = new TextEditingController();
  TextEditingController signupConfirmPasswordController =
      new TextEditingController();

  PageController _pageController;

  Color left = Colors.black;
  Color right = Colors.white;

  bool _bProfileEnabled = true;
  bool _bSignUpEnabled = true;
  Choice _selectedChoice = choices[0];

  Details _details;
  List<String> _litems = ["גינון", "הפקה", "חינוך", "כלים כבדים","sdsd","dsdsd"];

  void _select(Choice choice) {
    // Causes the app to rebuild with the new _selectedChoice.
    setState(() {
      _selectedChoice = choice;
    });
  }

  Image _image = new Image.asset('assets/img/no_portrait.png', fit: BoxFit.scaleDown, width: 250.0, height: 191.0);

  Future getImage() async {
    ImageSource _source;
    showModalBottomSheet<void>(context:context, builder: (BuildContext context) {
      return new Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        new IconButton(icon: Icon(FontAwesomeIcons.camera), onPressed: (){_source = ImageSource.camera;imagePick(_source);;}),
        new IconButton(icon: Icon(FontAwesomeIcons.fileImage), onPressed: (){_source = ImageSource.gallery;imagePick(_source);}),
        ]);
    });
  }
  getResolution(Image image) {
    Completer<ImageInfo> completer = new Completer<ImageInfo>();
    image.image
      .resolve(new ImageConfiguration())
      .addListener((ImageInfo info, bool _) => completer.complete(info));
    return completer.future;
  }
  void imagePick(ImageSource _source) {
    ImagePicker.pickImage(source: _source).then((img){
        var res = getResolution(Image.file(img));
        res.then((info) {
            var w = MediaQuery.of(context).size.width * 2 / 10;
            var h = w * info.image.height / info.image.width;
            var image = Image.file(img , fit: BoxFit.fill, width: w, height: h);
            setState(() {
                _image = image;
            });
            Navigator.pop(context);
        });
    });
  }

  static double hDefault = 775.0;
  double _heightImage = hDefault * 0.15;
  double _heightSwitch = hDefault * 0.05;
  double _heightCard = hDefault * 0.7;
  double _heightButton = hDefault * 0.1;

  @override
  Widget build(BuildContext context) {
    return new Directionality(
      textDirection: TextDirection.rtl,
        child : new Scaffold(
        appBar: AppBar(
        title: Text('פרופיל'),
        actions: <Widget>[
              IconButton(
                icon: Icon(FontAwesomeIcons.running),
                onPressed: () {
                  _select(choices[0]);
                },
              ),
              // action button
              IconButton(
                icon: Icon(FontAwesomeIcons.signOutAlt),
                onPressed: () {
                  _select(choices[0]);
                },
              ),
              PopupMenuButton<Choice>(
                onSelected: _select,
                itemBuilder: (BuildContext context) {
                  return choices.skip(2).map((Choice choice) {
                    return PopupMenuItem<Choice>(
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
                          Theme.Colors.zarizGradientStart,
                          Theme.Colors.zarizGradientEnd
                        ],
                        begin: const FractionalOffset(0.0, 0.0),
                        end: const FractionalOffset(1.0, 1.0),
                        stops: [0.0, 1.0],
                        tileMode: TileMode.clamp),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      
                      Padding(
                        padding: EdgeInsets.only(top: 5.0),
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
                      
                      Expanded(
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
                            new ConstrainedBox(
                              constraints: const BoxConstraints.expand(),
                              child: _buildCarousel(context),
                            ),
                            new ConstrainedBox(
                              constraints: const BoxConstraints.expand(),
                              child: _buildBossDetails(context),
                            ),
                          ],
                        ),
                      ),
                      Flexible( child: new Container(
                        height: _heightButton,
                  margin: EdgeInsets.only(top: 5.0),
                  decoration: new BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Theme.Colors.zarizGradientStart,
                        offset: Offset(1.0, 6.0),
                        blurRadius: 20.0,
                      ),
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(1.0, 6.0),
                        blurRadius: 20.0,
                      ),
                    ],
                    gradient: new LinearGradient(
                        colors: [
                          Theme.Colors.zarizGradientEnd,
                          Theme.Colors.zarizGradientStart
                        ],
                        begin: const FractionalOffset(0.2, 0.2),
                        end: const FractionalOffset(1.0, 1.0),
                        stops: [0.0, 1.0],
                        tileMode: TileMode.clamp),
                  ),
                  child: MaterialButton(
                      highlightColor: Colors.transparent,
                      splashColor: Theme.Colors.zarizGradientEnd,
                      //shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5.0))),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 0.0, horizontal: 42.0),
                        child: Text(
                          "עדכון",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 25.0,
                              fontFamily: "WorkSansBold"),
                        ),
                      ),
                      onPressed: null,
                      //onPressed: _bLoginEnabled ? (){ onLoginPressed(loginEmailController.text, loginPasswordController.text); } : null,
                  ),
                )),
                    ],
                  ),
                ),
              ),
        ),
      ),
    );
  }

  void onImagePressed(){
      getImage();
  }
  @override
  void dispose() {
    myFocusNodePassword.dispose();
    myFocusNodeEmail.dispose();
    myFocusNodeName.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();


    var resFuture = getFieldDetails();
    resFuture.then((res){
        if ((res["success"] == "true") || (res["success"] == true)) {
          var a = 3;
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
                      profileEmailController.text = o.getString("user");
                      profilePasswordController.text = o.getString("password");
                      onProfilePressed(profileEmailController.text, profilePasswordController.text);
                    });
    });
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
           var h = MediaQuery.of(context).size.height;
          _heightImage = h * 0.15;
          _heightSwitch = h * 0.05;
          _heightCard = h * 0.7;
          _heightButton = h * 0.05;

          var w = _heightImage * _image.width / _image.height;
          _image = new Image.asset('assets/img/no_portrait.png', fit: BoxFit.scaleDown, width: w, height: _heightImage);   
        });
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
        painter: TabIndicationPainter(dxTarget : (widthSwitch/2), radius : (_heightSwitch/2), dy : (_heightSwitch/2), dxEntry : 0.0, color: Theme.Colors.zarizGradientEnd.value, pageController: _pageController),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Expanded(
              child: FlatButton(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onPressed: _onSignInButtonPress,
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
                onPressed: _onSignUpButtonPress,
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

  Widget _buildRow(BuildContext context) {
    return new Container(
      child: new Column(children:<Widget>[ 
        new Row(children:<Widget>[ 
        new Flexible(child: TextField(
                            focusNode: myFocusNodeEmailProfile,
                            controller: profileEmailController,
                            keyboardType: TextInputType.emailAddress,
                            
                            style: TextStyle(
                                fontFamily: "WorkSansSemiBold",
                                fontSize: 16.0,
                                color: Colors.black),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              icon: Icon(
                                FontAwesomeIcons.envelope,
                                color: Colors.black87,
                                size: 22.0,
                              ),
                              hintText: "שם פרטי",
                              hintStyle: TextStyle(
                                  fontFamily: "WorkSansSemiBold", fontSize: 17.0),
                            ),
                          ),), 
        new Flexible(child: TextField(
                            focusNode: myFocusNodeEmailProfile,
                            controller: profileEmailController,
                            keyboardType: TextInputType.emailAddress,
                            
                            style: TextStyle(
                                fontFamily: "WorkSansSemiBold",
                                fontSize: 16.0,
                                color: Colors.black),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              icon: Icon(
                                FontAwesomeIcons.envelope,
                                color: Colors.black87,
                                size: 22.0,
                              ),
                              hintText: "שם משפחה",
                              hintStyle: TextStyle(
                                  fontFamily: "WorkSansSemiBold", fontSize: 17.0),
                            ),
                          ),)]),],)
    );
  }

  Widget _buildWorkerDetails1(BuildContext context) {
      return new Directionality(
        textDirection: TextDirection.rtl,
        child : new Container(
          decoration: new BoxDecoration(
                  gradient: new LinearGradient(
                      colors: [
                        Theme.Colors.zarizGradientStart,
                        Theme.Colors.zarizGradientEnd
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
                                focusNode: myFocusNodeEmailProfile,
                                controller: profileEmailController,
                                keyboardType: TextInputType.emailAddress,
                                
                                style: TextStyle(
                                  fontFamily: "WorkSansSemiBold",
                                  fontSize: 16.0,
                                  color: Colors.black),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    icon: Icon(
                                      FontAwesomeIcons.user,
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
                                  focusNode: myFocusNodeEmailProfile,
                                  controller: profileEmailController,
                                  keyboardType: TextInputType.emailAddress,
                                
                                  style: TextStyle(
                                    fontFamily: "WorkSansSemiBold",
                                    fontSize: 16.0,
                                    color: Colors.black
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    icon: Icon(
                                      FontAwesomeIcons.user,
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
                          Padding(
                            padding: EdgeInsets.only(
                                top: 20.0, bottom: 20.0, left: 25.0, right: 25.0),
                            child: TextField(
                              focusNode: myFocusNodePasswordProfile,
                              controller: profilePasswordController,
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
                        Theme.Colors.zarizGradientStart,
                        Theme.Colors.zarizGradientEnd
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
                            child: createMultiGridView(), 
                            
                          ),                         
                      ]))),
                  
                ],
              ),
            ],
          ),
        ),
              
      );
    }
  
  Widget _buildWorkerDetails(BuildContext context) {
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
                              focusNode: myFocusNodeEmailProfile,
                              controller: profileEmailController,
                              keyboardType: TextInputType.emailAddress,
                              
                              style: TextStyle(
                                fontFamily: "WorkSansSemiBold",
                                fontSize: 16.0,
                                color: Colors.black),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  icon: Icon(
                                    FontAwesomeIcons.user,
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
                                focusNode: myFocusNodeEmailProfile,
                                controller: profileEmailController,
                                keyboardType: TextInputType.emailAddress,
                              
                                style: TextStyle(
                                  fontFamily: "WorkSansSemiBold",
                                  fontSize: 16.0,
                                  color: Colors.black
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  icon: Icon(
                                    FontAwesomeIcons.user,
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
                        Padding(
                          padding: EdgeInsets.only(
                              top: 20.0, bottom: 20.0, left: 25.0, right: 25.0),
                          child: TextField(
                            focusNode: myFocusNodePasswordProfile,
                            controller: profilePasswordController,
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
            new Expanded(child: createMultiGridView()),
           
          ],
        ),
      ),
            
    );
  }

  GridView createMultiGridView(){
    
    var gridView = new GridView.builder(
        itemCount: _litems.length,
        shrinkWrap: true,
        gridDelegate:
            new SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        itemBuilder: (BuildContext context, int index) {
          var s = _litems[index];
          return new GestureDetector(
            child: new Card(
              elevation: 2.0,
                  color: Colors.white54,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
              child: new Container(
                alignment: Alignment.center,
                child: new Text('$s'),
              ),
            ),
            onTap: () {
              showDialog(
                barrierDismissible: false,
                context: context,
                child: new CupertinoAlertDialog(
                  title: new Column(
                    children: <Widget>[
                      new Text("GridView"),
                      new Icon(
                        Icons.favorite,
                        color: Colors.green,
                      ),
                    ],
                  ),
                  content: new Text("Selected Item $index"),
                  actions: <Widget>[
                    new FlatButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: new Text("OK"))
                  ],
                ),
              );
            },
          );
        });
        return gridView;
  }
  void onProfilePressed(email, password) {
    _bProfileEnabled = false;
    // var resFuture = performProfile(email, password);
    // resFuture.then((res){
    //     if ((res["success"] == "true") || (res["success"] == true)) {
    //         showInSnackBar(email + " שלום");
    //     } else if (res["error"].contains("Authent")) {
    //         showInSnackBar("שם משתמש או סיסמא אינם רשומים במערכת");
    //     } else {
    //         showInSnackBar("הקשר לשרת נכשל, אנא נסה שוב מאוחר יותר");
    //     }  
    //     _bProfileEnabled = true;
    // });
  }
  void onSignUpPressed(username, email, password)
  {
      _bSignUpEnabled = false;
      // var resFuture = performSignUp(username, email, password);
      // resFuture.then((res){
      //   if ((res["success"] == "true") || (res["success"] == true) ){
      //       if (res["isNewUser"] == "true") {
      //           showInSnackBar("משתמש קיים - נכנס");
      //       } else {
      //           showInSnackBar(email + " שלום");
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (context) => ProfilePage()),
      //           );
      //       }
      //   } else {
      //       showInSnackBar("ההרשמה נכשלה");
      //   }
      //    _bSignUpEnabled = true;
      // });
  }
  final List<Widget> DefaultPages = <Widget>[
    new ConstrainedBox(
      constraints: const BoxConstraints.expand(),
      child: new FlutterLogo(colors: Colors.red),
    ),
    new ConstrainedBox(
      constraints: const BoxConstraints.expand(),
      child: new FlutterLogo(style: FlutterLogoStyle.stacked, colors: Colors.red),
    ),
    new ConstrainedBox(
      constraints: const BoxConstraints.expand(),
      child: new FlutterLogo(style: FlutterLogoStyle.horizontal, colors: Colors.red),
    ),
  ];

  Widget _buildCarousel(BuildContext context) {
    var c = new CarosuelState(pages : <Widget>[new ConstrainedBox(
      constraints: const BoxConstraints.expand(),
      child: _buildWorkerDetails1(context),
    ),new ConstrainedBox(
      constraints: const BoxConstraints.expand(),
      child: _buildWorkerDetails2(context),
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
                        Padding(
                          padding: EdgeInsets.only(
                              top: 20.0, bottom: 20.0, left: 25.0, right: 25.0),
                          child: TextField(
                            focusNode: myFocusNodeName,
                            controller: signupNameController,
                            keyboardType: TextInputType.text,
                            textCapitalization: TextCapitalization.words,
                            style: TextStyle(
                                fontFamily: "WorkSansSemiBold",
                                fontSize: 16.0,
                                color: Colors.black),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              icon: Icon(
                                FontAwesomeIcons.user,
                                color: Colors.black,
                              ),
                              hintText: "שם",
                              hintStyle: TextStyle(
                                  fontFamily: "WorkSansSemiBold", fontSize: 16.0),
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
                            focusNode: myFocusNodeEmail,
                            controller: signupEmailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                                fontFamily: "WorkSansSemiBold",
                                fontSize: 16.0,
                                color: Colors.black),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              icon: Icon(
                                FontAwesomeIcons.envelope,
                                color: Colors.black,
                              ),
                              hintText: "דואר אלקטרוני",
                              hintStyle: TextStyle(
                                  fontFamily: "WorkSansSemiBold", fontSize: 16.0),
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
                            focusNode: myFocusNodePassword,
                            controller: signupPasswordController,
                            obscureText: _obscureTextSignup,
                            style: TextStyle(
                                fontFamily: "WorkSansSemiBold",
                                fontSize: 16.0,
                                color: Colors.black),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              icon: Icon(
                                FontAwesomeIcons.lock,
                                color: Colors.black,
                              ),
                              hintText: "סיסמא",
                              hintStyle: TextStyle(
                                  fontFamily: "WorkSansSemiBold", fontSize: 16.0),
                              suffixIcon: GestureDetector(
                                onTap: _toggleSignup,
                                child: Icon(
                                  FontAwesomeIcons.eye,
                                  size: 15.0,
                                  color: Colors.black,
                                ),
                              ),
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
                            controller: signupConfirmPasswordController,
                            obscureText: _obscureTextSignupConfirm,
                            style: TextStyle(
                                fontFamily: "WorkSansSemiBold",
                                fontSize: 16.0,
                                color: Colors.black),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              icon: Icon(
                                FontAwesomeIcons.lock,
                                color: Colors.black,
                              ),
                              hintText: "אישור סיסמא",
                              hintStyle: TextStyle(
                                  fontFamily: "WorkSansSemiBold", fontSize: 16.0),
                              suffixIcon: GestureDetector(
                                onTap: _toggleSignupConfirm,
                                child: Icon(
                                  FontAwesomeIcons.eye,
                                  size: 15.0,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 340.0),
                  decoration: new BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Theme.Colors.zarizGradientStart,
                        offset: Offset(1.0, 6.0),
                        blurRadius: 20.0,
                      ),
                      BoxShadow(
                        color: Theme.Colors.zarizGradientEnd,
                        offset: Offset(1.0, 6.0),
                        blurRadius: 20.0,
                      ),
                    ],
                    gradient: new LinearGradient(
                        colors: [
                          Theme.Colors.zarizGradientEnd,
                          Theme.Colors.zarizGradientStart
                        ],
                        begin: const FractionalOffset(0.2, 0.2),
                        end: const FractionalOffset(1.0, 1.0),
                        stops: [0.0, 1.0],
                        tileMode: TileMode.clamp),
                  ),
                  child: MaterialButton(
                      highlightColor: Colors.transparent,
                      splashColor: Theme.Colors.zarizGradientEnd,
                      //shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5.0))),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 42.0),
                        child: Text(
                          "הרשמה",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 25.0,
                              fontFamily: "WorkSansBold"),
                        ),
                      ),
                      onPressed:  _bSignUpEnabled ? signupButtonPressed : null,
                    ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void signupButtonPressed() {
    if (signupConfirmPasswordController.text != signupPasswordController.text) {
        showInSnackBar("הסיסמאות לא תואמות");
    } else if (signupNameController.text.isEmpty) {
        showInSnackBar("שכחת לציין את השם");
    } else if (signupEmailController.text.isEmpty) {
        showInSnackBar("שכחת לציין את כתובת הדואר האלקטרוני");
    } else {
        onSignUpPressed(signupNameController.text, signupEmailController.text, signupPasswordController.text);
    }
  }

  void _onSignInButtonPress() {
    _pageController.animateToPage(0,
        duration: Duration(milliseconds: 500), curve: Curves.decelerate);
  }

  void _onSignUpButtonPress() {
    _pageController?.animateToPage(1,
        duration: Duration(milliseconds: 500), curve: Curves.decelerate);
  }

  void _toggleProfile() {
    setState(() {
      _obscureTextProfile = !_obscureTextProfile;
    });
  }

  void _toggleSignup() {
    setState(() {
      _obscureTextSignup = !_obscureTextSignup;
    });
  }

  void _toggleSignupConfirm() {
    setState(() {
      _obscureTextSignupConfirm = !_obscureTextSignupConfirm;
    });
  }
}
