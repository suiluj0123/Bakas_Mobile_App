import 'package:flutter/foundation.dart';
import 'dart:io';

class ApiConfig {

  static const String publicUrl = ''; 

  static String get baseUrl {
    if (publicUrl.isNotEmpty) {
      return publicUrl.endsWith('/') 
          ? publicUrl.substring(0, publicUrl.length - 1) 
          : publicUrl;
    }
    
    if (kIsWeb) {
      return 'http://localhost:3001';
    }
    
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3001';
    }
    
    return 'http://localhost:3001';
  }
}


