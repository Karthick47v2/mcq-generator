import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:fdottedline/fdottedline.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:quizzzy/libs/custom_widgets.dart';
import 'package:quizzzy/src/service/fs_database.dart';

class ImportFile extends StatefulWidget {
  const ImportFile({Key? key}) : super(key: key);

  @override
  State<ImportFile> createState() => _ImportFileState();
}

class _ImportFileState extends State<ImportFile> {
  final fileNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return QuizzzyTemplate(
        body: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 100),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color.fromARGB(94, 153, 0, 255),
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            child: const Center(
              child: Text(
                "Upload materials (PDF) to generate questions. Please make sure there are only texts in uploaded content to get improved results.",
                style: TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        Center(
            child: InkWell(
          child: FDottedLine(
            child: Container(
              margin: const EdgeInsets.all(5),
              child: Image.asset(
                'assets/images/upload.png',
                scale: 2,
                color: Colors.black45,
              ),
            ),
            color: Colors.grey.shade700,
            strokeWidth: 2.0,
            dottedLength: 8.0,
            space: 3.0,
            corner: FDottedLineCorner.all(6.0),
          ),
          onTap: () {
            showDialog(
                context: context,
                builder: (BuildContext cntxt) {
                  return PopupModal(size: 200.0, wids: [
                    QuizzzyTextInput(
                      text: "Questionnaire name",
                      controller: fileNameController,
                    ),
                    QuizzzyNavigatorBtn(
                      text: "Confirm",
                      onTap: () => {
                        getFile(
                            context,
                            (fileNameController.text == "")
                                ? "noname"
                                : fileNameController.text),
                        setState(() {
                          fileNameController.text = "";
                        }),
                        Navigator.of(cntxt).pop()
                      },
                    )
                  ]);
                });
          },
        ))
      ],
    ));
  }

  Future getQuestions(String cont, BuildContext context, String qName) async {
    //TODO: ADD SECURITY
    var url =
        Uri.parse("https://mcq-gen-nzbm4e7jxa-el.a.run.app/get-questions");
    Map body = {'context': cont, 'uid': fs.user.uid, 'name': qName};

    var res = await http.post(url,
        headers: {"Content-Type": "application/json"}, body: json.encode(body));

    print(res.statusCode);

    if (res.statusCode == 200) {
      await fs.users.doc(fs.user.uid).set({
        'isWaiting': true,
      }, SetOptions(merge: true)).catchError(
          (err) => snackBar(context, err.toString(), (Colors.red.shade800)));
    } else {
      snackBar(context, res.body.toString(), (Colors.red.shade800));
    }
    snackBar(
        context,
        "Generating question may take a while. It will be available under 'Question Bank' once process is finished.",
        Colors.green.shade700);
  }

  getFile(BuildContext context, String fileName) async {
    if (await fs.getGeneratorStatus() != "Generated") {
      snackBar(context, "Please wait for previous document to get processed.",
          (Colors.amber.shade400));
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    // check if name is already taken
    bool docExists = true;
    int i = 0;
    String tempName = fileName;
    while (docExists) {
      if ((await fs.getUserDoc(tempName))!.exists) {
        tempName = fileName + "(" + (++i).toString() + ")";
      } else {
        docExists = false;
        fileName = tempName;
      }
    }

    if (result != null) {
      PDFDoc doc = await PDFDoc.fromPath(result.files.single.path.toString());
      String docText = await doc.text;
      getQuestions(docText, context, fileName);
    } else {
      return;
    }
  }
}
