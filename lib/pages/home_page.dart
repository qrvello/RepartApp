import 'package:flutter/material.dart';
import 'package:gastos_grupales/widgets/side_menu.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      drawer: SideMenu(),
      floatingActionButton: new FloatingActionButton(
        onPressed: () =>
            Navigator.pushReplacementNamed(context, 'create_group'),
        child: Icon(Icons.add),
      ),
    );
  }
}