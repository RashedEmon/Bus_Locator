import 'package:flutter/material.dart';
import 'package:background_location/background_location.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:permission_handler/permission_handler.dart';



import 'package:bus_locator/LocationInformation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Locator Device'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);


  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //instance variable
  bool isStart=true;
  bool locationMandatoryDialogue=false;
  String latitudeData='';
  String longitudeData='';
  LocationInfo locationInfo = LocationInfo();

    final channel=IOWebSocketChannel.connect('ws://localhost:8000/ws/location/bus');





  Future<bool> locationPermission() async{
    print('enter in locate');
    //await Permission.locationAlways.request();

     if(! await Permission.locationWhenInUse.isGranted){
       print('enter in check');
      PermissionStatus status= await Permission.locationWhenInUse.request();
      print(status);
     status= status.isGranted? await Permission.locationAlways.request(): PermissionStatus.denied ;
        if(status.isDenied){
          print('enter in denied');
          return false;
        }

     }
    return true;
  }
  Future<bool> locationAndSocket() async{
    try {

    } on Exception catch (e) {
     print(e);
    }

    if(! await locationPermission()){
      print('location denied');
      return false;
    }

    await BackgroundLocation.setAndroidNotification(
      title: 'Background service is running',
      message: 'Background location in progress',
    );

    dynamic locationOkay= await BackgroundLocation.startLocationService(distanceFilter: 0,forceAndroidLocationManager: false);
  BackgroundLocation.getLocationUpdates((location) => {
    locationInfo.latitude=location.latitude.toString(),
    locationInfo.longitude=location.latitude.toString(),
    locationInfo.accuracy=location.accuracy.toString(),
    locationInfo.speed=location.speed.toString(),
    locationInfo.time=location.time.toString(),
    //locationInfo.show(),
    setState(() {
      latitudeData=location.latitude.toString();
      longitudeData=location.longitude.toString();
    }),

    
    channel.sink.add(LocationInfo.toJson(locationInfo)),

  });

    channel.stream.listen((message) {
      channel.sink.add('received!');
      print('hi');
      print(message);
    });
   return true;
  }

  @override
  void dispose(){

    BackgroundLocation.stopLocationService();
    channel.sink.close(status.goingAway);

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(

        title: Center(
          child: Text(widget.title),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
               ElevatedButton(
                  onPressed: isStart?() async {
                    // channel.sink.add('hello');
                    // print('ok');
                   bool isEnabled= await locationAndSocket();
                    if(isEnabled){
                      setState(() {
                        isStart=! isStart;
                      });
                    }
                  }: null,
                  child: const Text(
                    'Start'
                  ),
                ),
                const SizedBox(width: 20,),
                ElevatedButton(
                  onPressed: !isStart?(){
                    dispose();
                    setState(() {
                      isStart=!isStart;
                    });
                  }: null,
                  child: const Text(
                      'Stop'
                  ),
                ),
                const SizedBox(height: 50,),

              ],
            ),
            Row(
              children: [
                Text(
                    'Latitude: $latitudeData \n Longitude: $longitudeData'
                )
              ],
            )
          ],
        ),
      ),
       // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}


