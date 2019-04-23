import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';





class User {

  String _phoneNumber;
  String _name;
  String _photoUrl;

  List _friends = [];
  List get friends => _friends;
  String get phoneNumber => _phoneNumber;

  String get username => _name;
  String get photoUrl => _photoUrl;

  Future<void> setName(String name) async {
    return Firestore.instance.collection("users")
        .document(phoneNumber)
        .updateData({
      "username": name
    });
  }

  Future<void> setPhoto(File photo) async {
  var photoSpace = FirebaseStorage.instance.ref()
      .child("users").child(phoneNumber);
  var task = photoSpace.putFile(photo);
  String url = await (await task.onComplete).ref.getDownloadURL();
  print(url);
  Firestore.instance.collection("users").document(phoneNumber).updateData({
  'photo-url': url.toString()
  }).then((var i) {
  this._photoUrl = url.toString();
  });

  }

  getPhoto() {
    if(photoUrl == null || photoUrl == "1") {
      print("---------------------------------------------noooooo");
      return AssetImage("assets/user.jpeg");
    }else {
      print("********************************************dooonennenenene");
      return NetworkImage(photoUrl);
    }
  }

  Future<bool> syncData() async {

    var user = await getData("users", phoneNumber).get();
    _name = user.data != null ? user.data['username'] : "1";
    _photoUrl = user.data != null ? user.data['photo-url']: "1";

    return _name != null && _name != "1";
  }

   static DocumentReference getData(String collection,String document) {

    return Firestore.instance.collection(collection).document(document);
  }

  Future<void> createDataFields() {
    return Firestore.instance.collection("users").document(phoneNumber).setData({
      'chat-rooms': [],
      'username': null,
      'photo-url': null
    });
  }



  User(FirebaseUser user) {
    this._phoneNumber = user.phoneNumber;
  }

  User.get(String phoneNumber) {
    this._phoneNumber = phoneNumber;
  }

  User.fromData(String phoneNumber, Map data) {
    this._phoneNumber = phoneNumber;
    this._name = data['username'];
    this._photoUrl = data['photo-url'];
  }

  Future<Map> addFriend(User user) async {


    DocumentReference ref = Firestore.instance.collection("chat").document();
    await ref.setData({
    'members': [phoneNumber, user.phoneNumber],
    'messages': []
  });

    await getData("users", phoneNumber).updateData({
    'chat-rooms': FieldValue.arrayUnion([ref.documentID])
  }
  );

    await getData("users", user.phoneNumber).updateData({
    'chat-rooms': FieldValue.arrayUnion([ref.documentID])
  });

    _friends.add({'friend': user, 'roomId': ref.documentID});
    return {'friend': user, 'roomId': ref.documentID};

  }

  Future getFriends() async {
  print(1);
  var userDataImage = await User.getData("users", phoneNumber).get();
  List chatRoomsId = userDataImage != null ? userDataImage.data['chat-rooms']: [];
  List rooms = [];
  var data = [];
  print(2);
  for(int i=0; i < chatRoomsId.length;i++) {
    var room = await User.getData("chat", chatRoomsId[i]).get();
    rooms.add(room.data);
  }
  for(int i=0;i<rooms.length;i++) {

    print(rooms[i]['members']);print(phoneNumber);
    String friendPhoneNumber = rooms[i]['members'][rooms[i]['members'].indexOf(phoneNumber) == 1 ? 0 : 1];

    User friend = User.get(friendPhoneNumber);
    await friend.syncData();

    data.add({'friend': friend, 'roomId': chatRoomsId[i]});
  }

  _friends = data;
  print(3);

  return data;

  }

}