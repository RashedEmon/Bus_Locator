import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:background_location/background_location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:io';
import 'package:bus_locator/LocationInformation.dart';
import 'login.dart';
import 'package:http/http.dart' as http;

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
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> implements Type{
  //instance variable
  bool isStart=true;
  bool locationMandatoryDialogue=false;
  String latitudeData='';
  String longitudeData='';
  LocationInfo locationInfo = LocationInfo();
  dynamic _subscription;
  dynamic channel;
  String bus='';
  var client=http.Client();
  late SharedPreferences sharedPreferences;
  //final channel=WebSocket.connect('ws://192.168.1.120:8000/ws/location/bus1',protocols: ['ws:']);
  getBusFromServer() async{
    var uri=Uri(scheme: 'http',host: '192.168.1.120',port: 8000,path: 'api/bus/',);
      try{
        http.Response response=await client.get(uri, headers: {
          "Authorization": "Token ${sharedPreferences.getString('token')}"
        });
        if(response.statusCode>=200 && response.statusCode<400){
          print(response.body);
          var res=jsonDecode(response.body);

          print(bus);
          setState(() {
            bus=res['bus_name'];
          });
        }else{

        }
      }on Exception catch(e){
        print('exception');
      }
  }
  Future<dynamic> createSocketConnection() async{
  //channel=WebSocketChannel.connect(Uri.parse('ws://192.168.1.120:8000/ws/location/bus1'));
    try{
      if(channel!=null){
        channel.close();
      }
      channel=await WebSocket.connect('ws://192.168.1.120:8000/ws/location/${bus}',protocols: ['ws:']);
    }on SocketException {
      print('exception here');
      return 1;

    }
  return channel;
    //print(channel.closeReason);
  }


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
    if(! await locationPermission()){
      print('location denied');
      return false;
    }

    await BackgroundLocation.setAndroidNotification(
      title: 'Background service is running',
      message: 'Background location in progress',
    );
    dynamic socket=await createSocketConnection();
    if(socket is int){
      return false;
    }
    dynamic locationOkay= await BackgroundLocation.startLocationService(distanceFilter: 0,forceAndroidLocationManager: false);
  BackgroundLocation.getLocationUpdates((location) => {
    locationInfo.latitude=location.latitude.toString(),
    locationInfo.longitude=location.longitude.toString(),
    locationInfo.accuracy=location.accuracy.toString(),
    locationInfo.speed=location.speed.toString(),
    locationInfo.time=location.time.toString(),


  //channel.sink.add(LocationInfo.toJson(locationInfo)),
        socket.add(LocationInfo.toJson(locationInfo)),



    setState(() {
      latitudeData=location.latitude.toString();
      longitudeData=location.longitude.toString();
    }),
  });
   _subscription=socket.listen(
          (message){
            //debugPrint(message);
          },
      onError: (e){
            socket.close();
            locationAndSocket();
          debugPrint('error');
      },
    onDone: (){
            if(_subscription!=null){
              _subscription.cancel();

            }
            setState(() {
              isStart=true;
            });
            if(channel!=null){
             channel.close();
            }
      debugPrint('Disconnected');
    },
       cancelOnError:true,
  );
   return true;
  }

  @override
  void dispose(){
    BackgroundLocation.stopLocationService();

    channel!=null?channel.close(): '';

  }
  @override
  void initState() {
   checkLoginStatus();
  }
  checkLoginStatus() async {
    sharedPreferences = await SharedPreferences.getInstance();
    if(sharedPreferences.getString("token") == null) {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => const LoginPage()), (Route<dynamic> route) => true);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text('Locator Device'),
        ),
         actions: <Widget>[
          ElevatedButton(
            onPressed: isStart?() {
              sharedPreferences.clear();
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => const LoginPage()), (Route<dynamic> route) => false);
            }: null,
            child: const Text("Log Out", style: TextStyle(color: Colors.white)),
          ),
        ],
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
                    await getBusFromServer();
                    if(bus!='') {
                      bool isEnabled = await locationAndSocket();
                      if (isEnabled) {
                        setState(() {
                          isStart = !isStart;
                        });
                      }
                    }
                  }: null,
                  child: const Text(
                    'Start'
                  ),
                ),
                const SizedBox(width: 20,),
                ElevatedButton(
                  onPressed: !isStart?(){

                    setState(() {
                      isStart=!isStart;
                    });
                    BackgroundLocation.stopLocationService();
                    channel!=null?channel.close(): '';
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


