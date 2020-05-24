import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:zariz_app/ui/profile_page.dart';

Widget buildMapWidgetJobsForWorker(List<JobDetailsForWorker> lJobs, WorkerDetails lWorkers, CurrentLocation currentLocation, Function(String) onTapInfoWindow)
{
  Set<Marker> markers = <Marker>{};
  for (JobDetailsForWorker job in lJobs) {
      String title = "${job.jd.discription}";
      String details = "שם העסק ${job.bd.buisnessName} \nשם המעסיק ${job.bd.firstName} ${job.bd.lastName}\nשכר ${job.jd.wage}\nמיקום ${job.jd.place}\n";
      InfoWindow iw = new InfoWindow(title: title, snippet: details, onTap: () {onTapInfoWindow(job.jd.jobId);});
      BitmapDescriptor markerIcon = job.bHired ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow) : job.bAuthorized ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen) : job.bResponded ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed) : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      markers.add(new Marker(icon: markerIcon, infoWindow: iw, position: LatLng(job.jd.lat, job.jd.lng) ,markerId: MarkerId(job.jd.jobId)));
  }
  
  Completer<GoogleMapController> _controller = Completer();
  CameraPosition _kCurLocation = CameraPosition(
    target: LatLng(currentLocation.lat, currentLocation.lng),
    zoom: 9,
  );
  return new GoogleMap(
        mapType: MapType.normal,
        markers: markers,
        initialCameraPosition: _kCurLocation,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      );
}