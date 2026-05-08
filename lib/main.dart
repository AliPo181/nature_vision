import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NatureVisionApp());
}

// ─── Theme ───────────────────────────────────────────────────────────────────

class NVColors {
  static const dark    = Color(0xFF27500A);
  static const medium  = Color(0xFF3B6D11);
  static const light   = Color(0xFF639922);
  static const pale    = Color(0xFFEAF3DE);
  static const accent  = Color(0xFF97C459);
  static const cream   = Color(0xFFC0DD97);
}

// ─── Data Model ──────────────────────────────────────────────────────────────

class Memento {
  final String prompt;
  final String? photoPath;
  final String? note;
  final DateTime date;

  Memento({required this.prompt, this.photoPath, this.note, required this.date});

  Map<String, dynamic> toJson() => {
    'prompt': prompt,
    'photoPath': photoPath,
    'note': note,
    'date': date.toIso8601String(),
  };

  factory Memento.fromJson(Map<String, dynamic> j) => Memento(
    prompt: j['prompt'],
    photoPath: j['photoPath'],
    note: j['note'],
    date: DateTime.parse(j['date']),
  );
}

// ─── App State ────────────────────────────────────────────────────────────────

class AppState extends ChangeNotifier {
  bool onboarded = false;
  String name = '';
  int streak = 0;
  int currentPromptIndex = 0;
  List<Memento> mementos = [];

  static const _prompts = [
    'Find something that looks soft',
    'Capture something that moves',
    'Find something red in nature',
    'Find something another person might overlook',
    'Spot something that reminds you of a memory',
  ];

  String get currentPrompt => _prompts[currentPromptIndex % _prompts.length];
  List<String> get allPrompts => _prompts;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    onboarded = prefs.getBool('onboarded') ?? false;
    name = prefs.getString('name') ?? '';
    streak = prefs.getInt('streak') ?? 0;
    currentPromptIndex = prefs.getInt('promptIndex') ?? 0;
    final raw = prefs.getString('mementos');
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      mementos = list.map((e) => Memento.fromJson(e)).toList();
    }
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarded', onboarded);
    await prefs.setString('name', name);
    await prefs.setInt('streak', streak);
    await prefs.setInt('promptIndex', currentPromptIndex);
    await prefs.setString('mementos', jsonEncode(mementos.map((m) => m.toJson()).toList()));
  }

  Future<void> completeOnboarding(String userName) async {
    onboarded = true;
    name = userName;
    await save();
    notifyListeners();
  }

  Future<void> addMemento(Memento m) async {
    mementos.insert(0, m);
    currentPromptIndex++;
    if (currentPromptIndex % _prompts.length == 0) streak++;
    await save();
    notifyListeners();
  }
}

// ─── Root App ─────────────────────────────────────────────────────────────────

class NatureVisionApp extends StatefulWidget {
  const NatureVisionApp({super.key});
  @override
  State<NatureVisionApp> createState() => _NatureVisionAppState();
}

class _NatureVisionAppState extends State<NatureVisionApp> {
  final _state = AppState();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _state.load().then((_) => setState(() => _loaded = true));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (ctx, _) => MaterialApp(
        title: 'Nature Vision',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: NVColors.medium),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: NVColors.dark,
            foregroundColor: Color(0xFFEAF3DE),
            elevation: 0,
          ),
        ),
        home: !_loaded
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : _state.onboarded
                ? MainShell(appState: _state)
                : OnboardingScreen(appState: _state),
      ),
    );
  }
}

