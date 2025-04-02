import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  // Ensure that widget binding is initialized before Firebase initialization.
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp();
  runApp(InventoryApp());
}

class InventoryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Management App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: InventoryHomePage(title: 'Inventory Home Page'),
    );
  }
}

class InventoryHomePage extends StatefulWidget {
  InventoryHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _InventoryHomePageState createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends State<InventoryHomePage> {
  // Controller for item name input
  final TextEditingController _itemController = TextEditingController();

  // Add new item to Firestore
  Future<void> _addNewItem(String itemName) async {
    if (itemName.isNotEmpty) {
      await FirebaseFirestore.instance.collection('items').add({'name': itemName});
    }
  }

  // Update an existing item in Firestore
  Future<void> _updateItem(String id, String newName) async {
    if (newName.isNotEmpty) {
      await FirebaseFirestore.instance.collection('items').doc(id).update({'name': newName});
    }
  }

  // Delete an item from Firestore
  Future<void> _deleteItem(String id) async {
    await FirebaseFirestore.instance.collection('items').doc(id).delete();
  }

  // Show dialog for adding a new item
  void _showAddItemDialog() {
    _itemController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Item'),
          content: TextField(
            controller: _itemController,
            autofocus: true,
            decoration: InputDecoration(labelText: 'Item Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _addNewItem(_itemController.text);
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            )
          ],
        );
      },
    );
  }

  // Show dialog for updating an existing item
  void _showUpdateItemDialog(String id, String currentName) {
    _itemController.text = currentName;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Item'),
          content: TextField(
            controller: _itemController,
            autofocus: true,
            decoration: InputDecoration(labelText: 'Item Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _updateItem(id, _itemController.text);
                Navigator.of(context).pop();
              },
              child: Text('Update'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            )
          ],
        );
      },
    );
  }

  // Build a list view using StreamBuilder for real-time updates
  Widget _buildInventoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('items').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        final items = snapshot.data!.docs;

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            String itemId = item.id;
            String itemName = item['name'];

            return ListTile(
              title: Text(itemName),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Update button
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      _showUpdateItemDialog(itemId, itemName);
                    },
                  ),
                  // Delete button
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      _deleteItem(itemId);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _buildInventoryList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        tooltip: 'Add Item',
        child: Icon(Icons.add),
      ),
    );
  }
}
