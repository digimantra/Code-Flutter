import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:Involvvely/common/colors.dart';
import 'package:Involvvely/common/common_urls.dart';
import 'package:Involvvely/common/general_dailogue.dart';
import 'package:Involvvely/common/toast_message.dart';
import 'package:Involvvely/common/wait_loader.dart';
import 'package:Involvvely/screens/parent/schedule/ScheduleListData.dart';
import 'package:Involvvely/screens/parent/schedule/TaskListData.dart';
import 'package:Involvvely/screens/parent/schedule/TaskListModel.dart';
import 'package:Involvvely/screens/parent/schedule/create_task.dart';
import 'package:Involvvely/screens/parent/schedule/parentTask_list_model.dart';
import 'package:Involvvely/screens/parent/schedule/schedule_description.dart';
import 'package:Involvvely/screens/parent/schedule/task_description.dart';
import 'package:Involvvely/utils/Constants.dart';
import 'package:async/async.dart';
import 'package:cross_connectivity/cross_connectivity.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pusher_websocket_flutter/pusher.dart';

class TaskList extends StatefulWidget {
  dynamic ScheduleId, AdminId, isScheduleAccept,ishandover;
  final List<dynamic> selectedDaysList;
  List<dynamic> assignedtolist;
  String startTime, endTime;

  TaskList({
    Key key,
    @required this.ScheduleId,
    @required this.ishandover,
    @required this.AdminId,
    @required this.isScheduleAccept,
    @required this.assignedtolist,
    @required this.selectedDaysList,
    @required this.startTime,
    @required this.endTime,
  }) : super(key: key);

  @override
  _TaskListState createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  double height;
  double width;
  bool isLoading = false;
  Channel _taskChanel,declinecannel, _completeChanel;
  TaskListModel getTaskListModel;
  List<TaskListData> ScheduleList = [];
  String taskId;
  bool needtoupdate = false;
  var snackBar;
  Timer timer;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    _initPusher();

    // *** initialise SnackBar Listener ***//
    snackBar = SnackBar(
      duration: Duration(hours: 12),
      content: Text('Please check your internet connection'),
      action: SnackBarAction(
        label: 'Refresh',
        onPressed: () {
          if (isconnected) {
            getTaskList();
          } else {
            _scaffoldKey.currentState.showSnackBar(snackBar);
          }
        },
      ),
    );

