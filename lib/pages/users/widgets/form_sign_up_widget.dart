import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:repartapp/providers/authentication_provider.dart';
import 'package:repartapp/pages/users/widgets/google_sign_up_button_widget.dart';

import 'google_sign_up_button_widget.dart';

class FormSignUp extends StatefulWidget {
  @override
  _FormSignUpState createState() => _FormSignUpState();
}

class _FormSignUpState extends State<FormSignUp> {
  final TextEditingController _password = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _email.dispose();
    _name.dispose();
    super.dispose();
  }

  bool _obscureText = true;
  bool _error = false;

  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final _formKey = GlobalKey<FormState>();

    return SingleChildScrollView(
      child: Column(
        children: [
          SafeArea(
            child: Container(
              height: size.height * 0.025,
            ),
          ),
          Container(
            width: (size.width > 1200) ? size.width * 0.40 : size.width * 0.85,
            margin: EdgeInsets.symmetric(vertical: 30.0),
            padding: EdgeInsets.symmetric(vertical: 50.0),
            decoration: BoxDecoration(
              color: Color(0xfff8f9fa),
              borderRadius: BorderRadius.circular(18.0),
            ),
            child: Column(
              children: <Widget>[
                _error != false
                    ? Container(
                        height: 32,
                        child: Text(
                          'Error al iniciar sesión: $_error',
                          style:
                              TextStyle(color: Color(0xffe76f51), fontSize: 22),
                        ),
                      )
                    : SizedBox.shrink(),
                Text(
                  'Registrate',
                  style: TextStyle(
                    fontSize: 20.0,
                    color: Colors.black,
                  ),
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SizedBox(height: 30.0),
                      _nameInput(),
                      SizedBox(height: 30.0),
                      _emailInput(),
                      SizedBox(height: 30.0),
                      _passwordInput(),
                      SizedBox(height: 30.0),
                      _button(_formKey, context),
                    ],
                  ),
                ),
                GoogleSignUpButtonWidget(),
              ],
            ),
          ),
          Container(
            width: size.width * 0.85,
            child: TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
              child: Text(
                '¿Ya te registraste? Iniciá sesión acá',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 17,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            child: Text(
              'Recuperá tu contraseña',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 17,
                letterSpacing: 1,
              ),
            ),
            // ignore: todo
            // TODO recuperar contraseña
          ),
        ],
      ),
    );
  }

  Widget _emailInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.0),
      child: TextFormField(
        style: TextStyle(color: Colors.black),
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xff0076ff),
            ),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xff0076ff),
            ),
          ),
          border: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xff0076ff),
            ),
          ),
          icon: Icon(
            Icons.alternate_email_rounded,
            color: Color(0xff0076ff),
          ),
          labelStyle: TextStyle(
            color: Color(0xff0076ff),
          ),
          hintText: 'ejemplo@correo.com',
          labelText: 'Correo electrónico',
        ),
        validator: (input) => input.trim().isValidEmail()
            ? null
            : "El email ingresado es incorrecto",
        controller: _email,
      ),
    );
  }

  Widget _passwordInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.0),
      child: TextFormField(
        style: TextStyle(color: Colors.black),
        obscureText: _obscureText,
        decoration: InputDecoration(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xff0076ff),
            ),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xff0076ff),
            ),
          ),
          border: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xff0076ff),
            ),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
            ),
            color: Color(0xff0076ff),
            onPressed: () {
              _toggle();
            },
          ),
          labelStyle: TextStyle(
            color: Color(0xff0076ff),
          ),
          icon: Icon(
            Icons.lock_outline_rounded,
            color: Color(0xff0076ff),
          ),
          labelText: 'Contraseña',
        ),
        validator: (value) {
          if (value.isEmpty) {
            return 'Ingrese una contraseña';
          }
          if (value.trim().length < 6) {
            return 'Ingrese una contraseña mayor a 6 caracteres';
          }
          return null;
        },
        controller: _password,
      ),
    );
  }

  Widget _button(_formKey, context) {
    return Container(
      width: 250,
      padding: EdgeInsets.all(4),
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState.validate()) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Registrandose...'),
              ),
            );
            _submit();
          }
        },
        child: Text('Registrarse'),
      ),
    );
  }

  void _submit() async {
    final firebaseInstance = FirebaseAuth.instance;

    final resp = await AuthenticationProvider(firebaseInstance)
        .signUp(_email.text.trim(), _password.text, _name.text.trim());

    if (resp != true) {
      _error = resp;
      setState(() {});
      return;
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    Navigator.of(context).pushNamed('/');
  }

  Widget _nameInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.0),
      child: TextFormField(
        style: TextStyle(color: Colors.black),
        keyboardType: TextInputType.name,
        decoration: InputDecoration(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xff0076ff),
            ),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xff0076ff),
            ),
          ),
          border: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xff0076ff),
            ),
          ),
          icon: Icon(
            Icons.person_rounded,
            color: Color(0xff0076ff),
          ),
          labelStyle: TextStyle(color: Color(0xff0076ff)),
          labelText: 'Nombre',
        ),
        validator: (value) =>
            (value.trim().isEmpty) ? 'Ingrese un nombre' : null,
        controller: _name,
      ),
    );
  }
}

extension EmailValidator on String {
  bool isValidEmail() {
    return RegExp(
            r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(this);
  }
}