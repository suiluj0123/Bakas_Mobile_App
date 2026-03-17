import 'package:flutter/material.dart';
import '../app_drawer.dart';
import '../../widgets/BakasHeader.dart';
import '../../widgets/WhiteContainer.dart';
import '../../widgets/backgroundRed.dart';

class BakasPage extends StatefulWidget {
  final String? firstName;
  final int? playerId;

  const BakasPage({super.key, this.firstName, this.playerId});

  @override
  State<BakasPage> createState() => _BakasPageState();
}

class _BakasPageState extends State<BakasPage> {
  @override
  Widget build(BuildContext context) {
    //invoked background red hehehe
    return backgroundRed( 
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        //app bar widget file ito
        appBar: myAppBar('Bakas'),
        //drawer widget file i2
        drawer: AppDrawer(
          firstName: widget.firstName,
          playerId: widget.playerId,
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              //balance widget import nlang para di na gagawa every page
              PlayerBalanceWidget(playerId: widget.playerId),
              //White container widget din i2
              WhiteContainer(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          margin: EdgeInsets.fromLTRB(20, 20, 10, 20),
                          child: Text(
                            'Channel',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700,
                              fontSize: 35,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    //Bakas o bFX ituuuu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/draw-date',
                                  arguments: {
                                    'firstName': widget.firstName,
                                    'playerId': widget.playerId,
                                  },
                                );
                              },
                              child: Container(
                                margin: EdgeInsets.fromLTRB(20, 20, 20, 5),
                                padding: EdgeInsets.all(30),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF910D0D),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                ),
                                child: Icon(
                                  Icons.sports_esports_outlined,
                                  size: 30.0,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Text(
                              'Bakas',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Container(
                              margin: EdgeInsets.fromLTRB(20, 20, 20, 5),
                              padding: EdgeInsets.all(30),
                              decoration: BoxDecoration(
                                color: const Color(0xFF910D0D),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20),
                                ),
                              ),
                              child: Icon(
                                Icons.draw_sharp,
                                size: 30.0,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'bFX',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
