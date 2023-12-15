import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AiAgent extends StatefulWidget {
  @override
  _AiAgentState createState() => _AiAgentState();
}

class _AiAgentState extends State<AiAgent> {
  Uint8List? uploadedImage;
  String result = '';

  Future<void> _startFilePicker() async {
    html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      // read file content as dataURL
      final files = uploadInput.files;
      if (files!.length == 1) {
        final file = files[0];
        html.FileReader reader = html.FileReader();

        reader.onLoadEnd.listen((e) {
          setState(() {
            uploadedImage = reader.result as Uint8List;
          });
        });

        reader.onError.listen((fileEvent) {
          setState(() {
            result = "Some Error occurred while reading the file";
          });
        });

        reader.readAsArrayBuffer(file);
      }
    });
  }

  Future<void> _predictResults() async {
    if (uploadedImage == null) {
      return;
    }

    try {
      var request =
          http.MultipartRequest('POST', Uri.parse('http://localhost:5000'));
      request.files.add(http.MultipartFile.fromBytes('file', uploadedImage!,
          filename: 'uploaded_image.jpg'));

      var response = await request.send();
      if (response.stream != null) {
        final String responseResult = await response.stream.bytesToString();
        setState(() {
          result = responseResult;
        });
      }

      // Parse the JSON result
      Map<String, dynamic> resultMap = parseResult(result);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Center(
                child: Text(
              'Prediction Result',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                  color: Color(0xFF0074d9)),
            )),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 20,
                ),
                // Display the selected image
                uploadedImage != null
                    ? Center(
                        child: Container(
                          height: 400,
                          width: 400,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.1),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset:
                                    Offset(0, 3), // changes position of shadow
                              ),
                            ],
                          ),
                          child: Center(
                            child: Image.memory(
                              uploadedImage!,
                              width: 400,
                              height: 400,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      )
                    : Container(width: 200, height: 200, color: Colors.white),
                SizedBox(height: 30),
                // Display the prediction result
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFF0074d9)),
                    borderRadius: BorderRadius.circular(15.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Row(
                        children: [
                          _buildResultRow(
                              "Test Result", resultMap["prediction"]),
                          SizedBox(width: 20),
                          // Display the confidence
                          _buildResultRow(
                              "Confidence", "${resultMap["confidence"]}%"),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error: $e');
    }
  }

  Map<String, dynamic> parseResult(String result) {
    try {
      Map<String, dynamic> resultMap = {};
      Map<String, dynamic> jsonResult =
          Map<String, dynamic>.from(json.decode(result));
      resultMap["prediction"] = jsonResult["prediction"];
      resultMap["confidence"] = jsonResult["confidence"]
          .toStringAsFixed(2); // Format confidence to 2 decimal places
      return resultMap;
    } catch (e) {
      print('Error parsing result: $e');
      return {};
    }
  }

  Widget _buildResultRow(String label, String value) {
    return Row(
      children: [
        // Display icon based on label
        label == "Test Result"
            ? Icon(Icons.assignment, color: Colors.blue)
            : Icon(Icons.bar_chart, color: Colors.green),
        SizedBox(width: 10),
        // Display label and value
        Row(
          children: [
            Text(
              "$label:",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Color(0xFF0074d9)),
            ),
            Text(
              " $value",
              style: TextStyle(fontSize: 24),
            ),
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Color(0xFF0074d9),
            expandedHeight: 200.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Endoscopy Analyzer'),
              background: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Image.asset(
                  'images/white.png',
                  width: 200,
                  height: 200,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  uploadedImage != null
                      ? Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset:
                                    Offset(0, 3), // changes position of shadow
                              ),
                            ],
                          ),
                          child: Image.memory(
                            uploadedImage!,
                            width: 300,
                            height: 300,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.1),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset:
                                    Offset(0, 3), // changes position of shadow
                              ),
                            ],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Image.asset(
                            "images/imageHere.png",
                            width: 300,
                            height: 300,
                          )),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () async {},
                        child: InkWell(
                          onTap: () async {
                            await _startFilePicker();
                          },
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.1),
                                  spreadRadius: 5,
                                  blurRadius: 7,
                                  offset: Offset(
                                      0, 3), // changes position of shadow
                                ),
                              ],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Image.asset(
                                  'images/upload.png',
                                  width: 300,
                                  height: 300,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {},
                        child: InkWell(
                          onTap: () async {
                            await _predictResults();
                          },
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.1),
                                  spreadRadius: 5,
                                  blurRadius: 7,
                                  offset: Offset(
                                      0, 3), // changes position of shadow
                                ),
                              ],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Image.asset(
                                  'images/predict.png',
                                  width: 350,
                                  height: 350,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
