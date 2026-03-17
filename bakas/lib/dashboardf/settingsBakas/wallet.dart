import 'package:flutter/material.dart';
import '../app_drawer.dart';
import '/widgets/BakasHeader.dart';
import '/widgets/WhiteContainer.dart';
import '/widgets/backgroundRed.dart';

class walletPage extends StatelessWidget {
  final String? firstName;
  final int? playerId;
  const walletPage({super.key, this.firstName, this.playerId});

void EditWalletModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Edit Wallet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.black),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Account Number*", style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
          const SizedBox(height: 8),
          const TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Save", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B0000)),
                child: const Text("Cancel", style: TextStyle(color: Colors.white)),
              ),
            ],
          )
        ],
      ),
    ),
  );
}
void LinkWalletModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Link Wallet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.black),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Account Number*", style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                    SizedBox(height: 5),
                    TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Wallet Type*", style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                    SizedBox(height: 5),
                    TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: "Select",
                        suffixIcon: Icon(Icons.arrow_drop_down),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Save", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B0000)),
                child: const Text("Cancel", style: TextStyle(color: Colors.white)),
              ),
            ],
          )
        ],
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
                  
                  const SizedBox(height: 30),

                  Column(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 190,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007DFE),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 0,
                              right: 0,
                              child: InkWell(
                                onTap: () => EditWalletModal(context),
                                child: const Icon(Icons.edit_document, color: Colors.white, size: 24),
                              ),
                            ),
                            const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.account_balance_wallet, color: Colors.white, size: 40),
                                  SizedBox(width: 10),
                                  Text("GCash", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("${firstName ?? 'User'} C.", style: const TextStyle(color: Colors.white, fontSize: 16)),
                                  Text("******** 123", style: const TextStyle(color: Colors.white, fontSize: 16)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () => LinkWalletModal(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B0000),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: const Text("Link Wallet", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}