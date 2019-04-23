import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart' as UrlLauncher;
import 'user.dart';
import 'chat.dart';
import 'main.dart';


Widget bottomBar({BuildContext context, imagePicker, User user, ChatRoom chatRoom}) {
  final textController = new TextEditingController();
  return
    Container(
      height: 55,
      color: Colors.indigoAccent,
      child: Row(

        children: <Widget>[
          IconButton(icon: Icon(Icons.image, color: Colors.white,),
              onPressed: imagePicker),

          Container(
            width: MediaQuery.of(context).size.width/1.5,
            height: 35,
            child: Transform(
              transform: Matrix4.translationValues(3, 8, 0),
              child: TextField(
                controller: textController,
                onSubmitted: (value){
                  if(value.trim().length == 0) return;
                  chatRoom.sendMessage(
                      new Message(user, Message.TEXT, value.trim())
                  );
                  textController.clear();
                },
                decoration: InputDecoration.collapsed(
                    hintText: "type your message..."
                ),
              ),
            ),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(25))
            ),
          ),
          IconButton(icon: Icon(Icons.send, color: Colors.white,), onPressed: (){
            if(textController.text.trim().length == 0) return;
            chatRoom.sendMessage(
                new Message(user, Message.TEXT, textController.text.trim())
            );
            textController.clear();
          })
        ],
      ),
    );
}

Widget messageForm(bool currentUser,User user ,Message message) {

  return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Row(
        textDirection: currentUser ? TextDirection.rtl : TextDirection.ltr,
        children: <Widget>[

          FutureBuilder(
            future: message.sender.syncData(),
            builder: (context, data) {
              if(!data.hasData) return Container();
              return CircleAvatar(
                backgroundImage: currentUser ? user.getPhoto() : message.sender.getPhoto(),
              );
            },
          ),
          Expanded(
            child: Transform(
              transform: Matrix4.translationValues(0, 20, 0),
              child: Container(
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Align(
                          alignment: AlignmentDirectional.topStart,
                          child: Text(message.sender.phoneNumber,style: TextStyle(color: Colors.blueGrey),)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Align(
                        alignment: AlignmentDirectional.topStart,
                        child: message.getContent(style:TextStyle(
                            color: Colors.white
                        )),
                      ),
                    ),
                  ],
                ),
                decoration: BoxDecoration(
                    color: currentUser ? Colors.deepPurple : Colors.purple,
                    borderRadius: BorderRadius.all(Radius.circular(20))
                ),
              ),
            ),
          ),

        ],
      )
  );
}

pickImage(User user, ChatRoom chatRoom) async {
  File image = await ImagePicker.pickImage(source: ImageSource.gallery);
  chatRoom.sendImageMessage(image);
}

class Home extends StatelessWidget {

  User user;

  Home(this.user);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return WillPopScope(
      onWillPop: () => Future.value(false),
      child: Scaffold(
          body: FutureBuilder(
              future: user.syncData(),
              builder: (context, data) {

                if(!data.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                if(data.data) {
                  return new MainPage(user);
                }else if(user.username == null){
                  return new CompletingRegisteration(user);
                }else {
                  return new FutureBuilder(future: user.createDataFields(),
                      builder: (a, b){
                    return new CompletingRegisteration(user);
                      });
                }
              }

          )
      ),
    );
  }

}

class MainPage extends StatefulWidget {

  User user;
  bool hasScaffoldFather;

  MainPage(this.user);

  @override
  State<StatefulWidget> createState() {

    return new _MainPage(user);
  }

}

class _MainPage extends State<MainPage> {

  User user;

  _MainPage(this.user);



