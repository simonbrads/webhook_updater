import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

class Webhook {
  final String description;
  final String url;
  final bool active;
  final List<String> events;

  Webhook.fromJson(Map<String, dynamic> json)
      : description = json['description'],
        url = json['url'],
        active = json['active'],
        events = List<String>.from(json['events']);

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'url': url,
      'active': active,
      'events': events,
    };
  }
}

Observable<List<Webhook>> getWebhooks() {
  final future = Firestore.instance.collection('hooks').getDocuments();
  return Observable.fromFuture(future).map((qs) => qs.documents.map((ds) => Webhook.fromJson(ds.data)).toList());
}

Observable<Webhook> getWebhook(String name) {
  final future = Firestore.instance.collection('hooks').document(name);
  return Observable.fromFuture(future.get()).map((ds) => Webhook.fromJson(ds.data));
}
