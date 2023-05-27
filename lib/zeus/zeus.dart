import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import 'dart:convert';
import 'dart:io';

Future<Zeus> fetchSchedule(
    {String url =
        'https://zeus.ionis-it.com/api/group/481/ics/ZVYpfiEoGM'}) async {
  // temporarily, to not get blacklisted by ionis servers
  File file = File('zeus.json');
  if (file.existsSync()) {
    print('loading zeus from file');
    return Zeus.fromJson(jsonDecode(file.readAsStringSync()));
  }
  //
  final response = await http.get(Uri.parse(url));
  print('Got response: $response');
  if (response.statusCode != 200) {
    throw Exception('Got invalid status code: ${response.statusCode}');
  }
  var zeus = Zeus(ICalendar.fromString(response.body.toString()));
  String encoded = jsonEncode(zeus);
  File('zeus.json').writeAsStringSync(encoded);
  return zeus;
}

class Zeus {
  late List<ZClass> classes;

  Zeus(ICalendar ical) {
    classes = ical.data
        .map((event) => ZClass.fromICal(event))
        .whereType<ZClass>()
        .toList();
  }

  /// Removes past classes and orders them by start date
  void preprocess() {
    var now = DateTime.now();
    classes = classes.where((zclass) => zclass.start.isAfter(now)).toList();
    classes.sort((a, b) => a.start.compareTo(b.start));
  }

  @override
  String toString() => 'Zeus:[${classes.join()}]';

  Zeus.fromJson(Map<String, dynamic> json)
      : classes = json["classes"]
            .map<ZClass>((zclass) => ZClass.fromJson(zclass))
            .toList();

  Map<String, dynamic> toJson() =>
      {"classes": classes.map((zclass) => zclass.toJson()).toList()};
}

class ZClass {
  DateTime start;
  DateTime end;
  String description;
  String? summary;
  String? location;
  String? url;

  ZClass._(this.start, this.end, this.description, this.summary, this.location,
      this.url);

  static ZClass? fromICal(Map<String, dynamic> event) {
    // mandatory keys
    for (var key in ["dtstart", "dtend", "description"]) {
      if (!event.containsKey(key)) {
        return null;
      }
    }
    IcsDateTime icsStart = event["dtstart"];
    IcsDateTime icsEnd = event["dtend"];
    DateTime? start = icsStart.toDateTime();
    DateTime? end = icsEnd.toDateTime();
    if (start == null || end == null) {
      return null;
    }
    return ZClass._(
        start,
        end,
        fixEncoding(event["description"])!,
        fixEncoding(event["summary"]),
        fixEncoding(event["location"]),
        fixEncoding(event["url"]));
  }

  @override
  String toString() =>
      'ZClass{\n\tstart: $start\n\tend: $end\n\tdescription: $description\n\tsummary: $summary\n\tlocation: $location\n\turl: $url\n}\n';

  Map<String, dynamic> toJson() => {
        "start": start.millisecondsSinceEpoch,
        "end": end.millisecondsSinceEpoch,
        "description": description,
        "summary": summary,
        "location": location,
        "url": url,
      };

  ZClass.fromJson(Map<String, dynamic> json)
      : start = DateTime.fromMillisecondsSinceEpoch(json["start"]),
        end = DateTime.fromMillisecondsSinceEpoch(json["end"]),
        description = json["description"],
        summary = json["summary"],
        location = json["location"],
        url = json["url"];
}

String? fixEncoding(String? s) =>
    s == null ? null : utf8.decode(latin1.encode(s));
