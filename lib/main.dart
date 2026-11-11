import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Global theme notifier for Dark Mode toggle
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() {
  runApp(const RectifierLabApp());
}

class RectifierLabApp extends StatelessWidget {
  const RectifierLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'EC2700 - Full Wave Rectification Lab',
          themeMode: currentMode,
          theme: ThemeData(
            brightness: Brightness.light,
            fontFamily: 'Roboto',
            scaffoldBackgroundColor: const Color(0xFFF8F9FA),
            sliderTheme: const SliderThemeData(
              activeTrackColor: Color(0xFF800000),
              thumbColor: Color(0xFF800000),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: 'Roboto',
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            sliderTheme: const SliderThemeData(
              activeTrackColor: Color(0xFFEF4444),
              thumbColor: Color(0xFFEF4444),
            ),
          ),
          home: const LabHomePage(),
        );
      },
    );
  }
}

// ===========================================================================
// QUIZ DATA MODEL
// ===========================================================================
class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

class LabHomePage extends StatefulWidget {
  const LabHomePage({super.key});

  @override
  State<LabHomePage> createState() => _LabHomePageState();
}

class _LabHomePageState extends State<LabHomePage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  // Animation controller driving the continuous real-time simulation
  late AnimationController _simController;

  // Center-tapped numerical parameters
  double _ctVm = 12.0;
  double _ctFreq = 50.0;
  double _ctVd = 0.7;
  double _ctRl = 1000.0;
  bool _ctIsRunning = true;
  double _ctSpeed = 1.0;

  late final TextEditingController _ctVmController;
  late final TextEditingController _ctFreqController;
  late final TextEditingController _ctVdController;
  late final TextEditingController _ctRlController;

  // Bridge numerical parameters
  double _brVm = 12.0;
  double _brFreq = 50.0;
  double _brVd = 0.7;
  double _brRl = 1000.0;
  bool _brIsRunning = true;
  double _brSpeed = 1.0;

  late final TextEditingController _brVmController;
  late final TextEditingController _brFreqController;
  late final TextEditingController _brVdController;
  late final TextEditingController _brRlController;

  // ================= QUIZ STATE VARIABLES =================
  final Map<int, int> _userAnswers = {};
  bool _quizSubmitted = false;

  final List<QuizQuestion> _quizQuestions = [
    QuizQuestion(
      question:
          '1. In a full wave rectifier with an input AC frequency of 50 Hz, what is the fundamental ripple frequency of the output?',
      options: ['25 Hz', '50 Hz', '100 Hz', '200 Hz'],
      correctIndex: 2,
      explanation:
          'Unlike a half-wave rectifier, a full wave rectifier conducts during both the positive and negative half-cycles. This produces two output pulses for every one full input cycle, effectively doubling the fundamental ripple frequency (2 × 50 Hz = 100 Hz).',
    ),
    QuizQuestion(
      question:
          '2. What is the Peak Inverse Voltage (PIV) rating required for each diode in a Bridge Rectifier?',
      options: ['Vm / 2', 'Vm', '√2 Vm', '2Vm'],
      correctIndex: 1,
      explanation:
          'In a bridge rectifier, the maximum reverse voltage across any non-conducting diode is equal to the peak secondary voltage (Vm). This is a major advantage over the center-tapped configuration.',
    ),
    QuizQuestion(
      question:
          '3. What is the Peak Inverse Voltage (PIV) across the non-conducting diode in a Center-Tapped Full Wave Rectifier?',
      options: ['Vm / 2', 'Vm', '2Vm', '4Vm'],
      correctIndex: 2,
      explanation:
          'In a center-tapped configuration, the non-conducting diode is connected across the entire secondary winding. Therefore, it must block twice the peak voltage of half the winding (2Vm).',
    ),
    QuizQuestion(
      question:
          '4. What is the maximum theoretical rectification efficiency of a full wave rectifier?',
      options: ['40.6%', '81.2%', '100%', '121%'],
      correctIndex: 1,
      explanation:
          'The maximum efficiency of full wave rectification is 81.2%, which is exactly double the efficiency of a half-wave rectifier (40.6%). The remaining power is dissipated as AC ripple and internal diode resistance.',
    ),
    QuizQuestion(
      question:
          '5. For a peak input voltage Vm (ignoring diode drops), what is the average DC output voltage (Vdc) of a full wave rectifier?',
      options: ['Vm / π', '2Vm / π', 'Vm / √2', 'Vm'],
      correctIndex: 1,
      explanation:
          'The average DC voltage is found by integrating the area under the full rectified sine wave over one period. This yields an average value of 2Vm / π (approximately 0.636 Vm).',
    ),
    QuizQuestion(
      question:
          '6. Which configuration requires a specialized transformer but uses only two diodes?',
      options: [
        'Half-Wave Rectifier',
        'Bridge Rectifier',
        'Center-Tapped Rectifier',
        'Voltage Multiplier'
      ],
      correctIndex: 2,
      explanation:
          'The center-tapped rectifier requires a transformer with a center-tap connection to establish the 0V ground reference, allowing it to function using only two diodes.',
    ),
    QuizQuestion(
      question:
          '7. In a practical bridge rectifier utilizing standard silicon diodes, what is the peak output voltage across the load if the peak secondary voltage is Vm?',
      options: ['Vm - 0.3V', 'Vm - 0.7V', 'Vm - 1.4V', 'Vm'],
      correctIndex: 2,
      explanation:
          'During any half-cycle in a bridge rectifier, current flows through two series diodes. Each silicon diode has a forward drop of approximately 0.7V, resulting in a total voltage loss of 2 × 0.7V = 1.4V.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _simController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _ctVmController = TextEditingController(text: _ctVm.toStringAsFixed(1));
    _ctFreqController = TextEditingController(text: _ctFreq.toStringAsFixed(0));
    _ctVdController = TextEditingController(text: _ctVd.toStringAsFixed(2));
    _ctRlController = TextEditingController(text: _ctRl.toStringAsFixed(0));

    _brVmController = TextEditingController(text: _brVm.toStringAsFixed(1));
    _brFreqController = TextEditingController(text: _brFreq.toStringAsFixed(0));
    _brVdController = TextEditingController(text: _brVd.toStringAsFixed(2));
    _brRlController = TextEditingController(text: _brRl.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _simController.dispose();
    _scrollController.dispose();

    _ctVmController.dispose();
    _ctFreqController.dispose();
    _ctVdController.dispose();
    _ctRlController.dispose();

    _brVmController.dispose();
    _brFreqController.dispose();
    _brVdController.dispose();
    _brRlController.dispose();

    super.dispose();
  }

  void _updateControllerSafely(TextEditingController controller, String newText) {
    if (controller.text != newText) {
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }

  void _scrollToContent() {
    _scrollController.animateTo(
      MediaQuery.of(context).size.height,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
    );
  }

  void _submitQuiz() {
    if (_userAnswers.length < _quizQuestions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions before submitting.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _quizSubmitted = true;
    });
  }

  // ================= PDF GENERATION =================
  Future<void> _generatePdfReport(
      int score, int total, bool isDark, Color brandColor) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'BASIC ELECTRONICS LAB PROJECT',
                  style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      decoration: pw.TextDecoration.underline),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text('Topic: Full Wave Rectification',
                    style: const pw.TextStyle(fontSize: 16)),
              ),
              pw.SizedBox(height: 30),
              pw.Text('Submitted By:',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('• Dwarika Singh Ghimire (125cs0158)'),
              pw.Text('• Manish Kumar Sah (125cs0159)'),
              pw.Text('• Nischal Chand (125cs0179)'),
              pw.SizedBox(height: 10),
              pw.Text('Subject Code: EC2700',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Divider(height: 40, thickness: 2),
              pw.Text('1. Final Simulation Parameters',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Center-Tapped Rectifier:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('  Peak Input (Vm): ${_ctVm.toStringAsFixed(1)} V'),
              pw.Text('  Frequency (f): ${_ctFreq.toStringAsFixed(0)} Hz'),
              pw.Text('  Diode Drop (Vd): ${_ctVd.toStringAsFixed(2)} V'),
              pw.Text('  Load Resistor (RL): ${_ctRl.toStringAsFixed(0)} Ω'),
              pw.SizedBox(height: 10),
              pw.Text('Bridge Rectifier:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('  Peak Input (Vm): ${_brVm.toStringAsFixed(1)} V'),
              pw.Text('  Frequency (f): ${_brFreq.toStringAsFixed(0)} Hz'),
              pw.Text('  Diode Drop (Vd): ${_brVd.toStringAsFixed(2)} V'),
              pw.Text('  Load Resistor (RL): ${_brRl.toStringAsFixed(0)} Ω'),
              pw.Divider(height: 40, thickness: 2),
              pw.Text('2. Quiz Performance',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Final Score: $score / $total',
                  style: const pw.TextStyle(
                      fontSize: 18, color: PdfColors.green700)),
              pw.SizedBox(height: 20),
              pw.Text('Verification Status: PASSED',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'EC2700_Rectification_Lab_Report.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dynamic Colors
    final Color brandColor =
        isDark ? const Color(0xFFEF4444) : const Color(0xFF800000);
    final Color bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final Color cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color textColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final Color subTextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final Color borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        onPressed: () {
          themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
        },
        child: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              // ================= 1. COVER / TITLE SCREEN =================
              Container(
                height: screenHeight,
                width: double.infinity,
                color: bgColor,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'BASIC ELECTRONICS LAB PROJECT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        color: brandColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Topic : Full Wave Rectification',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 25),
                    Image.asset(
                      'assets/nitr_logo.png',
                      height: 130,
                      fit: BoxFit.contain,
                      color: isDark ? Colors.white : null,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.school, size: 90, color: brandColor),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      'Submitted By :',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: brandColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dwarika Singh Ghimire (125cs0158)',
                      style: TextStyle(fontSize: 14, color: textColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manish Kumar Sah (125cs0159)',
                      style: TextStyle(fontSize: 14, color: textColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nischal Chand (125cs0179)',
                      style: TextStyle(fontSize: 14, color: textColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Subject Code : EC2700',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: brandColor,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _scrollToContent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_downward, size: 18),
                      label: const Text(
                        'Start Reading',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // ================= 2. LAB CONTENT SECTION =================
              Container(
                constraints: const BoxConstraints(maxWidth: 820),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF332A00)
                            : const Color(0xFFFFF9E6),
                        border: const Border(
                          left: BorderSide(color: Colors.amber, width: 4),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Learning Objectives :',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                              '• Understand rectification and diode conduction mechanics.',
                              style: TextStyle(color: textColor)),
                          Text(
                              '• Trace current flow across Center-Tapped and Bridge rectifiers.',
                              style: TextStyle(color: textColor)),
                          Text(
                              '• Observe how AC sine waves convert to pulsating unidirectional DC in real-time.',
                              style: TextStyle(color: textColor)),
                          Text(
                              '• Verify mathematical models for DC output voltage, RMS, ripple, and PIV.',
                              style: TextStyle(color: textColor)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 35),

                    _sectionHeading('1. What is Rectification?', textColor),
                    Text(
                      'Rectification is the process of converting bidirectional Alternating Current (AC) into unidirectional Direct Current (DC).',
                      style: TextStyle(
                          fontSize: 15, height: 1.5, color: textColor),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '• Mains electricity comes as an alternating sine wave because it is easy to transmit over long distances using transformers.\n'
                      '• Electronic gadgets (mobile phones, TVs, laptops) require constant one-direction DC.\n'
                      '• The P-N junction diode acts as an electronic one-way check valve: it conducts when forward-biased (anode at higher potential than cathode) and acts like an open switch when reverse-biased.',
                      style: TextStyle(
                          fontSize: 15, height: 1.6, color: textColor),
                    ),
                    const SizedBox(height: 35),

                    _sectionHeading(
                        '2. Center-Tapped Full Wave Rectifier', textColor),
                    Text(
                      'A center-tapped full wave rectifier uses a center-tapped secondary winding that establishes a zero-volt ground reference, accompanied by two diodes (D₁ and D₂).',
                      style: TextStyle(
                          fontSize: 15, height: 1.5, color: textColor),
                    ),
                    const SizedBox(height: 16),

                    _buildCenterTappedSimulationBlock(isDark, brandColor,
                        cardColor, textColor, subTextColor, borderColor),

                    const SizedBox(height: 20),
                    _subHeading('Working Principle:', textColor),
                    Text(
                      '1. During the Positive Half Cycle: Terminal A is positive (+) with respect to the center tap, and Terminal B is negative (-). Diode D₁ is forward-biased and conducts. Diode D₂ is reverse-biased (OFF). Current flows from Terminal A → D₁ → Load Resistor (RL, right to left) → Center Tap.\n\n'
                      '2. During the Negative Half Cycle: The polarity reverses. Terminal A becomes negative (-), and Terminal B becomes positive (+). Diode D₂ is forward-biased and conducts, while D₁ is reverse-biased (OFF). Current flows from Terminal B → D₂ → Load Resistor (RL, right to left) → Center Tap.\n\n'
                      'Result: Current passes through RL in the identical direction during both halves of the input AC cycle.',
                      style: TextStyle(
                          fontSize: 14.5, height: 1.55, color: textColor),
                    ),
                    const SizedBox(height: 35),

                    _sectionHeading('3. Bridge Full Wave Rectifier', textColor),
                    Text(
                      'The Bridge Rectifier uses four diodes (D₁, D₂, D₃, and D₄) connected in a closed bridge network. It does not require a bulky center-tapped transformer, functioning with a standard two-wire secondary coil.',
                      style: TextStyle(
                          fontSize: 15, height: 1.5, color: textColor),
                    ),
                    const SizedBox(height: 16),

                    _buildBridgeSimulationBlock(isDark, brandColor, cardColor,
                        textColor, subTextColor, borderColor),

                    const SizedBox(height: 20),
                    _subHeading('Working Step-by-Step:', textColor),
                    Text(
                      'A. Positive Half Cycle (Terminal A is +, Terminal B is -):\n'
                      '• Diodes D₁ and D₃ are forward-biased (turn ON).\n'
                      '• Diodes D₂ and D₄ are reverse-biased (turn OFF).\n'
                      '• Conduction path: Terminal A → D₁ → Load RL (top to bottom) → D₃ → Terminal B.\n\n'
                      'B. Negative Half Cycle (Terminal B is +, Terminal A is -):\n'
                      '• Diodes D₄ and D₂ are forward-biased (turn ON).\n'
                      '• Diodes D₁ and D₃ are reverse-biased (turn OFF).\n'
                      '• Conduction path: Terminal B → D₄ → Load RL (top to bottom) → D₂ → Terminal A.\n\n'
                      'Result: Current flows through RL in the same downward direction during both cycles, with lower peak inverse voltage requirement per diode.',
                      style: TextStyle(
                          fontSize: 14.5, height: 1.55, color: textColor),
                    ),
                    const SizedBox(height: 35),

                    _sectionHeading(
                        '4. Center-Tapped vs Bridge Rectifier', textColor),
                    Text(
                      'Point-by-point comparison of both full wave rectification configurations:',
                      style: TextStyle(fontSize: 15, color: textColor),
                    ),
                    const SizedBox(height: 14),
                    _buildComparisonTable(
                        isDark, brandColor, cardColor, textColor, borderColor),

                    const SizedBox(height: 50),
                    Divider(thickness: 2, color: borderColor),
                    const SizedBox(height: 40),

                    // ================= 3. QUIZ SECTION =================
                    _sectionHeading('5. Test Your Knowledge (Quiz)', textColor),
                    Text(
                      'Answer the following engineering questions based on the full wave rectification project. Explanations will be revealed after submission.',
                      style: TextStyle(fontSize: 15, color: subTextColor),
                    ),
                    const SizedBox(height: 24),
                    _buildQuizSection(
                        isDark, brandColor, cardColor, textColor, borderColor),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // QUIZ UI BUILDER
  // =========================================================================
  Widget _buildQuizSection(bool isDark, Color brandColor, Color cardColor,
      Color textColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _quizQuestions.length; i++)
          _buildQuizQuestionCard(i, _quizQuestions[i], isDark, brandColor,
              cardColor, textColor, borderColor),
        const SizedBox(height: 20),
        if (!_quizSubmitted)
          Center(
            child: ElevatedButton.icon(
              onPressed: _submitQuiz,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text(
                'Submit Quiz',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: brandColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          )
        else
          _buildQuizResults(
              isDark, brandColor, cardColor, textColor, borderColor),
      ],
    );
  }

  Widget _buildQuizQuestionCard(int qIndex, QuizQuestion question, bool isDark,
      Color brandColor, Color cardColor, Color textColor, Color borderColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.question,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          for (int optIndex = 0; optIndex < question.options.length; optIndex++)
            _buildQuizOption(qIndex, optIndex, question, isDark, brandColor,
                cardColor, textColor, borderColor),
          if (_quizSubmitted) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF064E3B) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: isDark
                        ? const Color(0xFF059669)
                        : const Color(0xFF86EFAC)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline,
                      color: isDark
                          ? const Color(0xFF34D399)
                          : const Color(0xFF16A34A),
                      size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Logic: ${question.explanation}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFFD1FAE5)
                            : const Color(0xFF14532D),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildQuizOption(
      int qIndex,
      int optIndex,
      QuizQuestion question,
      bool isDark,
      Color brandColor,
      Color cardColor,
      Color textColor,
      Color borderColor) {
    final isSelected = _userAnswers[qIndex] == optIndex;
    final isCorrectOption = optIndex == question.correctIndex;

    Color optBgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    Color optBorderColor = borderColor;
    Color optTextColor = textColor;
    FontWeight weight = FontWeight.normal;

    if (!_quizSubmitted) {
      if (isSelected) {
        optBgColor = isDark ? const Color(0xFF450a0a) : const Color(0xFFFFF1F2);
        optBorderColor = brandColor;
        optTextColor = brandColor;
        weight = FontWeight.bold;
      }
    } else {
      if (isCorrectOption) {
        optBgColor = isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7);
        optBorderColor =
            isDark ? const Color(0xFF10B981) : const Color(0xFF22C55E);
        optTextColor =
            isDark ? const Color(0xFF6EE7B7) : const Color(0xFF166534);
        weight = FontWeight.bold;
      } else if (isSelected && !isCorrectOption) {
        optBgColor = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2);
        optBorderColor =
            isDark ? const Color(0xFFEF4444) : const Color(0xFFEF4444);
        optTextColor =
            isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B);
        weight = FontWeight.bold;
      } else {
        optBgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
        optBorderColor = borderColor;
        optTextColor =
            isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
      }
    }

    return GestureDetector(
      onTap: () {
        if (!_quizSubmitted) {
          setState(() {
            _userAnswers[qIndex] = optIndex;
          });
        }
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: optBgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: optBorderColor,
              width: isSelected || (_quizSubmitted && isCorrectOption) ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected || (_quizSubmitted && isCorrectOption)
                    ? optBorderColor
                    : optBgColor,
                border: Border.all(color: optBorderColor),
              ),
              child: Text(
                String.fromCharCode(65 + optIndex),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected || (_quizSubmitted && isCorrectOption)
                      ? Colors.white
                      : optTextColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                question.options[optIndex],
                style: TextStyle(
                  fontSize: 14.5,
                  color: optTextColor,
                  fontWeight: weight,
                ),
              ),
            ),
            if (_quizSubmitted && isCorrectOption)
              Icon(Icons.check_circle,
                  color: isDark
                      ? const Color(0xFF34D399)
                      : const Color(0xFF22C55E),
                  size: 20)
            else if (_quizSubmitted && isSelected && !isCorrectOption)
              Icon(Icons.cancel,
                  color: isDark
                      ? const Color(0xFFF87171)
                      : const Color(0xFFEF4444),
                  size: 20)
          ],
        ),
      ),
    );
  }

  Widget _buildQuizResults(bool isDark, Color brandColor, Color cardColor,
      Color textColor, Color borderColor) {
    int score = 0;
    for (int i = 0; i < _quizQuestions.length; i++) {
      if (_userAnswers[i] == _quizQuestions[i].correctIndex) {
        score++;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Text(
            'Quiz Completed',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 12),
          Text(
            'You scored $score out of ${_quizQuestions.length}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: score >= 5
                  ? (isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A))
                  : brandColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Review the technical explanations detailed in the green boxes below each question.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _userAnswers.clear();
                    _quizSubmitted = false;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retake'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF334155),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _generatePdfReport(
                    score, _quizQuestions.length, isDark, brandColor),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Download Lab Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF059669)
                      : const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SIMULATION BLOCK: CENTER TAPPED (FIXED FOR KEYBOARD INPUT)
  // =========================================================================
  Widget _buildCenterTappedSimulationBlock(bool isDark, Color brandColor,
      Color cardColor, Color textColor, Color subTextColor, Color borderColor) {
    final vPeakOut = math.max(0.0, _ctVm - _ctVd);
    final vDc = (2 * vPeakOut) / math.pi;
    final vRms = vPeakOut / math.sqrt(2);
    final piv = 2 * _ctVm;
    final fOut = 2 * _ctFreq;
    final iDc = (_ctRl > 0) ? (vDc / _ctRl) * 1000 : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Controls outside AnimatedBuilder so TextFields never lose focus
          _buildControlPanelHeader(
            title: 'Center-Tapped Configuration Controls',
            isRunning: _ctIsRunning,
            textColor: textColor,
            onTogglePlay: () {
              setState(() => _ctIsRunning = !_ctIsRunning);
            },
            onReset: () {
              setState(() {
                _ctVm = 12.0;
                _ctFreq = 50.0;
                _ctVd = 0.7;
                _ctRl = 1000.0;
                _ctSpeed = 1.0;
                _updateControllerSafely(_ctVmController, '12.0');
                _updateControllerSafely(_ctFreqController, '50');
                _updateControllerSafely(_ctVdController, '0.70');
                _updateControllerSafely(_ctRlController, '1000');
              });
            },
          ),
          const SizedBox(height: 12),
          _buildInputControlsRow(
            vm: _ctVm,
            freq: _ctFreq,
            vd: _ctVd,
            rl: _ctRl,
            speed: _ctSpeed,
            vmController: _ctVmController,
            freqController: _ctFreqController,
            vdController: _ctVdController,
            rlController: _ctRlController,
            isDark: isDark,
            brandColor: brandColor,
            textColor: textColor,
            subTextColor: subTextColor,
            borderColor: borderColor,
            onVmChanged: (v) {
              setState(() {
                _ctVm = v;
                _updateControllerSafely(_ctVmController, v.toStringAsFixed(1));
              });
            },
            onFreqChanged: (v) {
              setState(() {
                _ctFreq = v;
                _updateControllerSafely(
                    _ctFreqController, v.toStringAsFixed(0));
              });
            },
            onVdChanged: (v) {
              setState(() {
                _ctVd = v;
                _updateControllerSafely(_ctVdController, v.toStringAsFixed(2));
              });
            },
            onRlChanged: (v) {
              setState(() {
                _ctRl = v;
                _updateControllerSafely(_ctRlController, v.toStringAsFixed(0));
              });
            },
            onSpeedChanged: (v) => setState(() => _ctSpeed = v),
            onVmTyped: (text) {
              final val = double.tryParse(text);
              if (val != null && val >= 0) setState(() => _ctVm = val);
            },
            onFreqTyped: (text) {
              final val = double.tryParse(text);
              if (val != null && val > 0) setState(() => _ctFreq = val);
            },
            onVdTyped: (text) {
              final val = double.tryParse(text);
              if (val != null && val >= 0) setState(() => _ctVd = val);
            },
            onRlTyped: (text) {
              final val = double.tryParse(text);
              if (val != null && val > 0) setState(() => _ctRl = val);
            },
          ),
          const SizedBox(height: 18),

          // 2. Only visual canvases animate at 60 FPS inside AnimatedBuilder
          AnimatedBuilder(
            animation: _simController,
            builder: (context, child) {
              final progress =
                  _ctIsRunning ? (_simController.value * _ctSpeed) % 1.0 : 0.25;
              final phase = progress * 2 * math.pi;
              final instantaneousVin = _ctVm * math.sin(phase);
              final isPositiveCycle = instantaneousVin >= 0;
              final instantaneousVout = math.max(
                0.0,
                instantaneousVin.abs() - _ctVd,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _subHeading('Input AC Waveform [Vin(t)]', textColor),
                  _buildScopeContainer(
                    child: CustomPaint(
                      size: const Size(double.infinity, 130),
                      painter: ScopeWaveformPainter(
                        phase: phase,
                        amplitude: _ctVm,
                        traceColor: const Color(0xFF0284C7),
                        isRectified: false,
                        diodeDrop: _ctVd,
                        label: 'CH1: AC Input (Secondary Half)',
                        instantaneousValue: instantaneousVin,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildStateChip(
                    isPositiveCycle: isPositiveCycle,
                    isDark: isDark,
                    labelPositive:
                        'Positive Half Cycle: Terminal A (+), D₁ Conducts (ON), D₂ (OFF)',
                    labelNegative:
                        'Negative Half Cycle: Terminal B (+), D₂ Conducts (ON), D₁ (OFF)',
                  ),
                  const SizedBox(height: 10),
                  _subHeading('Center-Tapped Circuit Simulation & Current Flow',
                      textColor),
                  Container(
                    width: double.infinity,
                    height: 280,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFFAFAFA),
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: CustomPaint(
                      painter: CenterTappedCircuitPainter(
                        phase: phase,
                        isPositiveCycle: isPositiveCycle,
                        instantaneousVin: instantaneousVin,
                        d1Conducting:
                            isPositiveCycle && instantaneousVin > _ctVd,
                        d2Conducting: !isPositiveCycle &&
                            instantaneousVin.abs() > _ctVd,
                        animationProgress: progress,
                        isDark: isDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _subHeading(
                      'Output DC Waveform [Vout(t) across RL]', textColor),
                  _buildScopeContainer(
                    child: CustomPaint(
                      size: const Size(double.infinity, 130),
                      painter: ScopeWaveformPainter(
                        phase: phase,
                        amplitude: _ctVm,
                        traceColor: const Color(0xFFD97706),
                        isRectified: true,
                        diodeDrop: _ctVd,
                        label: 'CH2: Full Wave Rectified DC',
                        instantaneousValue: instantaneousVout,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          _buildCalculationsGrid(
              isDark, borderColor, textColor, subTextColor, cardColor, [
            _calcItem('Peak Input (Vm)', '${_ctVm.toStringAsFixed(1)} V',
                cardColor, borderColor, subTextColor, textColor),
            _calcItem('Diode Drop (Vd)', '${_ctVd.toStringAsFixed(2)} V',
                cardColor, borderColor, subTextColor, textColor),
            _calcItem('DC Voltage (Vdc)', '${vDc.toStringAsFixed(2)} V',
                cardColor, borderColor, subTextColor, textColor),
            _calcItem('RMS Voltage (Vrms)', '${vRms.toStringAsFixed(2)} V',
                cardColor, borderColor, subTextColor, textColor),
            _calcItem('DC Load Current (Idc)', '${iDc.toStringAsFixed(2)} mA',
                cardColor, borderColor, subTextColor, textColor),
            _calcItem('Output Frequency', '${fOut.toStringAsFixed(0)} Hz',
                cardColor, borderColor, subTextColor, textColor),
            _calcItem('Peak Inverse Voltage', '${piv.toStringAsFixed(1)} V',
                cardColor, borderColor, subTextColor, textColor),
            _calcItem('Efficiency (η)', '81.2% max', cardColor, borderColor,
                subTextColor, textColor),
          ]),
        ],
      ),
    );
  }

  // =========================================================================
  // SIMULATION BLOCK: BRIDGE RECTIFIER (FIXED FOR KEYBOARD INPUT)
  // =========================================================================
  Widget _buildBridgeSimulationBlock(bool isDark, Color brandColor,
      Color cardColor, Color textColor, Color subTextColor, Color borderColor) {
    final vPeakOut = math.max(0.0, _brVm - (2 * _brVd));
    final vDc = (2 * vPeakOut) / math.pi;
    final vRms = vPeakOut / math.sqrt(2);
    final piv = _brVm;
    final fOut = 2 * _brFreq;
    final iDc = (_brRl > 0) ? (vDc / _brRl) * 1000 : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Controls outside AnimatedBuilder so TextFields never lose focus
          _buildControlPanelHeader(
            title: 'Bridge Rectifier Configuration Controls',
            isRunning: _brIsRunning,
            textColor: textColor,
            onTogglePlay: () {
              setState(() => _brIsRunning = !_brIsRunning);
            },
            onReset: () {
              setState(() {
                _brVm = 12.0;
                _brFreq = 50.0;
                _brVd = 0.7;
                _brRl = 1000.0;
                _brSpeed = 1.0;
                _updateControllerSafely(_brVmController, '12.0');
                _updateControllerSafely(_brFreqController, '50');
                _updateControllerSafely(_brVdController, '0.70');
                _updateControllerSafely(_brRlController, '1000');
              });
            },
          ),
          const SizedBox(height: 12),
          _buildInputControlsRow(
            vm: _brVm,
            freq: _brFreq,
            vd: _brVd,
            rl: _brRl,
            speed: _brSpeed,
            vmController: _brVmController,
            freqController: _brFreqController,
            vdController: _brVdController,
            rlController: _brRlController,
            isDark: isDark,
            brandColor: brandColor,
            textColor: textColor,
            subTextColor: subTextColor,
            borderColor: borderColor,
            onVmChanged: (v) {
              setState(() {
                _brVm = v;
                _updateControllerSafely(_brVmController, v.toStringAsFixed(1));
              });
            },
            onFreqChanged: (v) {
              setState(() {
                _brFreq = v;
                _updateControllerSafely(
                    _brFreqController, v.toStringAsFixed(0));
              });
            },
            onVdChanged: (v) {
              setState(() {
                _brVd = v;
                _updateControllerSafely(_brVdController, v.toStringAsFixed(2));
              });
            },
            onRlChanged: (v) {
              setState(() {
                _brRl = v;
                _updateControllerSafely(_brRlController, v.toStringAsFixed(0));
              });
            },
            onSpeedChanged: (v) => setState(() => _brSpeed = v),
            onVmTyped: (text) {
              final val = double.tryParse(text);
              if (val != null && val >= 0) setState(() => _brVm = val);
            },
            onFreqTyped: (text) {
              final val = double.tryParse(text);
              if (val != null && val > 0) setState(() => _brFreq = val);
            },
            onVdTyped: (text) {
              final val = double.tryParse(text);
              if (val != null && val >= 0) setState(() => _brVd = val);
            },
            onRlTyped: (text) {
              final val = double.tryParse(text);
              if (val != null && val > 0) setState(() => _brRl = val);
            },
          ),
          const SizedBox(height: 18),

          // 2. Only visual canvases animate at 60 FPS inside AnimatedBuilder
          AnimatedBuilder(
            animation: _simController,
            builder: (context, child) {
              final progress =
                  _brIsRunning ? (_simController.value * _brSpeed) % 1.0 : 0.25;
              final phase = progress * 2 * math.pi;
              final instantaneousVin = _brVm * math.sin(phase);
              final isPositiveCycle = instantaneousVin >= 0;
              final instantaneousVout = math.max(
                0.0,
                instantaneousVin.abs() - (2 * _brVd),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _subHeading('Input AC Waveform [Vin(t)]', textColor),
                  _buildScopeContainer(
                    child: CustomPaint(
                      size: const Size(double.infinity, 130),
                      painter: ScopeWaveformPainter(
                        phase: phase,
                        amplitude: _brVm,
                        traceColor: const Color(0xFF0284C7),
                        isRectified: false,
                        diodeDrop: _brVd,
                        label: 'CH1: AC Input (Secondary Voltage)',
                        instantaneousValue: instantaneousVin,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildStateChip(
                    isPositiveCycle: isPositiveCycle,
                    isDark: isDark,
                    labelPositive:
                        'Positive Half Cycle: Terminal A (+), D₁ & D₃ ON, D₂ & D₄ OFF',
                    labelNegative:
                        'Negative Half Cycle: Terminal B (+), D₂ & D₄ ON, D₁ & D₃ OFF',
                  ),
                  const SizedBox(height: 10),
                  _subHeading('Bridge Circuit Simulation & Current Flow',
                      textColor),
                  Container(
                    width: double.infinity,
                    height: 310,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFFAFAFA),
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: CustomPaint(
                      painter: BridgeCircuitPainter(
                        phase: phase,
                        isPositiveCycle: isPositiveCycle,
                        instantaneousVin: instantaneousVin,
                        d1d3Conducting:
                            isPositiveCycle && instantaneousVin > (2 * _brVd),
                        d2d4Conducting: !isPositiveCycle &&
                            instantaneousVin.abs() > (2 * _brVd),
                        animationProgress: progress,
                        isDark: isDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _subHeading(
                      'Output DC Waveform [Vout(t) across RL]', textColor),
                  _buildScopeContainer(
                    child: CustomPaint(
                      size: const Size(double.infinity, 130),
                      painter: ScopeWaveformPainter(
                        phase: phase,
                        amplitude: _brVm,
                        traceColor: const Color(0xFFD97706),
                        isRectified: true,
                        isBridge: true,
                        diodeDrop: _brVd,
                        label: 'CH2: Full Wave Rectified DC (Vm - 2Vd)',
                        instantaneousValue: instantaneousVout,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          _buildCalculationsGrid(
              isDark, borderColor, textColor, subTextColor, cardColor, [
            _calcItem('Peak Input (Vm)', '${_brVm.toStringAsFixed(1)} V',
                cardColor, borderColor, subTextColor, textColor),
            _calcItem(
                'Total Diode Drop (2Vd)',
                '${(2 * _brVd).toStringAsFixed(2)} V',
                cardColor,
                borderColor,
                subTextColor,
                textColor),
            _calcItem('DC Voltage (Vdc)', '${vDc.toStringAsFixed(2)} V',
                cardColor, borderColor, subTextColor, textColor),
            _calcItem('RMS Voltage (Vrms)', '${vRms.toStringAsFixed(2)} V',
                cardColor, borderColor, subTextColor, textColor),
            _calcItem('DC Load Current (Idc)', '${iDc.toStringAsFixed(2)} mA',
                cardColor, borderColor, subTextColor, textColor),
            _calcItem('Output Frequency', '${fOut.toStringAsFixed(0)} Hz',
                cardColor, borderColor, subTextColor, textColor),
            _calcItem('Peak Inverse Voltage', '${piv.toStringAsFixed(1)} V',
                cardColor, borderColor, subTextColor, textColor),
            _calcItem('Efficiency (η)', '81.2% max', cardColor, borderColor,
                subTextColor, textColor),
          ]),
        ],
      ),
    );
  }

  // =========================================================================
  // CONTROL PANEL UI HELPERS
  // =========================================================================
  Widget _buildControlPanelHeader({
    required String title,
    required bool isRunning,
    required Color textColor,
    required VoidCallback onTogglePlay,
    required VoidCallback onReset,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        IconButton(
          tooltip: isRunning ? 'Pause Simulation' : 'Resume Simulation',
          icon: Icon(
            isRunning ? Icons.pause_circle_filled : Icons.play_circle_filled,
            color:
                isRunning ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
          ),
          onPressed: onTogglePlay,
        ),
        IconButton(
          tooltip: 'Reset Default Values',
          icon: const Icon(Icons.refresh, color: Color(0xFF475569)),
          onPressed: onReset,
        ),
      ],
    );
  }

  Widget _buildInputControlsRow({
    required double vm,
    required double freq,
    required double vd,
    required double rl,
    required double speed,
    required TextEditingController vmController,
    required TextEditingController freqController,
    required TextEditingController vdController,
    required TextEditingController rlController,
    required bool isDark,
    required Color brandColor,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
    required ValueChanged<double> onVmChanged,
    required ValueChanged<double> onFreqChanged,
    required ValueChanged<double> onVdChanged,
    required ValueChanged<double> onRlChanged,
    required ValueChanged<double> onSpeedChanged,
    required ValueChanged<String> onVmTyped,
    required ValueChanged<String> onFreqTyped,
    required ValueChanged<String> onVdTyped,
    required ValueChanged<String> onRlTyped,
  }) {
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _parameterRow(
            label: 'Peak Input Voltage (Vm)',
            controller: vmController,
            unit: 'V',
            value: vm,
            min: 2.0,
            max: 24.0,
            isDark: isDark,
            brandColor: brandColor,
            textColor: textColor,
            subTextColor: subTextColor,
            borderColor: borderColor,
            onSliderChanged: onVmChanged,
            onTextChanged: onVmTyped,
          ),
          Divider(height: 14, thickness: 0.5, color: borderColor),
          _parameterRow(
            label: 'Input Frequency (f)',
            controller: freqController,
            unit: 'Hz',
            value: freq,
            min: 10.0,
            max: 100.0,
            isDark: isDark,
            brandColor: brandColor,
            textColor: textColor,
            subTextColor: subTextColor,
            borderColor: borderColor,
            onSliderChanged: onFreqChanged,
            onTextChanged: onFreqTyped,
          ),
          Divider(height: 14, thickness: 0.5, color: borderColor),
          _parameterRow(
            label: 'Diode Forward Drop (Vd)',
            controller: vdController,
            unit: 'V',
            value: vd,
            min: 0.0,
            max: 1.2,
            isDark: isDark,
            brandColor: brandColor,
            textColor: textColor,
            subTextColor: subTextColor,
            borderColor: borderColor,
            onSliderChanged: onVdChanged,
            onTextChanged: onVdTyped,
          ),
          Divider(height: 14, thickness: 0.5, color: borderColor),
          _parameterRow(
            label: 'Load Resistor (RL)',
            controller: rlController,
            unit: 'Ω',
            value: rl,
            min: 100.0,
            max: 2500.0,
            isDark: isDark,
            brandColor: brandColor,
            textColor: textColor,
            subTextColor: subTextColor,
            borderColor: borderColor,
            onSliderChanged: onRlChanged,
            onTextChanged: onRlTyped,
          ),
          Divider(height: 14, thickness: 0.5, color: borderColor),
          _speedRow(
            label: 'Simulation Visual Speed',
            value: speed,
            isDark: isDark,
            textColor: textColor,
            onChanged: onSpeedChanged,
          ),
        ],
      ),
    );
  }

  Widget _parameterRow({
    required String label,
    required TextEditingController controller,
    required String unit,
    required double value,
    required double min,
    required double max,
    required bool isDark,
    required Color brandColor,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
    required ValueChanged<double> onSliderChanged,
    required ValueChanged<String> onTextChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 175,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onSliderChanged,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 85,
          height: 34,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: textColor,
            ),
            decoration: InputDecoration(
              suffixText: unit,
              suffixStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: subTextColor,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
              isDense: true,
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: brandColor, width: 1.5),
              ),
            ),
            onChanged: onTextChanged,
          ),
        ),
      ],
    );
  }

  Widget _speedRow({
    required String label,
    required double value,
    required bool isDark,
    required Color textColor,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 175,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: 0.2,
            max: 2.0,
            divisions: 9,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 85,
          child: Text(
            '${value.toStringAsFixed(1)}x',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStateChip({
    required bool isPositiveCycle,
    required bool isDark,
    required String labelPositive,
    required String labelNegative,
  }) {
    final activeText = isPositiveCycle ? labelPositive : labelNegative;

    Color positiveBg =
        isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF);
    Color positiveBorder =
        isDark ? const Color(0xFF3B82F6) : const Color(0xFF93C5FD);
    Color positiveText =
        isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF);
    Color positiveIcon =
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8);

    Color negativeBg =
        isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2);
    Color negativeBorder =
        isDark ? const Color(0xFFEF4444) : const Color(0xFFFCA5A5);
    Color negativeText =
        isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B);
    Color negativeIcon =
        isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isPositiveCycle ? positiveBg : negativeBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isPositiveCycle ? positiveBorder : negativeBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.swap_calls,
            size: 18,
            color: isPositiveCycle ? positiveIcon : negativeIcon,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              activeText,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isPositiveCycle ? positiveText : negativeText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B), // Scope always stays dark CRT style
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF1C2541)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: child,
    );
  }

  Widget _buildCalculationsGrid(bool isDark, Color borderColor, Color textColor,
      Color subTextColor, Color cardColor, List<Widget> items) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Calculated Electrical Values',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: items,
          ),
        ],
      ),
    );
  }

  Widget _calcItem(String label, String value, Color cardColor,
      Color borderColor, Color subTextColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: subTextColor),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _subHeading(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildComparisonTable(bool isDark, Color brandColor, Color cardColor,
      Color textColor, Color borderColor) {
    const tableData = [
      ['Feature', 'Center-Tapped', 'Bridge'],
      ['Number of diodes', '2', '4'],
      [
        'Transformer',
        'Center-tapped required',
        'Standard transformer suitable'
      ],
      ['Diodes conducting per half-cycle', '1', '2'],
      ['PIV per diode', '2 Vm', 'Vm'],
      ['Efficiency (Max)', '81.2%', '81.2%'],
      ['Ripple frequency', '2 × fin (100 Hz)', '2 × fin (100 Hz)'],
      ['Forward voltage drop loss', '1 Diode drop (Vd)', '2 Diode drops (2Vd)'],
      ['Transformer Utilization Factor', 'Lower (~0.672)', 'Higher (~0.812)'],
    ];

    return Table(
      border: TableBorder.all(color: borderColor),
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(1.4),
        2: FlexColumnWidth(1.4),
      },
      children: tableData.asMap().entries.map((entry) {
        final index = entry.key;
        final row = entry.value;
        final isHeader = index == 0;

        return TableRow(
          decoration: BoxDecoration(
            color: isHeader
                ? brandColor
                : (index.isOdd
                    ? cardColor
                    : (isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC))),
          ),
          children: row.map((cellText) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Text(
                cellText,
                style: TextStyle(
                  fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                  color: isHeader ? Colors.white : textColor,
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

// ===========================================================================
// OSCILLOSCOPE WAVEFORM CUSTOM PAINTER
// ===========================================================================
class ScopeWaveformPainter extends CustomPainter {
  final double phase;
  final double amplitude;
  final Color traceColor;
  final bool isRectified;
  final bool isBridge;
  final double diodeDrop;
  final String label;
  final double instantaneousValue;

  ScopeWaveformPainter({
    required this.phase,
    required this.amplitude,
    required this.traceColor,
    required this.isRectified,
    this.isBridge = false,
    required this.diodeDrop,
    required this.label,
    required this.instantaneousValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height / 2;
    final double maxDisplayAmp = size.height * 0.40;

    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.0;

    const int vDivisions = 8;
    for (int i = 0; i <= vDivisions; i++) {
      final double x = (size.width / vDivisions) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    const int hDivisions = 4;
    for (int i = 0; i <= hDivisions; i++) {
      final double y = (size.height / hDivisions) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final axisPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), axisPaint);

    final wavePath = Path();
    const double totalRad = 2 * math.pi;
    final dropTotal = isBridge ? (2 * diodeDrop) : diodeDrop;

    for (double x = 0; x <= size.width; x += 1.5) {
      final double t = (x / size.width) * totalRad;
      final double rawSine = amplitude * math.sin(t);
      double v;

      if (!isRectified) {
        v = rawSine;
      } else {
        v = math.max(0.0, rawSine.abs() - dropTotal);
      }

      final double scale = amplitude > 0 ? (v / amplitude) * maxDisplayAmp : 0;
      final double y =
          isRectified ? (size.height * 0.85 - scale) : (midY - scale);

      if (x == 0) {
        wavePath.moveTo(x, y);
      } else {
        wavePath.lineTo(x, y);
      }
    }

    final tracePaint = Paint()
      ..color = traceColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(wavePath, tracePaint);

    final double progress = (phase % (2 * math.pi)) / (2 * math.pi);
    final double cursorX = progress * size.width;
    final double cursorScale =
        amplitude > 0 ? (instantaneousValue / amplitude) * maxDisplayAmp : 0;
    final double cursorY =
        isRectified ? (size.height * 0.85 - cursorScale) : (midY - cursorScale);

    final cursorLinePaint = Paint()
      ..color = const Color(0x4DFFFFFF)
      ..strokeWidth = 1.0;
    canvas.drawLine(
        Offset(cursorX, 0), Offset(cursorX, size.height), cursorLinePaint);

    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cursorX, cursorY), 4.0, dotPaint);
    final dotRingPaint = Paint()
      ..color = traceColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(cursorX, cursorY), 6.0, dotRingPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text:
            '$label  |  v(t) = ${instantaneousValue >= 0 ? "+" : ""}${instantaneousValue.toStringAsFixed(2)} V',
        style: TextStyle(
          color: traceColor,
          fontSize: 11,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, const Offset(8, 6));
  }

  @override
  bool shouldRepaint(covariant ScopeWaveformPainter oldDelegate) => true;
}

// ===========================================================================
// CENTER-TAPPED CIRCUIT CUSTOM PAINTER (WITH ANIMATED CURRENT)
// ===========================================================================
class CenterTappedCircuitPainter extends CustomPainter {
  final double phase;
  final bool isPositiveCycle;
  final double instantaneousVin;
  final bool d1Conducting;
  final bool d2Conducting;
  final double animationProgress;
  final bool isDark;

  CenterTappedCircuitPainter({
    required this.phase,
    required this.isPositiveCycle,
    required this.instantaneousVin,
    required this.d1Conducting,
    required this.d2Conducting,
    required this.animationProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;

    const double xPri = 45;
    const double xCore = 70;
    const double xSec = 95;
    final double xDiode = w * 0.48;
    final double xRightBus = w - 45;
    final double xRlLeft = w * 0.38;
    final double xRlRight = w * 0.72;

    const double yTop = 45;
    const double yCenter = 140;
    const double yBottom = 235;

    final wireColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final wirePaint = Paint()
      ..color = wireColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final textStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white70 : const Color(0xFF1E293B),
    );

    _drawTransformerPrimary(canvas, xPri, yTop, yBottom, wireColor);
    _drawIronCore(canvas, xCore, yTop - 10, yBottom + 10, isDark);
    _drawTransformerSecondary(canvas, xSec, yTop, yCenter, yBottom, wireColor);

    canvas.drawLine(
        const Offset(xSec, yTop), Offset(xDiode - 20, yTop), wirePaint);
    canvas.drawLine(
        Offset(xDiode + 20, yTop), Offset(xRightBus, yTop), wirePaint);

    canvas.drawLine(
        const Offset(xSec, yBottom), Offset(xDiode - 20, yBottom), wirePaint);
    canvas.drawLine(
        Offset(xDiode + 20, yBottom), Offset(xRightBus, yBottom), wirePaint);

    canvas.drawLine(
        Offset(xRightBus, yTop), Offset(xRightBus, yBottom), wirePaint);
    canvas.drawLine(
        const Offset(xSec, yCenter), Offset(xRlLeft, yCenter), wirePaint);
    canvas.drawLine(
        Offset(xRlRight, yCenter), Offset(xRightBus, yCenter), wirePaint);

    _drawResistor(canvas, Offset(xRlLeft, yCenter), Offset(xRlRight, yCenter),
        'RL', isDark);

    _drawDiode(
      canvas: canvas,
      center: Offset(xDiode, yTop),
      name: 'D₁',
      isConducting: d1Conducting,
      pointsRight: true,
      isDark: isDark,
    );
    _drawDiode(
      canvas: canvas,
      center: Offset(xDiode, yBottom),
      name: 'D₂',
      isConducting: d2Conducting,
      pointsRight: true,
      isDark: isDark,
    );

    _drawText(canvas, 'A', const Offset(xSec - 20, yTop - 16), textStyle);
    _drawText(
      canvas,
      isPositiveCycle ? '(+)' : '(-)',
      const Offset(xSec - 20, yTop),
      TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isPositiveCycle
            ? (isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A))
            : const Color(0xFFEF4444),
      ),
    );

    _drawText(
        canvas, 'CT (0V)', const Offset(xSec - 52, yCenter - 8), textStyle);

    _drawText(canvas, 'B', const Offset(xSec - 20, yBottom + 4), textStyle);
    _drawText(
      canvas,
      !isPositiveCycle ? '(+)' : '(-)',
      const Offset(xSec - 20, yBottom - 12),
      TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: !isPositiveCycle
            ? (isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A))
            : const Color(0xFFEF4444),
      ),
    );

    if (d1Conducting) {
      final loop1 = [
        const Offset(xSec, yTop),
        Offset(xRightBus, yTop),
        Offset(xRightBus, yCenter),
        Offset(xRlRight, yCenter),
        Offset(xRlLeft, yCenter),
        const Offset(xSec, yCenter),
      ];
      _drawAnimatedCurrentFlow(canvas, loop1, animationProgress,
          isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB));
    } else if (d2Conducting) {
      final loop2 = [
        const Offset(xSec, yBottom),
        Offset(xRightBus, yBottom),
        Offset(xRightBus, yCenter),
        Offset(xRlRight, yCenter),
        Offset(xRlLeft, yCenter),
        const Offset(xSec, yCenter),
      ];
      _drawAnimatedCurrentFlow(
          canvas, loop2, animationProgress, const Color(0xFFEF4444));
    }

    _drawText(
      canvas,
      '(+)  DC Output  (-)',
      Offset((xRlLeft + xRlRight) / 2 - 50, yCenter + 18),
      TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF800000),
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CenterTappedCircuitPainter oldDelegate) => true;
}

// ===========================================================================
// BRIDGE CIRCUIT CUSTOM PAINTER (WITH ANIMATED CURRENT)
// ===========================================================================
class BridgeCircuitPainter extends CustomPainter {
  final double phase;
  final bool isPositiveCycle;
  final double instantaneousVin;
  final bool d1d3Conducting;
  final bool d2d4Conducting;
  final double animationProgress;
  final bool isDark;

  BridgeCircuitPainter({
    required this.phase,
    required this.isPositiveCycle,
    required this.instantaneousVin,
    required this.d1d3Conducting,
    required this.d2d4Conducting,
    required this.animationProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    const double xSource = 45;
    final double xCenter = w * 0.44;
    final double yCenter = h * 0.50;
    const double radius = 60.0;

    final nodeTop = Offset(xCenter, yCenter - radius);
    final nodeBottom = Offset(xCenter, yCenter + radius);
    final nodeLeft = Offset(xCenter - radius, yCenter);
    final nodeRight = Offset(xCenter + radius, yCenter);

    final double xRl = w - 45;

    final wireColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final wirePaint = Paint()
      ..color = wireColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final textStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white70 : const Color(0xFF1E293B),
    );

    const double ySrcA = 70;
    const double ySrcB = 230;

    _drawACGenerator(canvas, const Offset(xSource, 150), isDark);
    canvas.drawLine(
        const Offset(xSource, ySrcA), Offset(nodeLeft.dx, ySrcA), wirePaint);
    canvas.drawLine(Offset(nodeLeft.dx, ySrcA), nodeLeft, wirePaint);

    canvas.drawLine(
        const Offset(xSource, ySrcB), Offset(nodeRight.dx, ySrcB), wirePaint);
    canvas.drawLine(Offset(nodeRight.dx, ySrcB), nodeRight, wirePaint);

    _drawDiodeArm(
        canvas, nodeLeft, nodeTop, 'D₁', d1d3Conducting, isDark, wireColor);
    _drawDiodeArm(
        canvas, nodeBottom, nodeLeft, 'D₂', d2d4Conducting, isDark, wireColor);
    _drawDiodeArm(
        canvas, nodeBottom, nodeRight, 'D₃', d1d3Conducting, isDark, wireColor);
    _drawDiodeArm(
        canvas, nodeRight, nodeTop, 'D₄', d2d4Conducting, isDark, wireColor);

    canvas.drawLine(nodeTop, Offset(xRl, nodeTop.dy), wirePaint);
    canvas.drawLine(nodeBottom, Offset(xRl, nodeBottom.dy), wirePaint);

    _drawResistor(canvas, Offset(xRl, nodeTop.dy), Offset(xRl, nodeBottom.dy),
        'RL', isDark);

    _drawText(canvas, 'A', const Offset(xSource - 20, ySrcA - 16), textStyle);
    _drawText(
      canvas,
      isPositiveCycle ? '(+)' : '(-)',
      const Offset(xSource - 20, ySrcA),
      TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isPositiveCycle
            ? (isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A))
            : const Color(0xFFEF4444),
      ),
    );

    _drawText(canvas, 'B', const Offset(xSource - 20, ySrcB + 4), textStyle);
    _drawText(
      canvas,
      !isPositiveCycle ? '(+)' : '(-)',
      const Offset(xSource - 20, ySrcB - 12),
      TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: !isPositiveCycle
            ? (isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A))
            : const Color(0xFFEF4444),
      ),
    );

    _drawText(
      canvas,
      '(+) DC',
      Offset(xRl - 40, nodeTop.dy - 10),
      TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF800000),
      ),
    );
    _drawText(
      canvas,
      '(-) DC',
      Offset(xRl - 40, nodeBottom.dy + 2),
      TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF800000),
      ),
    );

    if (d1d3Conducting) {
      final pathPos = [
        const Offset(xSource, ySrcA),
        Offset(nodeLeft.dx, ySrcA),
        nodeLeft,
        nodeTop,
        Offset(xRl, nodeTop.dy),
        Offset(xRl, nodeBottom.dy),
        nodeBottom,
        nodeRight,
        Offset(nodeRight.dx, ySrcB),
        const Offset(xSource, ySrcB),
      ];
      _drawAnimatedCurrentFlow(canvas, pathPos, animationProgress,
          isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB));
    } else if (d2d4Conducting) {
      final pathNeg = [
        const Offset(xSource, ySrcB),
        Offset(nodeRight.dx, ySrcB),
        nodeRight,
        nodeTop,
        Offset(xRl, nodeTop.dy),
        Offset(xRl, nodeBottom.dy),
        nodeBottom,
        nodeLeft,
        Offset(nodeLeft.dx, ySrcA),
        const Offset(xSource, ySrcA),
      ];
      _drawAnimatedCurrentFlow(
          canvas, pathNeg, animationProgress, const Color(0xFFEF4444));
    }
  }

  void _drawDiodeArm(
    Canvas canvas,
    Offset from,
    Offset to,
    String name,
    bool isConducting,
    bool isDark,
    Color wireColor,
  ) {
    final wirePaint = Paint()
      ..color = wireColor
      ..strokeWidth = 2.0;
    canvas.drawLine(from, to, wirePaint);

    final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);

    _drawRotatedDiode(canvas, mid, angle, name, isConducting, isDark);
  }

  @override
  bool shouldRepaint(covariant BridgeCircuitPainter oldDelegate) => true;
}

