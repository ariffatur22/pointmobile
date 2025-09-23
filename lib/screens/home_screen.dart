import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tatapoint_mobile/api/api_service.dart';
import 'package:tatapoint_mobile/models/member.dart';
import 'package:tatapoint_mobile/models/promo.dart';
import 'package:tatapoint_mobile/models/reward.dart';
import 'package:tatapoint_mobile/screens/login_screen.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  Member? _member;
  List<Reward> _rewards = [];
  List<Promo> _promos = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (!_isLoading) {
      setState(() {});
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final results = await Future.wait([
        ApiService().getMember(),
        ApiService().getRewards(),
        ApiService().getPromos(),
      ]);

      if (!mounted) return;
      setState(() {
        _member = results[0] as Member;
        _rewards = results[1] as List<Reward>;
        _promos = results[2] as List<Promo>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('401')) {
        _logout();
      } else {
        setState(() {
          _errorMessage = "Gagal memuat data. Periksa koneksi internet Anda.";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await ApiService().logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(
              icon: Icon(Icons.card_giftcard), label: 'Hadiah'),
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Promo'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Akun'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    if (_member == null) {
      return const Center(child: Text('Gagal memuat data member.'));
    }

    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildRewardsTab();
      case 2:
        return _buildScanTab();
      case 3:
        return _buildPromosTab();
      case 4:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  // --- WIDGETS FOR TABS ---

  Widget _buildHomeTab() {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildQrCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardsTab() {
    return Scaffold(
      appBar: AppBar(title: const Text('Tukar Hadiah')),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: _rewards.isEmpty
            ? Center(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 150),
                    Text('Belum ada hadiah tersedia.',
                        textAlign: TextAlign.center),
                  ],
                ),
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _rewards.length,
                itemBuilder: (context, index) {
                  final reward = _rewards[index];
                  final bool canRedeem =
                      _member!.points >= reward.pointsRequired;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: SizedBox(
                        width: 50,
                        height: 50,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: reward.imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: reward.imageUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Container(color: Colors.grey[200]),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.broken_image),
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image,
                                      color: Colors.grey)),
                        ),
                      ),
                      title: Text(reward.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${reward.pointsRequired} Poin',
                          style: TextStyle(
                              color: canRedeem ? Colors.indigo : Colors.grey)),
                      trailing: ElevatedButton(
                        onPressed:
                            canRedeem ? () => _redeemReward(reward) : null,
                        child: const Text('Tukar'),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildScanTab() {
    return Scaffold(
        appBar: AppBar(title: const Text('Scan QR Code Poin')),
        body: MobileScanner(onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? scanResult = barcodes.first.rawValue;
            if (scanResult != null) {
              _processScan(scanResult);
            }
          }
        }));
  }

  Widget _buildPromosTab() {
    return Scaffold(
      appBar: AppBar(title: const Text('Promo Spesial')),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: _promos.isEmpty
            ? Center(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 150),
                    Text('Belum ada promo saat ini.',
                        textAlign: TextAlign.center),
                  ],
                ),
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _promos.length,
                itemBuilder: (context, index) {
                  final promo = _promos[index];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (promo.imageUrl != null)
                          CachedNetworkImage(
                            imageUrl: promo.imageUrl!,
                            fit: BoxFit.cover,
                            height: 150,
                            width: double.infinity,
                            placeholder: (context, url) =>
                                Container(height: 150, color: Colors.grey[200]),
                            errorWidget: (context, url, error) => Container(
                                height: 150,
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image,
                                    color: Colors.grey)),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(promo.name,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              if (promo.description != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(promo.description!,
                                      style:
                                          const TextStyle(color: Colors.grey)),
                                ),
                              const SizedBox(height: 12),
                              Text(
                                'Berlaku s/d ${promo.endDate.day}/${promo.endDate.month}/${promo.endDate.year}',
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return Scaffold(
        appBar: AppBar(title: const Text('Profil Saya')),
        body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(children: [
              Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(children: [
                        ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: const Text('Nama'),
                            subtitle: Text(_member!.name)),
                        const Divider(),
                        ListTile(
                            leading: const Icon(Icons.email_outlined),
                            title: const Text('Email'),
                            subtitle: Text(_member!.email)),
                        const Divider(),
                        ListTile(
                            leading: const Icon(Icons.phone_outlined),
                            title: const Text('Nomor Telepon'),
                            subtitle: Text(_member!.phoneNumber))
                      ]))),
              const SizedBox(height: 30),
              SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text('Logout',
                          style: TextStyle(color: Colors.red)),
                      onPressed: _logout,
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: Colors.red)))))
            ])));
  }

  Future<void> _redeemReward(Reward reward) async {
    final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: const Text('Konfirmasi Penukaran'),
              content: Text(
                  'Anda akan menukar ${reward.pointsRequired} poin dengan "${reward.name}". Lanjutkan?'),
              actions: <Widget>[
                TextButton(
                    child: const Text('Batal'),
                    onPressed: () => Navigator.of(context).pop(false)),
                TextButton(
                    child: const Text('Tukar'),
                    onPressed: () => Navigator.of(context).pop(true))
              ]);
        });
    if (confirmed != true) return;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
              child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 20),
                    Text("Memproses...")
                  ])));
        });
    try {
      final response = await ApiService().redeemReward(reward.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      final updatedMember = Member.fromJson(response['member']);
      final updatedRewards = await ApiService().getRewards();
      if (!mounted) return;
      setState(() {
        _member = updatedMember;
        _rewards = updatedRewards;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response['message']), backgroundColor: Colors.green));
      setState(() {
        _selectedIndex = 0;
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      String errorMessage = 'Gagal menukar hadiah.';
      try {
        final errorBody = jsonDecode(e.toString());
        errorMessage = errorBody['message'] ?? errorMessage;
      } catch (parseError) {}
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
    }
  }

  Widget _buildHeader() {
    return Container(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.indigo,
            borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Selamat Datang,',
              style: TextStyle(color: Colors.white.withOpacity(0.8))),
          Text(_member!.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold))
        ]));
  }

  Widget _buildQrCard() {
    return Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        child: Card(
            elevation: 8,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(children: [
                  const Text('Poin Anda',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(_member!.points.toString(),
                      style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo)),
                  const SizedBox(height: 24),
                  QrImageView(
                      data: _member!.id.toString(),
                      version: QrVersions.auto,
                      size: 200.0),
                  const SizedBox(height: 16),
                  const Text('Tunjukkan QR Code ini di kasir',
                      style: TextStyle(color: Colors.grey))
                ]))));
  }

  Future<void> _processScan(String scanResult) async {
    if (!mounted) return;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
              child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 20),
                    Text("Memproses...")
                  ])));
        });
    try {
      final response = await ApiService().claimPoints(scanResult);
      if (!mounted) return;
      Navigator.of(context).pop();
      await _loadAllData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response['message']), backgroundColor: Colors.green));
      setState(() {
        _selectedIndex = 0;
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      final errorBody = jsonDecode(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorBody['message'] ?? 'QR Code tidak valid'),
          backgroundColor: Colors.red));
    }
  }
}
