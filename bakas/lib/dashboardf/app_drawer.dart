import 'package:flutter/material.dart';
import 'history.dart';
import 'cash_inout.dart';
import 'messagecenter.dart';

class AppDrawer extends StatelessWidget {
  final String? firstName;
  final int? playerId;
  final VoidCallback? onRefresh;

  const AppDrawer({super.key, this.firstName, this.playerId, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final userFirstName = firstName ??
        (ModalRoute.of(context)?.settings.arguments as String?);
    final displayName = userFirstName ?? 'User';

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF8B0000),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Color(0xFF8B0000), size: 30),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "bakas@email.com",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                children: [
                  _drawerItem(context, Icons.home_outlined, "Home", route: '/dashboard'),
                  _drawerItem(context, Icons.sports_esports_outlined, "Bakas"),
                  _drawerItem(context, Icons.account_balance_wallet_outlined, "Cash In / Cash Out", route: '/cash-inout'),
                  _drawerItem(context, Icons.confirmation_num_outlined, "Tickets"),
                  _drawerItem(context, Icons.history_outlined, "History", route: '/history'),
                  _drawerItem(context, Icons.message_outlined, "Message Center", route: '/message-center'),
                  
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(15),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                          childrenPadding: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
                          leading: const Icon(Icons.group_outlined, color: Color(0xFF8B0000)),
                          title: const Text(
                            "Groups",
                            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
                          ),
                          trailing: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF8B0000)),
                          children: [
                            ListTile(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              tileColor: Colors.white,
                              leading: const Icon(Icons.groups, size: 20, color: Color(0xFF8B0000)),
                              title: const Text("All Groups"),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.pushNamed(context, '/groups');
                              },
                            ),
                            const SizedBox(height: 8),
                            ListTile(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              tileColor: Colors.white,
                              leading: const Icon(Icons.mark_email_unread_outlined, size: 20, color: Colors.green),
                              title: const Text("Group Request"),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.pushNamed(context, '/group-request');
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  _drawerItem(context, Icons.settings_outlined, "Settings"),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  _drawerItem(context, Icons.logout, "Sign Out", isSignOut: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String title, {
    String? route,
    bool isSignOut = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          leading: Icon(
            icon,
            color: isSignOut ? Colors.red : const Color(0xFF8B0000),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isSignOut ? Colors.red : Colors.black87,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            if (isSignOut) {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            } else if (route != null) {
              if (ModalRoute.of(context)?.settings.name == route) return;
              
              if (route == '/history') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryUI(
                      playerId: playerId,
                      firstName: firstName,
                    ),
                  ),
                );
              } else if (route == '/cash-inout') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CashInOutPage(
                      playerId: playerId,
                      firstName: firstName,
                    ),
                  ),
                );
              } else if (route == '/message-center') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MessageCenterPage(
                      playerId: playerId,
                      firstName: firstName,
                    ),
                  ),
                );
              } else {
                Navigator.pushNamed(context, route, arguments: firstName);
              }
            }
          },
        ),
      ),
    );
  }
}