// ===========================================================================
// SCHEMATIC DRAWING UTILITIES & PRIMITIVES
// ===========================================================================
void _drawAnimatedCurrentFlow(
  Canvas canvas,
  List<Offset> polyline,
  double progress,
  Color color,
) {
  if (polyline.length < 2) return;

  double totalLen = 0.0;
  final List<double> segmentLens = [];
  for (int i = 0; i < polyline.length - 1; i++) {
    final len = (polyline[i + 1] - polyline[i]).distance;
    segmentLens.add(len);
    totalLen += len;
  }

  const double dotSpacing = 24.0;
  final double offset = (progress * dotSpacing) % dotSpacing;

  final particlePaint = Paint()..color = color;
  final particleGlow = Paint()
    ..color = color.withValues(alpha: 0.3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0;

  for (double d = offset; d < totalLen; d += dotSpacing) {
    double accumulated = 0.0;
    for (int i = 0; i < segmentLens.length; i++) {
      if (accumulated + segmentLens[i] >= d) {
        final segProgress = (d - accumulated) / segmentLens[i];
        final p = Offset.lerp(polyline[i], polyline[i + 1], segProgress)!;
        canvas.drawCircle(p, 3.5, particlePaint);
        canvas.drawCircle(p, 5.5, particleGlow);
        break;
      }
      accumulated += segmentLens[i];
    }
  }
}

void _drawTransformerPrimary(
    Canvas canvas, double x, double yTop, double yBottom, Color wireColor) {
  final p = Paint()
    ..color = wireColor
    ..strokeWidth = 2.2
    ..style = PaintingStyle.stroke;

  canvas.drawLine(Offset(x - 20, yTop), Offset(x, yTop), p);
  canvas.drawLine(Offset(x - 20, yBottom), Offset(x, yBottom), p);

  const int loops = 5;
  final step = (yBottom - yTop) / loops;
  for (int i = 0; i < loops; i++) {
    final rect = Rect.fromLTWH(x - 12, yTop + i * step, 24, step);
    canvas.drawArc(rect, -math.pi / 2, math.pi, false, p);
  }
}

void _drawTransformerSecondary(
  Canvas canvas,
  double x,
  double yTop,
  double yCenter,
  double yBottom,
  Color wireColor,
) {
  final p = Paint()
    ..color = wireColor
    ..strokeWidth = 2.2
    ..style = PaintingStyle.stroke;

  canvas.drawLine(Offset(x, yTop), Offset(x + 20, yTop), p);
  canvas.drawLine(Offset(x, yBottom), Offset(x + 20, yBottom), p);
  canvas.drawLine(Offset(x, yCenter), Offset(x + 20, yCenter), p);

  const int loops = 6;
  final step = (yBottom - yTop) / loops;
  for (int i = 0; i < loops; i++) {
    final rect = Rect.fromLTWH(x - 12, yTop + i * step, 24, step);
    canvas.drawArc(rect, math.pi / 2, math.pi, false, p);
  }
}

void _drawIronCore(
    Canvas canvas, double x, double yStart, double yEnd, bool isDark) {
  final p = Paint()
    ..color = isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)
    ..strokeWidth = 1.6;
  canvas.drawLine(Offset(x - 2, yStart), Offset(x - 2, yEnd), p);
  canvas.drawLine(Offset(x + 2, yStart), Offset(x + 2, yEnd), p);
}

