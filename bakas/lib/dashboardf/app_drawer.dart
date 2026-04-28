import 'package:flutter/material.dart';
import 'groups.dart';
import 'grouprequest.dart';
import '../services/session_service.dart';

class AppDrawer extends StatelessWidget {
  final String? firstName;
  final int? playerId;
  final VoidCallback? onRefresh;

  const AppDrawer({super.key, this.firstName, this.playerId, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final effectiveFirstName = firstName ?? args?['firstName'] ?? SessionService().firstName;
    final effectivePlayerId = playerId ?? args?['playerId'] ?? SessionService().playerId;
    final displayName = effectiveFirstName ?? 'User';

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
                  _drawerItem(context, Icons.home_outlined, "Home", displayName, effectivePlayerId, route: '/dashboard'),
                  _drawerItem(context, Icons.sports_esports_outlined, "Bakas", displayName, effectivePlayerId, route: '/draw-date'),
                  _drawerItem(context, Icons.account_balance_wallet_outlined, "Cash In / Cash Out", displayName, effectivePlayerId, route: '/cash-inout'),
                  _drawerItem(context, Icons.confirmation_num_outlined, "Tickets", displayName, effectivePlayerId, route: '/tickets'),
                  _drawerItem(context, Icons.history_outlined, "History", displayName, effectivePlayerId, route: '/history'),
                  _drawerItem(context, Icons.emoji_events_outlined, "Results", displayName, effectivePlayerId, route: '/results'),
                  _drawerItem(context, Icons.message_outlined, "Message Center", displayName, effectivePlayerId, route: '/message-center'),
                  
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GroupsPage(
                                      playerId: effectivePlayerId,
                                      firstName: displayName,
                                    ),
                                  ),
                                );
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GroupRequestPage(
                                      playerId: effectivePlayerId,
                                      firstName: displayName,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  _drawerItem(context, Icons.settings_outlined, "Settings", displayName, effectivePlayerId, route: '/setting'),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  _drawerItem(context, Icons.logout, "Sign Out", displayName, effectivePlayerId, isSignOut: true),
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
    String title,
    String currentDisplayName,
    dynamic currentPlayerId, {
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
              if (ModalRoute.of(context)?.settings.name == route) {
                if (onRefresh != null) onRefresh!();
                return;
              }
              
              final navArgs = {
                'firstName': currentDisplayName,
                'playerId': currentPlayerId,
              };

              Navigator.pushNamed(context, route, arguments: navArgs);
            }
          },
        ),
      ),
    );
  }
}
