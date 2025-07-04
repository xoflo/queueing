import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
  String? displayDate;

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

  @override
  void dispose() {
    dispose();
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
                                        Spacer(),
                                        control.controlName! == "Video in Queue Display" ? TextButton(onPressed: () async {
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

                                                        final response = await request.send();
                                                        addMedia(file.name, file.name);
                                                        setStateList((){});
                                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${file.name} added to videos")));


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
                                        control.controlName! == "Sliding Text" ? TextButton(onPressed: () {
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
                      lastAssigned.isNotEmpty ? Container(
                        height: 30,
                        child: IconButton(onPressed: () {
                          assignedGroups = lastAssigned.last;
                          lastAssigned.removeLast();
                          setStateList((){});
                        }, icon: Icon(Icons.chevron_left)),
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
                        controller: serviceType,
                        decoration: InputDecoration(
                          labelText: 'Service Type',
                        ),
                      )),
                      Container(
                          child: TextField(
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
                            service!.update({
                              'serviceType': serviceType.text,
                              'serviceCode': serviceCode.text,
                            });

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text("Service Updated")));
                            setState(() {});
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
                future: getUserSQL(),
                builder: (BuildContext context,
                    AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                  return snapshot.connectionState == ConnectionState.done
                      ? snapshot.data!.isNotEmpty
                      ? Container(
                    padding: EdgeInsets.all(10),
                    height: 400,
                    child: ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, i) {
                          final user = User.fromJson(snapshot.data![i]);

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
                                      TextButton(onPressed: () {
                                        if (oldPassController.text != user.pass) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Current Password does not match.")));
                                        } else {
                                          user.update({
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

                                showDialog(context: context, builder: (_) => AlertDialog(
                                  title: Text("Edit User"),
                                  content: Container(
                                    height: 200,
                                    width: 200,
                                    child: Column(
                                      children: [
                                        ListTile(
                                          title: Text("Username and Password"),
                                          onTap: () {
                                            Navigator.pop(context);
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
                                                  TextButton(onPressed: () {
                                                    user.update({
                                                      'username': userController.text,
                                                      'pass': userController.text
                                                    });

                                                    Navigator.pop(context);
                                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User updated")));
                                                    setStateView((){});
                                                  }, child: Text("Update"))
                                                ],
                                              );
                                            }));
                                          },
                                        ),
                                        ListTile(
                                          title: Text("Assigned Services"),
                                          onTap: () {
                                            Navigator.pop(context);
                                            showDialog(context: context, builder: (_) => Builder(
                                                builder: (context) {
                                                  List<String> services = stringToList(user.serviceType.toString());

                                                  return AlertDialog(
                                                    title: Text("Assign Service Types"),
                                                    content: Container(
                                                      height: 400,
                                                      width: 400,
                                                      child: FutureBuilder(
                                                          future: getServiceSQL(),
                                                          builder: (context, AsyncSnapshot<List<Service>> snapshot) {
                                                            return StatefulBuilder(
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
                                                        final servicesSetToAdd = services.length > 3 ? services.sublist(0, 3).toString() : services.toString();
                                                        await user.update({
                                                          'id': user.id!,
                                                          'serviceType': services.toString(),
                                                          'servicesSet': servicesSetToAdd
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
    String userType = "Staff";
    String display = "Select";

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text('Add User'),
              content: StatefulBuilder(
                builder: (BuildContext context,
                    void Function(void Function()) setStateDialog) {
                  return Container(
                    height: 220,
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
                        userType == 'Staff'
                            ? Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: ListTile(
                                    title: Text("Service Type: $display"),
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
                                                              builder: (BuildContext
                                                                      context,
                                                                  void Function(
                                                                          void
                                                                              Function())
                                                                      setStateList) {
                                                                return ListView
                                                                    .builder(
                                                                        itemCount: snapshot
                                                                            .data!
                                                                            .length,
                                                                        itemBuilder:
                                                                            (context,
                                                                                i) {
                                                                          final user = snapshot.data![i];
                                                                          return CheckboxListTile(
                                                                              title: Text(user.serviceType!),
                                                                              value: services.contains(user.serviceType!),
                                                                              onChanged: (value) {
                                                                                if (value == true) {
                                                                                  services.add(user.serviceType!);
                                                                                } else {
                                                                                  services.remove(user.serviceType!);
                                                                                }
                                                                                setStateList(() {});
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
                                                        display =
                                                            services.length == 1 ? services.first : "${services.length} Services";
                                                        Navigator.pop(context);
                                                        setStateDialog(() {});
                                                      },
                                                      child: Text("Confirm"))
                                                ],
                                              ));
                                    }),
                              )
                            : Container(
                                height: 20,
                              ),
                        /*
                        Row(
                          spacing: 5,
                          children: [
                            /*
                            GestureDetector(
                                onTap: () {
                                  userType = "Admin";
                                  setStateDialog(() {});
                                },
                                child: Container(
                                  height: 50,
                                  width: 100,
                                  child: Card(
                                    child: Center(
                                      child: Text("Admin"),
                                    ),
                                    color: userType == "Admin"
                                        ? Colors.redAccent
                                        : Colors.white,
                                  ),
                                )),
                             */
                            GestureDetector(
                                onTap: () {
                                  userType = "Staff";
                                  setStateDialog(() {});
                                },
                                child: Container(
                                  height: 50,
                                  width: 100,
                                  child: Card(
                                    child: Center(
                                      child: Text("Staff"),
                                    ),
                                    color: userType == "Staff"
                                        ? Colors.redAccent
                                        : Colors.white,
                                  ),
                                ))
                          ],
                        )
                         */
                      ],
                    ),
                  );
                },
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      try {
                        addUserSQL(services, userType);
                      } catch (e) {
                        print(e);
                      }
                      clearUserFields();
                    },
                    child: Text("Add User"))
              ],
            ));
  }

  addUserSQL(List<String> services, String userType) async {
    try {
      final uri = Uri.parse('http://$site/queueing_api/api_user.php');
      final body = jsonEncode({
        "username": user.text,
        "pass": password.text,
        "serviceType": services.toString(),
        "userType": userType,
        "loggedIn": null,
        "servicesSet": services.length > 3 ? "[${services[0]}, ${services[1]}, ${services[2]}]" : services.toString()
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
    return Container(
      child: Column(
        children: [
          Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                  onPressed: () {
                    addStation();
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
                          height: 400,
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
                                  trailing: IconButton(
                                      onPressed: () {
                                        if (station.inSession != 1) {
                                          deleteStation(station.id!);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Station must be inactive to delete.")));
                                        }
                                      },
                                      icon: Icon(Icons.delete)),
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
      ),
    );
  }

  getStationSQL() async {
    try {
      final uri = Uri.parse('http://$site/queueing_api/api_station.php');
      final result = await http.get(uri);
      final response = jsonDecode(result.body);
      response.sort((a, b) => int.parse(a['id'].toString())
          .compareTo(int.parse(b['id'].toString())));
      return response;
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Cannot connect to the server. Please try again.")));
      print(e);
      return [];
    }
  }

  addStation() {
    String display = "Select";

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text('Add Station'),
              content: StatefulBuilder(
                builder: (BuildContext context,
                    void Function(void Function()) setStateDialog) {
                  return Container(
                    height: 150,
                    width: 250,
                    child: Column(
                      children: [
                        Container(
                            child: TextField(
                          controller: stationName,
                          decoration: InputDecoration(
                            labelText: 'Station Name',
                          ),
                        )),
                        Container(
                            child: TextField(
                          controller: stationNumber,
                          decoration:
                              InputDecoration(labelText: 'Station Number'),
                        )),
                      ],
                    ),
                  );
                },
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      try {
                        if (stationName.text.trim() == "") {
                          addStationSQL(display);
                          clearUserFields();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Station name cannot be empty.")));
                        }
                      } catch (e) {
                        print(e);
                      }
                    },
                    child: Text("Add Station"))
              ],
            ));
  }

  addStationSQL(String serviceType) async {
    final uri = Uri.parse('http://$site/queueing_api/api_station.php');
    final body = jsonEncode({
      "stationNumber": stationNumber.text,
      "stationName":
          "${stationName.text[0].toUpperCase() + stationName.text.substring(1).toLowerCase()}",
      "serviceType": serviceType,
      "inSession": 0,
      "userInSession": "",
      "ticketServing": "",
      "sessionPing": ""
    });

    print("serviceType: $serviceType");

    final result = await http.post(uri, body: body);
    print("result: ${result.body}");

    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Station Added")));
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

  Future<List<Ticket>> getTicketSQL() async {

    try {
      final uri = Uri.parse('http://$site/queueing_api/api_ticket.php');
      final result = await http.get(uri);
      final List<dynamic> response = jsonDecode(result.body);
      List<Ticket> newTickets = [];

      for (int i = 0; i < response.length; i++) {
        newTickets.add(Ticket.fromJson(response[i]));
      }

      if (dates.isNotEmpty) {
        newTickets = newTickets.where((e) => e.timeCreatedAsDate!.isAfter(dates![0]) && e.timeCreatedAsDate!.isBefore(dates[1])).toList();
      } else {
        newTickets = newTickets.where((e) => e.timeCreatedAsDate!.isAfter(toDateTime(DateTime.now())) && e.timeCreatedAsDate!.isBefore(toDateTime(DateTime.now()).add(Duration(days: 1)))).toList();
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
                    child: ElevatedButton(
                        child: Text(dates.isNotEmpty ? "Filter: ${displayDate}" : "Filter Tickets: Today"),
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
                        })
                ),
                FutureBuilder(
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
                    ) : snapshot.data!.isEmpty ? Center(
                      child: Text("No Archives found.", style: TextStyle(color: Colors.grey)),
                    ): Container(
                      height: MediaQuery.of(context).size.height - 200,
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
                                          Text("${DateFormat.yMMMMd().add_jms().format(ticket.timeCreatedAsDate!)}"),
                                          Text("${ticket.codeAndNumber} | ${ticket.serviceType}", style: TextStyle(fontSize: 20)),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              statusColorHandler(ticket.status!),
                                              Text(" | Priority: ${ticket.priorityType}"),
                                            ],
                                          ),
                                          Text("Time Taken: ${ticket.timeTaken ?? "None"}"),
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
                    );
                  },
                ),
              ],
            );
          },
        )
      ],
    );
  }

  statusColorHandler(String status)  {
    Color? color;

    if (status == 'Done') color = Colors.blueGrey;
    if (status == 'Pending') color = Colors.yellow;
    if (status == 'Serving') color = Colors.green;
    if (status == 'Dismissed') color = Colors.orange;

    return Text(status,style: TextStyle(color: color));

  }

}
