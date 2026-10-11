import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AwakeningApp());
}

// ==================== MODEL APLIKASI ====================
class AppInfo {
  final String name;
  final String packageName;
  final bool isSystem;
  bool isSelected;

  AppInfo({
    required this.name,
    required this.packageName,
    this.isSystem = false,
    this.isSelected = false,
  });
}

// ==================== LAYANAN SHIZUKU & LAUNCHER ====================
class ShizukuService {
  static const MethodChannel _channel = MethodChannel('com.example.awakening_tools/shizuku');

  static Future<bool> checkPermission() async {
    try {
      final bool granted = await _channel.invokeMethod('checkPermission') ?? false;
      return granted;
    } catch (e) {
      return false;
    }
  }

  static Future<String> executeShell(String command) async {
    try {
      final String result = await _channel.invokeMethod('executeShell', {'command': command});
      return result;
    } catch (e) {
      return 'Gagal mengeksekusi: $e';
    }
  }
}

class LauncherService {
  static Future<String> exportLayout(Map<String, dynamic> config, String name) async {
    try {
      final dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$name.awkl');
      await file.writeAsString(jsonEncode(config));
      return file.path;
    } catch (e) {
      return '';
    }
  }
}

// ==================== WIDGET GLASSMORPHISM KUSTOM ====================
class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const GlassCard({Key? key, required this.child, this.onTap, this.padding}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: padding ?? const EdgeInsets.all(16.0),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== APLIKASI UTAMA ====================
class AwakeningApp extends StatelessWidget {
  const AwakeningApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Awakening Tools',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

// ==================== DASHBOARD UTAMA ====================
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    verifyShizuku();
  }

  Future<void> verifyShizuku() async {
    bool status = await ShizukuService.checkPermission();
    setState(() => isConnected = status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('AWAKENING TOOLS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 18)),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Chip(
                backgroundColor: isConnected ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                label: Text(
                  isConnected ? 'Shizuku Connected' : 'Disconnected',
                  style: TextStyle(color: isConnected ? Colors.greenAccent : Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF090A0F), Color(0xFF131722), Color(0xFF1A1F2C)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "System Customizer & Rescue Suite (Glass Edition)",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _buildMenuCard(
                      context,
                      title: "1. Hapus Bloatware",
                      subtitle: "Uninstall aplikasi bawaan pabrik via ADB / Shizuku",
                      icon: Icons.delete_sweep,
                      color: Colors.redAccent,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DebloaterScreen())),
                    ),
                    const SizedBox(height: 14),
                    _buildMenuCard(
                      context,
                      title: "2. Ubah Bootanimation",
                      subtitle: "Kustomisasi animasi saat perangkat dinyalakan",
                      icon: Icons.animation,
                      color: Colors.orangeAccent,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BootAnimationScreen())),
                    ),
                    const SizedBox(height: 14),
                    _buildMenuCard(
                      context,
                      title: "3. Anti-Lock Emergency Mode",
                      subtitle: "Bypass ransomware / screen-lock virus dengan kill background",
                      icon: Icons.security_update_warning,
                      color: Colors.greenAccent,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AntiLockScreen())),
                    ),
                    const SizedBox(height: 14),
                    _buildMenuCard(
                      context,
                      title: "4. Custom Launcher & Builder",
                      subtitle: "Rancang tata letak launcher sendiri dan ekspor format .awkl",
                      icon: Icons.dashboard_customize,
                      color: Colors.cyanAccent,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LauncherBuilderScreen())),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
        ],
      ),
    );
  }
}

// ==================== 1. DEBLOATER SCREEN ====================
class DebloaterScreen extends StatefulWidget {
  const DebloaterScreen({Key? key}) : super(key: key);

  @override
  State<DebloaterScreen> createState() => _DebloaterScreenState();
}

class _DebloaterScreenState extends State<DebloaterScreen> {
  List<AppInfo> apps = [
    AppInfo(name: "Bloatware App 1", packageName: "com.bloat.app1", isSystem: true),
    AppInfo(name: "Bloatware App 2", packageName: "com.bloat.app2", isSystem: true),
    AppInfo(name: "Operator App", packageName: "com.carrier.app", isSystem: true),
  ];
  bool isLoading = false;

