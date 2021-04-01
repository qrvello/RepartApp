import 'package:flutter/material.dart';
import 'package:repartapp/models/expense_model.dart';
import 'package:repartapp/models/group_model.dart';
import 'package:repartapp/models/transaction_model.dart';

class ActivityWidget extends StatefulWidget {
  final Group group;

  const ActivityWidget({Key key, this.group}) : super(key: key);
  @override
  _ActivityWidgetState createState() => _ActivityWidgetState();
}

class _ActivityWidgetState extends State<ActivityWidget> {
  List actions = [];
  @override
  void initState() {
    super.initState();
    for (Expense expense in widget.group.expenses) {
      actions.add(expense);
    }
    for (Transaction transaction in widget.group.transactions) {
      actions.add(transaction);
    }
    setState(() {
      actions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return CustomScrollView(
      slivers: <Widget>[
        SliverAppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xff0076ff).withOpacity(0.87),
              borderRadius: BorderRadius.circular(12),
            ),
            child: (widget.group.totalBalance > 0)
                ? Text(
                    'Gasto total: \$${widget.group.totalBalance}',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  )
                : Text(
                    'Sin gastos',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
          ),
          centerTitle: true,
          floating: true,
        ),
        SliverPadding(
          padding: EdgeInsets.only(bottom: size.height * 0.1),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _createItem(actions[i]),
              childCount: actions.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _createItem(action) {
    if (action is Expense) {
      Expense expense = action;
      return Card(
        child: ListTile(
          //subtitle: Text('Pagado por ${expense.paidBy}'),
          subtitle: Text('Pagado por ${expense.paidBy}'),
          title: Text(
            expense.description,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          trailing: Text(
            "\$${expense.amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 16,
              color: Color(0xffF4a74d),
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: Container(
            margin: EdgeInsets.only(left: 10),
            height: double.infinity,
            child: Icon(
              Icons.shopping_bag_rounded,
              color: Color(0xff0076FF),
            ),
          ),
        ),
      );
    }
    Transaction transaction = action;
    return Card(
      child: ListTile(
        title: Text(
            '${transaction.memberToPay.id} le pagó a ${transaction.memberToReceive.id}'),
        trailing: Text(
          '\$${transaction.amountToPay.toStringAsFixed(2)}',
          style: TextStyle(
            color: Color(0xff25C0B7),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: Container(
          margin: EdgeInsets.only(left: 10),
          height: double.infinity,
          child: Icon(
            Icons.sync_alt_rounded,
            color: Color(0xff0076FF),
          ),
        ),
      ),
    );
  }
}
