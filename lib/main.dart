import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'identity_provider.dart';
import 'features/ghost/ghost_screen.dart';
import 'features/ghost/ghost_provider.dart';
import 'features/private/vault_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => IdentityProvider()),
    ChangeNotifierProvider(create: (_) => GhostProvider()),
  ], child: const OrbApp()));
}

class OrbApp extends StatelessWidget {
  const OrbApp({super.key});
  @override
  Widget build(BuildContext context) {
    final id = context.watch<IdentityProvider>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: id.themeColor),
      home: const OrbHome(),
    );
  }
}

class OrbHome extends StatelessWidget {
  const OrbHome({super.key});

  @override
  Widget build(BuildContext context) {
    final id = context.watch<IdentityProvider>();
    return Scaffold(
      body: Stack(children: [
        SafeArea(child: _buildBody(context, id)),
        Positioned(bottom: 30, left: 0, right: 0, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _orb(context, IdentityMode.private, Icons.lock_outline),
          const SizedBox(width: 20),
          _orb(context, IdentityMode.ghost, Icons.visibility_off_outlined),
          const SizedBox(width: 20),
          _orb(context, IdentityMode.public, Icons.language_outlined),
        ]))
      ]),
    );
  }

  Widget _buildBody(BuildContext context, IdentityProvider id) {
    if (id.currentMode == IdentityMode.ghost) return GhostScreen();
    if (id.currentMode == IdentityMode.private) {
      return id.isAuthenticated ? const VaultScreen() : Center(child: ElevatedButton(onPressed: id.simulateAuthentication, child: const Text("Unlock Vault")));
    }
    return _buildPublicDashboard(context, id);
  }

  Widget _buildPublicDashboard(BuildContext context, IdentityProvider id) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(20),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(id.username, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.group_add, color: Colors.black), onPressed: () => _showContactPicker(context, id)),
        ]),
      ),
      // Financial Summary
      _buildTripCard(id),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        child: Align(alignment: Alignment.centerLeft, child: Text("ACTIVE CHATS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 2))),
      ),
      // Chat List
      Expanded(
        child: id.groups.isEmpty 
          ? const Center(child: Text("No groups yet. Tap + to invite contacts.", style: TextStyle(color: Colors.black38)))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: id.groups.length,
              itemBuilder: (context, index) {
                final group = id.groups[index];
                return ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.black, child: Icon(Icons.group, color: Colors.white, size: 16)),
                  title: Text(group['name'], style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  subtitle: Text(group['lastMsg'], style: const TextStyle(color: Colors.black45, fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.black12),
                );
              },
            ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 110),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.black,
          onPressed: () => _showAIExpenseDialog(context, id),
          label: const Text("AI LOG"),
          icon: const Icon(Icons.auto_awesome),
        ),
      )
    ]);
  }

  Widget _buildTripCard(IdentityProvider id) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white24)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("TOTAL EXPENSES", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
          Text("\$${id.totalSpent.toStringAsFixed(0)}", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 15),
        LinearProgressIndicator(value: id.totalSpent / 5000, backgroundColor: Colors.black12, color: Colors.black),
      ]),
    );
  }

  void _showContactPicker(BuildContext context, IdentityProvider id) async {
    await id.syncContacts();
    List<String> selectedNames = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (cxt) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(25),
          child: Column(children: [
            const Text("NEW GROUP", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: id.phoneContacts.length,
                itemBuilder: (context, index) {
                  final contact = id.phoneContacts[index];
                  bool isSelected = selectedNames.contains(contact.displayName);
                  return ListTile(
                    title: Text(contact.displayName!, style: const TextStyle(color: Colors.black)),
                    trailing: Icon(isSelected ? Icons.check_circle : Icons.add_circle_outline, color: isSelected ? Colors.green : Colors.black12),
                    onTap: () {
                      setModalState(() {
                        isSelected ? selectedNames.remove(contact.displayName) : selectedNames.add(contact.displayName!);
                      });
                    },
                  );
                },
              ),
            ),
            if (selectedNames.isNotEmpty) ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, minimumSize: const Size(double.infinity, 50)),
              onPressed: () {
                id.createGroup("Group ${id.groups.length + 1}", selectedNames);
                Navigator.pop(context);
              },
              child: const Text("CREATE WITH ${selectedNames.length} FRIENDS"),
            )
          ]),
        ),
      ),
    );
  }

  void _showAIExpenseDialog(BuildContext context, IdentityProvider id) {
    TextEditingController controller = TextEditingController();
    bool isProcessing = false;
    showDialog(context: context, builder: (cxt) => StatefulBuilder(builder: (context, setState) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text("AI Expense Parser"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: "Spent 40 on dinner")),
        if (isProcessing) const Padding(padding: EdgeInsets.only(top: 20), child: CircularProgressIndicator(color: Colors.white)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(cxt), child: const Text("Cancel")),
        ElevatedButton(onPressed: isProcessing ? null : () async {
          setState(() => isProcessing = true);
          final res = await context.read<GhostProvider>().parseExpense(controller.text);
          if (res != null) { id.addExpense(res['description'], (res['amount'] as num).toDouble()); Navigator.pop(cxt); }
          else { setState(() => isProcessing = false); }
        }, child: const Text("Process")),
      ],
    )));
  }

  Widget _orb(BuildContext context, IdentityMode mode, IconData icon) {
    final id = context.read<IdentityProvider>();
    bool active = id.currentMode == mode;
    return GestureDetector(onTap: () => id.setMode(mode), child: AnimatedContainer(duration: const Duration(milliseconds: 300), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: active ? Colors.white : Colors.white10, shape: BoxShape.circle), child: Icon(icon, color: active ? Colors.black : Colors.white)));
  }
}