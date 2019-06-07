import 'package:flutter/material.dart';

import 'firebase.dart';

class WebhookPickerDialog extends StatefulWidget {
  final List<Webhook> _webhooks;

  WebhookPickerDialog(this._webhooks);

  @override
  _WebhookPickerDialogState createState() => _WebhookPickerDialogState(_webhooks);
}

class _WebhookPickerDialogState extends State<WebhookPickerDialog> {
  List<Webhook> _webhooks;
  Webhook _webhook;

  _WebhookPickerDialogState(this._webhooks);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Webhook'),
      content: Container(
        width: double.maxFinite,
        child: Scrollbar(
          child: ListView(
            children: _webhooks.map((w) {
              return RadioListTile(
                title: Text(w.description),
                value: w,
                groupValue: _webhook,
                onChanged: (w) => setState(() => _webhook = w),
              );
            }).toList(),
          ),
        ),
      ),
      actions: <Widget>[
        FlatButton(
          child: const Text('Select'),
          onPressed: () {
            Navigator.of(context).pop(_webhook);
          },
        ),
      ],
    );
  }
}
