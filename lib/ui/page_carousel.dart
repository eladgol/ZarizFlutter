// Copyright 2017, the Flutter project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:zariz_app/style/theme.dart' as Theme;

/// An indicator showing the currently selected page of a PageController
class DotsIndicator extends AnimatedWidget {
  DotsIndicator({
    this.controller,
    this.itemCount,
    this.onPageSelected,
    this.color: Theme.Colors.zarizGradientEnd,
  }) : super(listenable: controller);

  /// The PageController that this DotsIndicator is representing.
  final PageController controller;

  /// The number of items managed by the PageController
  final int itemCount;

  /// Called when a dot is tapped
  final ValueChanged<int> onPageSelected;

  /// The color of the dots.
  ///
  /// Defaults to `Colors.white`.
  final Color color;

  // The base size of the dots
  static const double _kDotSize = 8.0;

  // The increase in the size of the selected dot
  static const double _kMaxZoom = 4.0;

  // The distance between the center of each dot
  static const double _kDotSpacing = 25.0;

  Widget _buildDot(int index) {
    double selectedness = Curves.easeOut.transform(
      max(
        0.0,
        1.0 - ((controller.page ?? controller.initialPage) - index).abs(),
      ),
    );
    double zoom = 1.0 + (_kMaxZoom - 1.0) * selectedness;
    return new Container(
      width: _kDotSpacing,
      child: new Center(
        child: new Material(
          color: color,
          type: MaterialType.circle,
          child: new Container(
            width: _kDotSize * zoom,
            height: _kDotSize * zoom,
            child: new InkWell(
              onTap: () => onPageSelected(index),
            ),
          ),
        ),
      ),
    );
  }

  Widget build(BuildContext context) {
    return new Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: new List<Widget>.generate(itemCount, _buildDot),
    );
  }
}

class CarosuelState {
  List<Widget> pages;
  CarosuelState({
    this.pages = const [],
  });
  final _controller = new PageController();

  static const _kDuration = const Duration(milliseconds: 300);

  static const _kCurve = Curves.ease;
  var currentPageValue = 0.0;
  PageView _pv;
  double getCurrentPage(BuildContext context) {
    try {
      return currentPageValue;
    } catch (e) {
      return 0.0;
    }
  }

  int getNumberOfPages() {
    return pages.length;
  }

  void setPage(int page) {
    try {
      _controller.animateToPage(page, duration: _kDuration, curve: _kCurve);
      _pv.controller.jumpToPage(page);
    } catch (e) {}
  }

  Widget buildCarousel(BuildContext context, double _height, Function(int) pageChangedCallback) {
    _controller.addListener(() {
      currentPageValue = _controller.page;
      print("JobsPageCarouselValue $currentPageValue");
    });
    _pv = new PageView.builder(
        onPageChanged: ((i) {
           pageChangedCallback(i);
        }),
        physics: (pages.length == 1)
            ? new NeverScrollableScrollPhysics()
            : new AlwaysScrollableScrollPhysics(),
        controller: _controller,
        itemBuilder: (BuildContext context, int index) {
          return pages[index % pages.length];
        });
    //_pv.onPageChanged

    return new Stack(
      children: <Widget>[
        new SizedBox(
          height: _height,
          child: _pv,
        )

        // new Positioned(
        //   top: 0.0,
        //   left: 0.0,
        //   right: 0.0,
        //   child: new Container(
        //     color: Colors.grey[800].withOpacity(0.1),
        //     padding: const EdgeInsets.all(20.0),
        //     child: new Center(
        //       child: new DotsIndicator(
        //         controller: _controller,
        //         itemCount: pages.length,
        //         onPageSelected: (int page) {
        //           _controller.animateToPage(
        //             page,
        //             duration: _kDuration,
        //             curve: _kCurve,
        //           );
        //         },
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }
}
