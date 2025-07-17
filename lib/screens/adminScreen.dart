import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:queueing/globals.dart';
import 'package:queueing/models/services/service.dart';
import 'package:http/http.dart' as http;
import 'package:queueing/models/services/serviceGroup.dart';
import 'package:video_player/video_player.dart';
import '../models/controls.dart';
import '../models/media.dart';
import '../models/priority.dart';
import '../models/station.dart';
import '../models/ticket.dart';
import '../models/user.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import '../platformHandler/web_stub.dart'
if (dart.library.html) '../platformHandler/web_real.dart' as web;


class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, required this.user});

  final User user;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int screenIndex = 0;
  List<String> lastAssigned = [];
  String assignedGroups = "_MAIN_";


  List<DateTime> dates = [];
  List<String> users = [];
  List<String> serviceTypes = [];
  List<String> priorities = [];
  List<String> statuses = [];
  List<String> genders = [];

  String? displayDate;
  String? displayUsers;
  String? displayServiceTypes;
  String? displayPriorities;
  String? displayStatus;
  String? displayGender;

  // Service

  TextEditingController serviceType = TextEditingController();
  TextEditingController serviceCode = TextEditingController();

  // Users

  TextEditingController user = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController userServiceType = TextEditingController();
  TextEditingController userType = TextEditingController();

  // Stations

  TextEditingController stationNumber = TextEditingController();
  TextEditingController stationName = TextEditingController();
  TextEditingController displayIndex = TextEditingController();

  @override
  void dispose() {
    stationName.dispose();
    stationNumber.dispose();
    user.dispose();
    password.dispose();
    userServiceType.dispose();
    userType.dispose();
    serviceType.dispose();
    serviceCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MediaQuery.of(context).size.width < 500 || MediaQuery.of(context).size.height < 500 ? Container(
        child: Center(child: Text("Expand Screen Size to Display", style: TextStyle(fontSize: 30))),
      ) : Stack(
        children: [
          imageBackground(context),
          logoBackground(context, 350),
          Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  spacing: 10,
                  children: [
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text(titleHandler(),
                            style: TextStyle(
                                fontSize: 30, fontWeight: FontWeight.w700))),
                    Spacer(),
                    IconButton(
                        color: colorHandler(screenIndex, 0),
                        tooltip: 'Services',
                        onPressed: () {
                          screenIndex = 0;
                          setState(() {});
                        },
                        icon: Icon(Icons.sticky_note_2)),
                    IconButton(
                        color: colorHandler(screenIndex, 1),
                        tooltip: 'Users',
                        onPressed: () {
                          screenIndex = 1;
                          setState(() {});
                        },
                        icon: Icon(Icons.supervised_user_circle_rounded)),
                    IconButton(
                        color: colorHandler(screenIndex, 2),
                        tooltip: 'Stations',
                        onPressed: () {
                          screenIndex = 2;
                          setState(() {});
                        },
                        icon: Icon(Icons.desktop_windows_rounded)),
                    IconButton(
                        color: colorHandler(screenIndex, 3),
                        tooltip: 'Archive',
                        onPressed: () {
                          screenIndex = 3;
                          setState(() {});
                        },
                        icon: Icon(Icons.history_edu)),
                    IconButton(
                        tooltip: "Log-out",
                        onPressed: () {
                          showDialog(context: context, builder: (_) => AlertDialog(
                            title: Text("Log-out"),
                            actions: [TextButton(onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            }, child: Text("Log-out", style: TextStyle(color: Colors.red)))],
                            content: Container(
                              height: 30,
                              child: Text("You will log-out as Administrator."),
                            )
                          ));
                        },
                        icon: Icon(Icons.logout))
                  ],
                ),
                Divider(),
                SizedBox(height: 10),
                screenHandler(screenIndex)
              ],
            ),
          ),
        )],
      ),
    );
  }

  //region

  titleHandler() {
    if (screenIndex == 0) {
      return "Services";
    }
    if (screenIndex == 1) {
      return "Users";
    }
    if (screenIndex == 2) {
      return "Stations";
    }

    if (screenIndex == 3) {
      return "Archive";
    }
  }

  colorHandler(int i, int type) {
    if (i == type) {
      return Colors.blueGrey;
    } else {
      return Colors.grey;
    }
  }

  screenHandler(int i) {
    if (i == 0) {
      return servicesView();
    }

    if (i == 1) {
      return usersView();
    }

    if (i == 2) {
      return stationsView();
    }

    if (i == 3) {
      return archiveView();
    }
  }

  servicesView() {
    return Container(
      child: Column(
        children: [
          Align(
              alignment: Alignment.centerLeft,
              child: Row(
                spacing: 10,
                children: [
                  ElevatedButton(
                      onPressed: () {
                        addService(0);
                      },
                      child: Text("+ Service")),

                  ElevatedButton(
                      onPressed: () {
                        addGroupDialog();
                      },
                      child: Text("+ Group")),
                  ElevatedButton(
                      onPressed: () {
                        TextEditingController name = TextEditingController();

                        showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                                content: Container(
                              height: 400,
                              width: 400,
                              child: StatefulBuilder(
                                builder: (BuildContext context, void Function(void Function()) setStateDialog) {
                                  return Column(
                                    children: [
                                      Container(
                                        height: 80,
                                        width: 380,
                                        child: Row(children: [
                                          Container(
                                            width: 250,
                                            child: TextField(
                                              controller: name,
                                              decoration: InputDecoration(
                                                  labelText:
                                                  'Priority Name',
                                                  labelStyle: TextStyle(
                                                      color: Colors.grey)),
                                            ),
                                          ),
                                          ElevatedButton(
                                              onPressed: () async {
                                                await addPriority(
                                                    name.text);
                                                setStateDialog(() {});
                                              },
                                              child: Text("Add Priority"))
                                        ]),
                                      ),
                                      SizedBox(height: 10),
                                      FutureBuilder(
                                          future: getPriority(),
                                          builder:
                                              (context, AsyncSnapshot<List<dynamic>> snapshot) {
                                            return Container(
                                              height: 300,
                                              child: snapshot.connectionState == ConnectionState.done ? snapshot.data!.isNotEmpty ? ListView.builder(
                                                itemCount: snapshot.data!.length,
                                                  itemBuilder: (context, i) {
                                                    final priority =
                                                    Priority.fromJson(
                                                        snapshot.data![i]);

                                                    return ListTile(
                                                      title: Text(
                                                          priority.priorityName!),
                                                      trailing: IconButton(
                                                          onPressed: () {
                                                            deletePriority(i);
                                                          },
                                                          icon:
                                                          Icon(Icons.delete)),
                                                    );
                                                  }) : Center(
                                                child: Text("No Priorities Added", style: TextStyle(color: Colors.grey)),
                                              ) : Center(
                                                child: Container(
                                                  height: 100,
                                                  width: 100,
                                                  child: CircularProgressIndicator(),
                                                )
                                              ),
                                            );
                                          })
                                    ],
                                  );
                                },
                              ),
                            )));
                      },
                      child: Text("+ Priority Type")),
                  Spacer(),
                  IconButton(onPressed: () {
                    showDialog(context: context, builder: (_) => AlertDialog(
                      title: Text("Settings"),
                      content: Container(
                        height: 400,
                        width: 400,
                        child: StatefulBuilder(
                          builder: (BuildContext context, void Function(void Function()) setStateSetting) {
                            return FutureBuilder(
                              future: getSettings(context),
                              builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
                                return snapshot.connectionState == ConnectionState.done ? snapshot.data!.isNotEmpty ? ListView.builder(
                                    itemCount: snapshot.data!.length,
                                    itemBuilder: (context, i) {
                                  final control = Control.fromJson(snapshot.data![i]);

                                  return ListTile(
                                    title: Row(
                                      spacing: 5,
                                      children: [
                                        Text(control.controlName!),
                                      ],
                                    ),
                                    subtitle: Row(
                                      children: [
                                        control.controlName! == "Video View (TV)" ? TextButton(onPressed: () async {
                                          showDialog(context: context, builder: (_) => StatefulBuilder(
                                            builder: (BuildContext context, void Function(void Function()) setStateList) {
                                              return AlertDialog(
                                                title: Text("Video List"),
                                                content: FutureBuilder(
                                                  future: getMedia(context),
                                                  builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
                                                    return snapshot.connectionState == ConnectionState.done ?
                                                    Container(
                                                      height: 400,
                                                      width: 400,
                                                      child: snapshot.data!.length == 0 ? Center(child: Text("No Videos Added", style: TextStyle(color: Colors.grey))) : ListView.builder(
                                                          itemCount: snapshot.data!.length,
                                                          itemBuilder: (context, i) {
                                                            final media = Media.fromJson(snapshot.data![i]);
                                                            return ListTile(
                                                              title: Text(media.name!),
                                                              onTap: () async {

                                                                final link = Uri.parse("http://$site/queueing_api/videos/${media.link}");
                                                                final videoController = VideoPlayerController.networkUrl(link)..initialize().then((_) {
                                                                  setStateSetting(() {}); // refresh UI when video is ready
                                                                });

                                                                videoController.setLooping(true);
                                                                int player = 0;

                                                                dispose(){
                                                                  videoController.dispose();
                                                                }

                                                                showDialog(context: context, builder: (_) => AlertDialog(
                                                                  content: StatefulBuilder(
                                                                    builder: (BuildContext context, void Function(void Function()) setStatePlayer) {
                                                                      return Container(
                                                                        height: 400,
                                                                        width: 400,
                                                                        child: Column(
                                                                          children: [
                                                                            Container(
                                                                                height: 350,
                                                                                width: 350,
                                                                                child: VideoPlayer(videoController)
                                                                            ),
                                                                            IconButton(onPressed: () {if (player == 0) {
                                                                              player = 1;
                                                                              videoController.play();
                                                                              setStateSetting((){});
                                                                            } else {
                                                                              player = 0;
                                                                              videoController.pause();
                                                                              setStateSetting((){});
                                                                            }}, icon: player == 0 ? Icon(Icons.play_arrow) : Icon(Icons.pause))
                                                                          ],
                                                                        ),
                                                                      );
                                                                    },
                                                                  ),
                                                                ));
                                                              },
                                                              trailing: IconButton(onPressed: () async {
                                                                final uri = Uri.parse(
                                                                    "http://$site/queueing_api/api_videoDelete.php");

                                                                final response = await http.post(uri, body: {
                                                                  'filename': media.link,
                                                                });

                                                                if (response.statusCode == 200) {
                                                                  print("Response: ${response.body}");

                                                                  final uri = Uri.parse('http://$site/queueing_api/api_media.php');
                                                                  final body = jsonEncode({'id': media.id});
                                                                  final result = await http.delete(uri, body: body);
                                                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Video removed")));
                                                                  setStateList((){});


                                                                } else {
                                                                  print("Error: ${response.statusCode}");
                                                                }

                                                              }, icon: Icon(Icons.delete)),
                                                            );
                                                          }),
                                                    ) : Container(
                                                      height: 50,
                                                      width: 50,
                                                      child: CircularProgressIndicator(),
                                                    );
                                                  },
                                                ),
                                                actions: [
                                                  TextButton(onPressed: () async {
                                                    try {
                                                      final result = await FilePicker.platform.pickFiles(
                                                        type: FileType.video,
                                                        allowMultiple: false,
                                                        withData: true,
                                                      );

                                                      if (result != null && result.files.isNotEmpty) {
                                                        final file = result.files.first;
                                                        final uri = Uri.parse(
                                                            "http://$site/queueing_api/api_video.php");

                                                        final request = http.MultipartRequest(
                                                            "POST", uri);
                                                        request.files.add(
                                                            http.MultipartFile.fromBytes(
                                                              'file',
                                                              file.bytes!,
                                                              filename: file.name,
                                                            ));



                                                        List<dynamic> media = await getMedia(context);
                                                        List<dynamic> similar = media.where((e) => e['name'] == file.name).toList();

                                                        if (similar.isEmpty) {
                                                          if (file.size < 524288000) {
                                                            final response = await request.send();
                                                            addMedia(file.name, file.name);
                                                            print(response.headers);
                                                            setStateList((){});
                                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${file.name} added to videos")));
                                                          } else {
                                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("File must not be above 500MB")));
                                                          }
                                                        } else {
                                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${file.name} already exists")));
                                                        }

                                                      }
                                                    } catch(e) {
                                                      print(e);
                                                    }

                                                  }, child: Text("Add Video"))
                                                ],
                                              );
                                            },
                                          ));
                                        }, child: Text("Set Videos")) : SizedBox(),
                                        control.controlName! == "Sliding Text" ? TextButton(
                                            onPressed: () {
                                              TextEditingController sliding = TextEditingController();


                                              final space = "                    ";

                                              String string = control.other!;
                                              string.trimLeft();
                                              string = string.split(space).join('\n');
                                              string = string.replaceFirst(RegExp(r'[\n\r]+'), '');
                                              sliding.text = string;

                                              showDialog(context: context, builder: (_) => AlertDialog(
                                                title: Text("Set Text"),
                                                content: Container(
                                                  height: 310,
                                                  width: 350,
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: Column(
                                                      children: [
                                                        TextField(
                                                          controller: sliding,
                                                          decoration: InputDecoration(
                                                            border: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(15)
                                                            ),
                                                            hintText: 'Input Sliding Text Content Here',
                                                          ),
                                                          maxLines: 10,
                                                        ),
                                                        SizedBox(height: 5),
                                                        Text("'Enter' will separate messages.", style: TextStyle(color: Colors.grey), textAlign: TextAlign.center)
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(onPressed: () {

                                                    List<String> lines = sliding.text.split(RegExp(r'\r?\n'));
                                                    lines = lines.where((line) => line.trim().isNotEmpty).toList();
                                                    String finalString = space + lines.join(space);

                                                    control.update({
                                                      'other' : finalString
                                                    });
                                                    Navigator.pop(context);
                                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sliding Text Updated")));
                                                  }, child: Text("Update"))
                                                ],
                                              ));
                                            }, child: Text("Set Text")) : SizedBox(),
                                        control.controlName! == "Kiosk Password" ? TextButton(onPressed: () {
                                          TextEditingController pass = TextEditingController();

                                          showDialog(context: context, builder: (_) => AlertDialog(
                                            title: Text("Kiosk Password"),
                                            content: Container(
                                              height: 100,
                                              child: Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Column(
                                                  children: [
                                                    TextField(
                                                      decoration: InputDecoration(
                                                          labelText: 'Set Password'
                                                      ),
                                                      controller: pass,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(onPressed: () {
                                                control.update({
                                                  'other' : pass.text
                                                });
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Kiosk Password Updated")));
                                              }, child: Text("Update"))
                                            ],
                                          ));
                                        }, child: Text("Set Password")) : SizedBox(),
                                        control.controlName! == "BG Video (TV)" ? TextButton(onPressed: () async {
                                          showDialog(context: context, builder: (_) => StatefulBuilder(
                                            builder: (BuildContext context, void Function(void Function()) setStateList) {
                                              return AlertDialog(
                                                title: Text("BG Video List"),
                                                content: FutureBuilder(
                                                  future: getMediabg(context),
                                                  builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
                                                    return snapshot.connectionState == ConnectionState.done ?
                                                    Container(
                                                      height: 400,
                                                      width: 400,
                                                      child: snapshot.data!.length == 0 ? Center(child: Text("No BG Videos Added", style: TextStyle(color: Colors.grey))) : ListView.builder(
                                                          itemCount: snapshot.data!.length,
                                                          itemBuilder: (context, i) {
                                                            final media = Media.fromJson(snapshot.data![i]);
                                                            return ListTile(
                                                              title: Text(media.name!),
                                                              onTap: () async {
                                                                final link = Uri.parse("http://$site/queueing_api/bgvideos/${media.link}");
                                                                final videoController = VideoPlayerController.networkUrl(link)..initialize().then((_) {
                                                                  setStateSetting(() {}); // refresh UI when video is ready
                                                                });

                                                                videoController.setLooping(true);
                                                                int player = 0;

                                                                dispose(){
                                                                  videoController.dispose();
                                                                }

                                                                showDialog(context: context, builder: (_) => AlertDialog(
                                                                  content: StatefulBuilder(
                                                                    builder: (BuildContext context, void Function(void Function()) setStatePlayer) {
                                                                      return Container(
                                                                        height: 400,
                                                                        width: 400,
                                                                        child: Column(
                                                                          children: [
                                                                            Container(
                                                                                height: 350,
                                                                                width: 350,
                                                                                child: VideoPlayer(videoController)
                                                                            ),
                                                                            IconButton(onPressed: () {if (player == 0) {
                                                                              player = 1;
                                                                              videoController.play();
                                                                              setStateSetting((){});
                                                                            } else {
                                                                              player = 0;
                                                                              videoController.pause();
                                                                              setStateSetting((){});
                                                                            }}, icon: player == 0 ? Icon(Icons.play_arrow) : Icon(Icons.pause))
                                                                          ],
                                                                        ),
                                                                      );
                                                                    },
                                                                  ),
                                                                ));
                                                              },
                                                              trailing: IconButton(onPressed: () async {
                                                                final uri = Uri.parse(
                                                                    "http://$site/queueing_api/api_videoDeletebg.php");

                                                                final response = await http.post(uri, body: {
                                                                  'filename': media.link,
                                                                });

                                                                if (response.statusCode == 200) {
                                                                  print("Response: ${response.body}");

                                                                  final uri = Uri.parse('http://$site/queueing_api/api_mediabg.php');
                                                                  final body = jsonEncode({'id': media.id});
                                                                  final result = await http.delete(uri, body: body);
                                                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Video removed")));
                                                                  setStateList((){});


                                                                } else {
                                                                  print("Error: ${response.statusCode}");
                                                                }

                                                              }, icon: Icon(Icons.delete)),
                                                            );
                                                          }),
                                                    ) : Container(
                                                      height: 50,
                                                      width: 50,
                                                      child: CircularProgressIndicator(),
                                                    );
                                                  },
                                                ),
                                                actions: [
                                                  TextButton(onPressed: () async {
                                                    try {
                                                      final result = await FilePicker.platform.pickFiles(
                                                        type: FileType.video,
                                                        allowMultiple: false,
                                                        withData: true,
                                                      );

                                                      if (result != null && result.files.isNotEmpty) {
                                                        final file = result.files.first;
                                                        final uri = Uri.parse(
                                                            "http://$site/queueing_api/api_videobg.php");

                                                        final request = http.MultipartRequest(
                                                            "POST", uri);
                                                        request.files.add(
                                                            http.MultipartFile.fromBytes(
                                                              'file',
                                                              file.bytes!,
                                                              filename: file.name,
                                                            ));

                                                        List<dynamic> mediabg = await getMediabg(context);
                                                        List<dynamic> similar = mediabg.where((e) => e['name'] == file.name).toList();

                                                        if (similar.isEmpty) {
                                                          if (file.size < 524288000) {
                                                            final response = await request.send();
                                                            addMediabg(file.name, file.name);
                                                            print(response.headers);
                                                            setStateList((){});
                                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${file.name} added to Background Videos")));
                                                          } else {
                                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("File must not be above 500MB")));
                                                          }
                                                        } else {
                                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${file.name} already exists")));
                                                        }
                                                      }
                                                    } catch(e) {
                                                      print(e);
                                                    }

                                                  }, child: Text("Add Video"))
                                                ],
                                              );
                                            },
                                          ));
                                        }, child: Text("Set BG Videos")) : SizedBox(),
                                        control.controlName! == "BG Video (Kiosk)" ? TextButton(onPressed: () async {
                                          showDialog(context: context, builder: (_) => StatefulBuilder(
                                            builder: (BuildContext context, void Function(void Function()) setStateList) {
                                              return AlertDialog(
                                                title: Text("BG Video List"),
                                                content: FutureBuilder(
                                                  future: getMediabg(context),
                                                  builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
                                                    return snapshot.connectionState == ConnectionState.done ?
                                                    Container(
                                                      height: 400,
                                                      width: 400,
                                                      child: snapshot.data!.length == 0 ? Center(child: Text("No BG Videos Added", style: TextStyle(color: Colors.grey))) : ListView.builder(
                                                          itemCount: snapshot.data!.length,
                                                          itemBuilder: (context, i) {
                                                            final media = Media.fromJson(snapshot.data![i]);
                                                            return ListTile(
                                                              title: Text(media.name!),
                                                              onTap: () async {
                                                                final link = Uri.parse("http://$site/queueing_api/bgvideos/${media.link}");
                                                                final videoController = VideoPlayerController.networkUrl(link)..initialize().then((_) {
                                                                  setStateSetting(() {}); // refresh UI when video is ready
                                                                });

                                                                videoController.setLooping(true);
                                                                int player = 0;

                                                                dispose(){
                                                                  videoController.dispose();
                                                                }

                                                                showDialog(context: context, builder: (_) => AlertDialog(
                                                                  content: StatefulBuilder(
                                                                    builder: (BuildContext context, void Function(void Function()) setStatePlayer) {
                                                                      return Container(
                                                                        height: 400,
                                                                        width: 400,
                                                                        child: Column(
                                                                          children: [
                                                                            Container(
                                                                                height: 350,
                                                                                width: 350,
                                                                                child: VideoPlayer(videoController)
                                                                            ),
                                                                            IconButton(onPressed: () {if (player == 0) {
                                                                              player = 1;
                                                                              videoController.play();
                                                                              setStateSetting((){});
                                                                            } else {
                                                                              player = 0;
                                                                              videoController.pause();
                                                                              setStateSetting((){});
                                                                            }}, icon: player == 0 ? Icon(Icons.play_arrow) : Icon(Icons.pause))
                                                                          ],
                                                                        ),
                                                                      );
                                                                    },
                                                                  ),
                                                                ));
                                                              },
                                                              trailing: IconButton(onPressed: () async {
                                                                final uri = Uri.parse(
                                                                    "http://$site/queueing_api/api_videoDeletebg.php");

                                                                final response = await http.post(uri, body: {
                                                                  'filename': media.link,
                                                                });

                                                                if (response.statusCode == 200) {
                                                                  print("Response: ${response.body}");

                                                                  final uri = Uri.parse('http://$site/queueing_api/api_mediabg.php');
                                                                  final body = jsonEncode({'id': media.id});
                                                                  final result = await http.delete(uri, body: body);
                                                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Video removed")));
                                                                  setStateList((){});


                                                                } else {
                                                                  print("Error: ${response.statusCode}");
                                                                }

                                                              }, icon: Icon(Icons.delete)),
                                                            );
                                                          }),
                                                    ) : Container(
                                                      height: 50,
                                                      width: 50,
                                                      child: CircularProgressIndicator(),
                                                    );
                                                  },
                                                ),
                                                actions: [
                                                  TextButton(onPressed: () async {
                                                    try {
                                                      final result = await FilePicker.platform.pickFiles(
                                                        type: FileType.video,
                                                        allowMultiple: false,
                                                        withData: true,
                                                      );

                                                      if (result != null && result.files.isNotEmpty) {
                                                        final file = result.files.first;
                                                        final uri = Uri.parse(
                                                            "http://$site/queueing_api/api_videobg.php");

                                                        final request = http.MultipartRequest(
                                                            "POST", uri);
                                                        request.files.add(
                                                            http.MultipartFile.fromBytes(
                                                              'file',
                                                              file.bytes!,
                                                              filename: file.name,
                                                            ));

                                                        List<dynamic> mediabg = await getMediabg(context);
                                                        List<dynamic> similar = mediabg.where((e) => e['name'] == file.name).toList();

                                                        if (similar.isEmpty) {
                                                          if (file.size < 524288000) {
                                                            final response = await request.send();
                                                            addMediabg(file.name, file.name);
                                                            print(response.headers);
                                                            setStateList((){});
                                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${file.name} added to Background Videos")));
                                                          } else {
                                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("File must not be above 500MB")));
                                                          }
                                                        } else {
                                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${file.name} already exists")));
                                                        }
                                                      }
                                                    } catch(e) {
                                                      print(e);
                                                    }

                                                  }, child: Text("Add Video"))
                                                ],
                                              );
                                            },
                                          ));
                                        }, child: Text("Set BG Videos")) : SizedBox(),
                                        control.controlName! == "RGB Screen (Kiosk)" ? TextButton(
                                            onPressed: () {

                                              bool alwaysOn = false;
                                              TextEditingController visibleTime = TextEditingController();
                                              TextEditingController invisibleTime = TextEditingController();
                                              double opacity = 0;


                                              if (control.other != null) {
                                                visibleTime.text = control.other.toString().split(':')[0];
                                                invisibleTime.text = control.other.toString().split(':')[1];
                                                opacity = double.parse(control.other.toString().split(':')[2]);
                                              }

                                              showDialog(context: context, builder: (_) => AlertDialog(
                                                title: Text("RGB (Kiosk)"),
                                                content: Container(
                                                    height: 250,
                                                    width: 150,
                                                    child: StatefulBuilder(
                                                      builder: (context, setStateDialog) {
                                                        return Column(
                                                          children: [
                                                            CheckboxListTile(
                                                                title: Text("Always On"),
                                                                value: alwaysOn, onChanged: (value) {
                                                              alwaysOn = !alwaysOn;
                                                              setStateDialog((){});
                                                            }),
                                                            alwaysOn == false ?
                                                            Column(
                                                              children: [
                                                                TextField(
                                                                  inputFormatters: [
                                                                    FilteringTextInputFormatter.digitsOnly
                                                                  ],
                                                                  controller: visibleTime,
                                                                  decoration: InputDecoration(
                                                                      labelText: 'Display Length (In Seconds)'
                                                                  ),
                                                                ),
                                                                TextField(
                                                                  inputFormatters: [
                                                                    FilteringTextInputFormatter.digitsOnly
                                                                  ],
                                                                  controller: invisibleTime,
                                                                  decoration: InputDecoration(
                                                                      labelText: 'Pause Interval (In Seconds)'
                                                                  ),
                                                                ),
                                                                SizedBox(height: 10),
                                                                Center(child: Text("Opacity: $opacity", style: TextStyle(fontWeight: FontWeight.w700))),
                                                                Slider(
                                                                  value: opacity,
                                                                  min: 0,
                                                                  max: 1,
                                                                  divisions: 10, // step of 0.1
                                                                  label: opacity.toStringAsFixed(1),
                                                                  onChanged: (v) => setStateDialog(() => opacity = v),
                                                                ),
                                                              ],
                                                            ) : Container(
                                                              height: 200,
                                                              child: Center(
                                                                child: Text("RGB Screen will always be on.", style: TextStyle(color: Colors.grey)),
                                                              ),
                                                            )
                                                          ],
                                                        );
                                                      },
                                                    )
                                                ),
                                                actions: [
                                                  TextButton(onPressed: () async {
                                                    final visibleValue = removeExtraZeros(visibleTime.text.trim());
                                                    final realVisible = visibleValue == "0" || visibleValue == "" ? "10" : visibleTime.text.trim();
                                                    final realInvisible = invisibleTime.text.trim() == "" ? "0" : invisibleTime.text.trim();
                                                    final realAlways = alwaysOn == true ? "1" : "0";

                                                    await control.update({
                                                      'other': '$realVisible:$realInvisible:$opacity:$realAlways'
                                                    });
                                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${control.controlName!} setting saved.")));
                                                    Navigator.pop(context);
                                                  }, child: Text("Save"))
                                                ],
                                              ));
                                            }, child: Text("Customize")) : SizedBox(),
                                        control.controlName! == "RGB Screen (TV)" ? TextButton(onPressed: () {
                                          bool alwaysOn = false;
                                          TextEditingController visibleTime = TextEditingController();
                                          TextEditingController invisibleTime = TextEditingController();
                                          double opacity = 0;

                                          if (control.other != null) {
                                            visibleTime.text = control.other.toString().split(':')[0];
                                            invisibleTime.text = control.other.toString().split(':')[1];
                                            opacity = double.parse(control.other.toString().split(':')[2]);
                                          }

                                          showDialog(context: context, builder: (_) => AlertDialog(
                                            title: Text("RGB (TV)"),
                                            content: Container(
                                                height: 250,
                                                width: 150,
                                                child: StatefulBuilder(
                                                  builder: (context, setStateDialog) {
                                                    return Column(
                                                      children: [
                                                        CheckboxListTile(
                                                            title: Text("Always On"),
                                                            value: alwaysOn, onChanged: (value) {
                                                          alwaysOn = !alwaysOn;
                                                          setStateDialog((){});
                                                        }),
                                                        alwaysOn == false ?
                                                        Column(
                                                          children: [
                                                            TextField(
                                                              inputFormatters: [
                                                                FilteringTextInputFormatter.digitsOnly
                                                              ],
                                                              controller: visibleTime,
                                                              decoration: InputDecoration(
                                                                  labelText: 'Display Length (In Seconds)'
                                                              ),
                                                            ),
                                                            TextField(
                                                              inputFormatters: [
                                                                FilteringTextInputFormatter.digitsOnly
                                                              ],
                                                              controller: invisibleTime,
                                                              decoration: InputDecoration(
                                                                  labelText: 'Pause Interval (In Seconds)'
                                                              ),
                                                            ),
                                                            SizedBox(height: 10),
                                                            Center(child: Text("Opacity: $opacity", style: TextStyle(fontWeight: FontWeight.w700))),
                                                            Slider(
                                                              value: opacity,
                                                              min: 0,
                                                              max: 1,
                                                              divisions: 10, // step of 0.1
                                                              label: opacity.toStringAsFixed(1),
                                                              onChanged: (v) => setStateDialog(() => opacity = v),
                                                            ),
                                                          ],
                                                        ) : Container(
                                                          height: 200,
                                                          child: Center(
                                                            child: Text("RGB Screen will always be on.", style: TextStyle(color: Colors.grey)),
                                                          ),
                                                        )
                                                      ],
                                                    );
                                                  },
                                                )
                                            ),
                                            actions: [
                                              TextButton(onPressed: () async {
                                                final visibleValue = removeExtraZeros(visibleTime.text.trim());
                                                final realVisible = visibleValue == "0" || visibleValue == "" ? "10" : visibleTime.text.trim();
                                                final realInvisible = invisibleTime.text.trim() == "" ? "0" : invisibleTime.text.trim();
                                                final realAlways = alwaysOn == true ? "1" : "0";

                                                await control.update({
                                                  'other': '$realVisible:$realInvisible:$opacity:$realAlways'
                                                });
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${control.controlName!} setting saved.")));
                                                Navigator.pop(context);
                                              }, child: Text("Save"))
                                            ],
                                          ));
                                        }, child: Text("Customize")) : SizedBox(),
                                        control.controlName! == "Staff Inactive Beep" ? TextButton(onPressed: () {

                                          TextEditingController time = TextEditingController();
                                          time.text = control.other ?? "";

                                          showDialog(context: context, builder: (_) => AlertDialog(
                                            title: Text("Update Timer"),
                                            content: Container(
                                              height: 150,
                                              width: 150,
                                              child: Column(
                                                children: [
                                                  TextField(
                                                    decoration: InputDecoration(
                                                        labelText: 'Inactive Time (Seconds)'
                                                    ),
                                                    controller: time,
                                                    inputFormatters: [
                                                      FilteringTextInputFormatter.digitsOnly
                                                    ],
                                                  )
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                  onPressed: () async {
                                                    final timeValue = removeExtraZeros(time.text.trim());

                                                    if (timeValue != "0" || timeValue != "") {
                                                      await control.update({
                                                        'other': time.text.trim()
                                                      });
                                                      Navigator.pop(context);
                                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Inactive Timer updated.")));
                                                    } else {
                                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Value cannot be zero")));
                                                    }

                                                  }, child: Text("Update"))
                                            ],
                                          ));
                                        }, child: Text("Set Time")) : SizedBox()
                                      ],
                                    ),
                                    trailing: Switch(value: control.value! == 1, onChanged: (value) {
                                      control.update({
                                        'id': control.id!,
                                        'value': control.value! == 1 ? 0 : 1
                                      });
                                      setStateSetting((){});
                                    }),
                                  );
                                }) : Container(
                                  height: 300,
                                  child: Center(
                                    child: Text("No settings"),
                                  ),
                                ) : Container();
                              },
                            );
                          },
                        ),
                      ),
                    ));
                  }, icon: Icon(Icons.settings))
                ],
              )),
          StatefulBuilder(
            builder: (BuildContext context, void Function(void Function()) setStateList) {
              return FutureBuilder(
                future: getServiceGroups(assignedGroups),
                builder: (BuildContext context,
                    AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                  return Column(
                    children: [
                      SizedBox(height: 5),
                      lastAssigned.isNotEmpty ? Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          padding: EdgeInsets.all(5),
                          height: 40,
                          width: 120,
                          child: Row(
                            children: [
                              TextButton(onPressed: () {
                                assignedGroups = lastAssigned.last;                            lastAssigned.removeLast();
                                setStateList((){});
                              }, child: Row(
                                children: [
                                  Icon(Icons.chevron_left),
                                  SizedBox(width: 5),
                                  Text("Return")
                                ],
                              ))
                            ],
                          ),
                        ),
                      ) : Container(),
                      snapshot.connectionState == ConnectionState.done
                          ? snapshot.data!.isNotEmpty
                          ? Container(
                        padding: EdgeInsets.all(10),
                        height: MediaQuery.of(context).size.height - 200,
                        child: ListView.builder(
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, i) {

                              return snapshot.data![i]['serviceType'] != null ? Builder(
                                  builder: (context) {
                                    final service = Service.fromJson(snapshot.data![i]);
                                    return ListTile(
                                      title: Text("${service.serviceType} (${service.serviceCode})"),
                                      subtitle: Text("Service"),
                                      onTap: () {
                                        addService(1, service);
                                        serviceType.text =  service.serviceType!;
                                        serviceCode.text =  service.serviceCode!;
                                      },
                                      trailing: IconButton(
                                          onPressed: () {
                                            showDialog(context: context, builder: (_) => AlertDialog(
                                              title: Text("Confirm Delete?"),
                                              content: Container(
                                                width: 100,
                                                height: 40,
                                                child: Text("This service will be gone forever."),
                                              ),
                                              actions: [
                                                TextButton(onPressed: () {
                                                  deleteService(service.id!);
                                                }, child: Text("Delete", style: TextStyle(color: Colors.red)))
                                              ],
                                            ));
                                          },
                                          icon: Icon(Icons.delete)),
                                    );
                                  }
                              ) : Builder(
                                  builder: (context) {
                                    final serviceGroup = ServiceGroup.fromJson(snapshot.data![i]);
                                    return ListTile(
                                      onTap: () {
                                        lastAssigned.add(assignedGroups);
                                        assignedGroups = serviceGroup.name!;
                                        setStateList((){});
                                      },
                                      title: Text(serviceGroup.name!),
                                      subtitle: Text("Group"),
                                      trailing: IconButton(
                                          onPressed: () {
                                            showDialog(context: context, builder: (_) => AlertDialog(
                                              title: Text("Confirm Delete?"),
                                              content: Container(
                                                width: 100,
                                                height: 60,
                                                child: Text("This group and the its contents will be gone forever."),
                                              ),
                                              actions: [
                                                TextButton(onPressed: () {
                                                  deleteGroup(serviceGroup.id!, serviceGroup.name!);
                                                }, child: Text("Delete", style: TextStyle(color: Colors.red)))
                                              ],
                                            ));
                                          },
                                          icon: Icon(Icons.delete)),
                                    );
                                  }
                              ) ;
                            }),
                      )
                          : Container(
                        height: 400,
                        child: Center(
                          child:
                          Text("Add Groups or Services",
                              style: TextStyle(color: Colors.grey)),
                        ),
                      )
                          : Container(
                        padding: EdgeInsets.all(20),
                            height: MediaQuery.of(context).size.height - 180,
                            child: Center(
                              child: Container(
                                height: 50,
                                width: 50,
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          )
                    ],
                  );
                },
              );
            },
          )
        ],
      ),
    );
  }

  String removeExtraZeros(String str) {
    if (RegExp(r'^0+$').hasMatch(str)) {
      // String contains only zeros → return single "0"
      return "0";
    } else {
      // Remove leading zeros normally
      return str.replaceFirst(RegExp(r'^0+'), '');
    }
  }

  addPriority(String name) async {
    final uri = Uri.parse('http://$site/queueing_api/api_priorities.php');
    final body = jsonEncode({'priorityName': name});
    final result = await http.post(uri, body: body);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Priority '$name' added.")));
  }

  getPriority() async {
    final uri = Uri.parse('http://$site/queueing_api/api_priorities.php');
    final result = await http.get(uri);
    final response = jsonDecode(result.body);
    return response;
  }

  deletePriority(int i) async {
    final uri = Uri.parse('http://$site/queueing_api/api_service.php');
    final body = jsonEncode({'id': '$i'});
    final result = await http.delete(uri, body: body);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Priority Deleted")));
  }

  deleteService(int i) async {
    final uri = Uri.parse('http://$site/queueing_api/api_service.php');
    final body = jsonEncode({'id': i});
    final result = await http.delete(uri, body: body);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Service Deleted")));
    Navigator.pop(context);
    setState(() {});
  }

  serviceExistChecker(String serviceType, String serviceCode) async {
    final List<Service> services = await getServiceSQL();
    final serviceCodeMatch = services.where((e) => e.serviceCode == serviceCode).toList().length;
    final serviceTypeMatch = services.where((e) => e.serviceType == serviceType).toList().length;

    if (serviceCodeMatch + serviceTypeMatch == 0) {
      return 1;
    } else {
      return 0;
    }

  }

  addService(int i, [Service? service]) {
    showDialog(
        context: context,
        builder: (_) => PopScope(
          canPop: true,
          onPopInvokedWithResult: (bool, value) {
            serviceType.clear();
            serviceCode.clear();
          },
          child: AlertDialog(
                title: Text('${i == 0 ? 'Add' : 'Edit'} Service'),
                content: Container(
                  height: 120,
                  width: 250,
                  child: Column(
                    children: [
                      Container(
                          child: TextField(
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(',')),
                            ],
                        controller: serviceType,
                        decoration: InputDecoration(
                          labelText: 'Service Type',
                        ),
                      )),
                      Container(
                          child: TextField(
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(',')),
                            ],
                        controller: serviceCode,
                        decoration: InputDecoration(labelText: 'Service Code'),
                      )),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: clearServiceFields, child: Text("Clear")),
                  TextButton(
                      onPressed: () async {
                        int checkResult = await serviceExistChecker(serviceType.text, serviceCode.text);

                        if (checkResult == 1) {
                          if (i == 0) {
                            addServiceSQL();
                          } else {

                            if (serviceType.text.trim() != "" && serviceCode.text.trim() != "") {
                              final oldName = service!.serviceType!;

                              service.update({
                                'serviceType': serviceType.text.trim(),
                                'serviceCode': serviceCode.text.trim(),
                              });

                              final ticket = await getTicketSQL(1);

                              await Future.wait(ticket.where((e) => e.serviceType! == oldName).map((e) async {
                                await e.update({
                                  'serviceType': serviceType.text.trim(),
                                  'serviceCode': serviceCode.text.trim(),
                                });
                              }));

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(content: Text("Service Updated")));
                              setState(() {});
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Values cannot be empty.")));
                            }
                          }
                          clearServiceFields();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ensure Service Name & Code are Unique")));
                        }
                      },
                      child: Text("${i == 0 ? 'Add' : 'Update'} Service"))
                ],
              ),
        ));
  }

  addServiceSQL() async {
    final uri = Uri.parse('http://$site/queueing_api/api_service.php');
    final body = jsonEncode({
      'serviceType': serviceType.text,
      'serviceCode': serviceCode.text,
      'assignedGroup' : assignedGroups,
    });


    final result = await http.post(uri, body: body);

    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Service Added")));
    setState(() {});
  }

  getServiceSQL() async {
    try {
      final uri = Uri.parse('http://$site/queueing_api/api_service.php');
      final result = await http.get(uri);
      final List<dynamic> response = jsonDecode(result.body);
      response.sort((a, b) => int.parse(a['id'].toString())
          .compareTo(int.parse(b['id'].toString())));

      List<Service> services = [];

      for (int i = 0; i < response.length; i++) {
        final service = Service.fromJson(response[i]);
        final result = await service.selfDeleteWithoutGroup();
        if (result == 1) {
          services.add(service);
        }
      }

      return services;

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Cannot connect to the server. Please try again.")));
      print(e);
      return [];
    }
  }

  clearServiceFields() {
    serviceCode.clear();
    serviceType.clear();
  }

  clearUserFields() {
    user.clear();
    password.clear();
    userServiceType.clear();
    userType.clear();
  }

  clearStationFields() {
    stationName.clear();
    stationNumber.clear();
    displayIndex.clear();
  }

  usersView() {
    return Container(
      child: Column(
        children: [
          Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                  onPressed: () {
                    addUser();
                  },
                  child: Text("+ Add User"))),
          StatefulBuilder(
            builder: (BuildContext context, void Function(void Function()) setStateView) {
              return FutureBuilder(
                future: getUserSQL('Staff'),
                builder: (BuildContext context,
                    AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                  return snapshot.connectionState == ConnectionState.done
                      ? snapshot.data!.isNotEmpty
                      ? Container(
                    padding: EdgeInsets.all(10),
                    height: MediaQuery.of(context).size.height - 200,
                    child: ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, i) {
                          User user = User.fromJson(snapshot.data![i]);

                          return ListTile(
                            title: Text("${user.username}"),
                            subtitle: Text(
                                "${user.userType}${user.serviceType!.isEmpty ? "" : user.serviceType!.length > 3 ? " | ${user.serviceType!.length} Services" : " | Service: ${user.serviceType!.join(', ')}"}"
                            ,style: TextStyle(color: Colors.grey),
                            ),
                            trailing: widget.user.username == user.username ? null : IconButton(
                                onPressed: () {
                                  deleteUser(user.id!);
                                },
                                icon: Icon(Icons.delete)),
                            onTap: () {
                              if (widget.user.username == user.username) {
                                bool obscure = true;
                                final userController = TextEditingController();
                                final oldPassController = TextEditingController();
                                final passController = TextEditingController();

                                showDialog(context: context, builder: (_) => StatefulBuilder(builder: (BuildContext context, void Function(void Function()) setState) {
                                  return AlertDialog(
                                    title: Text("Set Admin Password"),
                                    content: Container(
                                      height: 140,
                                      width: 200,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          TextField(
                                            obscureText: obscure,
                                            decoration: InputDecoration(
                                                labelText: "Old Password"
                                            ),
                                            controller: oldPassController,
                                          ),
                                          TextField(
                                            obscureText: obscure,
                                            decoration: InputDecoration(
                                                labelText: "New Password"
                                            ),
                                            controller: passController,
                                          ),
                                          IconButton(onPressed: () {
                                            obscure = !obscure;
                                            setState((){

                                            });
                                          }, icon: Icon(obscure == false ? Icons.remove_red_eye_rounded : Icons.remove_red_eye_outlined))
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () async {
                                        if (oldPassController.text != user.pass) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Current Password does not match.")));
                                        } else {
                                          await user.update({
                                            'pass': userController.text
                                          });

                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User updated")));
                                          setStateView((){});
                                        }
                                      }, child: Text("Update"))
                                    ],
                                  );
                                },));
                              } else {

                                bool obscure = true;
                                final userController = TextEditingController();
                                final passController = TextEditingController();

                                //region

                                showDialog(context: context, builder: (_) => AlertDialog(
                                  title: Text("Edit User: ${user.username}"),
                                  content: Container(
                                    height: 180,
                                    width: 200,
                                    child: Column(
                                      children: [
                                        ListTile(
                                          title: Text("Username and Password"),
                                          onTap: () {
                                            showDialog(context: context, builder: (_) => StatefulBuilder(builder: (context, setState) {
                                              return AlertDialog(
                                                title: Text("Username & Password"),
                                                content: Container(
                                                  height: 140,
                                                  width: 200,
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      TextField(
                                                        decoration: InputDecoration(
                                                            labelText: "Username"
                                                        ),
                                                        controller: userController,
                                                      ),
                                                      TextField(
                                                        obscureText: obscure,
                                                        decoration: InputDecoration(
                                                            labelText: "Password"
                                                        ),
                                                        controller: passController,
                                                      ),
                                                      IconButton(onPressed: () {
                                                        obscure = !obscure;
                                                        setState((){

                                                        });
                                                      }, icon: Icon(obscure == false ? Icons.remove_red_eye_rounded : Icons.remove_red_eye_outlined))
                                                    ],
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(onPressed: () async {
                                                    if (userController.text.trim() != "" && passController.text.trim() != "") {
                                                      final oldName = user.username;


                                                      await user.update({
                                                        'username': userController.text.trim(),
                                                        'pass': passController.text.trim()
                                                      });

                                                      final ticket = await getTicketSQL(1);

                                                      await Future.wait(ticket.where((e) => e.userAssigned! == oldName!).map((e) async {
                                                        await e.update({
                                                          'userAssigned': userController.text,
                                                        });
                                                      }));

                                                      Navigator.pop(context);
                                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User updated")));
                                                      setStateView((){});
                                                    } else {
                                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Values cannot be empty")));
                                                    }
                                                  }, child: Text("Update"))
                                                ],
                                              );
                                            }));
                                          },
                                        ),
                                        ListTile(
                                          title: Text("Assigned Services"),
                                          onTap: () {
                                            showDialog(context: context, builder: (_) => Builder(
                                                builder: (context) {
                                                  List<String> services = [];

                                                  if (user.serviceType!.isNotEmpty) {
                                                    services = stringToList(user.serviceType.toString());
                                                  }

                                                  final dialogKey = GlobalKey();

                                                  return AlertDialog(
                                                    title: Text("Assign Service Types"),
                                                    content: Container(
                                                      height: 400,
                                                      width: 400,
                                                      child: FutureBuilder(
                                                          future: getServiceSQL(),
                                                          builder: (context, AsyncSnapshot<List<Service>> snapshot) {
                                                            return StatefulBuilder(
                                                              key: dialogKey,
                                                              builder: (context, setStateList) {
                                                                return snapshot.connectionState == ConnectionState.done ?  ListView.builder(
                                                                    itemCount: snapshot.data!.length,
                                                                    itemBuilder: (context, i) {
                                                                      final service = snapshot.data![i];

                                                                      return CheckboxListTile(
                                                                        title: Text(service.serviceType!),
                                                                        value: services.contains(service.serviceType!.toString()),
                                                                        onChanged: (bool? value) {
                                                                          if (value == true) {
                                                                            services.add(service.serviceType!);
                                                                            setStateList((){});
                                                                          } else {
                                                                            services.remove(service.serviceType!);
                                                                            setStateList((){});
                                                                          }
                                                                        },
                                                                      );
                                                                    }) : Center(
                                                                  child: Container(
                                                                    height: 50,
                                                                    width: 50,
                                                                    child: CircularProgressIndicator(),
                                                                  ),
                                                                );
                                                              },
                                                            );
                                                          }),
                                                    ),
                                                    actions: [
                                                      TextButton(onPressed: () async {
                                                        services.clear();
                                                        dialogKey.currentState!.setState(() {});
                                                      }, child: Text("Clear")),
                                                      TextButton(onPressed: () async {
                                                        final List<Service> servicesSQL = await getServiceSQL();
                                                        services.clear();

                                                        for (int i = 0; i < servicesSQL.length; i++) {
                                                          services.add(servicesSQL[i].serviceType!);
                                                        }
                                                        dialogKey.currentState!.setState(() {});
                                                      }, child: Text("Select All")),
                                                      TextButton(onPressed: () async {
                                                        final servicesSetToAdd = services.length > 3 ? services.sublist(0, 3).toString() : services.isNotEmpty ? services.toString() : null;

                                                        await user.update({
                                                          'serviceType': services.isEmpty ? null : services.toString(),
                                                          'servicesSet': services.isEmpty ? null : servicesSetToAdd
                                                        });

                                                        setStateView(() {});
                                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User updated")));
                                                        Navigator.pop(context);
                                                      }, child: Text("Update"))
                                                    ],
                                                  );
                                                }
                                            ));
                                          },
                                        ),

                                        //endregion

                                        ListTile(
                                          title: Text("Assign Station"),
                                          onTap: () {
                                            showDialog(context: context, builder: (_) => AlertDialog(
                                              title: Text("Station: ${user.assignedStationId == 999 ? "Allow Select" : user.assignedStation}"),
                                              content: Container(
                                                height: 400,
                                                width: 400,
                                                child: FutureBuilder(
                                                    future: getStationSQL(),
                                                    builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                                                      return snapshot.connectionState == ConnectionState.done ? ListView.builder(
                                                          itemCount: snapshot.data!.length,
                                                          itemBuilder: (context, i) {
                                                        final Station station = Station.fromJson(snapshot.data![i]);
                                                        final stationNameAndNumber = "${station.stationName!}${station.stationNumber! == 0 ? "" : " ${station.stationNumber!}"}";
                                                        final stationId = station.id;

                                                        return ListTile(
                                                            title: Text("${station.stationName!} ${station.stationNumber! == 0 ? "" : " ${station.stationNumber!}"}"),
                                                          onTap: () {
                                                              Navigator.pop(context);
                                                              user.update({
                                                                'assignedStation': "${stationNameAndNumber}_$stationId"
                                                              });
                                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User Assigned to $stationNameAndNumber")));
                                                          },
                                                        );
                                                      }) : Center(
                                                        child: Container(
                                                          height: 50,
                                                          width: 50,
                                                          child: CircularProgressIndicator(),
                                                        ),
                                                      );
                                                    }),
                                              )
                                            ));
                                          },
                                        )
                                      ],
                                    ),
                                  ),
                                ));
                              };
                            },
                          );
                        }),
                  )
                      : Container(
                    height: 400,
                    child: Text("No users found",
                        style: TextStyle(color: Colors.grey)),
                  )
                      : Container(
                    height: MediaQuery.of(context).size.height - 200,
                        child: Center(
                                            child: Container(
                        height: 50,
                        width: 50,
                        child: CircularProgressIndicator(

                        ),
                                            ),
                                          ),
                      );
                },
              );
            },
          )
        ],
      ),
    );
  }

  getUserSQL([String? userType, String? serviceType]) async {
    try {
      final uri = Uri.parse('http://$site/queueing_api/api_user.php');
      final result = await http.get(uri);
      final response = jsonDecode(result.body);
      dynamic newResult = response;
      if (userType != null) {
        newResult = newResult.where((e) => e['userType'] == 'Staff').toList();
      }
      if (serviceType != null) {
        newResult =
            newResult.where((e) => e['serviceType'] == serviceType).toList();
      }

      return newResult;
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Cannot connect to the server. Please try again.")));
      print(e);
      return [];
    }
  }

  addUser() {
    bool obscure = true;
    List<String> services = [];
    List<String> allServices = [];
    String userType = "Staff";
    String displayService = "Select";
    String displayStation = "Select";
    int? stationId;

    final listKey = GlobalKey();

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text('Add User'),
              content: StatefulBuilder(
                builder: (BuildContext context,
                    void Function(void Function()) setStateDialog) {
                  return Container(
                    height: 250,
                    width: 250,
                    child: Column(
                      children: [
                        Container(
                            child: TextField(
                          controller: user,
                          decoration: InputDecoration(
                            labelText: 'Username',
                          ),
                        )),
                        Container(
                            child: Row(
                          children: [
                            Container(
                              width: 210,
                              child: TextField(
                                obscureText: obscure,
                                controller: password,
                                decoration:
                                    InputDecoration(labelText: 'Password'),
                              ),
                            ),
                            IconButton(
                                onPressed: () {
                                  obscure = !obscure;
                                  setStateDialog(() {});
                                },
                                icon: Icon(obscure == true
                                    ? Icons.remove_red_eye
                                    : Icons.remove_red_eye_outlined))
                          ],
                        )),
                        ListTile(
                            title: Text("Service Type: $displayService"),
                            onTap: () {
                              showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text("Assign Services"),
                                    content: Container(
                                      height: 400,
                                      width: 300,
                                      child: FutureBuilder(
                                        future: getServiceSQL(),
                                        builder: (BuildContext
                                        context,
                                            AsyncSnapshot<
                                                List<
                                                    Service>>
                                            snapshot) {
                                          return snapshot
                                              .connectionState ==
                                              ConnectionState
                                                  .done
                                              ? StatefulBuilder(

                                            key: listKey,
                                            builder: (context, setStateList) {

                                              return ListView
                                                  .builder(
                                                  itemCount: snapshot
                                                      .data!
                                                      .length,
                                                  itemBuilder:
                                                      (context,
                                                      i) {

                                                    final Service service = snapshot.data![i];
                                                    if (!allServices.contains(service.serviceType!)) {
                                                      allServices.add(service.serviceType!);
                                                    }

                                                    return CheckboxListTile(
                                                        title: Text(service.serviceType!),
                                                        value: services.contains(service.serviceType!),
                                                        onChanged: (value) {
                                                          if (value == true) {
                                                            services.add(service.serviceType!);
                                                            listKey.currentState!.setState(() {});
                                                          } else {
                                                            services.remove(service.serviceType!);
                                                            listKey.currentState!.setState(() {});
                                                          }
                                                        });
                                                  });
                                            },
                                          )
                                              : Center(
                                            child: Container(
                                              height: 50,
                                              width: 50,
                                              child:
                                              CircularProgressIndicator(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                          onPressed: () {
                                            services.clear();
                                            listKey.currentState!.setState(() {});
                                          },
                                          child: Text("Clear")),
                                      TextButton(
                                          onPressed: () {
                                            services.clear();
                                            services.addAll(allServices);
                                            listKey.currentState!.setState(() {});
                                          },
                                          child: Text("Select All")),
                                      TextButton(
                                          onPressed: () {
                                            displayService =
                                            services.length == 1 ? services.first : "${services.length} Services";
                                            Navigator.pop(context);
                                            setStateDialog(() {});
                                          },
                                          child: Text("Confirm"))
                                    ],
                                  ));
                            }),
                        ListTile(
                          title: Text("Assign Station: $displayStation"),
                          onTap: () {
                            showDialog(context: context, builder: (_) => PopScope(
                              child: AlertDialog(
                                title: Text("Select Station"),
                                content: Container(
                                  height: 400,
                                  width: 400,
                                  child: FutureBuilder(
                                    future: getStationSQL(),
                                    builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
                                      return snapshot.connectionState == ConnectionState.done ?
                                          ListView.builder(
                                              itemCount: snapshot.data!.length,
                                              itemBuilder: (context, i) {
                                                final Station station = Station.fromJson(snapshot.data![i]);
                                                final stationNameAndNumber = "${station.stationName!}${station.stationNumber! != 0 ? " ${station.stationNumber!}" : ""}";

                                                return ListTile(
                                                  title: Text(stationNameAndNumber),
                                                  onTap: () {
                                                    displayStation = stationNameAndNumber;
                                                    stationId = station.id;
                                                    Navigator.pop(context);
                                                    setStateDialog((){});
                                                  },
                                                );
                                              }) : Center(
                                        child: Container(
                                          height: 50,
                                          width: 50,
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                actions: [
                                  TextButton(onPressed: () {
                                    displayStation = "Allow Select";
                                    stationId = 999;
                                    Navigator.pop(context);
                                    setStateDialog((){});
                                  }, child: Text("Allow User to Select")),
                                ],
                              ),
                            ));
                          },
                        )
                      ],
                    ),
                  );
                },
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      try {
                        if (displayService != "Select" && displayStation != "Select") {
                          if (user.text.trim() != "" && password.text.trim() != "") {
                            addUserSQL(services, userType, displayStation, stationId);
                            clearUserFields();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Name and Password must not be empty.")));
                          }
                        } else {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Assign Service and Station")));
                        }
                      } catch (e) {
                        print(e);
                      }
                    },
                    child: Text("Add User"))
              ],
            ));
  }

  addUserSQL(List<String> services, String userType, String assignedStation, [int? stationId]) async {
    try {
      final uri = Uri.parse('http://$site/queueing_api/api_user.php');
      final body = jsonEncode({
        "username": user.text,
        "pass": password.text,
        "serviceType": services.isEmpty ? null : services.toString(),
        "userType": userType,
        "loggedIn": null,
        "servicesSet": services.length > 3 ? "[${services[0]}, ${services[1]}, ${services[2]}]" : services.isEmpty ? null : services.toString(),
        "assignedStation": "${assignedStation}_${stationId == null ? "All" : "$stationId"}"
      });

      final result = await http.post(uri, body: body);
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("User Added")));
      setState(() {});
    } catch(e) {
      print(e);
    }
  }

  deleteUser(int i) async {
    final uri = Uri.parse('http://$site/queueing_api/api_user.php');
    final body = jsonEncode({'id': '$i'});
    final result = await http.delete(uri, body: body);

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("User Deleted")));
    setState(() {});
  }

  stationsView() {
    return Column(
      children: [
        Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
                onPressed: () async {
                  final List<dynamic> stations = await getStationSQL();
                  if (stations.length >= 10) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Station number limit reached. (10 Maximum)")));
                  } else {
                    clearStationFields();
                    addStation(0);
                  }
                },
                child: Text("+ Add Station"))),
        FutureBuilder(
          future: getStationSQL(),
          builder: (BuildContext context,
              AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
            return snapshot.connectionState == ConnectionState.done
                ? snapshot.data!.isNotEmpty
                    ? Container(
                        padding: EdgeInsets.all(10),
                        height: MediaQuery.of(context).size.height - 200,
                        child: ListView.builder(
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, i) {
                              final station =
                                  Station.fromJson(snapshot.data![i]);

                              print(station.sessionPing!);

                              if (station.sessionPing! != "") {
                                print(DateTime.parse(station.sessionPing!.toString()).difference(DateTime.now()).inSeconds);

                                if (DateTime.parse(station.sessionPing!.toString()).difference(DateTime.now()).inSeconds < -5) {
                                  station.update({
                                    "sessionPing": "",
                                    "userInSession": "",
                                    "inSession": 0
                                  });
                                }
                              }

                              return ListTile(
                                title: Text(
                                    "${station.stationName} ${station.stationNumber == 0 ? "" : station.stationNumber}"),
                                subtitle: Row(
                                  children: [
                                    station.inSession == 1
                                        ? Text(
                                            "In Session: ${station.userInSession}",
                                            style:
                                                TextStyle(color: Colors.red))
                                        : Text("Available",
                                            style: TextStyle(
                                                color: Colors.green))
                                  ],
                                ),
                                /*
                                IconButton(
                                    onPressed: () {
                                      if (station.inSession != 1) {
                                        deleteStation(station.id!);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Station must be inactive to delete.")));
                                      }
                                    },
                                    icon: Icon(Icons.delete))
                                 */
                                onTap: () {
                                  addStation(1, station);
                                },
                              );
                            }),
                      )
                    : Container(
                        height: 400,
                        child: Text("No stations found",
                            style: TextStyle(color: Colors.grey)),
                      )
                : Container(
              height: MediaQuery.of(context).size.height - 200,
              child: Center(
                child: Container(
                  height: 50,
                  width: 50,
                  child: CircularProgressIndicator(

                  ),
                ),
              ),
            );
          },
        )
      ],
    );
  }

  getStationSQL() async {
    try {
      final uri = Uri.parse('http://$site/queueing_api/api_station.php');
      final result = await http.get(uri);
      final List<dynamic> response = jsonDecode(result.body);
      response.sort((a, b) => int.parse(a['id'].toString())
          .compareTo(int.parse(b['id'].toString())));

      response.sort((a, b) => int.parse(a['displayIndex'].toString())
          .compareTo(int.parse(b['displayIndex'].toString())));

      return response;
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Cannot connect to the server. Please try again.")));
      print(e);
      return [];
    }
  }

  addStation(int i, [Station? station]) {

    if (station != null) {
      stationName.text = station.stationName!;
      stationNumber.text = station.stationNumber!.toString();
      displayIndex.text = station.displayIndex!.toString();
    }

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text('${i == 0 ? "Add" : "Edit"} Station'),
              content: StatefulBuilder(
                builder: (BuildContext context,
                    void Function(void Function()) setStateDialog) {
                  return Container(
                    height: 160,
                    width: 250,
                    child: Column(
                      children: [
                        Container(
                            child: TextField(
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]'))
                              ],
                          controller: stationName,
                          decoration: InputDecoration(
                            labelText: 'Station Name',
                          ),
                        )),
                        Container(
                            child: TextField(
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                          controller: stationNumber,
                          decoration:
                              InputDecoration(
                                  labelText: 'Station Number'),
                        )),
                        Container(
                            child: TextField(
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              controller: displayIndex,
                              decoration:
                              InputDecoration(labelText: 'Display Index'),
                            )),
                      ],
                    ),
                  );
                },
              ),
              actions: [
                TextButton(
                    onPressed: () async {
                      try {
                        final nameInput = stationName.text.trim();
                        final numberInput = stationNumber.text.trim();
                        final indexInput = displayIndex.text.trim();
                        int? id;
                        int? exists;
                        int? indexBool;

                        final List<dynamic> stations = await getStationSQL();

                        if (station != null) {
                          id = station.id!;
                          exists = stations.where((e) => e['stationName'] == nameInput && e['stationNumber'] == numberInput).toList().where((e) => int.parse(e['id']) != id).toList().length;
                          indexBool = stations.where((e) => int.parse(e['displayIndex']) == int.parse(indexInput)).where((e) => int.parse(e['id']) != id).toList().length;
                        } else {
                          exists = stations.where((e) => e['stationName'] == nameInput && e['stationNumber'] == numberInput).toList().length;
                          indexBool = stations.where((e) => int.parse(e['displayIndex']) == int.parse(indexInput)).toList().length;
                        }


                        if (i == 0) {
                          if (nameInput != "" && numberInput != "" && indexInput != "") {
                            if (exists == 0 && indexBool == 0) {

                              await addStationSQL();
                              clearStationFields();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ensure Station or Display Index is unique")));
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Values cannot be empty.")));
                          }
                        } else {
                          if (station != null) {
                            final oldName = station.stationName;

                            if (nameInput != "") {
                              if (exists == 0 && indexBool == 0) {

                                await station.update({
                                  'stationName': nameInput,
                                  'stationNumber': numberInput == "" ? 0 : int.parse(numberInput),
                                  'displayIndex': indexInput == "" ? 0 : int.parse(indexInput)
                                });

                                final ticket = await getTicketSQL(1);

                                await Future.wait(ticket.where((e) => e.stationName! == oldName!).map((e) async {
                                  await e.update({
                                    'stationName': nameInput,
                                    'stationNumber': numberInput == "" ? 0 : int.parse(numberInput),
                                  });
                                }));

                                clearStationFields();
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Station Updated.")));
                                setState(() {});
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ensure Station Name is unique")));
                              }

                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Station Name cannot be empty")));
                            }
                          }
                        }
                      } catch (e) {
                        print(e);
                      }
                    },
                    child: Text("${i == 0 ? "Add" : "Update"} Station"))
              ],
            ));
  }

  addStationSQL() async {
    final uri = Uri.parse('http://$site/queueing_api/api_station.php');
    final body = jsonEncode({
      "stationNumber": stationNumber.text.trim(),
      "stationName": stationName.text.trim(),
      "inSession": 0,
      "userInSession": "",
      "ticketServing": "",
      "sessionPing": "",
      "displayIndex": displayIndex.text.trim()
    });

    final result = await http.post(uri, body: body);
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Station Added")));
    clearStationFields();
    setState(() {});
  }

  deleteStation(int i) async {
    final uri = Uri.parse('http://$site/queueing_api/api_station.php');
    final body = jsonEncode({'id': '$i'});

    final result = await http.delete(uri, body: body);

    print("result: ${result.body}");

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Station Deleted")));
    setState(() {});
  }

  addGroup(String name, String assignedGroup) async {
    final uri = Uri.parse('http://$site/queueing_api/api_serviceGroup.php');
    final body = jsonEncode({
      "name": name,
      "assignedGroup": assignedGroup
    });

    final result = await http.post(uri, body: body);
    print("result: ${result.body}");

    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Group Added")));
    setState(() {});
  }

  deleteGroup(int id, String name) async {
    final uri = Uri.parse('http://$site/queueing_api/api_serviceGroup.php');
    final body = jsonEncode({'id': '$id'});
    final result = await http.delete(uri, body: body);
    final uriService = Uri.parse('http://$site/queueing_api/api_service.php');
    final List<Service> services = await getServiceSQL();
    final sorted = services.where((e) => e.assignedGroup.toString() == name.toString()).toList();
    for (int i = 0; i < sorted.length; i++) {
      final service = Service.fromJson(sorted[i]);
      final body = jsonEncode({'id': service.id!});
      final result = await http.delete(uriService, body: body);
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Group Deleted")));
    setState(() {});
  }

  addGroupDialog() {
    TextEditingController controller = TextEditingController();

    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text("Add Group"),
      content: Container(
        height: 80,
        width: 300,
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Group Name'
              ),
            )
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () {
          addGroup(controller.text, assignedGroups);
        }, child: Text("Add"))
      ],
    ));
  }

  getServiceGroups(String assignedGroup) async {
    try {
      final uriGroup = Uri.parse('http://$site/queueing_api/api_serviceGroup.php');
      final resultGroup = await http.get(uriGroup);
      List<dynamic> responseGroup = jsonDecode(resultGroup.body);

      final uriService = Uri.parse('http://$site/queueing_api/api_service.php');
      final resultService = await http.get(uriService);
      List<dynamic> responseService = jsonDecode(resultService.body);

      List<dynamic> resultsToReturn = [];

      for (int i = 0; i < responseGroup.length; i++) {
        if (responseGroup[i]['assignedGroup'] == assignedGroup){
          resultsToReturn.add(responseGroup[i]);
        }
      }

      for (int i = 0; i < responseService.length; i++) {
        if (responseService[i]['assignedGroup'] == assignedGroup){
          resultsToReturn.add(responseService[i]);
        }
      }

      resultsToReturn.sort((a, b) => int.parse(a['id']).compareTo(int.parse(b['id'])));

      resultsToReturn.sort((a, b) {
        final at = b['timeCreated'];
        final bt = a['timeCreated'];

        if (at == null && bt != null) return 1;  // b before a
        if (bt == null && at != null) return -1; // a before b
        if (at != null && bt != null) {
          return at.compareTo(bt);
        }
        return 0;
      });

      return resultsToReturn;


    } catch(e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cannot connect to the server. Please try again.")));
      print(e);
      return [];
    }

  }

  addMedia(String name, String link) async {
    final uri = Uri.parse('http://$site/queueing_api/api_media.php');
    final body = jsonEncode({
      'name': name,
      'link': link
    });

    final response = await http.post(uri, body: body);
  }

  addMediabg(String name, String link) async {
    final uri = Uri.parse('http://$site/queueing_api/api_mediabg.php');
    final body = jsonEncode({
      'name': name,
      'link': link
    });

    final response = await http.post(uri, body: body);

  }

  Future<List<Ticket>> getTicketSQL([int? unsorted]) async {

    try {
      final uri = Uri.parse('http://$site/queueing_api/api_ticket.php');
      final result = await http.get(uri);
      final List<dynamic> response = jsonDecode(result.body);
      List<Ticket> newTickets = [];

      for (int i = 0; i < response.length; i++) {
        newTickets.add(Ticket.fromJson(response[i]));
      }

      if (unsorted == null) {

        if (dates.isNotEmpty) {
          newTickets = newTickets.where((e) => e.timeCreatedAsDate!.isAfter(dates![0]) && e.timeCreatedAsDate!.isBefore(dates[1])).toList();
        } else {
          newTickets = newTickets.where((e) => e.timeCreatedAsDate!.isAfter(toDateTime(DateTime.now())) && e.timeCreatedAsDate!.isBefore(toDateTime(DateTime.now()).add(Duration(days: 1)))).toList();
        }

        if (users.isNotEmpty) {
          List<Ticket> userSorted = [];

          for (int i = 0; i < users.length; i++) {
            userSorted.addAll(newTickets.where((e) => e.userAssigned! == users[i]).toList());
          }
          newTickets = userSorted;
        }

        if (serviceTypes.isNotEmpty) {
          List<Ticket> serviceSorted = [];

          for (int i = 0; i < serviceTypes.length; i++) {
            serviceSorted.addAll(newTickets.where((e) => e.serviceType! == serviceTypes[i]).toList());
          }
          newTickets = serviceSorted;
        }

        if (priorities.isNotEmpty) {
          List<Ticket> prioritySorted = [];

          for (int i = 0; i < priorities.length; i++) {
            prioritySorted.addAll(newTickets.where((e) => e.priorityType! == priorities[i]).toList());
          }
          newTickets = prioritySorted;
        }

        if (statuses.isNotEmpty) {
          List<Ticket> statusSorted = [];

          for (int i = 0; i < statuses.length; i++) {
            statusSorted.addAll(newTickets.where((e) => e.status! == statuses[i]).toList());
          }
          newTickets = statusSorted;
        }

        if (genders.isNotEmpty) {
          List<Ticket> statusSorted = [];

          for (int i = 0; i < genders.length; i++) {
            statusSorted.addAll(newTickets.where((e) => e.status! == genders[i]).toList());
          }
          newTickets = statusSorted;
        }
      }

      newTickets.sort((a,b) => b.timeCreatedAsDate!.compareTo(a.timeCreatedAsDate!));

      return newTickets;

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Cannot connect to the server. Please try again.")));
      print(e);
      return [];
    }
  }

  archiveView() {
    final DateTime dateNow = DateTime.now();

    return Column(
      children: [
        StatefulBuilder(
          builder: (context, setStateArchive) {
            return Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    width: MediaQuery.of(context).size.width - 20,
                    height: 45,
                    child: ListView(
                      padding: EdgeInsets.all(5),
                      scrollDirection: Axis.horizontal,
                      children: [
                        ElevatedButton(
                            child: Text(dates.isNotEmpty ? "Date: ${displayDate}" : "Date: Today"),
                            onPressed: () {
                              showDialog(context: context, builder: (_) => AlertDialog(
                                title: Text("Filter Archive"),
                                content: Container(
                                  height: 380,
                                  child: Column(
                                    children: [
                                      Container(
                                        height: 350,
                                        width: 350,
                                        child: CalendarDatePicker2(
                                            onValueChanged: (values) {
                                              dates = values;
                                            },
                                            value: dates,
                                            config: CalendarDatePicker2Config(
                                              calendarType: CalendarDatePicker2Type.range,
                                              firstDate: DateTime(2000, 1, 1),
                                              lastDate: DateTime(3000, 1, 1),
                                              currentDate: dateNow,
                                              allowSameValueSelection: true,
                                            )),
                                      ),
                                      SizedBox(height: 5),
                                      Text("Select Date Range to Filter", style: TextStyle(color: Colors.grey)),
                                      SizedBox(height: 5),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(onPressed: () {
                                    dates = [];
                                    setStateArchive((){});
                                    Navigator.pop(context);
                                  }, child: Text("Today")),
                                  TextButton(onPressed: () {
                                    if (dates.length == 1) {
                                      dates.add(dates[0].add(Duration(days: 1)).subtract(Duration(seconds: 1)));
                                    } else {
                                      dates[1].add(Duration(days: 1)).subtract(Duration(seconds: 1));
                                    }
                                    displayDate = "${DateFormat.yMMMMd().format(dates[0])} - ${DateFormat.yMMMMd().format(dates[1])}";
                                    setStateArchive((){});
                                    Navigator.pop(context);
                                  }, child: Text("Filter")),
                                ],
                              ));
                            }),
                        SizedBox(width: 10),
                        ElevatedButton(
                            child: Text(users.isNotEmpty ? "User: $displayUsers" : "User: All"),
                            onPressed: () {

                              final _listViewKey = GlobalKey();

                              showDialog(context: context, builder: (_) => AlertDialog(
                                title: Text("Filter User"),
                                content: FutureBuilder(future: getUserSQL("Staff"),
                                    builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                                      return snapshot.connectionState == ConnectionState.done ? Container(
                                        height: 400,
                                        width: 400,
                                        child: StatefulBuilder(
                                          key: _listViewKey,
                                          builder: (context, setStateList) {
                                            return ListView.builder(
                                                itemCount: snapshot.data!.length,
                                                itemBuilder: (context, i) {
                                                  final user = User.fromJson(snapshot.data![i]);

                                                  return CheckboxListTile(
                                                    title: Text(user.username!),
                                                    value: users.contains(user.username!),
                                                    onChanged: (bool? value) {
                                                      if (users.contains(user.username!)) {
                                                        users.remove(user.username!);
                                                        setStateList((){});
                                                      } else {
                                                        users.add(user.username!);
                                                        setStateList((){});
                                                      }
                                                    },
                                                  );
                                                });
                                          },
                                        ),
                                      ) : Container(
                                          height: 400,
                                          child: Center(
                                            child: Container(
                                                height: 50,
                                                width: 50,
                                                child: CircularProgressIndicator()),
                                          )
                                      );
                                    }),
                                actions: [
                                  TextButton(onPressed: () {
                                    users.clear();
                                    _listViewKey.currentState!.setState(() {});
                                    setStateArchive((){});
                                  }, child: Text("Clear")),
                                  TextButton(onPressed: () {
                                    displayUsers = users.length > 3 ? "4 Users" : users.sublist(0, users.length).join(', ');
                                    Navigator.pop(context);
                                    setStateArchive((){});
                                  }, child: Text("Filter"))
                                ],
                              ));

                        }),
                        SizedBox(width: 10),
                        ElevatedButton(
                            child: Text(serviceTypes.isNotEmpty ? "Service: $displayServiceTypes" : "Service: All"),
                            onPressed: () {

                          final _listViewKey = GlobalKey();

                          showDialog(context: context, builder: (_) => AlertDialog(
                            title: Text("Filter Services"),
                            content: FutureBuilder(future: getServiceSQL(),
                                builder: (context, AsyncSnapshot<List<Service>> snapshot) {
                                  return snapshot.connectionState == ConnectionState.done ? Container(
                                    height: 400,
                                    width: 400,
                                    child: StatefulBuilder(
                                      key: _listViewKey,
                                      builder: (context, setStateList) {
                                        return ListView.builder(
                                            itemCount: snapshot.data!.length,
                                            itemBuilder: (context, i) {
                                              final service = snapshot.data![i];

                                              return CheckboxListTile(
                                                title: Text(service.serviceType!),
                                                value: serviceTypes.contains(service.serviceType!),
                                                onChanged: (bool? value) {
                                                  if (serviceTypes.contains(service.serviceType!)) {
                                                    serviceTypes.remove(service.serviceType!);
                                                    setStateList((){});
                                                  } else {
                                                    serviceTypes.add(service.serviceType!);
                                                    setStateList((){});
                                                  }
                                                },
                                              );
                                            });
                                      },
                                    ),
                                  ) : Container(
                                      height: 400,
                                      child: Center(
                                        child: Container(
                                            height: 50,
                                            width: 50,
                                            child: CircularProgressIndicator()),
                                      )
                                  );
                                }),
                            actions: [
                              TextButton(onPressed: () {
                                serviceTypes.clear();
                                _listViewKey.currentState!.setState(() {});
                                setStateArchive((){});
                              }, child: Text("Clear")),
                              TextButton(onPressed: () {
                                displayServiceTypes = serviceTypes.length > 1 ? "2 Services" : serviceTypes[0];
                                Navigator.pop(context);
                                setStateArchive((){});
                              }, child: Text("Filter"))
                            ],
                          ));
                        }),
                        SizedBox(width: 10),
                        ElevatedButton(onPressed: () {
                          final _listViewKey = GlobalKey();

                          showDialog(context: context, builder: (_) => AlertDialog(
                            title: Text("Filter Priorities"),
                            content: FutureBuilder(future: getPriority(),
                                builder: (context, AsyncSnapshot<List<Service>> snapshot) {
                                  return snapshot.connectionState == ConnectionState.done ? Container(
                                    height: 400,
                                    width: 400,
                                    child: StatefulBuilder(
                                      key: _listViewKey,
                                      builder: (context, setStateList) {
                                        return ListView.builder(
                                            itemCount: snapshot.data!.length,
                                            itemBuilder: (context, i) {
                                              final priority = Priority.fromJson(snapshot.data![i]);

                                              return CheckboxListTile(
                                                title: Text(priority.priorityName!),
                                                value: priorities.contains(priority.priorityName!),
                                                onChanged: (bool? value) {
                                                  if (priorities.contains(priority.priorityName!)) {
                                                    priorities.remove(priority.priorityName!);
                                                    setStateList((){});
                                                  } else {
                                                    priorities.add(priority.priorityName!);
                                                    setStateList((){});
                                                  }
                                                },
                                              );
                                            });
                                      },
                                    ),
                                  ) : Container(
                                      height: 400,
                                      child: Center(
                                        child: Container(
                                            height: 50,
                                            width: 50,
                                            child: CircularProgressIndicator()),
                                      )
                                  );
                                }),
                            actions: [
                              TextButton(onPressed: () {
                                priorities.clear();
                                _listViewKey.currentState!.setState(() {});
                                setStateArchive((){});
                              }, child: Text("Clear")),
                              TextButton(onPressed: () {
                                displayPriorities = priorities.length > 3 ? "4 Priorities" : priorities.sublist(0, priorities.length).join(', ');
                                Navigator.pop(context);
                                setStateArchive((){});
                              }, child: Text("Filter"))
                            ],
                          ));
                        }, child: Text(priorities.isNotEmpty ? "Priority: $displayPriorities" : "Priority: All")),
                        SizedBox(width: 10),
                        ElevatedButton(onPressed: () {
                          final _listViewKey = GlobalKey();
                          List<String> statusList = ['Pending', 'Serving', 'Done', 'Released'];

                          showDialog(context: context, builder: (_) => AlertDialog(
                            title: Text("Filter Status"),
                            content: Container(
                              height: 300,
                              width: 400,
                              child: StatefulBuilder(
                                key: _listViewKey,
                                builder: (context, setStateList) {
                                  return ListView.builder(
                                      itemCount: statusList.length,
                                      itemBuilder: (context, i) {
                                        return CheckboxListTile(
                                          title: Text(statusList[i]),
                                          value: statuses.contains(statusList[i]),
                                          onChanged: (bool? value) {
                                            if (statuses.contains(statusList[i])) {
                                              statuses.remove(statusList[i]);
                                              setStateList((){});
                                            } else {
                                              statuses.add(statusList[i]);
                                              setStateList((){});
                                            }
                                          },
                                        );
                                      });
                                },
                              ),
                            ),
                            actions: [
                              TextButton(onPressed: () {
                                statuses.clear();
                                _listViewKey.currentState!.setState(() {});
                                setStateArchive((){});
                              }, child: Text("Clear")),
                              TextButton(onPressed: () {
                                displayStatus = statuses.length > 3 ? "4 Priorities" : statuses.sublist(0, statuses.length).join(', ');
                                Navigator.pop(context);
                                setStateArchive((){});
                              }, child: Text("Filter"))
                            ],
                          ));
                        }, child: Text(statuses.isNotEmpty ? "Status: $displayPriorities" : "Status: All")),
                        SizedBox(width: 10),
                        ElevatedButton(onPressed: () {
                          final _listViewKey = GlobalKey();
                          List<String> genderList = ['Male', 'Female', 'Others'];

                          showDialog(context: context, builder: (_) => AlertDialog(
                            title: Text("Filter Gender"),
                            content: Container(
                              height: 300,
                              width: 400,
                              child: StatefulBuilder(
                                key: _listViewKey,
                                builder: (context, setStateList) {
                                  return ListView.builder(
                                      itemCount: genderList.length,
                                      itemBuilder: (context, i) {
                                        return CheckboxListTile(
                                          title: Text(genderList[i]),
                                          value: genders.contains(genderList[i]),
                                          onChanged: (bool? value) {
                                            if (genders.contains(genderList[i])) {
                                              genders.remove(genderList[i]);
                                              setStateList((){});
                                            } else {
                                              genders.add(genderList[i]);
                                              setStateList((){});
                                            }
                                          },
                                        );
                                      });
                                },
                              ),
                            ),
                            actions: [
                              TextButton(onPressed: () {
                                genders.clear();
                                _listViewKey.currentState!.setState(() {});
                                setStateArchive((){});
                              }, child: Text("Clear")),
                              TextButton(onPressed: () {
                                displayGender = genders.length > 3 ? "4 Genders" : genders.sublist(0, genders.length).join(', ');
                                Navigator.pop(context);
                                setStateArchive((){});
                              }, child: Text("Filter"))
                            ],
                          ));
                        }, child: Text(genders.isNotEmpty ? "Status: $displayGender" : "Gender: All")),
                        SizedBox(width: 10),
                        TextButton(
                            child: Row(
                              children: [
                                Text("Export", textAlign: TextAlign.center),
                                SizedBox(width: 10),
                                Icon(Icons.download),
                              ],
                            ),
                            onPressed: () {
                              String fileType = '.XLSX';
                              String paperSize = 'A4';

                              showDialog(context: context, builder: (_) => StatefulBuilder(
                                builder: (BuildContext context, void Function(void Function()) setStateExport) {
                                  return AlertDialog(
                                    title: Text("Export"),
                                    content: Container(
                                      height: 140,
                                      width: 200,
                                      child: Column(
                                        children: [
                                          Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text("File Type", style: TextStyle(fontSize: 18))),
                                          Row(
                                            children: [
                                              Checkbox(value: fileType == '.XLSX',
                                                  onChanged: (value) {
                                                    if (value == true) fileType = '.XLSX';
                                                    setStateExport((){});
                                                  }),
                                              Text('.XLSX'),
                                              SizedBox(width: 10),
                                              Checkbox(value: fileType == '.PDF',
                                                  onChanged: (value) {
                                                    if (value == true) fileType = '.PDF';
                                                    setStateExport((){});
                                                  }),
                                              Text('.PDF'),
                                            ],
                                          ),
                                          SizedBox(height: 10),
                                          Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text("Paper Size", style: TextStyle(fontSize: 18))),
                                          SizedBox(height: 10),
                                          fileType == '.XLSX' ? Container(
                                            height: 30,
                                            child: Center(
                                              child: Text("Size is scalable sheet", style: TextStyle(color: Colors.grey)),
                                            ),
                                          ) : Row(
                                            children: [
                                              Checkbox(value: paperSize == 'A4',
                                                  onChanged: (value) {
                                                    if (value == true) paperSize = 'A4';
                                                    setStateExport((){});
                                                  }),
                                              Text('A4'),


                                              Checkbox(value: paperSize == 'Letter',
                                                  onChanged: (value) {
                                                    if (value == true) paperSize = 'Letter';
                                                    setStateExport((){});
                                                  }),
                                              Text('Letter'),

                                              Checkbox(value: paperSize == '8.5 x 13',
                                                  onChanged: (value) {
                                                    if (value == true) paperSize = '8.5 x 13';
                                                    setStateExport((){});
                                                  }),
                                              Text('8.5 x 13'),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                          child: Text("Export"),
                                          onPressed: () async {
                                            final tickets = await getTicketSQL();

                                            if (tickets.isNotEmpty)  {
                                              if (fileType == '.XLSX') createExcel(tickets);
                                              if (fileType == '.PDF') createPDF(paperSize, tickets);
                                            }

                                          })
                                    ],
                                  );
                                },
                              ));
                            })
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: FutureBuilder(
                    future: getTicketSQL(),
                    builder: (context, AsyncSnapshot<List<Ticket>> snapshot) {
                      return snapshot.connectionState != ConnectionState.done ? Container(
                        height: MediaQuery.of(context).size.height - 200,
                        child: Center(
                          child: Container(
                            height: 50,
                            width: 50,
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ) : snapshot.data!.isEmpty ? Container(
                        height: 400,
                        child: Center(
                          child: Text("No Archives found.", style: TextStyle(color: Colors.grey)),
                        ),
                      ): Column(
                        children: [
                          SizedBox(height: 5),
                          Text("Results: ${snapshot.data!.length} Tickets", style: TextStyle(fontWeight: FontWeight.w700)),
                          SizedBox(height: 5),
                          Container(
                            height: MediaQuery.of(context).size.height - 220,
                            child: ListView.builder(
                                itemCount: snapshot.data!.length,
                                itemBuilder: (context, i) {
                                  final ticket = snapshot.data![i];

                                  return ListTile(
                                    title: Row(
                                      children: [
                                        statusColorHandler(ticket.status!),
                                        Text(" | ${ticket.codeAndNumber!} | ${ticket.serviceType!}"),
                                      ],
                                    ),
                                    subtitle: Text(DateFormat.yMMMMd().add_jm().format(ticket.timeCreatedAsDate!)),
                                    onTap: () {
                                      showDialog(context: context, builder: (_) => AlertDialog(
                                        content: Container(
                                          height: 350,
                                          width: 350,
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.vertical,
                                            child: Column(
                                              children: [
                                                Text("${DateFormat.yMMMMd().add_jms().format(ticket.timeCreatedAsDate!)}", textAlign: TextAlign.center),
                                                Text("${ticket.codeAndNumber} | ${ticket.serviceType}", style: TextStyle(fontSize: 20), textAlign: TextAlign.center),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    statusColorHandler(ticket.status!),
                                                    Text(" | Priority: ${ticket.priorityType}"),
                                                  ],
                                                ),
                                                Text("Time Taken: ${ticket.timeTaken ?? "None"}"),
                                                Text("Gender: ${ticket.gender ?? "None"}"),
                                                SizedBox(height: 5),
                                                Divider(),
                                                SizedBox(height: 5),
                                                Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Text("Ticket Log:")),
                                                SizedBox(height: 5),
                                                Text("${ticket.log!.replaceAll(', ', '\n')}")
                                              ],
                                            ),
                                          ),
                                        )
                                      ));
                                    },
                                  );
                                }),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        )
      ],
    );
  }

  createExcel(List<Ticket> tickets) async {
    loadWidget();

    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];

    String? dateXlsx;
    String? usersXlsx;
    String? serviceTypesXlsx;
    String? prioritiesXlsx;
    String? statusesXlsx;
    String? gendersXlsx;

    if (displayDate != null) dateXlsx = "${DateFormat.yMMMMd().format(dates[0])} - ${DateFormat.yMMMMd().format(dates[1])}"; else dateXlsx = "${DateFormat.yMMMMd().format(dates[0])}";
    if (displayUsers != null) usersXlsx = users.join(', '); else usersXlsx = "All";
    if (displayServiceTypes != null) serviceTypesXlsx = serviceTypes.join(', '); else serviceTypesXlsx = "All";
    if (displayPriorities != null) prioritiesXlsx = priorities.join(', '); else prioritiesXlsx = "All";
    if (displayStatus != null) statusesXlsx = statuses.join(', '); else statusesXlsx = "All";
    if (displayGender != null) gendersXlsx = genders.join(', '); else gendersXlsx = "All";

    sheet.appendRow([
      TextCellValue('Office of the Ombusdman')
    ]);
    sheet.appendRow([
      TextCellValue('Davao City, Philippines')
    ]);
    sheet.appendRow([
      TextCellValue('Queueing App Report')
    ]);
    sheet.appendRow([
      TextCellValue('Queueing App Report')
    ]);
    sheet.appendRow([
      TextCellValue('')
    ]);
    sheet.appendRow([
      TextCellValue('Summary Report:')
    ]);
    sheet.appendRow([
      TextCellValue("Date: $dateXlsx"),
      TextCellValue("Users: $usersXlsx"),
      TextCellValue("Services: $serviceTypesXlsx"),
      TextCellValue("Priority: $prioritiesXlsx"),
      TextCellValue("Status: $statusesXlsx"),
      TextCellValue("Status: $gendersXlsx"),
    ]);

    sheet.appendRow([
      TextCellValue('')
    ]);
    sheet.appendRow([
      TextCellValue('Detailed Report:')
    ]);
    sheet.appendRow([
      TextCellValue('#'),
      TextCellValue('Date'),
      TextCellValue('Code'),
      TextCellValue('User'),
      TextCellValue('Service'),
      TextCellValue('Priority'),
      TextCellValue('Status'),
      TextCellValue('Gender'),
    ]);

    for (int i = 0; i < tickets.length; i++) {
      sheet.appendRow([
        IntCellValue(i+1),
        TextCellValue(DateFormat.yMMMMd().format(tickets[i].timeCreatedAsDate!)),
        TextCellValue(tickets[i].codeAndNumber!),
        TextCellValue(tickets[i].userAssigned!),
        TextCellValue(tickets[i].serviceType!),
        TextCellValue(tickets[i].priorityType!),
        TextCellValue(tickets[i].status!),
        TextCellValue(tickets[i].gender!)
      ]
      );
    }


    if (kIsWeb) {
      var fileBytes = excel.save(fileName: 'OMBReport_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      Navigator.pop(context);
    } else {
      var fileBytes = excel.save();
      var directory = await getApplicationDocumentsDirectory();

      File(p.join('$directory/OMBReport_${DateTime.now().millisecondsSinceEpoch}.xlsx'))
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes!);
      Navigator.pop(context);
    }
  }

  createPDF(String size, List<Ticket> tickets) async {
   loadWidget();

    final pdf = pw.Document();
    PdfPageFormat? pageFormat;

    final img = await rootBundle.load('assets/images/logo.png');
    final imageBytes = img.buffer.asUint8List();
    pw.Image logoImage = pw.Image(pw.MemoryImage(imageBytes));

    if (size == 'A4') pageFormat = PdfPageFormat.a4;
    if (size == 'Letter') pageFormat = PdfPageFormat.letter;
    if (size == '8.5 x 13') pageFormat = PdfPageFormat(612, 936);

    String datePdf = "Today";
    String usersPdf = "All";
    String serviceTypesPdf = "All";
    String prioritiesPdf = "All";
    String statusesPdf = "All";
   String gendersPdf = "All";

    List<pw.Widget> widgets = [];


    contain(pw.Widget widget) {
      return pw.Container(
          height: 30,
          width: 60,
          child: widget
      );
    }

    center(pw.Widget widget){
      return pw.Center(
        child: widget
      );
    }

    final bold = pw.TextStyle(fontWeight: pw.FontWeight.bold);

    if (displayDate != null) datePdf = "${DateFormat.yMMMMd().format(dates[0])} - ${DateFormat.yMMMMd().format(dates[1])}"; else datePdf = "${DateFormat.yMMMMd().format(dates[0])}";
    if (displayUsers != null) usersPdf = users.join(', '); else usersPdf = "All";
    if (displayServiceTypes != null) serviceTypesPdf = serviceTypes.join(', '); else serviceTypesPdf = "All";
    if (displayPriorities != null) prioritiesPdf = priorities.join(', '); else prioritiesPdf = "All";
    if (displayStatus != null) statusesPdf = statuses.join(', '); else statusesPdf = "All";
   if (displayGender != null) gendersPdf = genders.join(', '); else gendersPdf = "All";


    widgets.addAll([
        pw.Column(
          children: [
            pw.Container(
                height: 50,
                child: logoImage
            ),
            pw.SizedBox(height: 10),
            pw.Text("Office of the Ombudsman", style: bold),
            pw.Text("Davao City, Philippines", style: bold),
            pw.Text("Queueing App Report", style: bold),
            pw.SizedBox(height: 10),


            pw.Column(
                children: [
                  pw.Row(
                      children: [
                        pw.Text("Summary Report", style: bold),
                        pw.SizedBox(width: 5),
                        pw.Expanded(
                            child: pw.Divider()
                        )
                      ]
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                      children: [
                        pw.Text(datePdf),
                      ]
                  ),
                  pw.Row(
                      children: [
                        pw.Text("Users: "),
                        pw.Text(usersPdf),
                      ]
                  ),
                  pw.Row(
                      children: [
                        pw.Text("Services: "),
                        pw.Text(serviceTypesPdf),
                      ]
                  ),
                  pw.Row(
                      children: [
                        pw.Text("Priority: "),
                        pw.Text(prioritiesPdf),
                      ]
                  ),
                  pw.Row(
                      children: [
                        pw.Text("Status: "),
                        pw.Text(statusesPdf),
                      ]
                  ),
                  pw.Row(
                      children: [
                        pw.Text("Gender: "),
                        pw.Text(gendersPdf),
                      ]
                  ),
                  pw.Row(
                      children: [
                        pw.Text("Total Tickets: ${tickets.length}")
                      ]
                  )
                ]
            ),
            pw.SizedBox(height: 5),
            pw.Row(
                children: [
                  pw.Text("Detailed Report", style: bold),
                  pw.SizedBox(width: 5),
                  pw.Expanded(
                      child: pw.Divider()
                  )
                ]
            ),
            pw.SizedBox(height: 5),
            pw.SizedBox(height: 5),
            pw.Row(
                children: [
                  center(pw.Text("#  Date", style: bold)),
                  pw.Spacer(),
                  center(pw.Text("Code", style: bold)),
                  pw.Spacer(),
                  center(pw.Text("User Assigned", style: bold)),
                  pw.Spacer(),
                  center(pw.Text("Service", style: bold)),
                  pw.Spacer(),
                  center(pw.Text("Priority", style: bold)),
                  pw.Spacer(),
                  center(pw.Text("Status", style: bold)),
                  pw.Spacer(),
                  center(pw.Text("Gender", style: bold)),
                ]
            ),
            pw.SizedBox(height: 5),
          ],
        )
      ]);

    for (int i = 0; i < tickets.length; i++) {
      widgets.add(
          pw.Column(
            children: [
              pw.Row(
                  children: [
                    pw.Container(
                      height: 30,
                      child: pw.Text("${i+1}", style: pw.TextStyle(fontSize: 8))
                    ),
                    pw.SizedBox(width: 5),
                    contain(pw.Text(DateFormat.yMMMMd().add_jms().format(tickets[i].timeCreatedAsDate!), style: pw.TextStyle(fontSize: 9))),
                    pw.Spacer(),
                    contain(pw.Text(tickets[i].codeAndNumber!.length > 20 ? "${tickets[i].codeAndNumber!.substring(0, 20).toString()}..." : tickets[i].codeAndNumber!)),
                    pw.Spacer(),
                    contain(pw.Text(tickets[i].userAssigned!.length > 20 ? "${tickets[i].userAssigned!.substring(0, 20).toString()}..." : tickets[i].userAssigned!)),
                    pw.Spacer(),
                    contain(pw.Text(tickets[i].serviceType!.length > 20 ? "${tickets[i].serviceType!.substring(0, 20).toString()}..." : tickets[i].serviceType!, style: pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.left, overflow: pw.TextOverflow.clip)),
                    pw.Spacer(),
                    contain(pw.Text(tickets[i].priorityType!)),
                    pw.Spacer(),
                    contain(pw.Text(tickets[i].status!)),
                    pw.Spacer(),
                    contain(pw.Text(tickets[i].gender!))
                  ]),
              pw.SizedBox(height: 1),
            ]
          )
      );
    }


    pdf.addPage(
        pw.MultiPage(
          margin: pw.EdgeInsets.all(30),
        pageFormat: pageFormat ?? PdfPageFormat.a4,
        build: (pw.Context context) {
          return widgets; // Center
        }));

    if (!kIsWeb) {
      final file = File("OMBMindanaoQueueReport_${DateTime.now().millisecondsSinceEpoch}");
      await file.writeAsBytes(await pdf.save());
      Navigator.pop(context);

    } else {
      var savedFile = await pdf.save();
      Navigator.pop(context);
      List<int> fileInts = List.from(savedFile);
      web.AnchorElement()
        ..href = "data:application/octet-stream;charset=utf-16le;base64,${base64.encode(fileInts)}"
        ..setAttribute("download", "OMBMindanaoQueueReport_${DateTime.now().millisecondsSinceEpoch}.pdf")
        ..click();
    }
  }


  loadWidget() {
    return showDialog(context: context, builder: (_) => AlertDialog(
        content: Container(
          height: 100,
          width: 100,
          child: Center(
            child: Container(
                height: 50,
                width: 50,
                child: CircularProgressIndicator()
            ),
          ),
        )
    ));
  }

  statusColorHandler(String status)  {
    Color? color;
    if (status == 'Done') color = Colors.blueGrey;
    if (status == 'Pending') color = Colors.orangeAccent;
    if (status == 'Serving') color = Colors.green;
    if (status == 'Released') color = Colors.red;
    return Text(status,style: TextStyle(color: color));

  }

  //endregion

}