void _drawACGenerator(Canvas canvas, Offset center, bool isDark) {
  final circlePaint = Paint()
    ..color = isDark ? Colors.white70 : const Color(0xFF0F172A)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;
  canvas.drawCircle(center, 18, circlePaint);

  final sinePath = Path();
  sinePath.moveTo(center.dx - 10, center.dy);
  sinePath.quadraticBezierTo(
      center.dx - 5, center.dy - 9, center.dx, center.dy);
  sinePath.quadraticBezierTo(
      center.dx + 5, center.dy + 9, center.dx + 10, center.dy);
  canvas.drawPath(sinePath, circlePaint);
}

void _drawDiode({
  required Canvas canvas,
  required Offset center,
  required String name,
  required bool isConducting,
  required bool isDark,
  bool pointsRight = true,
}) {
  final double dir = pointsRight ? 1 : -1;
  final trianglePaint = Paint()
    ..color = isConducting
        ? (isDark ? const Color(0xFF10B981) : const Color(0xFF16A34A))
        : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8))
    ..style = isConducting ? PaintingStyle.fill : PaintingStyle.stroke
    ..strokeWidth = 2.0;

  final barPaint = Paint()
    ..color = isConducting
        ? (isDark ? const Color(0xFF10B981) : const Color(0xFF16A34A))
        : (isDark ? const Color(0xFF64748B) : const Color(0xFF64748B))
    ..strokeWidth = 2.4;

  const double s = 11.0;
  final triPath = Path()
    ..moveTo(center.dx - dir * s, center.dy - s)
    ..lineTo(center.dx - dir * s, center.dy + s)
    ..lineTo(center.dx + dir * s, center.dy)
    ..close();

  canvas.drawPath(triPath, trianglePaint);
  canvas.drawLine(
    Offset(center.dx + dir * s, center.dy - s),
    Offset(center.dx + dir * s, center.dy + s),
    barPaint,
  );

  _drawText(
    canvas,
    name,
    Offset(center.dx - 8, center.dy - 28),
    TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: isConducting
          ? (isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A))
          : (isDark ? Colors.white70 : const Color(0xFF475569)),
    ),
  );
}

