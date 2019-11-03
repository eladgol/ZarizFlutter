import 'dart:math';

import 'package:flutter/material.dart';
class TabIndicationPainterNoPageControllerListener extends Listenable {
  int iPos;
  final int nPages;
  TabIndicationPainterNoPageControllerListener({this.iPos, this.nPages});
  @override
  void addListener(listener) {
   
  }

  @override
  void removeListener(listener) {
  
  }

}
class TabIndicationPainterNoPageController extends CustomPainter {
  Paint painter;
  final double dxTarget;
  final double dxEntry;
  final double radius;
  final double dy;
  final int color;
  final TabIndicationPainterNoPageControllerListener listener;
  

  TabIndicationPainterNoPageController(
      {this.dxTarget = 125.0,
        this.dxEntry = 25.0,
        this.radius = 21.0,
        this.dy = 25.0, 
        this.color = 0xFFFFFFFF,
        this.listener}) : super(repaint: listener) {
    painter = new Paint()
      ..color = Color(this.color)
      ..style = PaintingStyle.fill;
  }

  @override
  void paint(Canvas canvas, Size size) {

    final pos = listener.iPos;
    
    double pageOffset = pos / (listener.nPages);

    bool left2right = dxEntry < dxTarget;
    Offset entry = new Offset(left2right ? dxEntry: dxTarget, dy);
    Offset target = new Offset(left2right ? dxTarget : dxEntry, dy);

    Path path = new Path();
    path.addArc(
        new Rect.fromCircle(center: entry, radius: radius), 0.5 * pi, 1 * pi);
    path.addRect(
        new Rect.fromLTRB(entry.dx, dy - radius, target.dx, dy + radius));
    path.addArc(
        new Rect.fromCircle(center: target, radius: radius), 1.5 * pi, 1 * pi);

    canvas.translate(size.width * pageOffset, 0.0);
    canvas.drawShadow(path, Color(0xFFfbab66), 3.0, true);
    canvas.drawPath(path, painter); 
  }

  @override
  bool shouldRepaint(TabIndicationPainterNoPageController oldDelegate) => true;
}