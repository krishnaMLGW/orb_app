import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});
  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  List<Reference> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final res = await FirebaseStorage.instance.ref("vault").listAll();
    setState(() { _items = res.items; _loading = false; });
  }

  Future<void> _upload() async {
    FilePickerResult? res = await FilePicker.platform.pickFiles();
    if (res != null) {
      await FirebaseStorage.instance.ref("vault/${res.files.first.name}").putData(res.files.first.bytes!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: _upload, 
        child: const Icon(Icons.add, color: Colors.black)
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10
        ),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          return FutureBuilder<String>(
            future: _items[index].getDownloadURL(),
            builder: (context, snapshot) {
              return Container(
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)),
                child: snapshot.hasData 
                  ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(snapshot.data!, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.description)))
                  : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            },
          );
        },
      ),
    );
  }
}