  @override
  Widget build(BuildContext context) {

    return WillPopScope(
      onWillPop: () => Future.value(false),
      child: Scaffold(
        appBar: new AppBar(
            title: Text("weShare", style: TextStyle(fontStyle: FontStyle.italic),),
            automaticallyImplyLeading: false,
          actions: <Widget>[IconButton(icon: Icon(Icons.search), onPressed: (){
            Navigator.push(context, new MaterialPageRoute(builder: (c) => new SearchForFriend(user)));
          }),
          IconButton(icon: Icon(Icons.settings), onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (c) => UpdateProfile(user)));
          })
          ],
        ),
        body: Padding(
          padding: EdgeInsets.only(top: 20),
          child: Column(
            children: <Widget>[
              ListTile(
                title: Text("Global chat"),
                leading: Hero(
                    tag: 'global-chat-room',
                    child: CircleAvatar(backgroundImage: AssetImage("assets/icon.png"),)),
                subtitle: Text("chat with many people from around the whole world in one chat room!"),
                onTap: (){
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => new GlobalChat(user)));
                },
              ),
              Divider(),
              SizedBox(height: 5),
              FutureBuilder(
                future: user.getFriends(),
                builder: (context, snapShot) {

                  if(!snapShot.hasData) return CircularProgressIndicator();
                  if(snapShot.data.length == 0) return Padding(padding: EdgeInsets.all(15),child: Center(child: Text("no current pivate chat, search for another users to chat with.")));
                  return Expanded(
                    child: ListView.builder(
                        itemCount: snapShot.data.length,
                        itemBuilder: (context, index) {
                          User friend = snapShot.data.reversed.toList()[index]['friend'];
                          return ListTile(
                            onTap: (){
                              Navigator.push(context,
                                  new MaterialPageRoute(builder:
                                      (context) => CoupleChatPage(this.user, friend,
                                          snapShot.data.reversed.toList()[index]['roomId'])));
                            },
                            leading: Hero(
                              tag: "${friend.phoneNumber}",
                              child: CircleAvatar(
                                backgroundImage: friend.getPhoto(),
                              ),
                            ),
                            title: Text(friend.username),
                            subtitle: Text(friend.phoneNumber),
                          );
                        }

                    ),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }

}

class CompletingRegisteration extends StatefulWidget {

  User user;

  CompletingRegisteration(this.user);

  @override
  _CompletingRegisteration createState() {

    return new _CompletingRegisteration(this.user);
  }

}

class _CompletingRegisteration extends State<CompletingRegisteration> {

  User user;
  TextEditingController nameFieldController;
  File photo = null;
  bool readyToMove = false;

  String errorMessage = null;

  _CompletingRegisteration(this.user);
  
  completeRegisteration(String name, {photo}) {

    setState(() {
      readyToMove = false;
    });

    if(photo != null) {
      user.setName(name);
      user.setPhoto(photo).then((var i){
        Navigator.push(context, new MaterialPageRoute(builder: (context){
          return new MainPage(user);
        }));
      });

    }else {
      user.setName(name).then((var i) {
        Navigator.push(context, new MaterialPageRoute(builder: (context){
          return new MainPage(user);
        }));
      });
    }



  }

  pickImage() async {
    File image = await ImagePicker.pickImage(source: ImageSource.gallery);
    if(image != null) {
      setState(() {
        photo = image;
      });
    }
  }
  
  @override
  void initState() {
    
    super.initState();

    nameFieldController = new TextEditingController();
    nameFieldController.addListener(() {
      if(nameFieldController.text.length < 3) {
        setState(() {
          readyToMove = false;
          errorMessage = "name can minimum have 3 characters";
        });
      }else {
        setState(() {
          readyToMove = true;
          errorMessage = null;
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ClipPath(
          clipper: TopClipper(300),
          child: Container(
            width: double.infinity,
            alignment: AlignmentDirectional.topStart,
            child: Padding(
              padding: const EdgeInsets.only(top: 60, left: 10),
              child: Text("Complete Registeration",
              style: TextStyle(color: Colors.white, fontSize: 25,
                  fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),),
            ),
            height: 300,
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: <Color>[Colors.blue, Colors.deepPurple])
            ),
          ),
        ),
        Transform(
          transform: Matrix4.translationValues(0, -140, 0),
          child: ClipOval(
            clipper: ImageClipper(),
            child: Container(
              alignment: AlignmentDirectional.bottomCenter,
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                  image: DecorationImage(
                      image: photo == null ? user.getPhoto() : FileImage(photo),
                      fit: BoxFit.cover
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(360)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(spreadRadius: .5, color: Colors.black)]
              ),
              child: Container(
                height: 60,
                width: 160,
                color: Colors.white70,
                child: FlatButton(onPressed: pickImage,
                    child: Text("pick image",
                      style: TextStyle(color: Colors.blue),)),
              ),
            ),
          ),
        ),

        Transform(
          transform: Matrix4.translationValues(0, -120, 0),
          child: Padding(
            padding: EdgeInsets.only(left: 60, right: 60),
            child: TextField(
              maxLength: 30,
              controller: nameFieldController,
              decoration: InputDecoration(
                errorText: errorMessage,
                hintText: "enter your name",
                labelText: "name"
              ),
            ),
          ),
        ),
        Transform(
          transform: Matrix4.translationValues(0, -110, 0),
          child: Padding(
              padding: EdgeInsets.only(left: 60, right: 60),
            child: Container(
              width: double.infinity,
              height: 50,

              child: RaisedButton(
                color: Colors.cyan,
                child: Text("Complete", style: TextStyle(color: Colors.white),),
                  onPressed: readyToMove ? () =>
                      completeRegisteration(nameFieldController.text, photo: photo) : null),

            ),
          ),
        )

      ],
    );
  }

}

class ImageClipper extends CustomClipper<Rect> {

  @override
  Rect getClip(Size size) {

    return Rect.fromCircle(center: Offset(size.width/2, size.height/2), radius: 85);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {

    return false;
  }


}

class GlobalChat extends StatefulWidget {

  User user;
  GlobalChat(this.user);

  @override
  State<StatefulWidget> createState() {

    return new _GlobalChat(user);
  }

}

class _GlobalChat extends State<GlobalChat> {

  User user;
  _GlobalChat(this.user);
  

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            Hero(
              tag: 'global-chat-room',
              child: CircleAvatar(
                backgroundImage: AssetImage("assets/icon.png"),
              ),
            ),
            Text("Global chat"),
          ],
        ),
          leading: IconButton(icon: Icon(Icons.arrow_back_ios), onPressed: ()=> Navigator.pop(context))

      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder(

    stream: GlobalChatRoom(user).getChatSnapShots(),
    builder: (context, snapshot) {
            if(!snapshot.hasData){return Center(child: CircularProgressIndicator());}
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                  itemCount: snapshot.data['messages'].length,
                  itemBuilder: (context, index) {
                    Message message = new Message.setup(snapshot.data['messages'][index]);
                    return messageForm(user.phoneNumber == message.sender.phoneNumber,user,
                        message);
              }),
            );

    }),
          ),
          bottomBar(
            user: user,
            imagePicker: () => pickImage(user, GlobalChatRoom(user)),
            context: context,
            chatRoom: GlobalChatRoom(user)
          )
        ],
      )

    );

  }


}