// ─── Onboarding ───────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  final AppState appState;
  const OnboardingScreen({super.key, required this.appState});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  final _nameCtrl = TextEditingController();
  int _page = 0;

  final _slides = [
    _Slide(Icons.nature, 'Welcome to Nature Vision',
        'Transform every walk into a mindful, creative adventure. Discover the small, beautiful details hiding in nature around you.'),
    _Slide(Icons.camera_alt_outlined, 'Follow gentle prompts',
        'Receive open-ended prompts like "find something soft". Capture a photo or note, mark it done, and unlock the next prompt.'),
    _Slide(Icons.book_outlined, 'Build your journal',
        'Every memento is saved in your personal journal. Revisit memories and see how your connection with nature grows.'),
  ];

  void _next() {
    if (_page < _slides.length - 1) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  void _finish() {
    final n = _nameCtrl.text.trim();
    if (n.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name to continue.')),
      );
      return;
    }
    widget.appState.completeOnboarding(n).then((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainShell(appState: widget.appState)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NVColors.pale,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _SlideView(
                  slide: _slides[i],
                  isLast: i == _slides.length - 1,
                  nameCtrl: _nameCtrl,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                width: _page == i ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: _page == i ? NVColors.medium : NVColors.accent.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NVColors.dark,
                    foregroundColor: NVColors.pale,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(_page < _slides.length - 1 ? 'Next' : 'Start exploring',
                      style: const TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final String title;
  final String body;
  const _Slide(this.icon, this.title, this.body);
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  final bool isLast;
  final TextEditingController nameCtrl;
  const _SlideView({required this.slide, required this.isLast, required this.nameCtrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(color: NVColors.medium, shape: BoxShape.circle),
            child: Icon(slide.icon, size: 50, color: NVColors.pale),
          ),
          const SizedBox(height: 28),
          Text(slide.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: NVColors.dark),
              textAlign: TextAlign.center),
          const SizedBox(height: 14),
          Text(slide.body,
              style: const TextStyle(fontSize: 15, color: NVColors.medium, height: 1.6),
              textAlign: TextAlign.center),
          if (isLast) ...[
            const SizedBox(height: 28),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                hintText: 'Enter your name',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: NVColors.accent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: NVColors.medium, width: 2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Main Shell (Bottom Nav) ──────────────────────────────────────────────────

class MainShell extends StatefulWidget {
  final AppState appState;
  const MainShell({super.key, required this.appState});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(appState: widget.appState, onStartWalk: () => setState(() => _tab = 1)),
      WalkScreen(appState: widget.appState),
      JournalScreen(appState: widget.appState),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        selectedItemColor: NVColors.dark,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Walk'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Journal'),
        ],
      ),
    );
  }
}

// ─── Home Screen ─────────────────────────────────────────────────────────────

class HomeScreen extends StatelessWidget {
  final AppState appState;
  final VoidCallback onStartWalk;
  const HomeScreen({super.key, required this.appState, required this.onStartWalk});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nature Vision', style: TextStyle(fontWeight: FontWeight.w500)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_greeting()}, ${appState.name} 👋',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: NVColors.dark)),
            Text(
              '${DateTime.now().day} ${_monthName(DateTime.now().month)} ${DateTime.now().year}',
              style: const TextStyle(fontSize: 14, color: NVColors.medium),
            ),
            const SizedBox(height: 20),
            // Streak card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NVColors.pale,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Text('${appState.streak}',
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: NVColors.dark)),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('day streak 🌿', style: TextStyle(fontSize: 16, color: NVColors.dark, fontWeight: FontWeight.w500)),
                      Text('Keep walking and exploring!', style: TextStyle(fontSize: 13, color: NVColors.medium)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Today's prompt
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NVColors.pale,
                borderRadius: BorderRadius.circular(14),
                border: Border(left: BorderSide(color: NVColors.light, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Today's prompt", style: TextStyle(fontSize: 11, color: NVColors.light, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(appState.currentPrompt,
                      style: const TextStyle(fontSize: 16, color: NVColors.dark, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onStartWalk,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Start walk', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NVColors.medium,
                  foregroundColor: NVColors.pale,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) => ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m-1];
}

// ─── Walk Screen ─────────────────────────────────────────────────────────────

class WalkScreen extends StatefulWidget {
  final AppState appState;
  const WalkScreen({super.key, required this.appState});
  @override
  State<WalkScreen> createState() => _WalkScreenState();
}

class _WalkScreenState extends State<WalkScreen> {
  final _noteCtrl = TextEditingController();
  File? _photo;
  bool _done = false;
  final _picker = ImagePicker();

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _markDone() async {
    final note = _noteCtrl.text.trim();
    if (_photo == null && note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Take a photo or add a note first.')),
      );
      return;
    }
    final m = Memento(
      prompt: widget.appState.currentPrompt,
      photoPath: _photo?.path,
      note: note.isNotEmpty ? note : null,
      date: DateTime.now(),
    );
    await widget.appState.addMemento(m);
    setState(() { _done = true; _photo = null; _noteCtrl.clear(); });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _done = false);
  }

  @override
  Widget build(BuildContext context) {
    final prompts = widget.appState.allPrompts;
    final idx = widget.appState.currentPromptIndex % prompts.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Walk'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('${idx + 1} / ${prompts.length}',
                  style: const TextStyle(color: NVColors.cream, fontSize: 14)),
            ),
          )
        ],
      ),
      body: _done ? _doneView() : _captureView(prompts[idx]),
    );
  }

  Widget _captureView(String prompt) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NVColors.pale,
              borderRadius: BorderRadius.circular(14),
              border: Border(left: BorderSide(color: NVColors.light, width: 3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your prompt', style: TextStyle(fontSize: 11, color: NVColors.light, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(prompt, style: const TextStyle(fontSize: 17, color: NVColors.dark, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_photo != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_photo!, height: 200, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.camera_alt_outlined, color: NVColors.medium),
                  label: Text(_photo == null ? 'Take photo' : 'Retake',
                      style: const TextStyle(color: NVColors.medium)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: NVColors.light),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add a note about what you noticed…',
              filled: true,
              fillColor: NVColors.pale,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _markDone,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Mark as done', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: NVColors.medium,
                foregroundColor: NVColors.pale,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _doneView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 72, color: NVColors.medium),
            const SizedBox(height: 20),
            const Text('Memento saved!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: NVColors.dark)),
            const SizedBox(height: 8),
            const Text('The next prompt is waiting for you.',
                style: TextStyle(fontSize: 15, color: NVColors.medium), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Journal Screen ───────────────────────────────────────────────────────────

class JournalScreen extends StatelessWidget {
  final AppState appState;
  const JournalScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_monthName(now.month)} ${now.year}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: NVColors.dark),
            ),
            const SizedBox(height: 12),
            _CalendarGrid(appState: appState, year: now.year, month: now.month),
            const SizedBox(height: 24),
            const Text('Recent mementos',
                style: TextStyle(fontSize: 13, color: NVColors.medium, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            if (appState.mementos.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text('No mementos yet — start a walk!',
                      style: TextStyle(color: NVColors.medium, fontSize: 15)),
                ),
              )
            else
              ...appState.mementos.map((m) => _MementoCard(m: m)).toList(),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) => ['January','February','March','April','May','June','July','August','September','October','November','December'][m-1];
}

