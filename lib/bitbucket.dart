import 'dart:convert';

import 'package:http/http.dart';
import 'package:rxdart/rxdart.dart';

import 'firebase.dart';

class BitbucketApi {
  String _workspace;
  String _username;
  String _appPassword;

  BitbucketApi(this._workspace, this._username, this._appPassword);

  String get _auth => base64.encode(ascii.encode('$_username:$_appPassword'));

  Observable<String> getRepositories() {
    final subject = ReplaySubject<String>();
    final uri = 'https://api.bitbucket.org/2.0/repositories/$_workspace';
    getValuesFromUri(uri, subject);
    return subject;
  }

  getValuesFromUri(String uri, Subject<String> subject) {
    Observable.fromFuture(get(uri, headers: {'Authorization': 'Basic $_auth'})).listen((response) {
      final json = jsonDecode(response.body);
      final values = json['values'];

      for (final value in values) {
        subject.add(value['name']);
      }

      if (json['next'] != null) {
        getValuesFromUri(json['next'], subject);
      } else {
        subject.close();
      }
    });
  }

  Observable<List<Map<String, dynamic>>> getWebhooks(String repo) {
    return Observable.fromFuture(get('https://api.bitbucket.org/2.0/repositories/$_workspace/$repo/hooks',
        headers: {'Authorization': 'Basic $_auth'})).map((response) {
      final json = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(json['values']);
    });
  }

  Observable<bool> createWebhook(String repo, Webhook webhook) {
    return Observable.fromFuture(post('https://api.bitbucket.org/2.0/repositories/$_workspace/$repo/hooks',
            headers: {'Authorization': 'Basic $_auth'}, body: jsonEncode(webhook)))
        .map((response) => response.statusCode >= 200 && response.statusCode < 300);
  }

  Observable<bool> updateWebhook(String repo, String uuid, Webhook webhook) {
    return Observable.fromFuture(put('https://api.bitbucket.org/2.0/repositories/$_workspace/$repo/hooks/$uuid',
            headers: {'Authorization': 'Basic $_auth'}, body: jsonEncode(webhook)))
        .map((response) => response.statusCode == 200);
  }
}