class CoupleChatPage extends StatefulWidget {

  User user;
  User friend;
  String roomId;

  CoupleChatPage(this.user, this.friend, this.roomId);
  @override
  State<StatefulWidget> createState() {

    return new _CoupleChatPage(user, friend, roomId);
  }

}

class _CoupleChatPage extends State<CoupleChatPage> {

  User user;
  User friend;
  String roomId;
  

  _CoupleChatPage(this.user, this.friend, this.roomId);

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(
          title: Row(
            children: <Widget>[
              Hero(
                tag: '${friend.phoneNumber}',
                child: CircleAvatar(
                  backgroundImage: friend.getPhoto(),
                ),
              ),
              Text("${friend.username}"),
            ],

          ),
            leading: IconButton(icon: Icon(Icons.arrow_back_ios), onPressed: ()=> Navigator.pop(context)),
          actions: <Widget>[
            IconButton(icon: Icon(Icons.call), onPressed: (){

              UrlLauncher.launch('tel:${friend.phoneNumber}');
            })
          ],

        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: StreamBuilder(

                  stream: CoupleChatRoom(user, roomId).getChatSnapShots(),
                  builder: (context, snapshot) {
                    if(!snapshot.hasData){return Center(child: CircularProgressIndicator());}
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListView.builder(
                          itemCount: snapshot.data['messages'].length,
                          itemBuilder: (context, index) {
                            Message message = new Message.setup(snapshot.data['messages'][index]);
                            return messageForm(user.phoneNumber == message.sender.phoneNumber,user,
                                message);
                          }),
                    );

                  }),
            ),
            bottomBar(
                user: user,
                imagePicker: () => pickImage(user, CoupleChatRoom(user, roomId)),
                context: context,
                chatRoom: CoupleChatRoom(user, roomId)
            )
          ],
        )

    );

  }

}

class SearchForFriend extends StatefulWidget {

  User user;
  SearchForFriend(this.user);