    // *** initialise connectivity Listener ***//
    Connectivity().onConnectivityChanged.listen((event) {
      if (event != ConnectivityStatus.none &&
          event != ConnectivityStatus.unknown) {
        if (ScheduleList.isEmpty) {
          getTaskList();
        }
        _scaffoldKey.currentState.removeCurrentSnackBar();
      } else {
        _scaffoldKey.currentState.showSnackBar(snackBar);
      }
    });
    super.initState();
  }

  // *** function to get task(Api Call request) ***//
  getTaskList() async {
    setState(() {
      isLoading = true;
    });
    final Map<String, String> map = {
      "user_id": user.data.id.toString(),
      "schedule_id": widget.ScheduleId,
      //  'token':user.data.token
    };
    final response = await http.post(Uri.parse(schedule_task_List), body: map);
    if (response.statusCode == 200) {
      setState(() {
        isLoading = false;
      });
      var res = json.decode(response.body);
      getTaskListModel = TaskListModel.fromJson(res);
      if(getTaskListModel.error){
        print(getTaskListModel.message);

      }else{
        setState(() {
          ScheduleList = getTaskListModel.data ?? [];
        });
      }

      return GetTaskListResponse.fromJson(json.decode(response.body));
    } else {
      setState(() {
        isLoading = false;
      });
      print(response.statusCode);
      throw Exception('Failed to load task');
    }
  }

  // *** task list ***//
  Expanded taskVerticalList(List<TaskListData> scheduleList) {
    return Expanded(
        child: scheduleList.isEmpty
            ? Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Text("No Tasks.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: darkgrey,
                      fontSize: 16,
                    )),
              )
            ],
          ),
        )
            : Container(
          margin: EdgeInsets.only(
              bottom:
              user.data.id.toString() == widget.AdminId ? 150 : 5),
          child: ListView.builder(
            padding: const EdgeInsets.only(
                left: 5, right: 5, top: 0, bottom: 5),
            physics: const BouncingScrollPhysics(),
            itemCount: scheduleList.length,
            itemBuilder: (con, index) {
              return Column(children: <Widget>[
                InkWell(
                  onTap: () async {
                    if (isconnected) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => TaskDescription(
                                  taskId:
                                  scheduleList[index].id.toString(),
                                  taskList: scheduleList))).then((value) {
                        setState(() {
                          if (isconnected) {
                            getTaskList();
                          } else {
                            _scaffoldKey.currentState
                                .showSnackBar(snackBar);
                          }
                        });
                      });
                    }
                  },
                  child: Container(
                      padding: EdgeInsets.all(0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                title: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      scheduleList[index].taskName,
                                      style: TextStyle(
                                          color: black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    SizedBox(
                                      height: 5,
                                    )
                                  ],
                                ),
                                trailing:
                                /* IconButton(
                                        icon:*/
                                Padding(
                                  padding:
                                  const EdgeInsets.only(top: 10.0),
                                  child: Image.asset(
                                    "images/arrow.png",
                                    height: 30,
                                    width: 30,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                            "Assigned By : " +
                                                " " +
                                                scheduleList[index]
                                                    .user
                                                    .name,
                                            style: TextStyle(
                                                color: black,
                                                fontSize: 14,
                                                fontWeight:
                                                FontWeight.w400,
                                                fontFamily: "Rubik")),
                                      ],
                                    ),
                                    scheduleList[index]
                                        .isComplete
                                        .toString() ==
                                        "1"
                                        ? Container(
                                      padding: EdgeInsets.only(
                                          left: 8,
                                          top: 3,
                                          bottom: 3,
                                          right: 8),
                                      margin: EdgeInsets.only(
                                          left: 0,
                                          top: 10,
                                          bottom: 10,
                                          right: 15),
                                      constraints: BoxConstraints(
                                          minWidth: 70,
                                          maxHeight: 75),
                                      decoration: BoxDecoration(
                                          borderRadius:
                                          BorderRadius.circular(
                                              20),
                                          color: Color(0xffFFAD33)),
                                      child: Text(
                                        "Completed",
                                        style: TextStyle(
                                            color: Colors.white),
                                      ),
                                    )
                                        : Container(
                                      padding: EdgeInsets.only(
                                          left: 8,
                                          top: 3,
                                          bottom: 3,
                                          right: 8),
                                      margin: EdgeInsets.only(
                                          left: 0,
                                          top: 10,
                                          bottom: 10,
                                          right: 15),
                                      constraints: BoxConstraints(
                                          minWidth: 70,
                                          maxHeight: 75),
                                      decoration: BoxDecoration(
                                          borderRadius:
                                          BorderRadius.circular(
                                              20),
                                          color: Color(0xff4ECB5F)),
                                      child: Text(
                                        "Pending",
                                        style: TextStyle(
                                            color: Colors.white),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ]),
                      )),
                )
              ]);
            },
          ),
        ));
  }

  // *** Notify Parent Api Call ***//
  NotifyParentApiCall(String scheduleId) async {
    setState(() {
      isLoading = true;
    });

    var map = {
      "schedule_id": scheduleId,
    };

    final response = await http.post(Uri.parse(notifyParent), body: map);
    var responseBody = json.decode(response.body);

    if (responseBody["error"]) {
      setState(() {
        isLoading = false;
      });
      return mShowGeneralDialog(context,
          content: responseBody["message"], callback: () {});
    } else {
      setState(() {
        isLoading = false;
        widget.ishandover="1";
      });
      return mShowGeneralDialog(context,
          content: "Schedule has been handed over successfully.", callback: () {

          });
    }
  }

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Center(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ScheduleDescription(
                              ScheduleId: widget.ScheduleId.toString(),
                            ))).then((value) {
                      setState(() {
                        if (isconnected) {
                          getTaskList();
                        } else {
                          _scaffoldKey.currentState.showSnackBar(snackBar);
                        }
                      });
                    });
                  },
                  child: Text("View details",
                      style: TextStyle(
                          fontFamily: "Rubik",
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                          fontSize: 16)),
                ),
              ))
        ],
        iconTheme: new IconThemeData(color: white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[gradientFirstColor, gradientEndColor])),
        ),
        title: Text(
          "Tasks",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      key: _scaffoldKey,
      body: Stack(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                taskVerticalList(ScheduleList),
              ],
            ),
          ),
          user.data.id.toString() == widget.AdminId
              ? Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                    width: width * 0.90,
                    height: 50,
                    decoration: BoxDecoration(
                        borderRadius:
                        BorderRadius.all(Radius.circular(10)),
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              gradientFirstColor,
                              gradientEndColor
                            ])),
                    margin: const EdgeInsets.only(
                        top: 10, left: 15, right: 15, bottom: 10),
                    child: InkWell(
                        onTap: () {
                          if (isconnected) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        CreateTaskScreen(
                                          scheduleId: widget.ScheduleId,
                                          selectedDaysList:
                                          widget.selectedDaysList,
                                          assignTo: widget.assignedtolist,
                                          startTime: widget.startTime,
                                          endTime: widget.endTime,
                                          isFromtasklist: 1,
                                        ))).then((value) {
                              setState(() {
                                if (isconnected) {
                                  getTaskList();
                                } else {
                                  _scaffoldKey.currentState
                                      .showSnackBar(snackBar);
                                }
                              });
                            });
                          }
                        },
                        child: Center(
                          child: Text("Create New Task",
                              style: TextStyle(
                                  fontFamily: "Rubik",
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 17)),
                        ))),
                ScheduleList.isEmpty || widget.ishandover=="1"
                    ? Container()
                    : Container(
                    width: width * 0.90,
                    height: 50,
                    decoration: BoxDecoration(
                        borderRadius:
                        BorderRadius.all(Radius.circular(10)),
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              gradientFirstColor,
                              gradientEndColor
                            ])),
                    margin: const EdgeInsets.only(
                        top: 10, left: 15, right: 15, bottom: 10),
                    child: InkWell(
                        onTap: () {
                          if (commentMethod.checkInternet()) {
                            if (ScheduleList.length == 0) {
                              showToastMsg(
                                  "There are no task to notify");
                            } else {
                              NotifyParentApiCall(widget.ScheduleId);
                            }

                          }
                        },
                        child: Center(
                          child: Text("Handover Schedule",
                              style: TextStyle(
                                  fontFamily: "Rubik",
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 17)),
                        ))),
              ],
            ),
          )
              : Container(),
          isLoading ? WaitLoader() : Container()
        ],
      ),
    );
  }
  //*** initialise snd subscribe the pusher event.   ***//
  Future<void> _initPusher() async {
    declinecannel = await Pusher.subscribe("decline-channel");
    declinecannel.bind('decline_schedule', (onEvent) {
      if (mounted) {
        final data = json.decode(onEvent.data);
        print(data);
        setState(() {
          widget.ishandover ="0";
        });



      }});
    _taskChanel = await Pusher.subscribe("task-channel");

    _taskChanel = await Pusher.subscribe("task-channel");
    _taskChanel.bind('task_add', (onEvent) {
      if (mounted) {
        final data = json.decode(onEvent.data);
        print(data);
        TaskListData model = TaskListData.fromJson(data);

        if (widget.ScheduleId.toString() == model.scheduleId.toString()) {
          if (user.data.id.toString() == model.task_assigned_to.toString()) {
            setState(() {
              ScheduleList.insert(0, model);
            });
          }
        }
      }
    });
    _taskChanel.bind('complete_task', (onEvent) {
      if (mounted) {
        final data = json.decode(onEvent.data);
        String scheduleId = data["schedule_id"].toString();
        String taskId = data["task_id"].toString();

        if (widget.ScheduleId == scheduleId) {
          for (int i = 0; i < ScheduleList.length; i++) {
            if (taskId == ScheduleList[i].id.toString()) {
              setState(() {
                ScheduleList[i].isComplete = 1;
              });
            }
          }
        }
      }
    });

    _taskChanel = await Pusher.subscribe("remove-channel");
    _taskChanel.bind('remove_task', (onEvent) {
      if (mounted) {
        final data = json.decode(onEvent.data);
        print(data);
        TaskListData model = TaskListData.fromJson(data);
        for (int i = 0; i < ScheduleList.length; i++) {
          if (model.id.toString() == ScheduleList[i].id.toString()) {
            setState(() {
              ScheduleList.removeAt(i);
            });
          }
        }
      }
    });
  }
}