  Future<void> uninstallSelected() async {
    setState(() => isLoading = true);
    for (var app in apps.where((a) => a.isSelected)) {
      String cmd = "pm uninstall -k --user 0 ${app.packageName}";
      await ShizukuService.executeShell(cmd);
    }
    setState(() {
      apps.removeWhere((a) => a.isSelected);
      isLoading = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aplikasi terpilih berhasil dihapus dari sistem.")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Debloater System Apps')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF090A0F), Color(0xFF131722), Color(0xFF1A1F2C)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text("Pilih aplikasi sistem yang ingin dihapus untuk menghemat ruang dan performa:", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: CheckboxListTile(
                          title: Text(app.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          subtitle: Text(app.packageName, style: const TextStyle(fontSize: 12, color: Colors.white60)),
                          value: app.isSelected,
                          activeColor: Colors.redAccent,
                          onChanged: (val) => setState(() => app.isSelected = val ?? false),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.delete),
                      label: const Text("Hapus Aplikasi Terpilih", style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: uninstallSelected,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== 2. BOOTANIMATION SCREEN ====================
class BootAnimationScreen extends StatefulWidget {
  const BootAnimationScreen({Key? key}) : super(key: key);

  @override
  State<BootAnimationScreen> createState() => _BootAnimationScreenState();
}

class _BootAnimationScreenState extends State<BootAnimationScreen> {
  String? selectedFilePath;

  Future<void> pickAnimationFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
    if (result != null) {
      setState(() => selectedFilePath = result.files.single.path);
    }
  }

  Future<void> applyBootAnimation() async {
    if (selectedFilePath == null) return;
    String cmd = "cp $selectedFilePath /system/media/bootanimation.zip";
    String res = await ShizukuService.executeShell(cmd);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hasil: $res")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Bootanimation Customizer')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF090A0F), Color(0xFF131722), Color(0xFF1A1F2C)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlassCard(
                child: Column(
                  children: [
                    const Icon(Icons.animation, size: 70, color: Colors.orangeAccent),
                    const SizedBox(height: 20),
                    Text(
                      selectedFilePath != null ? "File: $selectedFilePath" : "Belum ada file .zip dipilih",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white24,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.folder_open),
                      label: const Text("Pilih File Bootanimation.zip"),
                      onPressed: pickAnimationFile,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: selectedFilePath != null ? applyBootAnimation : null,
                      child: const Text("Terapkan ke Sistem", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== 3. ANTI-LOCK SCREEN ====================
class AntiLockScreen extends StatefulWidget {
  const AntiLockScreen({Key? key}) : super(key: key);

  @override
  State<AntiLockScreen> createState() => _AntiLockScreenState();
}

class _AntiLockScreenState extends State<AntiLockScreen> {
  bool isExecuting = false;

  Future<void> executeAntiLockRescue() async {
    setState(() => isExecuting = true);
    await ShizukuService.executeShell("am force-stop");
    await ShizukuService.executeShell("dpm remove-active-admin");
    setState(() => isExecuting = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Rescue Mode Aktif: Proses latar belakang dibekukan.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Anti-Lock Emergency Rescue')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF090A0F), Color(0xFF131722), Color(0xFF1A1F2C)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlassCard(
                child: Column(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.greenAccent),
                    const SizedBox(height: 16),
                    const Text(
                      "Mode Penyelamatan Anti-Lock",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Jika HP terkunci oleh aplikasi berbahaya, tekan tombol di bawah untuk menutup paksa seluruh aktivitas latar belakang.",
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    isExecuting
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: executeAntiLockRescue,
                            child: const Text("AKTIFKAN EMERGENCY RESCUE", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== 4. LAUNCHER BUILDER SCREEN ====================
class LauncherBuilderScreen extends StatefulWidget {
  const LauncherBuilderScreen({Key? key}) : super(key: key);

  @override
  State<LauncherBuilderScreen> createState() => _LauncherBuilderScreenState();
}

class _LauncherBuilderScreenState extends State<LauncherBuilderScreen> {
  final TextEditingController _nameController = TextEditingController(text: "MyCustomLayout");
  Color gridColor = Colors.cyanAccent;
  int gridColumns = 4;
  String exportStatus = "";

  Future<void> generateAndExport() async {
    Map<String, dynamic> config = {
      "layout_name": _nameController.text.trim(),
      "columns": gridColumns,
      "accent_color": gridColor.value,
      "created_at": DateTime.now().toIso8601String(),
    };

    String path = await LauncherService.exportLayout(config, _nameController.text.trim());
    setState(() {
      exportStatus = path.isNotEmpty ? "Berhasil disimpan di: $path" : "Gagal menyimpan file layout.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Custom Launcher Builder')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF090A0F), Color(0xFF131722), Color(0xFF1A1F2C)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Rancang Tata Letak Tampilan & Grid Launcher:", style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Nama Konfigurasi Launcher',
                        labelStyle: const TextStyle(color: Colors.white60),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.cyanAccent),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Jumlah Kolom Grid:", style: TextStyle(color: Colors.white70)),
                        DropdownButton<int>(
                          value: gridColumns,
                          dropdownColor: const Color(0xFF1A1F2C),
                          style: const TextStyle(color: Colors.white),
                          items: [3, 4, 5].map((val) => DropdownMenuItem(value: val, child: Text("$val Kolom"))).toList(),
                          onChanged: (val) => setState(() => gridColumns = val ?? 4),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.save_alt),
                      label: const Text("Generate & Export File (.awkl)", style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: generateAndExport,
                    ),
                    if (exportStatus.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
                        child: Text(exportStatus, style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}