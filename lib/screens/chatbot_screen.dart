import 'package:flutter/material.dart';

/// Seluna assistant — FAQ chatbot with keyword-matched responses.
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  static const _deep  = Color(0xFF880E4F);
  static const _mid   = Color(0xFFE91E63);
  static const _light = Color(0xFFF48FB1);
  static const _bg    = Color(0xFFFFF8F0);

  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_Msg> _msgs = [];

  @override
  void initState() {
    super.initState();
    _msgs.add(_Msg(
      text: 'Hi! I\'m your Seluna assistant 🌸\n\n'
          'Ask me anything about your cycle, period health, or how to use the app.\n\n'
          'You can also tap a quick question below:',
      isBot: true,
    ));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send(String text) {
    final q = text.trim();
    if (q.isEmpty) return;
    setState(() {
      _msgs.add(_Msg(text: q, isBot: false));
      _msgs.add(_Msg(text: _answer(q), isBot: true));
    });
    _inputCtrl.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Keyword-based FAQ engine ─────────────────────────────────────────────
  String _answer(String q) {
    final lq = q.toLowerCase();

    if (_has(lq, ['late', 'missed', 'overdue', 'delay', 'irregular'])) {
      return 'A late period can be caused by stress, weight changes, illness, travel, or hormonal fluctuations. '
          'Cycles between 21–35 days are considered normal. If you\'re more than 2 weeks late or this is unusual for you, '
          'consider taking a pregnancy test or speaking with a doctor. 🩺';
    }
    if (_has(lq, ['cramp', 'pain', 'dysmenorrhoea', 'hurts', 'ache'])) {
      return 'Period cramps are caused by prostaglandins that make the uterus contract. Tips:\n'
          '• A warm heat pad on your lower abdomen\n'
          '• Light exercise like walking or yoga\n'
          '• Ibuprofen or naproxen taken before cramps start\n'
          '• Stay hydrated and reduce caffeine\n\n'
          'Severe cramps that interfere with daily life could indicate endometriosis — worth discussing with a doctor. 💊';
    }
    if (_has(lq, ['predict', 'prediction', 'next period', 'when will'])) {
      return 'Seluna predicts your next period by calculating your average cycle length from your logged periods. '
          'The more periods you log, the more accurate it becomes. '
          'Log at least 2–3 cycles for reliable predictions. You can see the predicted dates (drop shapes 💧) on the home calendar.';
    }
    if (_has(lq, ['log', 'add period', 'start period', 'how to track', 'how do i'])) {
      return 'To log a period:\n'
          '1. Go to the Home tab 🏠\n'
          '2. Tap any past date on the calendar\n'
          '3. Confirm to start your period on that date\n'
          '4. To end it, tap a date during the period and choose "End Period"\n\n'
          'You can also edit or delete logs in the History tab. ✏️';
    }
    if (_has(lq, ['fertile', 'ovulation', 'ovulate', 'pregnancy', 'conceive', 'baby'])) {
      return 'Your fertile window is typically the 5 days before ovulation and the day of ovulation. '
          'Ovulation usually occurs around day 14 of a 28-day cycle (or cycle length − 14 days). '
          'On the cycle ring (History tab), the teal arc shows your predicted fertile window. '
          'Note: Seluna is a tracking tool and not a contraceptive — please consult a doctor for family planning. 👶';
    }
    if (_has(lq, ['heavy', 'bleeding', 'clot', 'flow', 'light period', 'spotting'])) {
      return 'Period flow varies widely. Light to moderate flow is normal. '
          'Heavy bleeding (soaking a pad/tampon every hour for several hours) or passing large clots '
          'could indicate fibroids or other conditions. Spotting between periods can be normal but '
          'is worth checking with a doctor if it\'s new or frequent. 🩸';
    }
    if (_has(lq, ['pms', 'mood', 'emotional', 'bloat', 'headache', 'breast', 'tender'])) {
      return 'PMS (Pre-Menstrual Syndrome) typically occurs 1–2 weeks before your period. '
          'Common symptoms: mood swings, bloating, breast tenderness, headaches, fatigue.\n\n'
          'Tips: regular exercise, reducing salt and sugar, magnesium supplements, and good sleep '
          'can all help manage PMS symptoms. 🍓';
    }
    if (_has(lq, ['cycle length', 'how long', 'normal cycle', 'average'])) {
      return 'A typical menstrual cycle is 21–35 days, with an average of 28 days. '
          'Period duration is usually 3–7 days. Both vary person to person and even cycle to cycle — '
          'that\'s completely normal! Seluna tracks your personal average over time. 📅';
    }
    if (_has(lq, ['birth control', 'pill', 'iud', 'implant', 'contraception', 'depo'])) {
      return 'Hormonal birth control (pill, IUD, implant, injection) can significantly affect your cycle — '
          'lighter periods, no periods, or irregular spotting are all common side effects. '
          'Seluna can still help you track patterns while on birth control, '
          'but predictions may be less accurate. Always consult your doctor for contraception advice. 💊';
    }
    if (_has(lq, ['pcos', 'endometriosis', 'fibroids', 'thyroid', 'condition'])) {
      return 'Conditions like PCOS, endometriosis, and thyroid disorders can cause irregular, heavy, '
          'or painful periods. If you notice persistent irregularity, very heavy flow, or severe pain, '
          'please see a healthcare provider. Early diagnosis and management can make a big difference. 🏥';
    }
    if (_has(lq, ['notification', 'remind', 'alert'])) {
      return 'Seluna can send you a reminder a few days before your next predicted period. '
          'Go to your Profile (top-right avatar) → turn on Notifications. '
          'Make sure you\'ve also allowed notifications for the app in your phone\'s settings. 🔔';
    }
    if (_has(lq, ['delete', 'edit', 'change', 'wrong date', 'mistake'])) {
      return 'To edit or delete a period log:\n'
          '1. Go to the History tab (bottom nav)\n'
          '2. Find the period entry\n'
          '3. Tap ✏️ to edit the start date, or 🗑️ to delete it\n\n'
          'On the calendar, you can tap any highlighted date to end an ongoing period or '
          'adjust the start date.';
    }
    if (_has(lq, ['dark mode', 'theme', 'colour', 'color', 'appearance'])) {
      return 'You can switch between light and dark mode in your Profile settings. '
          'Go to the Profile tab → Theme → choose Light, Dark, or System. 🌙';
    }
    if (_has(lq, ['profile', 'name', 'account', 'settings', 'photo', 'avatar'])) {
      return 'To update your profile, tap your avatar in the top-right of the Home screen. '
          'You can change your name, profile photo, period/cycle length settings, and notification preferences there. 👤';
    }
    if (_has(lq, ['google', 'sign in', 'login', 'register', 'password', 'forgot'])) {
      return 'You can sign in with email/password or with your Google account. '
          'If you\'ve forgotten your password, tap "Forgot password?" on the login screen and '
          'we\'ll send a reset link to your email. 🔑';
    }
    if (_has(lq, ['period ring', 'cycle ring', 'circle', 'ring', 'chart', 'history'])) {
      return 'The cycle ring on the History tab shows your current position in your menstrual cycle!\n'
          '🔴 Red arc = Period phase\n'
          '🩵 Teal arc = Fertile window\n'
          '⚪ White dot = Today\'s position\n\n'
          'The center shows today\'s date and how many days until your next period. 💫';
    }
    if (_has(lq, ['hi', 'hello', 'hey', 'good morning', 'good afternoon', 'good evening'])) {
      return 'Hello! 🌸 I\'m your Seluna assistant. How can I help you today?\n\n'
          'You can ask me about your cycle, period symptoms, how to use the app, or general menstrual health.';
    }
    if (_has(lq, ['thank', 'thanks', 'great', 'helpful', 'awesome'])) {
      return 'You\'re welcome! 💕 Remember — every body is different and your cycle is uniquely yours. '
          'Keep tracking and I\'m always here if you have questions. 🌸';
    }

    // Default fallback
    return 'That\'s a great question! I don\'t have a specific answer for that yet. '
        'For personalised medical advice, please consult a healthcare provider.\n\n'
        'You can also try asking about:\n'
        '• Period cramps or pain\n'
        '• Irregular cycles\n'
        '• Fertile window\n'
        '• How to log periods\n'
        '• PMS symptoms 🌸';
  }

  bool _has(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));

  // ── Quick-question chips ─────────────────────────────────────────────────
  static const _quickQs = [
    'Why is my period late?',
    'How do I log a period?',
    'What is the fertile window?',
    'How to reduce cramps?',
    'How does prediction work?',
    'What is the cycle ring?',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A0508) : _bg;
    final cardColor = isDark ? const Color(0xFF2A0A14) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: _mid,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.assistant_rounded, size: 22),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Seluna Assistant',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                Text('Period & cycle FAQ',
                    style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_deep, _mid],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _msgs.length,
              itemBuilder: (ctx, i) => _BubbleTile(
                msg: _msgs[i],
                cardColor: cardColor,
              ),
            ),
          ),

          // Quick question chips
          if (_msgs.length <= 2)
            Container(
              color: bgColor,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _quickQs.map((q) => ActionChip(
                  label: Text(q,
                      style: const TextStyle(fontSize: 12, color: _deep)),
                  backgroundColor: _light.withAlpha(30),
                  side: BorderSide(color: _light.withAlpha(100)),
                  onPressed: () => _send(q),
                )).toList(),
              ),
            ),

          // Input bar
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    onSubmitted: _send,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Ask about your cycle...',
                      hintStyle: TextStyle(
                          color: Colors.grey.shade400, fontSize: 14),
                      filled: true,
                      fillColor: isDark
                          ? Colors.black.withAlpha(30)
                          : const Color(0xFFFCE4EC),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              const BorderSide(color: _mid, width: 1.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _send(_inputCtrl.text),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [_deep, _mid],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message data ─────────────────────────────────────────────────────────────
class _Msg {
  final String text;
  final bool isBot;
  _Msg({required this.text, required this.isBot});
}

// ── Chat bubble tile ─────────────────────────────────────────────────────────
class _BubbleTile extends StatelessWidget {
  final _Msg msg;
  final Color cardColor;
  const _BubbleTile({required this.msg, required this.cardColor});

  static const _mid  = Color(0xFFE91E63);
  static const _deep = Color(0xFF880E4F);

  @override
  Widget build(BuildContext context) {
    final isBot = msg.isBot;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isBot) ...[
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [_deep, _mid],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.assistant_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isBot
                    ? cardColor
                    : _mid,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isBot ? 4 : 18),
                  bottomRight: Radius.circular(isBot ? 18 : 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  fontSize: 14,
                  color: isBot
                      ? Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87
                      : Colors.white,
                  height: 1.45,
                ),
              ),
            ),
          ),
          if (!isBot) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