void _drawRotatedDiode(
  Canvas canvas,
  Offset center,
  double angle,
  String name,
  bool isConducting,
  bool isDark,
) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(angle);

  final trianglePaint = Paint()
    ..color = isConducting
        ? (isDark ? const Color(0xFF10B981) : const Color(0xFF16A34A))
        : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8))
    ..style = isConducting ? PaintingStyle.fill : PaintingStyle.stroke
    ..strokeWidth = 2.0;

  final barPaint = Paint()
    ..color = isConducting
        ? (isDark ? const Color(0xFF10B981) : const Color(0xFF16A34A))
        : (isDark ? const Color(0xFF64748B) : const Color(0xFF64748B))
    ..strokeWidth = 2.4;

  const double s = 10.0;
  final triPath = Path()
    ..moveTo(-s, -s)
    ..lineTo(-s, s)
    ..lineTo(s, 0)
    ..close();

  canvas.drawPath(triPath, trianglePaint);
  canvas.drawLine(const Offset(s, -s), const Offset(s, s), barPaint);
  canvas.restore();

  _drawText(
    canvas,
    name,
    Offset(center.dx + 12, center.dy - 12),
    TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: isConducting
          ? (isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A))
          : (isDark ? Colors.white70 : const Color(0xFF475569)),
    ),
  );
}

