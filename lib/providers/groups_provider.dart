//import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:repartapp/models/expense_model.dart';
import 'package:repartapp/models/group_model.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:repartapp/models/member_model.dart';
import 'package:repartapp/models/transaction_model.dart';
import 'package:repartapp/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroupsProvider {
  final user = auth.FirebaseAuth.instance.currentUser;

  final databaseReference = FirebaseDatabase.instance.reference();

  Stream<Group> getGroup(Group group) async* {
    Group groupComplete;

    DatabaseReference groupReference =
        databaseReference.child('groups/${group.id}');

    Stream<Event> groupStream = groupReference.onValue;

    await for (Event event in groupStream) {
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value != null) {
        Group thisGroup = Group.fromMap(snapshot.value, snapshot.key);

        groupComplete = thisGroup;
      }

      yield groupComplete;
    }
  }

  Stream<List<Group>> getGroupsList() async* {
    final List<Group> foundGroups = [];

    if (user != null) {
      DatabaseReference userGroups =
          databaseReference.child('users_groups/${user.uid}/groups');

      Stream<Event> userGroupsStream = userGroups.orderByKey().onValue;

      await for (Event event in userGroupsStream) {
        foundGroups.clear();

        if (event.snapshot.value != null) {
          Map<dynamic, dynamic> mapGroups = event.snapshot.value;

          mapGroups.forEach((id, group) {
            final Group thisGroup = Group.fromMap(group, id);
            foundGroups.add(thisGroup);
          });

          yield foundGroups;
        }
      }
    }
    yield foundGroups;
  }

  Future<bool> createGroup(Group group) async {
    // Guarda el id del creador del grupo
    group.adminUser = user.uid;

    // Crea la referencia con una key creada por firebase

    final newChildGroupRef = databaseReference.child('/groups').push();

    // Crea la referencia en usuarios con la key anterior
    final newChildUserGroupsRef = databaseReference
        .child('/users_groups/${user.uid}/groups/${newChildGroupRef.key}');

    // Guarda la data en un mapa

    final Map<String, dynamic> dataUser = {
      'name': group.name,
      'admin_user': group.adminUser,
      'timestamp': ServerValue.timestamp,
    };

    final prefs = await SharedPreferences.getInstance();

    final name = prefs.getString('displayName');

    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://repartapp2.page.link/',
      link:
          Uri.parse('https://repartapp2.page.link/?id=${newChildGroupRef.key}'),
      androidParameters: AndroidParameters(
        packageName: 'com.curvello.repartapp',
        minimumVersion: 1,
      ),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: 'Link para unirse a ${group.name}',
        description: 'This link works whether app is installed or not!',
      ),
      navigationInfoParameters: NavigationInfoParameters(
        forcedRedirectEnabled: true,
      ),
    );

    final ShortDynamicLink shortDynamicLink = await parameters.buildShortLink();

    final Uri shortUrl = shortDynamicLink.shortUrl;

    final Map<String, dynamic> data = {
      'members': {
        name: {
          "balance": 0,
        },
      },
      'users': {
        user.uid: true,
      },
      'total_balance': 0,
      'link': shortUrl.toString(),
    };

    data.addAll(dataUser);

    // Crea un mapa para usar multiple paths al insertar datos
    final Map<String, dynamic> mapRefs = {
      newChildGroupRef.path: data,
      newChildUserGroupsRef.path: dataUser,
    };

    databaseReference.update(mapRefs).catchError((onError) {
      print("Error al crear nuevo grupo: $onError");
      return false;
    });

    return true;
  }

  Future<bool> updateGroup(Group group) async {
    // Obtiene la referencia

    final DatabaseReference groupRef =
        databaseReference.child('groups/${group.id}/');

    // Crea un mapa para usar multiple paths al insertar datos
    Map<String, dynamic> updateObj = {
      "${groupRef.path}/name": group.name,
    };

    group.users.keys.forEach((user) {
      updateObj.putIfAbsent(
          'users_groups/$user/groups/${group.id}/name', () => group.name);
    });

    databaseReference.update(updateObj).catchError((onError) {
      print("Error al actualizar el grupo: $onError");
      return false;
    });

    return true;
  }

  Future<bool> deleteGroup(Group group) async {
    Map<String, dynamic> removeObj = {};

    // Valida que el admin del grupo sea el usuario que lo elimina sino solo lo borra de mis grupos
    if (group.adminUser == user.uid) {
      final String groupPath =
          databaseReference.child('/groups/${group.id}').path;
      removeObj = {groupPath: null};
      final DataSnapshot users =
          await databaseReference.child('/groups/${group.id}/users').once();

      // Si las keys recibe null (por ejemplo si solo hay una key) entonces solo borra del único miembro que está en el grupo.
      if (users.value != null) {
        users.value.keys.forEach((key) {
          removeObj.putIfAbsent(
              '/users_groups/$key/groups/${group.id}', () => null);
        });
      }
    } else {
      removeObj.putIfAbsent('/group/${group.id}/users/${user.uid}', () => null);
    }

    removeObj.putIfAbsent(
        '/users_groups/${user.uid}/groups/${group.id}', () => null);

    databaseReference.update(removeObj).catchError((error) {
      print('error al borrar o salir del grupo $error');
      return false;
    });

    return true;
  }

  Future<bool> addExpense(Group group, Expense expense) async {
    final DatabaseReference groupReference =
        databaseReference.child('groups/${group.id}');

    final DatabaseReference newChildExpenseReference =
        groupReference.child('expenses').push();

    final List<Member> members = group.members;

    final int countMembers = members.length;

    Map<String, dynamic> updateObj = {
      '${groupReference.path}/total_balance':
          group.totalBalance + expense.amount,
      newChildExpenseReference.path: expense.toMap(),
    };

    // Solo usa 2 decimales
    double debtForEach = (expense.amount / countMembers);

    debtForEach = double.parse(debtForEach.toStringAsFixed(2));
    members.forEach((member) {
      double updatedBalance = 0;

      if (member.id == expense.paidBy) {
        updatedBalance = member.balance + expense.amount - member.amountToPay;
      } else {
        updatedBalance = member.balance - member.amountToPay;
      }

      updateObj.putIfAbsent(
        '${groupReference.path}/members/${member.id}/',
        () => {"balance": updatedBalance},
      );
    });

    await databaseReference.update(updateObj).catchError((error) {
      print("Error al agregar gasto: ${error.message}");
      return false;
    });

    return true;
  }

  Future<bool> deleteExpense(Group group, Expense expense) async {
    // ignore: todo
    // TODO restar balance que se habia agregado previamente con el gasto

    await databaseReference
        .child('groups/${group.id}/expenses/${expense.id}')
        .remove()
        .catchError((onError) {
      print('Error al borrar expensa ${onError.message}');
      return false;
    });

    return true;
  }

  Future<bool> addUserToGroup(User userToInvite, Group group) async {
    final DataSnapshot snapshotMembers =
        await databaseReference.child('groups/${group.id}/users').once();

    if (snapshotMembers.value != null) {
      List keysList = [];
      snapshotMembers.value.forEach((key, value) {
        if (key != null) {
          keysList.add(key);
        }
      });

      // Verifica que no llegue data nula
      if (keysList.length > 1) {
        // Recorre las keys de los miembros para compararlas con el uid del usuario que se quiere agregar
        Map keys = snapshotMembers.value.keys;
        if (keys.containsKey(userToInvite.id)) {
          // Si el usuario que se quiere agregar ya esta en el grupo entonces retorna falso.
          return false;
        }
      }
    }
    // Sino, se agrega al grupo
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await databaseReference
        .child('users_requests/${userToInvite.id}/groups')
        .update({
      group.id: {
        'name': group.name,
        'invited_by': prefs.getString('displayName'),
      }
    }).catchError((error) {
      print('Error al invitar a usuario $error');
      return false;
    });

    return true;
  }

  Future<dynamic> acceptInvitationGroup(String groupId) async {
    DataSnapshot snapshot =
        await databaseReference.child('groups/$groupId').once();

    Group group;

    if (snapshot.value != null) {
      group = Group.fromMap(snapshot.value, snapshot.key);
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();

    final requestUserPath = databaseReference
        .child('users_requests/${user.uid}/groups/${group.id}/')
        .path;

    final usersGroupPath =
        databaseReference.child('groups/${group.id}/users/${user.uid}').path;

    final membersGroupPath = databaseReference
        .child('groups/${group.id}/members/${prefs.getString('displayName')}')
        .path;

    final groupsUserPath = databaseReference
        .child('users_groups/${user.uid}/groups/${group.id}')
        .path;

    final Map<String, dynamic> data = {
      'name': group.name,
      'timestamp': group.timestamp,
    };

    final Map<String, dynamic> updateObj = {
      usersGroupPath: true,
      groupsUserPath: data,
      membersGroupPath: {'balance': 0},
      requestUserPath: null,
    };

    await databaseReference.update(updateObj).catchError((onError) {
      print("Error al aceptar invitacion: $onError");
      return false;
    });

    return group;
  }

  void addPersonToGroup(String name, Group group) {
    final newChildMember =
        databaseReference.child('/groups/${group.id}/members/$name');

    newChildMember.update({
      "balance": 0,
    });
  }

  List<Transaction> balanceDebts(List<Member> members2) {
    List<Transaction> transactions = [];
    List<Member> members = [];

    // Crea una nueva lista de miembros y copia la lista original para no modificar la original.

    for (Member member in members2) {
      Member member2 = Member();
      member2.id = member.id;
      member2.balance = member.balance;
      members.add(member2);
    }

    Iterable<Member> membersWithDebt =
        members.where((member) => member.balance < 0);

    Iterable<Member> membersWithPositiveBalance =
        members.where((member) => member.balance > 0);

    for (Member member1 in membersWithDebt) {
      for (Member member2 in membersWithPositiveBalance) {
        if (member1.balance.abs() <= member2.balance) {
          double toPay = member1.balance.abs();

          member1.balance += toPay;
          member2.balance -= toPay;

          Transaction transaction = Transaction();

          transaction.amountToPay = toPay;
          transaction.memberToPay = member1;
          transaction.memberToReceive = member2;

          transactions.add(transaction);

          break;
        }

        if (member1.balance.abs() > member2.balance) {
          double toPay = member2.balance;

          member1.balance += toPay;
          member2.balance -= toPay;

          Transaction transaction = Transaction();

          transaction.amountToPay = toPay;
          transaction.memberToPay = member1;
          transaction.memberToReceive = member2;

          transactions.add(transaction);
        }
      }
    }

    return transactions;
  }

  Future<bool> checkTransaction(Transaction transaction, Group group) async {
    DatabaseReference groupReference =
        databaseReference.child('/groups/${group.id}');

    String groupMembersPath = groupReference.child('/members').path;

    String newTransactionChildPath =
        groupReference.child('transactions').push().path;

    Member memberToPay = group.members
        .firstWhere((member) => member.id == transaction.memberToPay.id);

    Member memberToReceive = group.members
        .firstWhere((member) => member.id == transaction.memberToReceive.id);

    memberToPay.balance += transaction.amountToPay;
    memberToReceive.balance -= transaction.amountToPay;

    Map<String, dynamic> updateObj = {
      '$groupMembersPath/${memberToPay.id}/balance': memberToPay.balance,
      '$groupMembersPath/${memberToReceive.id}/balance':
          memberToReceive.balance,
      newTransactionChildPath: transaction.toMap(),
    };

    await databaseReference.update(updateObj).catchError((onError) {
      print('Error al chequear transacción: ${onError.message}');
      return false;
    });

    return true;
  }

  void deleteMember(Group group, Member member) async {
    await databaseReference
        .child('/groups/${group.id}/members/${member.id}')
        .remove();
    return;
  }
}
