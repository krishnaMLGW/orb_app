import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ghost_provider.dart';

class GhostScreen extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();
  GhostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ghostProvider = context.watch<GhostProvider>();

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Row(
            children: GhostStyle.values.map((style) {
              bool active = ghostProvider.currentStyle == style;
              return GestureDetector(
                onTap: () => ghostProvider.setStyle(style),
                child: Container(
                  margin: const EdgeInsets.only(right: 10), // FIXED
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white10,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(style.name.toUpperCase(), 
                    style: TextStyle(color: active ? Colors.black : Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: "Whisper..."))),
              ghostProvider.isGhosting 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) 
                : IconButton(icon: const Icon(Icons.send), onPressed: () {
                    context.read<GhostProvider>().postGhostMessage(_controller.text);
                    _controller.clear();
                  }),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('ghost_threads').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  return ListTile(title: Text(data['content'] ?? "", style: const TextStyle(fontStyle: FontStyle.italic)));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}