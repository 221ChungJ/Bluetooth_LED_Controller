import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async';
import 'package:led_controller_ble_2/constants.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:led_controller_ble_2/bottom_button.dart';

void main() => runApp(MaterialApp(
    theme: ThemeData.dark().copyWith(
      primaryColor: Color(0xFF0A0E21),
      scaffoldBackgroundColor: Color(0xFF0A0E21),
    ),
    home: MyApp()));

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<List<Color>> colorz = [
    [],
    [],
    [],
  ];
  List<Color> sliderColor = [Colors.black, Colors.black, Colors.black];
  List<Color> blockColor = [Colors.black, Colors.black, Colors.black];


  void saveData() async{
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
    for (var i = 0; i < colorz.length; i++) {
      for (var j = 0; j < colorz[i].length; j++) {
        await prefs.setInt('color' + i.toString() + j.toString(), colorz[i][j].value);
      }
    }
    await prefs.setInt('listNum1', colorz[0].length);
    await prefs.setInt('listNum2', colorz[1].length);
    await prefs.setInt('listNum3', colorz[2].length);
  }

  void loadData() async{
    final prefs = await SharedPreferences.getInstance();
    int listNum1 = (await prefs.getInt('listNum1') ?? 1);
    for (var i = 0; i < listNum1; i++) {
      colorz[0].add(Color(prefs.getInt('color0'+i.toString()) ?? 4278190080));
    }
    int listNum2 = (await prefs.getInt('listNum2') ?? 1);
    for (var i = 0; i < listNum2; i++) {
      colorz[1].add(Color(prefs.getInt('color1'+i.toString()) ?? 4278190080));
    }
    int listNum3 = (await prefs.getInt('listNum3') ?? 1);
    for (var i = 0; i < listNum3; i++) {
      colorz[2].add(Color(prefs.getInt('color2'+i.toString()) ?? 4278190080));
    }
  }

  initState(){
    loadData();
  }

  // Some state management stuff
  bool _scanStarted = false;
  bool _connected = false;
  // Bluetooth related variables
  late DiscoveredDevice _ubiqueDevice;
  final flutterReactiveBle = FlutterReactiveBle();
  late StreamSubscription<DiscoveredDevice> _scanStream;
  late QualifiedCharacteristic _rxCharacteristic;
  // These are the UUIDs of your device
  final Uuid serviceUuid = Uuid.parse("0000ffe0-0000-1000-8000-00805f9b34fb");
  final Uuid characteristicUuid =
  Uuid.parse("0000ffe1-0000-1000-8000-00805f9b34fb");

  void _stopScan() async {
    setState(() {
      _scanStarted = false;
      _scanStream.cancel();
    });
  }

  void _startScan() async {
    // Platform permissions handling stuff
    bool permGranted = false;
    setState(() {
      _scanStarted = true;
    });

    // Main scanning logic happens here ⤵️
    _scanStream = flutterReactiveBle
        .scanForDevices(withServices: [serviceUuid]).listen((device) {
      // Change this string to what you defined in Zephyr
      if (device.name == 'DSD TECH') {
        setState(() {
          _ubiqueDevice = device;
        });
        _connectToDevice();
      }
    });
  }

  void _connectToDevice() {
    // We're done scanning, we can cancel it
    _scanStream.cancel();
    // Let's listen to our connection so we can make updates on a state change
    Stream<ConnectionStateUpdate> _currentConnectionStream = flutterReactiveBle
        .connectToAdvertisingDevice(
        id: _ubiqueDevice.id,
        prescanDuration: const Duration(seconds: 1),
        withServices: [serviceUuid, characteristicUuid]);
    _currentConnectionStream.listen((event) {
      switch (event.connectionState) {
      // We're connected and good to go!
        case DeviceConnectionState.connected:
          {
            _rxCharacteristic = QualifiedCharacteristic(
                serviceId: serviceUuid,
                characteristicId: characteristicUuid,
                deviceId: event.deviceId);
            setState(() {
              _connected = true;
            });
            break;
          }
      // Can add various state state updates on disconnect
        case DeviceConnectionState.disconnected:
          {
            break;
          }
        default:
      }
    });
  }

  Widget deviceCard(String deviceName, int deviceNum) {
    void addColor() {
      setState(() {
        if (colorz[deviceNum].length < 8 && colorz[deviceNum].indexOf(sliderColor[deviceNum]) < 0) {
          colorz[deviceNum].add(sliderColor[deviceNum]);
          saveData();
        }
      });
    }

    return Card(
      color: Color(0xFF1D1E33),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 20,
          ),
          Text(
            deviceName,
            style: kTitleTextStyle,
          ),
          SizedBox(
            height: 20,
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    SlidePicker(
                      //showIndicator: false,
                      sliderSize:
                      Size(MediaQuery.of(context).size.width - 50, 40),
                      indicatorSize:
                      Size(MediaQuery.of(context).size.width - 50, 70),
                      enableAlpha: false,
                      pickerColor: sliderColor[deviceNum],
                      onColorChanged: (Color color) {
                        setState(() => sliderColor[deviceNum] = color);
                      },
                    ),
                    BottomButton(
                      buttonTitle: 'ADD COLOR',
                      onTap: addColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          BlockPicker(
            pickerColor: blockColor[deviceNum],
            availableColors: colorz[deviceNum],
            onColorChanged: (Color color) {},
            layoutBuilder: (context, colors, child) {
              return GridView.count(
                // Create a grid with 2 columns. If you change the scrollDirection to
                // horizontal, this produces 2 rows.
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 25.0),
                children: List.generate(colorz[deviceNum].length, (idx) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        blockColor[deviceNum] = colors[idx];
                        flutterReactiveBle.writeCharacteristicWithoutResponse(
                            _rxCharacteristic,
                            value: [
                              deviceNum,
                              blockColor[deviceNum].red,
                              blockColor[deviceNum].green,
                              blockColor[deviceNum].blue
                            ]);
                      });
                    },
                    onLongPress: () {
                      setState(() {
                        if (colors[idx] != Colors.black){
                          colorz[deviceNum].remove(colors[idx]);
                          saveData();
                        }
                      });
                    },
                    child: Container(
                      height: 100,
                      width: 50,
                      decoration: BoxDecoration(
                        color: colors[idx],
                        border: Border.all(
                          color: colors[idx],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ),
                  );
                }),
              );
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _connected
          ? ListView(
        scrollDirection: Axis.vertical,
        children: [
          deviceCard('Left City', 0),
          deviceCard('Right City', 1),
          deviceCard('Lightsaber Display', 2),
        ],
      )
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Waiting to Connect to Device',
              style: kLabelTextStyle,
            ),
            SizedBox(
              height: 20,
            ),
            LoadingAnimationWidget.staggeredDotsWave(
                color: Color(0xFFEB1555), size: 100)
          ],
        ),
      ),
      persistentFooterButtons: [
        _scanStarted
        //True Condition
            ? ElevatedButton(
          style: ElevatedButton.styleFrom(
            primary: Color(0xFFEB1555), // background
            onPrimary: Colors.white, // foreground
          ),
          onPressed: _stopScan,
          child: const Icon(Icons.bluetooth),
        )
        //False Condition
            : ElevatedButton(
          style: ElevatedButton.styleFrom(
            primary: Color(0xFF8D8E98), // background
            onPrimary: Colors.white, // foreground
          ),
          onPressed: _startScan,
          child: const Icon(Icons.bluetooth),
        ),
      ],
    );
  }
}
