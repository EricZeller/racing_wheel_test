import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  double _gyroscopeX = 0.0;
  double _gyroscopeY = 0.0; // Y-Achse des Gyroskops für die Lenkung
  double _gyroscopeZ = 0.0;
  double _gasValue = 0.0; // Wert für Gas
  double _brakeValue = 0.0; // Wert für Bremse
  RawDatagramSocket? _socket;

  @override
  void initState() {
    super.initState();
    // Gyroskop überwachen
    gyroscopeEvents.listen((GyroscopeEvent event) {
      setState(() {
        _gyroscopeX = event.x;
        _gyroscopeY = event.y; // Lenkung über Y-Achse
        _gyroscopeZ = event.z;
      });
      sendData();
    });

    // UDP Socket einrichten
    setupSocket();
  }

  Future<void> setupSocket() async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  }

  // Daten an den PC senden
  void sendData() {
    if (_socket != null) {
      // Lenkung, Gas und Bremse in eine einfache Nachricht packen
      String data = jsonEncode({
        'steering': _gyroscopeY,
        'gas': _gasValue,
        'brake': _brakeValue,
      });

      // Senden an den PC, IP und Port entsprechend anpassen
      _socket!.send(utf8.encode(data), InternetAddress('192.168.0.95'), 8080);
    }
  }

  @override
  void dispose() {
    _socket?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('ACC Handy Lenkrad'),
        ),
        body: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              // Rechts für Gas
              if (details.localPosition.dx > MediaQuery.of(context).size.width / 2) {
                _gasValue = (MediaQuery.of(context).size.height - details.localPosition.dy) /
                    MediaQuery.of(context).size.height;
                _brakeValue = 0.0;
              } 
              // Links für Bremse
              else {
                _brakeValue = (MediaQuery.of(context).size.height - details.localPosition.dy) /
                    MediaQuery.of(context).size.height;
                _gasValue = 0.0;
              }
            });
            sendData();
          },
          onPanEnd: (details) {
            // Gas und Bremse zurücksetzen, wenn kein Finger mehr auf dem Bildschirm ist
            setState(() {
              _gasValue = 0.0;
              _brakeValue = 0.0;
            });
            sendData();
          },
          child: Stack(
            children: [
              // Gas-Bereich anzeigen
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    color: Colors.green.withOpacity(0.3),
                    width: MediaQuery.of(context).size.width / 2,
                    child: Center(
                      child: Text(
                        'Gas: ${_gasValue.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                ),
              ),
              // Brems-Bereich anzeigen
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    color: Colors.red.withOpacity(0.3),
                    width: MediaQuery.of(context).size.width / 2,
                    child: Center(
                      child: Text(
                        'Bremse: ${_brakeValue.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                ),
              ),
              // Gyroskop-Daten anzeigen
              Positioned(
                bottom: 0,
                left: 5,
                child: Container(
                  padding: EdgeInsets.all(8),
                  color: Colors.black.withOpacity(0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gyroskop X: ${_gyroscopeX.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      Text(
                        'Gyroskop Y (Lenkung): ${_gyroscopeY.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      Text(
                        'Gyroskop Z: ${_gyroscopeZ.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
