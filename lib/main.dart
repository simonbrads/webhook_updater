import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import 'bitbucket.dart';
import 'firebase.dart';
import 'webhook_picker.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Webhook Updater',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();

  final _workspaceController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  Webhook _webhook;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Webhook Updater'),
      ),
      body: Builder(
        builder: (BuildContext context) {
          return Stack(
            children: <Widget>[
              Visibility(
                visible: _isLoading,
                child: SizedBox.expand(
                  child: Container(
                    decoration: BoxDecoration(color: Color.fromARGB(128, 0, 0, 0)),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                ignoring: _isLoading,
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: EdgeInsets.only(left: 20, right: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          TextFormField(
                            controller: _workspaceController,
                            decoration: InputDecoration(labelText: 'Workspace'),
                            validator: (value) => value.isEmpty ? 'Please enter the workspace' : null,
                          ),
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(labelText: 'Username'),
                            validator: (value) => value.isEmpty ? 'Please enter your username' : null,
                          ),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(labelText: 'Password'),
                            validator: (value) => value.isEmpty ? 'Please enter your password' : null,
                            obscureText: true,
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: <Widget>[
                              RaisedButton(
                                color: Colors.green,
                                textColor: Colors.white,
                                child: const Text('Select'),
                                onPressed: _showWebhookPicker,
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                child: Text(_webhook != null ? _webhook.description : 'Select webhook'),
                              ),
                            ],
                          ),
                          RaisedButton(
                            color: Colors.green,
                            textColor: Colors.white,
                            child: const Text('Submit'),
                            onPressed: () => _processWebhook(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  _showWebhookPicker() {
    setState(() => _isLoading = true);

    getWebhooks().listen((webhooks) {
      setState(() => _isLoading = false);

      Observable.fromFuture(showDialog(
        context: context,
        builder: (context) {
          return WebhookPickerDialog(webhooks);
        },
      )).listen((webhook) => setState(() => _webhook = webhook));
    });
  }

  _processWebhook(BuildContext context) {
    if (!_formKey.currentState.validate()) {
      return;
    }

    if (_webhook == null) {
      final snackBar = SnackBar(content: Text('Select webhook first.'));
      Scaffold.of(context).showSnackBar(snackBar);
      return;
    }

    setState(() => _isLoading = true);

    final api = BitbucketApi(_workspaceController.text, _usernameController.text, _passwordController.text);
    final failures = <String>[];
    var count = 0;
    var errors = 0;

    api
        .getRepositories()
        .flatMap((repo) => api.getWebhooks(repo).map((hooks) => {'repo': repo, 'hooks': hooks}))
        .flatMap((data) {
      final String repo = data['repo'];
      final List<Map<String, dynamic>> hooks = data['hooks'];

      final hook = hooks.firstWhere((h) => h['description'] == _webhook.description, orElse: () => null);

      final success =
          hook == null ? api.createWebhook(repo, _webhook) : api.updateWebhook(repo, hook['uuid'], _webhook);

      return success.map((success) => {'repo': repo, 'success': success});
    }).listen((data) {
      final String repo = data['repo'];
      final bool success = data['success'];

      if (success) {
        count++;
        print('Processed hook for $repo ($count)');
      } else {
        failures.add('$repo');
        print('Failed to process hook for $repo ($count)');
      }
    }, onError: (e) {
      errors++;
      print('Unknown error: $e');
    }, onDone: () {
      setState(() => _isLoading = false);
      showDialog(context: context, builder: (context) => _createResultDialog(count, errors, failures));
    });
  }

  AlertDialog _createResultDialog(int count, int errors, List<String> failures) {
    final sb = StringBuffer();
    sb.writeln('$count repositories processed.');
    sb.writeln('${failures.length} failed repositor${failures.length == 1 ? 'y' : 'ies'}.');
    sb.write('$errors unknown error${errors == 1 ? '' : 's'}.');

    if (failures.isNotEmpty) {
      sb.writeln('\n\nFailed repositories:\n');
      sb.write(failures.join('\n'));
    }

    return AlertDialog(
      title: const Text('Results'),
      content: Container(
        width: double.maxFinite,
        child: Scrollbar(
          child: SingleChildScrollView(
            child: Text(
              sb.toString(),
              textScaleFactor: .7,
            ),
          ),
        ),
      ),
      actions: <Widget>[
        FlatButton(
          child: const Text('OK'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
