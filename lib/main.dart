import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

// ★ 본인 PC의 와이파이 IP로 변경
const String SERVER_URL = 'http://192.168.201.102:3000';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late WebViewController webController;
  bool webLoaded = false;
  String statusText = '📡 GPS 연결 중...';

  @override
  void initState() {
    super.initState();
    _initWebView();
    _initGPS();
  }

  // WebView 초기화
  void _initWebView() {
    webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          setState(() => webLoaded = true);
        },
        onWebResourceError: (error) {
          setState(() => statusText = '❌ 웹 로드 실패: ${error.description}');
        },
      ))
      ..loadRequest(Uri.parse("$SERVER_URL/testBike_main.html"));
  }

  // GPS 초기화
  Future<void> _initGPS() async {
    // 위치 권한 요청
    await Permission.location.request();

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => statusText = '❌ GPS를 켜주세요');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // GPS 실시간 수신 시작
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3, // 3m 이상 움직일 때마다 전송
      ),
    ).listen((Position pos) {
      _sendLocationToServer(pos.latitude, pos.longitude);
      setState(() {
        statusText =
        '📍 ${pos.latitude.toStringAsFixed(5)}, '
            '${pos.longitude.toStringAsFixed(5)}';
      });
    });
  }

  // 서버로 GPS 데이터 전송
  Future<void> _sendLocationToServer(double lat, double lng) async {
    try {
      await http.post(
        Uri.parse('$SERVER_URL/location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'lat': lat, 'lng': lng}),
      );
    } catch (e) {
      print('전송 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚴 내 위치 테스트'),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [

          // 웹뷰 (카카오 지도)
          WebViewWidget(controller: webController),

          // 로딩 중
          if (!webLoaded)
            const Center(
              child: CircularProgressIndicator(color: Colors.green),
            ),

          // GPS 상태 표시 (하단)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}