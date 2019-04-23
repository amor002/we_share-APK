import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'user.dart';
import 'home.dart';
import 'package:firebase_auth/firebase_auth.dart';
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    
    Widget startPage;

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    startPage = FutureBuilder(
        future: FirebaseAuth.instance.currentUser(),
        builder: (context, user) {

          if(!user.hasData) {
            return new LoginPage();
          }else {

            return new Home(new User(user.data));
          }
        });

    return MaterialApp(
      title: 'weShare',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple
      ),
      home: startPage,
    );
  }

}

class LoginPage extends StatefulWidget {

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  TextEditingController phoneNumberController;
  TextEditingController codeInputController;
  double form = 0;
  String verificationId;

  String SMSErrorText = null;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool validInput = false;
  bool phoneNumberSubmitted = false;

  @override
  void initState() {
    super.initState();

    phoneNumberController = new TextEditingController();
    phoneNumberController.addListener(checkInput);
    codeInputController = new TextEditingController();


  }

  void checkInput() {

    if(phoneNumberController.text.length == 10) {
      setState((){validInput = true;});
    }else {
      setState(() {
        validInput = false;
      });
    }
  }

  Dialog sendingSMSDialog() {

    Dialog dialog =Dialog(
      child: Container(
          height: 100,
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              children: <Widget>[
                CircularProgressIndicator(),
                SizedBox(width: 20,),
                Text("sending SMS code...")
              ],
            ),
          )),
    );

    showDialog(
        context: context,
        builder: (dialogContext){
          return dialog;
        });

    return dialog;
  }

  Future verifyPhoneNumber(String number) async {
    return FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: number,
        timeout: const Duration(seconds: 7),
        verificationCompleted: (FirebaseUser firebaseUser){

          User user = new User(firebaseUser);
          Navigator.push(context, MaterialPageRoute(builder: (context) => new Home(user)));
        },
        verificationFailed: (error){
          print(error.message);
          _scaffoldKey.currentState.showSnackBar(SnackBar(
            content: Text("something went wrong, please try again later"), duration: const Duration(seconds: 5),));

          setState(() {
            form = 0;
            phoneNumberSubmitted = false;
          });
        },
        codeSent: (id, [forcedsent]){
          verificationId = id;
          setState(() {
            validInput = false;
            phoneNumberSubmitted = true;
            form = 1;
          });
        },
        codeAutoRetrievalTimeout: (id){});
  }

  void sendSMS()  {
    Dialog dialog = sendingSMSDialog();
    verifyPhoneNumber("+20${phoneNumberController.text}").then((var i) {
      Navigator.pop(context, dialog);
      Future.delayed(Duration(minutes: 1), (){

        setState(() {
          validInput = true;
          phoneNumberSubmitted = false;
        });

      });
    });

  }

  Widget phoneNumberWidget() {
    return TextField(
      controller: phoneNumberController,
      maxLength: 10,
      keyboardType: TextInputType.numberWithOptions(decimal: false),
      inputFormatters: <TextInputFormatter>[
          WhitelistingTextInputFormatter.digitsOnly
      ],
      decoration: InputDecoration(
          hintText: "1007927278",
          labelText: "phone number",
          prefixText: "+20",
          errorText: phoneNumberSubmitted ? "field will be available after 1 minute" : null,
          enabled:  !phoneNumberSubmitted,
          border: OutlineInputBorder(
              borderSide: BorderSide(width: 5)
          ),

          suffix: FlatButton(
              onPressed: validInput ? sendSMS : null,
              child: Text("VERIFY",
                style: TextStyle(
                    color: validInput ? Colors.blue : Colors.grey
                ),))
      ),
    );

  }

  signIn(String smsCode) {
    AuthCredential credential = PhoneAuthProvider.getCredential(
    verificationId: verificationId, smsCode: smsCode);


    FirebaseAuth.instance
      .signInWithCredential(credential).then(
  (FirebaseUser firebaseUser){
    setState(() {
      phoneNumberSubmitted = true;
    });


    User user = new User(firebaseUser);
    Navigator.push(context, MaterialPageRoute(builder: (context) => new Home(user)));
  }).catchError((error){
      print("////////////////////////////////////////////");
      print(error);
      setState(() {
        SMSErrorText = "the code you have entered is not correct";
      });
  });

  }

  Widget createForm(double transform, Widget child) {

    return Transform(
      transform: Matrix4.translationValues(
        MediaQuery.of(context).size.width*transform, 0, 0),
      child: Padding(
          padding: EdgeInsets.all(30),
          child: child),
    );

  }

  Widget SMSInputWidget() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: <Widget>[
          TextField(
            maxLength: 6,
            inputFormatters: <TextInputFormatter>[
                WhitelistingTextInputFormatter.digitsOnly
            ],
            keyboardType: TextInputType.numberWithOptions(decimal: false),
            controller: codeInputController,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: "* * * * * *",
              errorText: SMSErrorText,
              labelText: "code",
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              RaisedButton(
                color: Colors.deepPurple,
                onPressed: (){
                  final snackbar = SnackBar(
                  content:
                  Text("field will be available again after 1 minute", style: TextStyle(color: Colors.yellow),),
                          duration: Duration(seconds: 5));
                  _scaffoldKey.currentState.showSnackBar(snackbar);
                  setState(() {
                  form = 0;
                });},
                child: Row(
                  children: <Widget>[
                    Icon(Icons.arrow_back_ios, color: Colors.white12,),
                    Text("back",
                    style: TextStyle(color: Colors.white),)
                  ],
                ),
              ),
              RaisedButton(
                color: Colors.blue,
                onPressed: () => signIn(codeInputController.text),
                child: Text("Submit",style: TextStyle(color: Colors.white),),
              )
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
    key: _scaffoldKey,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(

          children: <Widget>[
            ClipPath(
              clipper: TopClipper(180),
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: <Color>[Colors.blue, Colors.deepPurple])
                ),
              ),
            ),

            Stack(
              children: <Widget>[
                createForm(form, phoneNumberWidget()),

                createForm(1-form, SMSInputWidget())

              ],
            ),
            SizedBox(height: 30),
            Expanded(
              child: ClipPath(
                clipper: BottomClipper(),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(colors: <Color>[Colors.blue, Colors.deepPurple])
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

}

class TopClipper extends CustomClipper<Path> {

  double height;

  @override
  Path getClip(Size size) {
    Path clip = new Path();
    clip.lineTo(0, height/2);

    clip.lineTo(size.width, height);
    clip.lineTo(size.width, 0);
    return clip;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    
    return false;
  }

  TopClipper(this.height);
  
}

class BottomClipper extends CustomClipper<Path> {

  @override
  Path getClip(Size size) {

    Path clip = new Path();
    clip.lineTo(0, size.height);
    clip.lineTo(size.width, size.height);
    clip.lineTo(size.width, size.height/2);
    return clip;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {

    return false;
  }

}