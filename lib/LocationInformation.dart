import 'dart:convert';
class LocationInfo{
  String latitude='';
  String longitude='';
  String bearing='';
  String speed='';
  String accuracy='';
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
            'time': info.time
          });
    } catch (e) {
      print(e);
      return '';
    }
  }

  show(){
    print(this.latitude);
    print(this.longitude);
  }
}