//***  Custom Dialog picker  ***///
class CustomPickerDialog extends StatefulWidget {
  String taskId;
  int Index;
  List<TaskListData> Mainlist;

  CustomPickerDialog(
      {Key key,
        @required this.taskId,
        @required this.Index,
        @required this.Mainlist})
      : super(key: key);

  @override
  _CustomPickerDialogState createState() => _CustomPickerDialogState();
}

class _CustomPickerDialogState extends State<CustomPickerDialog> {
  bool hidefile = false;
  List<File> doc_files = [];
  List<File> files = [];
  bool autoValidate = false;
  TextEditingController groupdes_controler = TextEditingController();
  String groupdes = "";
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: transparentColor,
        body: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: (SingleChildScrollView(
                child: Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 10.0,
                            bottom: 10,
                          ),
                          child: Text(
                            "Enter Details For Completion(Optional)",
                            style: TextStyle(
                                fontFamily: "Rubik",
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                decoration: TextDecoration.none),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 10.0,
                            bottom: 10,
                          ),
                          child: Text(
                            "Upload Image",
                            style: TextStyle(
                                fontFamily: "Rubik",
                                color: Colors.black,
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                                decoration: TextDecoration.none),
                          ),
                        ),
                      ),
                      DottedBorder(
                          radius: const Radius.circular(5),
                          borderType: BorderType.RRect,
                          dashPattern: const [5, 5],
                          child: Container(
                            height: 120,
                            width: MediaQuery.of(context).size.width - 15,
                            color: blueDivderColor,
                            child: doc_files.length == 0 ||
                                doc_files == null ||
                                hidefile == true
                                ? Center(
                              child: InkWell(
                                  onTap: () {
                                    showFilePicker();
                                  },
                                  child: Image.asset(
                                    "images/upload.png",
                                    height: 30,
                                    width: 30,
                                  )),
                            )
                                : Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        showFilePicker();
                                      },
                                      child: Image.asset(
                                        "images/upload.png",
                                        height: 30,
                                        width: 30,
                                      ),
                                    )),
                                Expanded(
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: doc_files.length,
                                    itemBuilder: (context, index) {
                                      return Stack(
                                        alignment: Alignment.topRight,
                                        children: [
                                          Container(
                                            margin: EdgeInsets.all(5),
                                            width: 50,
                                            height: 700,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                              BorderRadius.circular(10),
                                              image: DecorationImage(
                                                fit: BoxFit.fill,
                                                image: FileImage(
                                                  doc_files[index],
                                                ),
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                if (doc_files.length == 1) {
                                                  hidefile = true;
                                                  doc_files.removeAt(index);
                                                } else {
                                                  doc_files.removeAt(index);
                                                }
                                              });
                                            },
                                            child: const CircleAvatar(
                                              backgroundColor:
                                              gradientFirstColor,
                                              radius: 10,
                                              child: Text(
                                                "x",
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          )
                                        ],
                                      );
                                    },
                                  ),
                                )
                              ],
                            ),
                          )),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 20.0,
                            bottom: 10,
                          ),
                          child: Text(
                            "Note",
                            style: TextStyle(
                              fontFamily: "Rubik",
                              color: Colors.black,
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        child: TextFormField(
                          autofocus: false,
                          maxLines: 4,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(150),
                          ],
                          controller: groupdes_controler,
                          onChanged: (value) {
                            setState(() {
                              groupdes = value.trim();
                            });
                          },
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            fillColor: Colors.grey[200],
                            filled: true,
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 10.0),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: () {
                              accept_and_rejectTask(
                                  context,
                                  doc_files,
                                  user.data.id.toString(),
                                  widget.taskId,
                                  "3",
                                  groupdes.trim(),
                                  widget.Index);
                            },
                            child: Container(
                              height: 50.0,
                              width: 100,
                              margin: EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [gradientFirstColor, gradientEndColor]),
                                borderRadius: new BorderRadius.circular(10.0),
                              ),
                              child: new Center(
                                child: new Text(
                                  'Submit',
                                  style: new TextStyle(
                                      fontFamily: "Rubik",
                                      fontWeight: FontWeight.w400,
                                      fontSize: 16.0,
                                      color: white),
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Container(
                              height: 50.0,
                              width: 100,
                              margin: EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [gradientFirstColor, gradientEndColor]),
                                borderRadius: new BorderRadius.circular(10.0),
                              ),
                              child: new Center(
                                child: new Text(
                                  'Cancel',
                                  style: new TextStyle(
                                      fontFamily: "Rubik",
                                      fontWeight: FontWeight.w400,
                                      fontSize: 16.0,
                                      color: white),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                      SizedBox(
                        height: 30,
                      ),
                    ],
                  ),
                ))),
            // ),
          ),
        ));
  }

  //*** function to Accept and Reject the task ***//
  Future<String> accept_and_rejectTask(
      BuildContext context,
      List files,
      String userid,
      String taskId,
      String accept_reject,
      String notes,
      int index) async {


    print("task id   :::" + taskId);
    commentMethod.showLoaderDialog(context);
// create multipart request
    var request = new http.MultipartRequest("POST", Uri.parse(acceptRejectask));

    for (var file in files) {
      String fileName = file.path.split("/").last;
      var stream = new http.ByteStream(DelegatingStream.typed(file.openRead()));

      // get file length

      var length = await file.length(); //imageFile is your image file

      // multipart that takes file
      var multipartFileSign =
      new http.MultipartFile('image[]', stream, length, filename: fileName);

      request.files.add(multipartFileSign);
    }
    commentMethod.checknetmethod(context);

    Map<String, String> headers = {
      "Accept": "application/json",
      // "Authorization": "Bearer $value"
    }; // ignore this headers if there is no authentication

//add headers
    request.headers.addAll(headers);

//adding params
    //request.fields['post_name'] = postname;
    request.fields['task_id'] = taskId;
    request.fields['accept_reject'] = accept_reject;
    request.fields['parent_id'] = userid;
    request.fields['notes'] = notes.trim();
    //  request.fields['token'] = user.data.token;

// send
    var response = await request.send();

    print(response.statusCode);

    if (response.statusCode == 200) {
      Navigator.pop(context);
      Navigator.pop(context);
      setState(() {
        widget.Mainlist[index].isComplete = 1;
      });
      doc_files.clear();
      response.stream.transform(utf8.decoder).listen((value) {

        print(value);
      });
    } else {
      doc_files.clear();
      setState(() {
        widget.Mainlist[index].isComplete = 0;
      });
      Navigator.pop(context);
      showToastMsg("Something went wrong");
    }

  }

  //*** function to pick file ***//
  showFilePicker() async {
    setState(() {
      hidefile = false;
    });
    files.clear();

    FilePickerResult result = await FilePicker.platform
        .pickFiles(type: FileType.image, allowMultiple: true);
    print("result-----" + result.toString());
    if (result != null) {
      // Navigator.pop(context);
      setState(() {
        result.paths.forEach((e) => files.add(File(e)));
        print("filessssss ---------" + files.toString());
        //doc_files.addAll(result.paths.map((e) => File(e)).toList());
        if (doc_files.length > 7) {
          showToastMsg("You can upload only 7 files at a time");
        } else if (doc_files.length < 7) {
          if (files.length > 7) {
            showToastMsg("You can upload only 7 files at a time");
            int val1 = (7 - doc_files.length);
            for (int i = 0; i < val1.toInt(); i++) {
              doc_files.add(files[i]);
              print("count yyyyyy ${i} ");
            }
          } else {
            if ((files.length + doc_files.length) > 7) {
              int val2 = (7 - doc_files.length);
              for (int i = 0; i < val2; i++) {
                doc_files.add(files[i]);
              }
            } else {
              for (int i = 0; i < files.length; i++) {
                doc_files.add(files[i]);
              }
            }
          }
        } else {
          showToastMsg("You can upload only 7 files at a time");
        }
      });
    } else {
      if (files.length == 0) {
        setState(() {
          hidefile = true;
        });
      }

    }
  }

}
