import 'dart:convert';
class LocationInfo{
  String latitude='24.5';
  String longitude='83.45';
  String bearing='192';
  String speed='0.0';
  String accuracy='10';
  String time='';


  static String toJson(LocationInfo info) {
    try {
      return json.encode(info,
          toEncodable: (info) => {
            'latitude': info.latitude,
            'longitude': info.longitude,
            'bearing': info.bearing,
            'speed': info.speed,
            'accuracy': info.accuracy,
            'time': info.time,
          });
    } catch (e) {
      print(e);
      return 'error when decode';
    }
  }
}