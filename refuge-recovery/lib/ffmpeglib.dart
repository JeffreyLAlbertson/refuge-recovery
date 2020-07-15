library refuge_recovery.ffmpeg;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:path/path.dart';
import 'package:refugerecovery/globals.dart' as globals;

class Util {
  static FlutterFFmpeg mpeg = new FlutterFFmpeg();

  static void writeToAppFolder(ByteData bytes, String pathDestination) {
    ByteBuffer buf = bytes.buffer;
    File file = File(pathDestination);
    file.writeAsBytesSync(
        buf.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
  }

  static mergeReadingWithChimes(String meditationFolderName,
      String readingFolderName, String readingFileName, String chimeFileName) {
    String pathOriginChime = join(srcChimesPath, chimeFileName);
    String pathOriginMeditation =
        join(srcMeditationsPath, meditationFolderName);
    String pathOriginReading = join(pathOriginMeditation, readingFileName);

    String outputPath =
        getDstReadingPath(meditationFolderName, readingFolderName);

    String pathDestinationChime = join(outputPath, chimeFileName);
    String pathDestinationReading = join(outputPath, readingFileName);
    String pathDestinationChimedReading =
        join(outputPath, "chimed-$readingFileName");

    rootBundle
        .load(pathOriginChime)
        .then((bytes) {
          writeToAppFolder(bytes, pathDestinationChime);
        })
        .whenComplete(() => rootBundle.load(pathOriginReading).then((bytes) {
              writeToAppFolder(bytes, pathDestinationReading);
            }))
        .whenComplete(() {
          String listFilePath = join(outputPath, 'list.txt');
          File listFile = File(listFilePath);
          String listFileContents =
              "file '$pathDestinationChime'\nfile '$pathDestinationReading'";
          listFile.writeAsStringSync(listFileContents);

          mpeg.execute(
              '-y -f concat -safe 0 -i "$listFilePath" -c copy "$pathDestinationChimedReading" -loglevel quiet');

          File c = File(pathDestinationChime);
          File r = File(pathDestinationReading);
          File cr = File(pathDestinationChimedReading);

          while (c.statSync().size + r.statSync().size > cr.statSync().size) {
            sleep(Duration(milliseconds: 100));
          }
        });
  }

  static String get srcChimesPath {
    return 'assets/meditation_audio/_chimes';
  }

  static String get srcMeditationsPath {
    return 'assets/meditation_audio';
  }

  static String getSrcMeditationPath(String meditationFolderName) {
    return join(srcMeditationsPath, meditationFolderName);
  }

  static String get dstMeditationsPath {
    return join(globals.appDocsDirectory.path, 'Meditations');
  }

  static String getDstMeditationPath(String meditationFolderName) {
    return join(dstMeditationsPath, meditationFolderName);
  }

  static String getDstReadingPath(
      String meditationFolderName, String readingFolderName) {
    String meditationPath = getDstMeditationPath(meditationFolderName);
    return join(meditationPath, readingFolderName);
  }
}
