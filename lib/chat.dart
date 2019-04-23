import 'dart:io';
import 'user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

class Message {

  String messageType;
  String content;
  User sender;
  static final String TEXT = "text-message";
  static final String IMAGE = "image-message";

  Message(this.sender, this.messageType, this.content);

  Message.setup(Map message) {
    this.sender = User.get(message.keys.first);
    this.content = message[sender.phoneNumber]['content'];
    this.messageType = message[sender.phoneNumber]['message-type'];

  }

  Widget getContent({TextStyle style}) {
    if(messageType == IMAGE) {
      return Image.network(content);
    }
    return new Text(content, style: style);
  }

}


abstract class ChatRoom {

  final DocumentReference textField;
  final StorageReference imageField;
  User currentUser;

  ChatRoom(this.currentUser, this.textField, this.imageField);

  Future<void> sendImageMessage(File image) async {

  final date = DateTime.now().toString();
  final imagePlaceHolder = imageField.child("$date");
  final task = imagePlaceHolder.putFile(image);

  String url = await (await task.onComplete).ref.getDownloadURL();
  Message message = new Message(currentUser, Message.IMAGE, url);
  sendMessage(message);
  }

  Future<void> sendMessage(Message message) {

  return textField
      .updateData({'messages': FieldValue.arrayUnion(
  [{
  message.sender.phoneNumber : {
  'message-type': message.messageType,
  'content': message.content,

  }
  }
  ])});
  }

  Stream<DocumentSnapshot> getChatSnapShots() => textField.snapshots();
  Future<DocumentSnapshot> getData() => textField.get();

}


class GlobalChatRoom extends ChatRoom {


  GlobalChatRoom(User user)
      : super(
      user
      ,User.getData("chat", "global-chat")
      ,FirebaseStorage.instance.ref().child("messages").child("global-chat")
  );

}


class CoupleChatRoom extends ChatRoom {


  CoupleChatRoom(User user, String roomId)
      : super(user,
    User.getData("chat", roomId),
    FirebaseStorage.instance.ref().child("messages").child(roomId));



}