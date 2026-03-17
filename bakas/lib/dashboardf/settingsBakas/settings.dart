import 'package:flutter/material.dart';
import '../app_drawer.dart';
import '/widgets/BakasHeader.dart';
import '/widgets/WhiteContainer.dart';
import '/widgets/backgroundRed.dart';

class settingPage extends StatelessWidget {
  final String? firstName;
  final int? playerId;
  const settingPage({super.key, this.firstName, this.playerId});

void showModalProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('User Registration'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
               
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[300],
                    child: const Icon(Icons.camera_alt, size: 30),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text("Attach Profile Pic"),
                  ),

                  const SizedBox(height: 10),
                  editTextTemplate("Last Name"),
                  editTextTemplate("First Name"),
                  editTextTemplate("Middle Name"),
                  editTextTemplate(
                    "Mobile Number",
                    keyboardType: TextInputType.phone,
                  ),
                  editTextTemplate(
                    "Email",
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const Divider(),
                  const Text(
                    "Address Information",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  editTextTemplate("Province"),
                  editTextTemplate("City"),
                  editTextTemplate("Barangay"),
                  editTextTemplate("Street No."),

                  const Divider(),
                  const Text(
                    "Identification",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  editTextTemplate("ID Type (e.g. Passport, Driver's License)"),
                  editTextTemplate("ID Number"),

                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Upload ID Photo"),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
              
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

Widget editTextTemplate(
    String label, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return backgroundRed(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: myAppBar('Setting'),
        drawer: AppDrawer(
          firstName: firstName,
          playerId: playerId,
        ),
        body: SafeArea(
          bottom: false,
          child: WhiteContainer(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () {
                           Navigator.pop(context);
                           Navigator.pushNamed(context, '/setting', arguments: {
                             'firstName': firstName,
                             'playerId': playerId,
                           });
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        child: Text(
                          'Profile',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {
                           Navigator.pop(context);
                           Navigator.pushNamed(context, '/wallet', arguments: {
                             'firstName': firstName,
                             'playerId': playerId,
                           });
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        child: Text(
                          'Wallet',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/security', arguments: {
                            'firstName': firstName,
                            'playerId': playerId,
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        child: Text(
                          'Security',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    ],
                  ),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFD66D6D), Color(0xFF912A2A)],
                      ),
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: InkWell(
                            onTap: () => showModalProfile(context),
                            child: const Icon(
                              Icons.edit_document,
                              color: Colors.white70,
                              size: 22,
                            ),
                          ),
                        ),

                        const CircleAvatar(
                          radius: 52,
                          backgroundColor: Color(0xFFFFD152),
                          child: CircleAvatar(
                            radius: 48,
                            backgroundImage: NetworkImage(
                              'https://i.pravatar.cc/150?img=5',
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        Text(
                          firstName ?? "User",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "User Code: 2024G006amiZU",
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          child: Divider(color: Colors.white24, height: 1),
                        ),

                        infoRow("Mobile Number", "0912-356-4897"),
                        infoRow("Email", "Juville@Email.Com"),
                        infoRow("Region", "National Capital Region (NCR)"),
                        infoRow("Province", "City Of Manila"),
                        infoRow("City", "Caloocan City"),
                        infoRow("Barangay", "Barangay 111"),
                        infoRow("Address", "Fake St. 123"),
                        infoRow("ID Type", "UMID"),
                        infoRow("ID Number", "0123456789"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              "$label:",
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