class _CalendarGrid extends StatelessWidget {
  final AppState appState;
  final int year, month;
  const _CalendarGrid({required this.appState, required this.year, required this.month});

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1).weekday; // Mon=1
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final today = DateTime.now().day;
    final labels = ['Mo','Tu','We','Th','Fr','Sa','Su'];

    return Column(
      children: [
        Row(
          children: labels.map((l) => Expanded(
            child: Center(child: Text(l, style: const TextStyle(fontSize: 11, color: NVColors.medium))),
          )).toList(),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4),
          itemCount: (firstDay - 1) + daysInMonth,
          itemBuilder: (_, i) {
            if (i < firstDay - 1) return const SizedBox();
            final day = i - (firstDay - 1) + 1;
            final entry = appState.mementos.firstWhere(
              (m) => m.date.year == year && m.date.month == month && m.date.day == day,
              orElse: () => Memento(prompt: '', date: DateTime(0)),
            );
            final hasEntry = entry.date.year != 0;
            final isToday = day == today;
            return GestureDetector(
              onTap: hasEntry ? () => _showDay(context, entry) : null,
              child: Container(
                decoration: BoxDecoration(
                  color: hasEntry ? NVColors.pale : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday ? Border.all(color: NVColors.light, width: 1.5) : null,
                ),
                child: hasEntry && entry.photoPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(fit: StackFit.expand, children: [
                          Image.file(File(entry.photoPath!), fit: BoxFit.cover),
                          Positioned(
                            bottom: 2, left: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(color: NVColors.dark.withOpacity(0.7), borderRadius: BorderRadius.circular(4)),
                              child: Text('$day', style: const TextStyle(color: NVColors.pale, fontSize: 9)),
                            ),
                          ),
                        ]),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('$day', style: TextStyle(fontSize: 12, color: hasEntry ? NVColors.dark : Colors.grey, fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
                            if (hasEntry) Container(width: 5, height: 5, decoration: const BoxDecoration(color: NVColors.medium, shape: BoxShape.circle)),
                          ],
                        ),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showDay(BuildContext ctx, Memento m) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.prompt, style: const TextStyle(fontSize: 13, color: NVColors.medium)),
            const SizedBox(height: 8),
            if (m.photoPath != null) ...[
              ClipRRect(borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(m.photoPath!), height: 180, width: double.infinity, fit: BoxFit.cover)),
              const SizedBox(height: 8),
            ],
            if (m.note != null) Text(m.note!, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 8),
            Text(
              '${m.date.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m.date.month-1]} ${m.date.year}',
              style: const TextStyle(fontSize: 12, color: NVColors.medium),
            ),
          ],
        ),
      ),
    );
  }
}

class _MementoCard extends StatelessWidget {
  final Memento m;
  const _MementoCard({required this.m});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (m.photoPath != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Image.file(File(m.photoPath!), height: 140, width: double.infinity, fit: BoxFit.cover),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.prompt, style: const TextStyle(fontSize: 12, color: NVColors.medium)),
                if (m.note != null) ...[
                  const SizedBox(height: 4),
                  Text(m.note!, style: const TextStyle(fontSize: 14)),
                ],
                const SizedBox(height: 6),
                Text(
                  '${m.date.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m.date.month-1]} ${m.date.year}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}