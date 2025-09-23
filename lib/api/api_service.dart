import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tatapoint_mobile/models/member.dart';
import 'package:tatapoint_mobile/models/promo.dart';
import 'package:tatapoint_mobile/models/reward.dart';

class ApiService {
  // Ganti dengan alamat IP yang sesuai (127.0.0.1 untuk desktop, 10.0.2.2 atau IP lokal untuk emulator)
  final String _baseUrl = "http://127.0.0.1:8000/api";

  // ... (Fungsi login, register, logout, getMember, getRewards, getPromos, claimPoints tetap sama) ...
  Future<Map<String, dynamic>> login(String email, String pin) async {
    final response = await http.post(Uri.parse('$_baseUrl/login'),
        headers: await _getHeaders(),
        body: jsonEncode({'email': email, 'pin': pin}));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('authToken', data['access_token']);
      return data;
    } else {
      throw Exception(response.body);
    }
  }

  Future<Map<String, dynamic>> register(
      String name, String email, String phone) async {
    final response = await http.post(Uri.parse('$_baseUrl/register'),
        headers: await _getHeaders(),
        body:
            jsonEncode({'name': name, 'email': email, 'phone_number': phone}));
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('authToken', data['access_token']);
      return data;
    } else {
      throw Exception(response.body);
    }
  }

  Future<void> logout() async {
    await http.post(Uri.parse('$_baseUrl/logout'),
        headers: await _getHeaders());
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
  }

  Future<Member> getMember() async {
    final response = await http.get(Uri.parse('$_baseUrl/member'),
        headers: await _getHeaders());
    if (response.statusCode == 200) {
      return Member.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal memuat data member');
    }
  }

  Future<List<Reward>> getRewards() async {
    final response = await http.get(Uri.parse('$_baseUrl/rewards'),
        headers: await _getHeaders());
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Reward.fromJson(item)).toList();
    } else {
      throw Exception('Gagal memuat hadiah');
    }
  }

  Future<List<Promo>> getPromos() async {
    final response = await http.get(Uri.parse('$_baseUrl/promos'),
        headers: await _getHeaders());
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Promo.fromJson(item)).toList();
    } else {
      throw Exception('Gagal memuat promo');
    }
  }

  Future<Map<String, dynamic>> claimPoints(String scanResult) async {
    final response = await http.post(Uri.parse('$_baseUrl/points/claim'),
        headers: await _getHeaders(),
        body: jsonEncode({'scan_result': scanResult}));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(response.body);
    }
  }

  // --- FUNGSI BARU UNTUK TUKAR HADIAH ---
  Future<Map<String, dynamic>> redeemReward(int rewardId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/rewards/$rewardId/redeem'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(response.body);
    }
  }

  // --- HELPER METHODS ---
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