void _drawResistor(
    Canvas canvas, Offset start, Offset end, String label, bool isDark) {
  final isHorizontal = (start.dy - end.dy).abs() < (start.dx - end.dx).abs();
  final wirePaint = Paint()
    ..color = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;

  final textColor = isDark ? Colors.white70 : const Color(0xFF0F172A);

  final path = Path();
  path.moveTo(start.dx, start.dy);

  if (isHorizontal) {
    final double midY = start.dy;
    final double left = math.min(start.dx, end.dx) + 15;
    final double right = math.max(start.dx, end.dx) - 15;
    final double span = right - left;
    const int teeth = 6;
    final step = span / teeth;

    path.lineTo(left, midY);
    for (int i = 0; i < teeth; i++) {
      final double yOffset = (i % 2 == 0) ? -8 : 8;
      path.lineTo(left + (i + 0.5) * step, midY + yOffset);
    }
    path.lineTo(right, midY);
    path.lineTo(end.dx, end.dy);
    canvas.drawPath(path, wirePaint);

    _drawText(
      canvas,
      label,
      Offset((start.dx + end.dx) / 2 - 8, midY - 26),
      TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  } else {
    final double midX = start.dx;
    final double top = math.min(start.dy, end.dy) + 15;
    final double bottom = math.max(start.dy, end.dy) - 15;
    final double span = bottom - top;
    const int teeth = 6;
    final step = span / teeth;

    path.lineTo(midX, top);
    for (int i = 0; i < teeth; i++) {
      final double xOffset = (i % 2 == 0) ? -8 : 8;
      path.lineTo(midX + xOffset, top + (i + 0.5) * step);
    }
    path.lineTo(midX, bottom);
    path.lineTo(end.dx, end.dy);
    canvas.drawPath(path, wirePaint);

    _drawText(
      canvas,
      label,
      Offset(midX + 14, (start.dy + end.dy) / 2 - 6),
      TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }
}

void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, offset);
}