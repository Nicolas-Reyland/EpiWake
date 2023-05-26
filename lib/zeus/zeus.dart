import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';

Future<ICalendar> fetchSchedule(
    {String url =
        'https://zeus.ionis-it.com/api/group/481/ics/ZVYpfiEoGM'}) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    throw Exception('Got invalid status code: ${response.statusCode}');
  }
  return ICalendar.fromString(response.body.toString());
}
