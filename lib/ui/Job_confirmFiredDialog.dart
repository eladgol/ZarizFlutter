import 'package:flutter/material.dart';
import 'package:zariz_app/style/theme.dart' as Theme;
import 'package:zariz_app/utils/Services.dart';
import 'package:zariz_app/ui/uiUtils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

class JobConfirmFiredPage extends StatefulWidget {
  final String sTitle;
  final String jobID;
  final String workerID;
  JobConfirmFiredPage({Key key, this.sTitle, this.jobID, this.workerID})
      : super(key: key);

  @override
  _JobConfirmFiredPageState createState() => new _JobConfirmFiredPageState();
}

class _JobConfirmFiredPageState extends State<JobConfirmFiredPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool _bUpdating = false;
  String sTitle = "";
  String jobID = "";
  String workerID = "";
  Services _services = new Services();
  Widget build(BuildContext context) {
    sTitle = widget.sTitle;
    jobID = widget.jobID;
    workerID = widget.workerID;
    return new Scaffold(
        appBar: AppBar(
          title: Text('הוחלט שלא להעסיק אותך'),
        ),
        key: _scaffoldKey,
        body: NotificationListener<OverscrollIndicatorNotification>(
          onNotification: (overscroll) {
            overscroll.disallowGlow();
            return false;
          },
          child: new Container(
              height: MediaQuery.of(context).size.height >= 775.0
                  ? MediaQuery.of(context).size.height
                  : 775.0,
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
              child: new SingleChildScrollView(
                  child: Column(children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 75.0),
                  child: new Image(
                      width: 250.0,
                      height: 191.0,
                      fit: BoxFit.scaleDown,
                      image: new AssetImage('assets/img/login_logo.jpg')),
                ),
                (_bUpdating)
                    ? new CircularProgressIndicator(
                        backgroundColor: Theme.Colors.zarizGradientStart)
                    : new Container(),
                createTextField(" הוחלט שלא להעסיק אותך", null, null, null,
                    textSize: 32.0, bCenter: true),
                createTextField(sTitle, null, null, null,
                    bCenter: true, maxLines: 4),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      new RaisedButton(
                          child: const Text('לא צריך'),
                          onPressed: () {
                            Navigator.pop(context, 'לא צריך');
                          },
                          color: Colors.red),
                    ]),
              ]))),
        ));
  }
}
