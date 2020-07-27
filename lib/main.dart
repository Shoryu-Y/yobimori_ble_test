import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:yobimori_bluetooth_app/blue_widgets.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StreamBuilder<BluetoothState>(
          stream: FlutterBlue.instance.state,
          initialData: BluetoothState.unknown,
          builder: (c, snapshot) {
            final state = snapshot.data;
            if (state == BluetoothState.on) {
              return MyHomePage();
            }
            return BluetoothOffScreen(state: state);
        }),
    );
  }
}

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key key, this.state}) : super(key: key);
  final BluetoothState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: Center(
        child: Text(
          'Bluetooth Adapter is ${state != null ? state.toString().substring(15) : 'not available'}.',
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FlutterBlue flutterBlue = FlutterBlue.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            StreamBuilder<List<ScanResult>>(
              stream: flutterBlue.scanResults,
              initialData: [],
              builder: (BuildContext context, snapshot){
                return Column(
                  children: snapshot.data.map((r) => ScanResultTile(
                      result: r,
                      onTap: (){
                        flutterBlue.stopScan();
                        Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) {
                              return DeviceScreen(device: r.device);
                            })
                        );
                      }
                    ),
                  ).toList(),
                );
              }
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => flutterBlue.startScan(),
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({Key key, this.device}) : super(key: key);

  final BluetoothDevice device;

  @override
  _DeviceScreenState createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  ScanResult result;
  String strength;

  @override
  void initState() {
    super.initState();
    /*
    Timer.periodic(Duration(seconds: 3), (timer) {
      flutterBlue.stopScan();
      print('スキャン');
      flutterBlue.startScan();
    });

   */

    Timer.periodic(Duration(seconds: 3), (timer) {
      flutterBlue.stopScan();
      flutterBlue.scan(timeout: Duration(seconds: 2)).listen((scanResult){
        if(scanResult.device.id == widget.device.id){
          print('rssi: ${scanResult.rssi}');
          setState(() {
            result = scanResult;
          });
          flutterBlue.stopScan();
        }else{
          print('dont find');
        }
      }, onDone: () => flutterBlue.stopScan()
      );
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            StreamBuilder<BluetoothDeviceState>(
              stream: widget.device.state,
              initialData: BluetoothDeviceState.connecting,
              builder: (c, snapshot){
                return ListTile(
                  leading: (snapshot.data == BluetoothDeviceState.connected)
                      ? Icon(Icons.bluetooth_connected)
                      : Icon(Icons.bluetooth_disabled),
                  title: Text(
                      'Device is ${snapshot.data.toString().split('.')[1]}.'),
                  subtitle: Text('${widget.device.id}'),
                  trailing: StreamBuilder<bool>(
                    stream: widget.device.isDiscoveringServices,
                    initialData: false,
                    builder: (c, snapshot) => IndexedStack(
                      index: snapshot.data ? 1 : 0,
                      children: <Widget>[
                        IconButton(
                          icon: Icon(Icons.refresh),
                          onPressed: () => widget.device.discoverServices(),
                        ),
                        IconButton(
                          icon: SizedBox(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(Colors.grey),
                            ),
                            width: 18.0,
                            height: 18.0,
                          ),
                          onPressed: null,
                        )
                      ],
                    ),
                  ),
                );
              }
            ),
            Text('RSSI'),
            /*
            StreamBuilder(
              stream: flutterBlue.scanResults,
              builder: (BuildContext context, AsyncSnapshot snapshot){
                if(!snapshot.hasData){
                  return Text('no signal');
                }
                List<ScanResult> result = snapshot.data;
                ScanResult target = result.singleWhere((r) => r.device.id == widget.device.id, orElse: () => null);
                if(target == null){
                  strength = '--';
                }else{
                  print('rssi : ${target.rssi}');
                  strength = target.rssi.toString();
                }
                return Text('${target.rssi}');
              },

            ),
             */
          ],
        ),
      ),
    );
  }
}