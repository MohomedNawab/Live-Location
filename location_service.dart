import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../constants.dart';
import '../profiles/profile2.dart';
import '../widgets/custom_btn.dart';

class RealTimeLocationUpdates extends StatefulWidget {
  const RealTimeLocationUpdates({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RealTimeLocationUpdatesState createState() =>
      _RealTimeLocationUpdatesState();
}

class _RealTimeLocationUpdatesState extends State<RealTimeLocationUpdates> {
  // final geoLocator = GeolocatorPlatform.instance;
  final firestoreInstance = FirebaseFirestore.instance;

  StreamSubscription<Position>? _positionStreamSubscription;
  GeoPoint? _currentPosition;
  final startDate = DateTime.utc(2022, 1, 1);
  final endDate = DateTime.utc(2022, 1, 31);
  @override
  void initState() {
    super.initState();
    _initLocationUpdates();
  }

  @override
  void dispose() {
    super.dispose();
    _positionStreamSubscription?.cancel();
  }

  Future<void> _initLocationUpdates() async {
    try {
      // Check location service permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permission denied';
        }
      }

      // Start listening for location updates with a time interval of 5 seconds
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // meters
        timeLimit: Duration(minutes: 10), // milliseconds
      );
      _positionStreamSubscription =
          Geolocator.getPositionStream(locationSettings: locationSettings)
              .listen(
        (position) async {
          setState(() {
            _currentPosition = GeoPoint(position.latitude, position.longitude);
          });
          if (FirebaseAuth.instance.currentUser != null) {
            await firestoreInstance
                .collection('Logins')
                .doc(FirebaseAuth.instance.currentUser!.email)
                .collection('LocationData')
                .add({
              'email': FirebaseAuth.instance.currentUser!.email,
              'location': _currentPosition,
              'time': FieldValue.serverTimestamp(),
            }).then((value) => print("Data added!"),
                    onError: (e) => print("error $e"));
          } else {
            print(FirebaseAuth.instance.currentUser);
          }
        },
      );
    } catch (error) {
      print(error);
    }
  }

  // final documentReference = FirebaseFirestore.instance
  //     .collection('dailyLogin')
  //     .doc(FirebaseAuth.instance.currentUser!.uid);
  //     final field = await documentReference.get().then((snapshot) => snapshot.data()!['email']);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
                image: DecorationImage(
                    image: AssetImage('assets\locationbg.jpg'),
                    fit: BoxFit.cover)),
            child: Column(
              children: [
                const SizedBox(
                  height: 50,
                ),
                const Text(
                  "Location Service",
                  textAlign: TextAlign.center,
                  style: Constants.boldHeading,
                ),
                const SizedBox(
                  height: 50,
                ),
                const Icon(Icons.location_on, size: 46.0, color: Colors.black),
                const SizedBox(
                  height: 50,
                ),
                Center(
                  child: _currentPosition != null
                      ? Text(
                          'Latitude: ${_currentPosition?.latitude}\nLongitude: ${_currentPosition?.longitude}',
                          textAlign: TextAlign.center,
                          style: Constants.regularDarkText,
                        )
                      : CircularProgressIndicator(),
                ),
                const SizedBox(
                  height: 50,
                ),
                Center(
                  child: CustomBtn(
                    text: "Logout",
                    onPressed: () {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (context) => const Profile()));
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
