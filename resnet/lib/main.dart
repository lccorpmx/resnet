import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as Io;

import 'package:path/path.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

import 'package:rflutter_alert/rflutter_alert.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LCC PRDICTIÓN',
      theme: ThemeData.dark(
        
      ),
      home: const MyHomePage(title: 'LCC PREDICTIÓN'),
    );
  }

}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;


  @override
  State<MyHomePage> createState() => _MyHomePageState();
}
class _MyHomePageState extends State<MyHomePage> {
  File? _image;

  final url = Uri.parse("https://resnet-service-lccorpmx.cloud.okteto.net");
  final headers = {"Content-Type": "application/json;charset=UTF-8"};

  Future getImage(ImageSource source) async {
    try{
      final image = await ImagePicker().pickImage(source: source);
      if(image == null ) return;

      //final imageTemporary = File(image.path);
      final imagePermanent = await saveFilePermanently(image.path);


      File file = File(image.path);
      List<int> fileInByte = file.readAsBytesSync();
      String fileInBase64 = base64Encode(fileInByte);
      uploadImage(fileInBase64);

      setState(() {
        this._image = imagePermanent;



      });
    }on PlatformException catch (e){
      print("Falló al obtener recursos de las imagenes: $e");
    }
  }

  Future<File> saveFilePermanently(String imagePath) async{
    final directory = await getApplicationDocumentsDirectory();
    final name = basename(imagePath);
    final image = File('${directory.path}/${name}');


    return File(imagePath).copy(image.path);
  }


  Future<void> uploadImage(base64) async {

    try {

      final prediction_instance = {
        "instances" : [
          {
            "b64": "$base64"
          }
        ]
      };

      final res = await http.post(url, headers: headers, body: jsonEncode(prediction_instance));
      print(jsonEncode(prediction_instance));



      if (res.statusCode == 200) {
        final json_prediction = jsonDecode(res.body);
        print(json_prediction);

        String clases_prediction = json_prediction['predictions'][0]['classes'].toString();
        log("Clase: $clases_prediction");


        final value = await rootBundle.loadString('Data/imagenet_class_index.json');
        var datos = json.decode(value);
        var class_result_prediction = datos[clases_prediction.toString()][1];
        var result_prediction = datos[clases_prediction.toString()];


        Alert(
          context: this.context,
          title: "ID: $clases_prediction",
          desc: "Creo que es: $class_result_prediction",
          buttons: [
            DialogButton(
              child: Text(
                "Salir",
                style: TextStyle(color: Colors.black, fontSize: 20),
              ),
              onPressed: () => Navigator.pop(this.context),
              width: 120,
            )
          ],
        ).show();

      }

    } catch (e) {
      print("error");
      print(e.toString());
    }
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("LCC PREDICTIÓN"),
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 40,),
            _image != null ? Image.file(_image!, width: 250, height: 250, fit: BoxFit.cover,) :
            Image.network('assets/logo.png'),
            SizedBox(height: 40,),
            CustomButton(
              title: "Toma una fotografia",
              icon: Icons.add_a_photo,
              onClick: () => getImage(ImageSource.camera),
            ),
          ],
        )

      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }


}

Widget CustomButton(
    {required String title,required IconData icon, required onClick}){
  return Container(
    width: 280,
    child: ElevatedButton(
      onPressed: onClick,
      style: ElevatedButton.styleFrom(
        primary: Colors.green,
      ),
      
      child: Row(
        children: [
          Icon(icon),
          SizedBox(width: 20,),
          Text(title)
        ],
      ),
    ),
  );


}