  @override
  State<StatefulWidget> createState() {

    return _SearchForFriend(user);
  }


}

class _SearchForFriend extends State<SearchForFriend> {

  User user;
  TextEditingController searchController;
  String name;
  _SearchForFriend(this.user);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    searchController = new TextEditingController();
    searchController.addListener((){setState(() {

      name = searchController.text.trim();
    });});
  }

  @override
  Widget build(BuildContext context) {

    String name = searchController.text.trim();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.close), onPressed: (){Navigator.pop(context);}),
        title: TextField(
          controller: searchController,
          maxLength: 70,
          decoration: InputDecoration(
            suffixIcon: Icon(Icons.search, color: Colors.white),
            hintText: "search for name..."
          ),
        ),

      ),
      body: Container(
        child: StreamBuilder(
            stream: Firestore.instance
                .collection("users").where('username', isEqualTo: name)
                .snapshots(),
            builder: (context, snapShot) {
              if(!snapShot.hasData) return Center(child:CircularProgressIndicator());

              var documents = snapShot.data.documents;
              if(documents.length == 0 && name.length != 0) return Center(child: Text("couldn't locate a such user."),);

              return ListView.builder(
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    User suggestedUser = User.fromData(documents[index].documentID, documents[index].data);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: suggestedUser.getPhoto(),
                      ),
                      title: Text(suggestedUser.username),
                      subtitle: Text(suggestedUser.phoneNumber),
                      onTap: documents[index].documentID == user.phoneNumber ? null :(){

                        for(var data in user.friends) {
                          if(suggestedUser.phoneNumber == data['friend'].phoneNumber) {
                            Navigator.pop(context);
                            Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (c) => CoupleChatPage(user, suggestedUser, data['roomId'])));
                            return;
                          }
                        }
                        user.addFriend(suggestedUser).then((data){
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(
                              builder: (c) => CoupleChatPage(user, suggestedUser, data['roomId'])));
                        });

                      },
                    );
                  });

            }),
      ),
    );
  }



}

class UpdateProfile extends StatefulWidget {

  User user;
  UpdateProfile(this.user);

  @override
  State<StatefulWidget> createState() {

    return _UpdateProfile(user);
  }


}



class _UpdateProfile extends State<UpdateProfile> {

  User user;
  File photo;
  TextEditingController controller;
  bool nameChanged = false;
  bool photoChanged = false;

  _UpdateProfile(this.user);

  initState() {
    super.initState();

    controller = new TextEditingController();
    controller.text = user.username;
    controller.addListener((){
      if(user.username != controller.text.trim()) {
        setState(() {
          nameChanged = true;
        });
      }
    });
  }

  pickImage() async {
    photo = await ImagePicker.pickImage(source: ImageSource.gallery);
    if(photo != null) {
      setState(() {
        photoChanged = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
          leading: IconButton(icon: Icon(Icons.arrow_back_ios), onPressed: ()=> Navigator.pop(context)),
        title: Text("Edit profile"),
      ),
      body: Center(
          child: Container(
            width: MediaQuery.of(context).size.width/1.5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ClipOval(
                  clipper: ImageClipper(),
                  child: Container(
                    alignment: AlignmentDirectional.bottomCenter,
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            image: photo == null ? user.getPhoto() : FileImage(photo),
                            fit: BoxFit.cover
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(360)),
                        boxShadow: <BoxShadow>[
                          BoxShadow(spreadRadius: .5, color: Colors.black)]
                    ),
                    child: Container(
                      height: 60,
                      width: 160,
                      color: Colors.white70,
                      child: FlatButton(onPressed: pickImage,
                          child: Text("pick image",
                            style: TextStyle(color: Colors.blue),)),
                    ),
                  ),
                ),
                SizedBox(height: 10,),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: "name"
                  ),
                ),
                SizedBox(height: 5,),
                Container(
                  width: double.infinity,
                  child: RaisedButton(
                    color: Colors.purple,
                      onPressed: nameChanged || photoChanged ? () async {

                      if(photoChanged) {
                        await user.setPhoto(photo);
                      }

                      if(nameChanged) {
                        await user.setName(controller.text.trim());
                      }

                      Navigator.pop(context);

                      }: null, child: Text("Update", style: TextStyle(color: Colors.white),),),
                )

              ],
            ),
          ),
        )
    );
  }


}













