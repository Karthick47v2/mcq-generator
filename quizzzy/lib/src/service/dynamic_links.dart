// ignore_for_file: avoid_print

import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:quizzzy/src/home_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quizzzy/libs/custom_widgets.dart';

class DynamicLinks {
  final FirebaseDynamicLinks _dLink;

  DynamicLinks({required dLink}) : _dLink = dLink;

  Future initDynamicLink(BuildContext context) async {
    // fg/bg state
    _dLink.onLink.listen((dynamicLink) {
      _handleDynamicLink(dynamicLink.link, context);
    }).onError((e) {
      snackBar(context, e.toString(), (Colors.red.shade800));
    });

    // initilize dynamic link for terminated state

    final PendingDynamicLinkData? initialLink = await _dLink.getInitialLink();

    if (initialLink != null) {
      try {
        _handleDynamicLink(initialLink.link, context);
      } catch (e) {
        snackBar(context, "Link not found", (Colors.red.shade800));
      }
    } else {
      return null;
    }
  }

  Future generateDynamicLink(String teacherID, String quizID) async {
    String url = "https://quizzzy.page.link";
    final dynamicLinkParams = DynamicLinkParameters(
        link: Uri.parse("$url/$teacherID/$quizID"),
        uriPrefix: url,
        androidParameters:
            const AndroidParameters(packageName: "com.example.quizzzy"),
        iosParameters: const IOSParameters(bundleId: "com.example.quizzzy"));

    // var dynamicUrl = await _dLink.buildLink(dynamicLinkParams);
    var uri = await _dLink.buildShortLink(dynamicLinkParams);
    Share.share(uri.shortUrl.toString());
    // _handleDynamicLink(dynamicUrl);
    // print("${dynamicUrl}");
    // dynamicUrl.
    // Share.share(desc, subject:quizID)
  }

  _handleDynamicLink(Uri url, BuildContext context) {
    List<String> splitLink = url.path.split('/');
    print(splitLink);
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const HomePage()));
  }
}

late DynamicLinks dlink;
