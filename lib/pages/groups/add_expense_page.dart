import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:repartapp/models/expense_model.dart';
import 'package:repartapp/models/group_model.dart';
import 'package:repartapp/models/member_model.dart';

import 'package:repartapp/providers/groups_provider.dart';

class AddExpensePage extends StatefulWidget {
  final Group group;
  AddExpensePage({this.group});
  @override
  _AddExpensePageState createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final groupProvider = new GroupsProvider();

  final _expenseNameController = new TextEditingController();
  final _expenseAmountController = new TextEditingController();

  final formKey = GlobalKey<FormState>();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  Expense expense = new Expense();
  bool _guardando = false;
  bool error = false;
  String dropdownValue = '';
  bool allCheckbox = true;
  List<Member> payingMembers = [];

  @override
  void initState() {
    payingMembers = List.from(widget.group.members);
    super.initState();
  }

  @override
  void dispose() {
    _expenseNameController.dispose();
    _expenseAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    final List<DropdownMenuItem<String>> items = [
      DropdownMenuItem(
        value: '',
        child: Text('Seleccioná'),
      ),
    ];

    // Crea los items para el dropdown con los miembros.

    for (Member member in widget.group.members) {
      items.add(
        DropdownMenuItem(
          value: member.id,
          child: Text(member.id),
        ),
      );
    }

    return Scaffold(
      key: scaffoldKey,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.check_rounded),
        onPressed: () {
          _submit(context);
        },
      ),
      appBar: AppBar(title: Text('Agregar gasto')),
      body: Form(
        key: formKey,
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                children: [
                  (error)
                      ? Container(
                          margin: EdgeInsets.only(bottom: 20, top: 5),
                          child: Text(
                            'Error al agregar gasto',
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        )
                      : SizedBox.shrink(),
                  _inputDescription(),
                  SizedBox(height: 12),
                  _inputAmount(),
                  SizedBox(height: 16),
                  Container(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Pagado por'),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      isExpanded: true,
                      value: dropdownValue,
                      onChanged: (newValue) {
                        setState(() {
                          dropdownValue = newValue;
                        });
                      },
                      onSaved: (value) => expense.paidBy = value,
                      items: items,
                      validator: (value) {
                        if (value == '') {
                          return 'Seleccione un miembro';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            CheckboxListTile(
              activeColor: Color(0xff0076ff),
              controlAffinity: ListTileControlAffinity.leading,
              checkColor: Colors.white,
              secondary: TextButton(
                child: Text('Avanzado'),
                onPressed: () {
                  // TODO Division de gastos avanzada
                },
              ),
              tileColor: Color(0xff1c1e20).withOpacity(0.3),
              value: allCheckbox,
              title: Text('Para quien'),
              onChanged: (value) {
                setState(() {
                  allCheckbox = value;

                  // Todos los miembros se ponen del valor que este sea
                  if (value == true) {
                    payingMembers = List.from(widget.group.members);
                  } else {
                    payingMembers = [];
                  }
                  widget.group.members.forEach((Member member) {
                    member.amountToPay = 0;
                    member.checked = value;
                  });
                });
                calculateDivision();
              },
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(bottom: size.height * 0.01),
                itemCount: widget.group.members.length,
                itemBuilder: (context, index) {
                  return CheckboxListTile(
                    secondary: Text(
                        widget.group.members[index].amountToPay.toString()),
                    activeColor: Color(0xff0076ff),
                    controlAffinity: ListTileControlAffinity.leading,
                    checkColor: Colors.white,
                    title: Text(widget.group.members[index].id),
                    value: widget.group.members[index].checked,
                    onChanged: (value) {
                      setState(() {
                        widget.group.members[index].checked = value;
                        if (value == true) {
                          payingMembers.add(widget.group.members[index]);
                        } else {
                          widget.group.members[index].amountToPay = 0;
                          payingMembers.remove(widget.group.members[index]);
                        }
                      });
                      calculateDivision();
                    },
                  );
                },
              ),
            ),
            SizedBox(
              height: size.height * 0.1,
            )
          ],
        ),
      ),
    );
  }

  Widget _inputDescription() {
    return TextFormField(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      autofocus: true,
      maxLength: 25,
      style: TextStyle(fontSize: 20),
      decoration: InputDecoration(
        helperText: 'Ejemplo: almuerzo',
        labelText: 'Descripción',
      ),
      onSaved: (value) => expense.description = value,
      controller: _expenseNameController,
      validator: (value) {
        if (value.trim().isEmpty) return 'Por favor ingresá una descripción';
        return null;
      },
    );
  }

  Widget _inputAmount() {
    return TextFormField(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: TextStyle(fontSize: 20),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.attach_money),
        labelText: 'Cantidad',
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,2}')),
      ],
      onChanged: (_) {
        calculateDivision();
      },
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      controller: _expenseAmountController,
      onSaved: (value) => expense.amount = double.tryParse(value).toDouble(),
      validator: (value) {
        if (value.trim().isEmpty) return 'Por favor ingresa un número';
        if (_isNumeric(value.trim()) != false) {
          return null;
        } else {
          return 'Por favor ingresa solo números.';
        }
      },
    );
  }

  void _submit(context) async {
    if (!formKey.currentState.validate()) return;

    formKey.currentState.save();

    bool resp = await groupProvider.addExpense(widget.group, expense);

    if (resp != false) {
      error = false;
      Navigator.pop(context);
    } else {
      setState(() {
        error = true;
      });
    }
  }

  bool _isNumeric(String str) {
    if (str == null) {
      return false;
    }
    return double.tryParse(str) != null;
  }

  void calculateDivision() {
    setState(() {
      double debtForEach = (double.tryParse(_expenseAmountController.text) /
          payingMembers.length);

      debtForEach = double.parse(debtForEach.toStringAsFixed(2));

      payingMembers.forEach((member) {
        member.amountToPay = debtForEach;
      });
    });
  }
}