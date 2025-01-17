import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:quick_usb/quick_usb.dart';

void main() {
  runApp(MyHome());
}

class MyHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: MyApp(),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return _buildColumn();
  }

  void log(String info) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(info)));
  }

  Widget _buildColumn() {
    return Column(
      children: [
        _init_exit(),
        _getDeviceList(),
        _getDevicesWithDescription(),
        _getDeviceDescription(),
        if (Platform.isLinux) _setAutoDetachKernelDriver(),
        _has_request(),
        _open_close(),
        _get_set_configuration(),
        _claim_release_interface(),
        _bulk_transfer(),
      ],
    );
  }

  Widget _init_exit() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          child: Text('init'),
          onPressed: () async {
            var init = await QuickUsb.init();
            print("Init info : $init");
            // log('init $init');
          },
        ),
        ElevatedButton(
          child: Text('exit'),
          onPressed: () async {
            await QuickUsb.exit();
            log('exit');
          },
        ),
      ],
    );
  }

  List<UsbDevice> _deviceList = [];

  Widget _getDeviceList() {
    return ElevatedButton(
      child: Text('getDeviceList'),
      onPressed: () async {
        _deviceList = await QuickUsb.getDeviceList();
        // log('deviceList $_deviceList');
        print("Device length was ${_deviceList.length}");
      },
    );
  }

  Widget _has_request() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          child: Text('hasPermission'),
          onPressed: () async {
            var hasPermission = await QuickUsb.hasPermission(_deviceList.last);
            for (var x = 0; x < _deviceList.length; x++) {
              print(
                  "Device id --> $x : Device status --> ${await QuickUsb.hasPermission(_deviceList[x])}");
            }
            log('hasPermission $hasPermission');
          },
        ),
        ElevatedButton(
          child: Text('requestPermission'),
          onPressed: () async {
            await QuickUsb.requestPermission(_deviceList.first);
            log('requestPermission');
          },
        ),
      ],
    );
  }

  Widget _open_close() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          child: Text('openDevice'),
          onPressed: () async {
            var openDevice = await QuickUsb.openDevice(_deviceList.last);

            for (var x = 0; x < _deviceList.length; x++) {
              print(
                  "Device id --> $x : Device status --> ${await QuickUsb.openDevice(_deviceList[x])}");
            }
            log('openDevice $openDevice');
          },
        ),
        ElevatedButton(
          child: Text('closeDevice'),
          onPressed: () async {
            await QuickUsb.closeDevice();
            log('closeDevice');
          },
        ),
      ],
    );
  }

  UsbConfiguration _configuration;

  Widget _get_set_configuration() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          child: Text('getConfiguration'),
          onPressed: () async {
            _configuration = await QuickUsb.getConfiguration(4);
            print("config for phone : $_configuration");
            log('getConfiguration $_configuration');
            for (var x = 0; x < _deviceList.length; x++) {
              print(
                  "Device id --> $x : Device status --> ${await QuickUsb.getConfiguration(x)}");
            }
          },
        ),
        ElevatedButton(
          child: Text('setConfiguration'),
          onPressed: () async {
            var setConfiguration =
                await QuickUsb.setConfiguration(_configuration);
            log('setConfiguration $setConfiguration');
          },
        ),
      ],
    );
  }

  Widget _claim_release_interface() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          child: Text('claimInterface'),
          onPressed: () async {
            var claimInterface =
                await QuickUsb.claimInterface(_configuration.interfaces[0]);
            log('claimInterface $claimInterface');
          },
        ),
        ElevatedButton(
          child: Text('releaseInterface'),
          onPressed: () async {
            var releaseInterface =
                await QuickUsb.releaseInterface(_configuration.interfaces[0]);
            log('releaseInterface $releaseInterface');
          },
        ),
      ],
    );
  }

  Widget _bulk_transfer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          child: Text('bulkTransferIn'),
          onPressed: () async {
            var endpoint = _configuration.interfaces[0].endpoints
                .firstWhere((e) => e.direction == UsbEndpoint.DIRECTION_IN);
            var bulkTransferIn = await QuickUsb.bulkTransferIn(endpoint, 1024);
            log('bulkTransferIn ${hex.encode(bulkTransferIn)}');
          },
        ),
        ElevatedButton(
          child: Text('bulkTransferOut'),
          onPressed: () async {
            var data = Uint8List.fromList(utf8.encode(''));
            var endpoint = _configuration.interfaces[0].endpoints
                .firstWhere((e) => e.direction == UsbEndpoint.DIRECTION_OUT);
            var bulkTransferOut =
                await QuickUsb.bulkTransferOut(endpoint, data);
            log('bulkTransferOut $bulkTransferOut');
          },
        ),
      ],
    );
  }

  Widget _getDevicesWithDescription() {
    return ElevatedButton(
      child: Text('getDevicesWithDescription'),
      onPressed: () async {
        var descriptions = await QuickUsb.getDevicesWithDescription();
        _deviceList = descriptions.map((e) => e.device).toList();

        log('descriptions $descriptions');
      },
    );
  }

  Widget _getDeviceDescription() {
    return ElevatedButton(
      child: Text('getDeviceDescription'),
      onPressed: () async {
        var description =
            await QuickUsb.getDeviceDescription(_deviceList.first);
        log('description ${description.toMap()}');
        for (var x = 0; x < _deviceList.length; x++) {
          print(
              "Device id --> $x : Device description --> ${await QuickUsb.getDeviceDescription(_deviceList[x])}");
        }
      },
    );
  }

  bool _autoDetachEnabled = false;
  Widget _setAutoDetachKernelDriver() {
    return ElevatedButton(
      child: Text('setAutoDetachKernelDriver'),
      onPressed: () async {
        await QuickUsb.setAutoDetachKernelDriver(!_autoDetachEnabled);
        _autoDetachEnabled = !_autoDetachEnabled;
        log('setAutoDetachKernelDriver: $_autoDetachEnabled');
      },
    );
  }
}
