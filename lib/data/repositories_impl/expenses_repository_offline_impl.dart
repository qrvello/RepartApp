import 'package:firebase_database/firebase_database.dart';
import 'package:hive/hive.dart';
import 'package:splitex/domain/models/transaction_model.dart';
import 'package:splitex/domain/models/member_model.dart';
import 'package:splitex/domain/models/group_model.dart';
import 'package:splitex/domain/models/expense_model.dart';
import 'package:splitex/domain/repositories/expenses_repository_offline.dart';

class ExpensesRepositoryOfflineImpl extends ExpensesRepositoryOffline {
  final DatabaseReference databaseReference =
      FirebaseDatabase.instance.reference();

  Box<Group?> _groupsBox = Hive.box<Group?>('groups');

  @override
  Future<bool> addExpense(Group group, Expense expense) async {
    group.members!.forEach((member) {
      // Si el miembro que se recorre actualmente es el que pagó el gasto
      // se suma el balance del miembro previo más lo que cuesta este gasto
      // menos lo que le corresponde pagar a este miembro.

      if (member.id == expense.paidBy) {
        member.balance = member.balance + expense.amount! - member.amountToPay!;
      } else if (member.amountToPay != null) {
        member.balance = member.balance - member.amountToPay!;
      }
    });

    expense.timestamp = DateTime.now().millisecondsSinceEpoch;

    group.expenses!.add(expense);

    group.totalBalance += expense.amount!;

    await _groupsBox.put(group.id, group);

    return true;
  }

  @override
  List<Transaction> balanceDebts(List<Member> members) {
    List<Transaction> transactions = [];
    List<Member> members2 = [];

    // Crea una nueva lista de miembros y copia la lista original para no modificar la original.

    for (Member member in members) {
      Member member2 = Member(
        id: member.id,
        balance: member.balance,
        name: member.name,
      );
      members2.add(member2);
    }

    Iterable<Member> membersWithDebt =
        members2.where((member) => member.balance < 0);

    Iterable<Member> membersWithPositiveBalance =
        members2.where((member) => member.balance > 0);

    // Recorre los miembros con deudas (member1)
    for (Member member1 in membersWithDebt) {
      // Recorre los miembros con balance positivo (member2)
      for (Member member2 in membersWithPositiveBalance) {
        if (member1.balance.abs() <= member2.balance) {
          double toPay = member1.balance.abs();

          member1.balance += toPay;
          member2.balance -= toPay;

          Transaction transaction = Transaction(
            amountToPay: toPay,
            memberToPay: member1,
            memberToReceive: member2,
          );

          transactions.add(transaction);

          break;
        }

        if (member1.balance.abs() > member2.balance) {
          double toPay = member2.balance;

          member1.balance += toPay;
          member2.balance -= toPay;

          Transaction transaction = Transaction(
            amountToPay: toPay,
            memberToPay: member1,
            memberToReceive: member2,
          );

          transactions.add(transaction);
        }
      }
    }

    return transactions;
  }

  @override
  Future<bool> checkTransaction(Group group, Transaction transaction) async {
    Member memberToPay = group.members!
        .firstWhere((member) => member.id == transaction.memberToPay);

    Member memberToReceive = group.members!
        .firstWhere((member) => member.id == transaction.memberToReceive);

    memberToPay.balance += transaction.amountToPay;
    memberToReceive.balance -= transaction.amountToPay;

    transaction.timestamp = DateTime.now().millisecondsSinceEpoch;

    group.transactions!.add(transaction);

    await _groupsBox.put(group.id, group);

    return true;
  }

  @override
  Future<bool> deleteExpense(Expense expense) {
    // TODO: implement deleteExpense
    throw UnimplementedError();
  }
}
