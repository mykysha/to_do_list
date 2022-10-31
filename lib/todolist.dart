// Create class todolist that will serve as a todolist app.
import 'dart:convert';
import 'dart:html';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TodoList extends StatefulWidget {
  const TodoList({super.key});

  @override
  createState() => TodoListState();
}

class TodoListState extends State<TodoList> {
  // Create a list of todo items.
  final List<ToDoItem> _todoItems = CookieManager.getCookie().cast<ToDoItem>();
  /*
  List<ToDoItem> _todoItems = [
    ToDoItem(task: "task1"),
    ToDoItem(task: "task2"),
    ToDoItem(task: "task3")
  ];
  */

  // Create a text controller and use it to retrieve the current value of the TextField.
  final TextEditingController _textController = TextEditingController();

  // Build the whole list of todo items.
  Widget _buildTodoList() {
    CookieManager.setCookie(_todoItems);

    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('todoitems').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Text('No items to display');
        }
        return ReorderableListView.builder(
          itemBuilder: (context, index) {
            return _buildCard(snapshot.data!, index);
          },
          onReorder: (oldIndex, newIndex) {
            setState(
              () {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final items = _todoItems.removeAt(oldIndex);
                _todoItems.insert(newIndex, items);
              },
            );
          },
          itemCount: snapshot.data!.docs.length,
        );
      },
    );
  }

  Widget _buildCard(QuerySnapshot<Map<String, dynamic>> itemQuery, int index) {
    ToDoItem item = ToDoItem.fromMap(itemQuery.docs[index].data());

    return Card(
      key: ValueKey(item),
      child: _buildTodoItem(item, index),
    );
  }

  // Build a single todo item.
  Widget _buildTodoItem(ToDoItem todoItem, int index) {
    // Create a row with a checkbox and a label.
    return Row(
      children: [
        // Add a checkbox.
        Checkbox(
          value: todoItem.isDone,
          onChanged: (bool? value) {
            // When the value of the checkbox changes, update the todo item.
            setState(() {
              _todoItems[index].isDone = value!;
            });
          },
        ),
        // If the item is done, add a strike through to the text.
        Text(
          todoItem.task,
          style: todoItem.isDone
              ? const TextStyle(
                  decoration: TextDecoration.lineThrough,
                )
              : null,
        ),
        IconButton(
            onPressed: () {
              _promptRemoveTodoItem(index);
            },
            icon: const Icon(Icons.highlight_remove_rounded)),
      ],
    );
  }

  void _promptRemoveTodoItem(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove "${_todoItems[index].task}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No, abort'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Yes, continue'),
              onPressed: () {
                _removeTodoItem(index);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _markAsDone(int index) {
    setState(() {
      _todoItems[index].isDone = true;
    });
  }

  void _removeTodoItem(int index) {
    setState(() => _todoItems.removeAt(index));
  }

  // Add a todo item.
  void _addTodoItem() {
    // show input dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add a new task'),
          content: TextField(
            controller: _textController,
            decoration:
                const InputDecoration(hintText: 'Enter something to do...'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                setState(() {
                  // _todoItems.add(ToDoItem(task: _textController.text));
                  FirebaseFirestore.instance.collection('todoitems').add({
                    'task': _textController.text,
                    'isDone': false,
                    'position': _todoItems.length
                  });
                });
                _textController.clear();
                Navigator.pop(context);
              },
            )
          ],
        );
      },
    );
  }

  // Build the whole screen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todo List')),
      body: _buildTodoList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTodoItem,
        tooltip: 'Add task',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ToDoItem {
  String task;
  bool isDone;

  ToDoItem({required this.task, this.isDone = false});

  void toggleDone() {
    isDone = !isDone;
  }

  // fromJson and toJson are used to convert the object to and from a JSON string.
  factory ToDoItem.fromJson(Map<String, dynamic> json) => ToDoItem(
        task: json['task'],
        isDone: json['isDone'],
      );

  Map<String, dynamic> toJson() => {
        'task': task,
        'isDone': isDone,
      };

  // fromMap is used to convert the Map to an object.
  factory ToDoItem.fromMap(Map<String, dynamic> map) => ToDoItem(
        task: map['task'],
        isDone: map['isDone'],
      );
}

class CookieManager {
  static void setCookie(List<ToDoItem> value) {
    final cookie = jsonEncode(value);
    final date = DateTime.now();
    date.add(const Duration(days: 1));
    document.cookie = 'todolistcookie=$cookie;expires=$date';
  }

  static List<dynamic> getCookie() {
    final fullCookie = document.cookie;

    if (fullCookie == null) {
      return [];
    }

    final cookies = fullCookie.split(';');

    for (final cookie in cookies) {
      final cookieName = cookie.split('=')[0];
      if (cookieName == 'todolistcookie') {
        final cookieValue = cookie.split('=')[1];

        Iterable l = json.decode(cookieValue);
        List<ToDoItem> decodedCookie =
            List<ToDoItem>.from(l.map((model) => ToDoItem.fromJson(model)));

        return decodedCookie;
      }
    }

    return [];
  }

  static void deleteCookie() {
    final date = DateTime.now();
    date.subtract(const Duration(days: 1));
    document.cookie = 'todolistcookie=;expires=$date';
  }
}
