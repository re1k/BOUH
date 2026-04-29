import 'dart:convert';
import 'package:bouh/config/slot_config.dart';
import 'package:bouh/dto/bookAppointmentRequestDto.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bouh/config/api_config.dart';
import 'package:bouh/dto/upcomingAppointmentDto.dart';
import 'package:bouh/authentication/AuthSession.dart';
import 'package:bouh/dto/bookAppointmentRequestDto.dart';

class AppointmentsService {
  final AuthSession _session = AuthSession.instance;

  /// GET /api/appointments/upcoming/{caregiverId}. On 2xx parses JSON list to [UpcomingAppointmentDto].
  /// On non-2xx throws [Exception] with status code and body.
  Future<List<UpcomingAppointmentDto>> getUpcomingAppointments(
    String caregiverId,
  ) async {
    final token = _session.idToken;
    if (token == null || token.isEmpty) {
      throw Exception('UNAUTHORIZED');
    }

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/appointments/upcoming/$caregiverId',
    );
    final res = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Backend error ${res.statusCode}: ${res.body}');
    }

    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => UpcomingAppointmentDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/appointments/previous/{caregiverId}. Same DTO as upcoming; parses to [UpcomingAppointmentDto].
  Future<List<UpcomingAppointmentDto>> getPreviousAppointments(
    String caregiverId,
  ) async {
    final token = _session.idToken;
    if (token == null || token.isEmpty) {
      throw Exception('UNAUTHORIZED');
    }

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/appointments/previous/$caregiverId',
    );
    final res = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Backend error ${res.statusCode}: ${res.body}');
    }

    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => UpcomingAppointmentDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> cancelAppointment({required String appointmentId}) async {
    final token = _session.idToken;
    if (token == null || token.isEmpty) {
      throw Exception('UNAUTHORIZED');
    }

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/appointments/$appointmentId',
    );

    final res = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      try {
        final body = jsonDecode(res.body);
        final message = body['message']?.toString();
        throw Exception(message ?? 'Failed to cancel appointment');
      } catch (_) {
        throw Exception('Backend error ${res.statusCode}: ${res.body}');
      }
    }
  }

  /// GET /api/appointments/upcoming/doctor/{doctorId}. For doctor view; DTO includes caregiverName.
  Future<List<UpcomingAppointmentDto>> getUpcomingAppointmentsByDoctor(
    String doctorId,
  ) async {
    final token = _session.idToken;
    if (token == null || token.isEmpty) {
      throw Exception('UNAUTHORIZED');
    }
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/appointments/upcoming/doctor/$doctorId',
    );
    final res = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Backend error ${res.statusCode}: ${res.body}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => UpcomingAppointmentDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/appointments/previous/doctor/{doctorId}. For doctor view; DTO includes caregiverName.
  Future<List<UpcomingAppointmentDto>> getPreviousAppointmentsByDoctor(
    String doctorId,
  ) async {
    final token = _session.idToken;
    if (token == null || token.isEmpty) {
      throw Exception('UNAUTHORIZED');
    }
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/appointments/previous/doctor/$doctorId',
    );
    final res = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Backend error ${res.statusCode}: ${res.body}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => UpcomingAppointmentDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Same as getFullPreviousWithUpcoming but for doctor: previous + upcoming merged; used for stream.
  Future<(List<UpcomingAppointmentDto>, List<UpcomingAppointmentDto>)>
  getFullPreviousWithUpcomingForDoctor(String doctorId) async {
    final results = await Future.wait([
      getPreviousAppointmentsByDoctor(doctorId),
      getUpcomingAppointmentsByDoctor(doctorId),
    ]);
    final previous = results[0];
    final upcoming = results[1];
    final now = DateTime.now();
    final existingIds = previous.map((d) => d.appointmentId).toSet();
    for (final dto in upcoming) {
      if (existingIds.contains(dto.appointmentId)) continue;
      final end = parseAppointmentTime(dto.date, dto.endTime);
      if (end != null && !now.isBefore(end)) previous.add(dto);
    }
    final previousIds = previous.map((d) => d.appointmentId).toSet();
    upcoming.removeWhere((d) => previousIds.contains(d.appointmentId));
    previous.sort((a, b) {
      final ta = parseAppointmentTime(a.date, a.startTime);
      final tb = parseAppointmentTime(b.date, b.startTime);
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    });
    return (previous, upcoming);
  }

  /// Listen to Firestore for realtime appointment changes.
  /// Each time Firestore reports a change, we call the backend to get the
  /// latest enriched upcoming appointments (with doctor and child names).
  Stream<List<UpcomingAppointmentDto>> streamUpcomingAppointments(
    String caregiverId,
  ) {
    // Watch the 'appointments' collection filtered to this caregiver only.
    // The stream emits a new event every time any document changes.
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('caregiverId', isEqualTo: caregiverId)
        .snapshots()
        // For each Firestore snapshot, call the backend to get enriched data.
        // asyncMap runs one backend call at a time; new events are queued.
        .asyncMap((_) => getUpcomingAppointments(caregiverId));
  }

  /// Single place to parse backend date (yyyy-MM-dd) + time (h:mm, 4–9 PM) into
  /// local DateTime. Used by Upcoming (filter/Join) and by getFullPreviousAppointments.
  static DateTime? parseAppointmentTime(String date, String? time) {
    if (time == null) return null;
    final d = date.split('-');
    if (d.length != 3) return null;
    final y = int.tryParse(d[0]);
    final m = int.tryParse(d[1]);
    final day = int.tryParse(d[2]);
    if (y == null || m == null || day == null) return null;
    final t = time.split(':');
    if (t.length != 2) return null;
    int? h = int.tryParse(t[0]);
    final min = int.tryParse(t[1]);
    if (h == null || min == null) return null;

    int resolvedHour = h;
    bool matched = false;

    // Check start times
    for (int i = 0; i < SlotConfig.slotCount; i++) {
      if (SlotConfig.slotStartText(i) == time) {
        final (fullHour, _) = SlotConfig.slotStart(i);
        resolvedHour = fullHour;
        matched = true;
        break;
      }
    }

    // If no start match, check end times
    if (!matched) {
      for (int i = 0; i < SlotConfig.slotCount; i++) {
        final (endH, endM) = SlotConfig.slotEnd(i);
        final hh = endH > 12 ? endH - 12 : (endH == 0 ? 12 : endH);
        final endText = '$hh:${endM.toString().padLeft(2, '0')}';
        if (endText == time) {
          resolvedHour = endH;
          matched = true;
          break;
        }
      }
    }

    return DateTime(y, m, day, resolvedHour, min);
  }

  /// Returns (merged previous list, upcoming list). Widget shows merged and
  /// keeps upcoming for a 1s ticker to move ended ones locally (no extra reads).
  Future<(List<UpcomingAppointmentDto>, List<UpcomingAppointmentDto>)>
  getFullPreviousWithUpcoming(String caregiverId) async {
    final results = await Future.wait([
      getPreviousAppointments(caregiverId),
      getUpcomingAppointments(caregiverId),
    ]);
    final previous = results[0];
    final upcoming = results[1];
    final now = DateTime.now();
    final existingIds = previous.map((d) => d.appointmentId).toSet();

    for (final dto in upcoming) {
      if (existingIds.contains(dto.appointmentId)) continue;
      final end = parseAppointmentTime(dto.date, dto.endTime);
      if (end != null && !now.isBefore(end)) previous.add(dto);
    }

    // Remove already-ended appointments from upcoming so the ticker
    // does not add them to previous a second time
    final previousIds = previous.map((d) => d.appointmentId).toSet();
    upcoming.removeWhere((d) => previousIds.contains(d.appointmentId));

    // Sort previous: newest first (by date+startTime descending)
    previous.sort((a, b) {
      final ta = parseAppointmentTime(a.date, a.startTime);
      final tb = parseAppointmentTime(b.date, b.startTime);
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    });

    return (previous, upcoming);
  }

  /// Stream: one fetch per Firestore change. Emits (merged, upcoming) so the
  /// page can tick locally and move ended appointments without polling.
  Stream<(List<UpcomingAppointmentDto>, List<UpcomingAppointmentDto>)>
  streamPreviousAppointments(String caregiverId) {
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('caregiverId', isEqualTo: caregiverId)
        .snapshots()
        .asyncMap((_) => getFullPreviousWithUpcoming(caregiverId));
  }

  /// Realtime stream for doctor upcoming: Firestore where doctorId, then backend enrich.
  Stream<List<UpcomingAppointmentDto>> streamUpcomingAppointmentsByDoctor(
    String doctorId,
  ) {
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .asyncMap((_) => getUpcomingAppointmentsByDoctor(doctorId));
  }

  /// Realtime stream for doctor previous: Firestore where doctorId, then merged previous+upcoming.
  Stream<(List<UpcomingAppointmentDto>, List<UpcomingAppointmentDto>)>
  streamPreviousAppointmentsByDoctor(String doctorId) {
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .asyncMap((_) => getFullPreviousWithUpcomingForDoctor(doctorId));
  }

  Future<void> createAppointment(BookAppointmentRequestDto request) async {
    final token = _session.idToken;
    if (token == null || token.isEmpty) {
      throw Exception('UNAUTHORIZED');
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/api/appointments');

    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(request.toJson()),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      try {
        final body = jsonDecode(res.body);
        final message = body['message']?.toString();
        throw Exception(message ?? 'Failed to create appointment');
      } catch (_) {
        throw Exception('Failed to create appointment: ${res.body}');
      }
    }
  }
}
