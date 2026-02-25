import 'package:flutter/material.dart';
import 'app_drawer.dart';

class MessageCenterPage extends StatefulWidget {
  const MessageCenterPage({Key? key}) : super(key: key);

  @override
  State<MessageCenterPage> createState() => _MessageCenterPageState();
}

class _MessageCenterPageState extends State<MessageCenterPage> {
  List<bool> selected = [true, true, false];
  bool isGroupExpanded = false; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8B0000), Color.fromARGB(255, 235, 112, 112)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Builder(
                  builder: (context) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
               IconButton(
                 icon: const Icon(Icons.menu, color: Colors.white),
                 onPressed: () => Scaffold.of(context).openDrawer(),
                ),

               Container(
                padding: const EdgeInsets.all(10),
                 decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 238, 244, 192).withOpacity(0.15), // soft shade
                  shape: BoxShape.circle,
                  border: Border.all(
                   color: const Color.fromARGB(255, 242, 245, 157).withOpacity(0.3),
                    width: 1,
                     ),
                    ),
                    child: const Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                    size: 22,
                      ),
                     ),
                    ],
                  ),
                ),
              ),

              const Text(
                "Message Center",
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
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 45,
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const TextField(
                          decoration: InputDecoration(
                            hintText: "Search",
                            prefixIcon: Icon(Icons.search),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 143, 143, 143),
                            ),
                            child: const Text("Mark as Read"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 153, 11, 1),
                            ),
                            child: const Text("Delete"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Expanded(
                        child: ListView.builder(
                          itemCount: 2,
                          itemBuilder: (context, index) {
                            String title = index == 0
                                ? "Happy birthday, Menggay!"
                                : "Happy birthday, Duday!";
                            String date = index == 0
                                ? "January 25, 2022"
                                : "April 25, 2022";
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 15),
                              child: _buildMessageCard(
                                  index: index, title: title, date: date),
                            );
                          },
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

  Widget _buildMessageCard({
    required int index,
    required String title,
    required String date,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: selected[index],
            activeColor: Colors.red,
            onChanged: (value) {
              setState(() {
                selected[index] = value!;
              });
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    date,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
