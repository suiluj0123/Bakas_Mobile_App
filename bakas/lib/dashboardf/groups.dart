import 'package:flutter/material.dart';
import 'app_drawer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GroupsPage(),
    );
  }
}

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final List<Map<String, String>> groups = [
    {"title": "High Rollers"},
    {"title": "Admin"},
  ];

  void showCreateDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String status = "Active";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Create Group"),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: "Status"),
                  items: ["Active", "Inactive"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => setStateDialog(() => status = value!),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFF202020))),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  groups.add({
                    "title": nameController.text,
                    "subtitle": descController.text,
                    "status": status,
                  });
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 0, 125, 4),
            ),
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void showJoinDialog() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Join Group"),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(labelText: "Group Code"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFF121212))),
          ),
          ElevatedButton(
            onPressed: () {
              if (codeController.text.isNotEmpty) {
                setState(() {
                  groups.add({
                    "title": "Joined (${codeController.text})",
                    "subtitle": "New joined group",
                    "status": "Active"
                  });
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 0, 122, 4),
            ),
            child: const Text("Join"),
          ),
        ],
      ),
    );
  }

  void showOpenDialog(int index) {
    final nameController = TextEditingController(text: groups[index]["title"]);
    final descController = TextEditingController(text: groups[index]["subtitle"]);
    String status = groups[index]["status"] ?? "Active";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Group"),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: "Status"),
                  items: ["Active", "Inactive"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => setStateDialog(() => status = value!),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFF202020))),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                groups[index] = {
                  "title": nameController.text,
                  "subtitle": descController.text,
                  "status": status,
                };
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 0, 118, 4),
            ),
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void deleteGroup(int index) {
    setState(() => groups.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(), 
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8B0000), Color(0xFF6E0000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
      
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Builder(
                  builder: (context) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                      const Icon(Icons.notifications_none, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const Text(
                "Groups",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: showCreateDialog,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF8B0000)),
                              foregroundColor: const Color(0xFF8B0000),
                            ),
                            child: const Text("Create Group"),
                          ),
                          const SizedBox(width: 15),
                          OutlinedButton(
                            onPressed: showJoinDialog,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF8B0000)),
                              foregroundColor: const Color(0xFF8B0000),
                            ),
                            child: const Text("Join Group"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          itemCount: groups.length,
                          itemBuilder: (context, index) => Center(
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.9,
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 10)
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(groups[index]["title"]!,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 5),
                                  Text(groups[index]["subtitle"] ?? "",
                                      style: const TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 15),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      smallButton("Open", () => showOpenDialog(index)),
                                      smallButton("Invite", () {}),
                                      smallButton("Members", () {}),
                                      ElevatedButton(
                                        onPressed: () => deleteGroup(index),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF8B0000),
                                        ),
                                        child: const Text("Delete", style: TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget smallButton(String text, VoidCallback onTap) => ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade200,
          foregroundColor: Colors.black,
          elevation: 0,
          minimumSize: const Size(60, 30),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: Text(text, style: const TextStyle(fontSize: 12)),
      );
}

