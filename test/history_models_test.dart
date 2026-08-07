import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_grow_code/logs/models/sensor_history_record.dart';
import 'package:smart_grow_code/logs/models/system_event_log.dart';
import 'package:smart_grow_code/logs/repositories/firestore_logbook_repository.dart';
import 'package:smart_grow_code/logs/repositories/logbook_repository.dart';
import 'package:smart_grow_code/logs/repositories/mock_logbook_repository.dart';

Map<String, dynamic> sensor(Object timestamp) => {'deviceId':'smartGrow01','timestamp':timestamp,'environmentTemp':25,'humidity':80,'co2':500,'waterLevel':90,'humidifierTemp':23,'validity':{'co2':true}};

void main() {
  final time = DateTime.utc(2026, 8, 5, 12);
  test('sensor history parses Timestamp and validity', () {
    final r = SensorHistoryRecord.fromMap({...sensor(Timestamp.fromDate(time))});
    expect(r.timestamp, time); expect(r.temperature, 25); expect(r.validity['co2'], isTrue);
  });
  test('timestamps normalize to UTC', () {
    expect(parseHistoryTimestamp(DateTime(2026,8,5,20)), DateTime.utc(2026,8,5,12));
    expect(parseHistoryTimestamp(time.millisecondsSinceEpoch), time);
  });
  test('missing timestamp and reading are rejected', () {
    expect(() => SensorHistoryRecord.fromMap({'deviceId':'smartGrow01'}), throwsFormatException);
    final missing = sensor(time)..remove('co2');
    expect(() => SensorHistoryRecord.fromMap(missing), throwsFormatException);
  });
  test('event preserves primitive transition values', () {
    for (final value in <Object?>['auto', true, 3, null]) {
      final event = SystemEventLog.fromMap({'deviceId':'smartGrow01','timestamp':time,'category':'component','eventType':'state_changed','message':'event','previousValue':value,'newValue':value});
      expect(event.newValue, value);
    }
  });
  test('unsupported event transition values become null', () {
    final e = SystemEventLog.fromMap({'deviceId':'smartGrow01','timestamp':time,'category':'device','eventType':'device_online','message':'online','previousValue':{}});
    expect(e.previousValue, isNull);
  });
  test('selected end becomes exclusive next midnight', () => expect(exclusiveHistoryEnd(DateTime(2026,8,5,3)), DateTime(2026,8,6)));
  test('mock ids are deterministic and empty ranges remain empty', () async {
    expect(MockLogBookRepository.sensorId(time), MockLogBookRepository.sensorId(time.add(const Duration(minutes:4))));
    expect(await MockLogBookRepository(now: time).getSensorHistory(start:DateTime(2000),end:DateTime(2000)), isEmpty);
  });
  test('one malformed sensor document is skipped', () {
    final records = parseHistoryDocuments<SensorHistoryRecord>(collection:'sensorHistory', documents:[(id:'good',data:sensor(time)),(id:'bad',data:<String,dynamic>{})], parse:(data,id)=>SensorHistoryRecord.fromMap(data,id:id));
    expect(records.single.id, 'good');
  });
  test('all malformed sensor documents throw HistoryDataException', () => expect(
    () => parseHistoryDocuments<SensorHistoryRecord>(collection:'sensorHistory',documents:[(id:'bad',data:<String,dynamic>{})],parse:(data,id)=>SensorHistoryRecord.fromMap(data,id:id)), throwsA(isA<HistoryDataException>())));
  test('one malformed event document is skipped', () {
    final events = parseHistoryDocuments<SystemEventLog>(collection:'systemEvents',documents:[(id:'good',data:{'deviceId':'smartGrow01','timestamp':time,'category':'device','eventType':'device_online','message':'online'}),(id:'bad',data:<String,dynamic>{})],parse:(data,id)=>SystemEventLog.fromMap(data,id:id));
    expect(events.single.id, 'good');
  });
}
