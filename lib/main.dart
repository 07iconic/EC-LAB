import 'package:flutter/material.dart';

void main() {
  runApp(const RectifierLabApp());
}

class RectifierLabApp extends StatelessWidget {
  const RectifierLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EC2700 - Full Wave Rectification Lab',
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: const LabHomePage(),
    );
  }
}

class LabHomePage extends StatefulWidget {
  const LabHomePage({super.key});

  @override
  State<LabHomePage> createState() => _LabHomePageState();
}

class _LabHomePageState extends State<LabHomePage> {
  final ScrollController _scrollController = ScrollController();
  static const Color brandColor = Color(0xFF800000);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToContent() {
    _scrollController.animateTo(
      MediaQuery.of(context).size.height,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // ================= 1. COVER / TITLE SCREEN =================
            Container(
              height: screenHeight,
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
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
                  const Text(
                    'Topic : Full Wave Rectification',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // NIT Rourkela Official Emblem
                  Image.asset(
                    'assets/nitr_logo.png',
                    height: 130,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.school, size: 90, color: brandColor),
                  ),
                  const SizedBox(height: 25),

                  const Text(
                    'Submitted By :',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: brandColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Dwarika Singh Ghimire (125cs0158)',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Manish Kumar Sah (125cs0159)',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Nischal Chand (125cs0179)',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),

                  const Text(
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
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // ================= 2. LAB CONTENT SECTION =================
            Container(
              constraints: const BoxConstraints(maxWidth: 820),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Learning Objectives Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9E6),
                      border: const Border(
                        left: BorderSide(color: Colors.amber, width: 4),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Learning Objectives (Class 12 Level):',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                            '• Understand what rectification is and why diodes make it possible.'),
                        Text(
                            '• Trace the current path in Center-Tapped Full Wave Rectification.'),
                        Text(
                            '• Trace the conduction cycle of the Bridge Rectifier.'),
                        Text(
                            '• Master formulas for DC voltage, frequency, efficiency, and PIV.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 35),

                  // ---------------- TOPIC 1 ----------------
                  _sectionHeading('1. What is Rectification?'),
                  const Text(
                    'Rectification is the process of converting bidirectional Alternating Current (AC) into unidirectional Direct Current (DC).',
                    style: TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '• Mains electricity comes as an alternating sine wave because it is easy to transmit over long distances using transformers.\n'
                    '• Electronic gadgets (mobile phones, TVs, laptops) require constant one-direction DC.\n'
                    '• The P-N junction diode acts as an electronic one-way check valve: it conducts when forward-biased (anode at higher potential than cathode) and acts like an open switch when reverse-biased.',
                    style: TextStyle(fontSize: 15, height: 1.6),
                  ),
                  const SizedBox(height: 35),

                  // ---------------- TOPIC 2 ----------------
                  _sectionHeading('2. Center-Tapped Full Wave Rectifier'),
                  const Text(
                    'A center-tapped full wave rectifier uses a special step-down transformer with a wire connected directly to the midpoint of the secondary winding (the center tap, which acts as zero-volt ground reference) and two diodes (D₁ and D₂).',
                    style: TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 15),

                  // Center-Tapped Circuit Image
                  _buildImageCard(
                    imagePath: 'assets/centerd_rectifier.jpg.png',
                    caption:
                        'Figure 1: Center-Tapped Full Wave Rectifier Circuit and Current Paths',
                  ),
                  const SizedBox(height: 15),

                  _subHeading('Working Principle:'),
                  const Text(
                    '1. During the Positive Half Cycle: Terminal A is positive (+) with respect to the center tap, and Terminal B is negative (-). Diode D₁ is forward-biased and conducts. Diode D₂ is reverse-biased (OFF). Current flows from A → D₁ → Load Resistor (RL, right to left) → Center Tap.\n\n'
                    '2. During the Negative Half Cycle: The polarity reverses. Terminal A becomes negative (-), and Terminal B becomes positive (+). Diode D₂ becomes forward-biased and conducts, while D₁ is reverse-biased (OFF). Current flows from B → D₂ → Load Resistor (RL, right to left) → Center Tap.\n\n'
                    'Result: Current passes through the load resistor RL in the exact same direction during both halves of the input cycle!',
                    style: TextStyle(fontSize: 14.5, height: 1.55),
                  ),
                  const SizedBox(height: 15),

                  // Center-Tapped Waveform Image
                  _buildImageCard(
                    imagePath: 'assets/centered_rectifier_waveform.jpg.png',
                    caption:
                        'Figure 2: Center-Tapped Rectifier Input vs Output Waveforms',
                  ),
                  const SizedBox(height: 15),

                  _formulaBox([
                    '• DC Output Voltage:   V_dc = (2 × V_m) / π  ≈  0.636 × V_m',
                    '• RMS Output Voltage:  V_rms = V_m / √2  ≈  0.707 × V_m',
                    '• Peak Inverse Voltage (PIV):  PIV = 2 × V_m',
                    '• Ripple Frequency:    f_out = 2 × f_in  (e.g., 50 Hz AC → 100 Hz pulses)',
                    '• Maximum Efficiency (η):  81.2%',
                  ]),
                  const SizedBox(height: 35),

                  // ---------------- TOPIC 3 ----------------
                  _sectionHeading('3. Bridge Full Wave Rectifier'),
                  const Text(
                    'The Bridge Rectifier uses four diodes (D₁, D₂, D₃, and D₄) connected in a diamond-like bridge network. It does not require a bulky center-tapped transformer; a standard two-wire secondary transformer is used.',
                    style: TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 15),

                  // Bridge Overview Image
                  _buildImageCard(
                    imagePath: 'assets/bridge_rectifier.jpg.png',
                    caption: 'Figure 3: Full Wave Bridge Rectifier Circuit',
                  ),
                  const SizedBox(height: 20),

                  _subHeading('Working Step-by-Step:'),
                  const Text(
                    'A. During the Positive Half Cycle:\n'
                    '• Terminal A is positive (+), and Terminal B is negative (-).\n'
                    '• Diodes D₁ and D₃ are forward-biased (turn ON).\n'
                    '• Diodes D₂ and D₄ are reverse-biased (turn OFF).\n'
                    '• Conduction path: Terminal A → Diode D₁ → Node D → Load Resistor RL → Node C → Diode D₃ → Terminal B.',
                    style: TextStyle(fontSize: 14.5, height: 1.55),
                  ),
                  const SizedBox(height: 12),

                  // Positive Half Cycle Conduction Image
                  _buildImageCard(
                    imagePath: 'assets/bridge_positivehalfcycle.jpg.png',
                    caption:
                        'Figure 4: Current Path During Positive Half Cycle (D₁ & D₃ ON)',
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'B. During the Negative Half Cycle:\n'
                    '• Terminal B is positive (+), and Terminal A is negative (-).\n'
                    '• Diodes D₂ and D₄ are forward-biased (turn ON).\n'
                    '• Diodes D₁ and D₃ are reverse-biased (turn OFF).\n'
                    '• Conduction path: Terminal B → Diode D₄ → Node D → Load Resistor RL → Node C → Diode D₂ → Terminal A.',
                    style: TextStyle(fontSize: 14.5, height: 1.55),
                  ),
                  const SizedBox(height: 12),

                  // Negative Half Cycle Conduction Image
                  _buildImageCard(
                    imagePath: 'assets/negative_halfcycle_bridge.png',
                    caption:
                        'Figure 5: Current Path During Negative Half Cycle (D₂ & D₄ ON)',
                  ),
                  const SizedBox(height: 15),

                  // Bridge Waveform Image
                  _buildImageCard(
                    imagePath: 'assets/Brideg_waveform.jpg.png',
                    caption:
                        'Figure 6: Bridge Rectifier Waveforms showing D₁, D₃ and D₂, D₄ conduction pulses',
                  ),
                  const SizedBox(height: 15),

                  _formulaBox([
                    '• DC Output Voltage:   V_dc = (2 × V_m) / π  ≈  0.636 × V_m',
                    '  (Considering diode drop: V_dc = 2(V_m - 2V_d) / π, where V_d ≈ 0.7V)',
                    '• Peak Inverse Voltage (PIV):  PIV = V_m  (Half of center-tapped!)',
                    '• Ripple Frequency:    f_out = 2 × f_in',
                    '• Maximum Efficiency (η):  81.2%',
                  ]),
                  const SizedBox(height: 35),

                  // ---------------- TOPIC 4: COMPARISON ----------------
                  _sectionHeading('4. Center-Tapped vs Bridge Rectifier'),
                  const Text(
                    'Here is the complete point-by-point comparison of both full wave rectifiers:',
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 14),

                  _buildComparisonTable(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper: Section Heading
  Widget _sectionHeading(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A365D),
        ),
      ),
    );
  }

  // Helper: Sub Heading
  Widget _subHeading(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
        ),
      ),
    );
  }

  // Helper: Image Card with Caption & fallback
  Widget _buildImageCard({required String imagePath, required String caption}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Image.asset(
            imagePath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 120,
              color: const Color(0xFFF1F5F9),
              alignment: Alignment.center,
              child: Text(
                'Missing Image: $imagePath\nCheck asset path in pubspec.yaml',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Formula Box
  Widget _formulaBox(List<String> lines) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(6),
        border: const Border(
          left: BorderSide(color: Color(0xFF22C55E), width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map(
              (line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  line,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: Color(0xFF14532D),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // Helper: Comparison Table
  Widget _buildComparisonTable() {
    const tableData = [
      ['Feature', 'Center-Tapped', 'Bridge'],
      ['Number of diodes', '2', '4'],
      [
        'Transformer',
        'Center-tapped required',
        'Normal transformer can be used'
      ],
      ['Diodes conducting at a time', '1', '2'],
      ['PIV per diode', '2Vm', 'Vm'],
      ['Efficiency', '≈ 81.2%', '≈ 81.2%'],
      ['Ripple frequency', '2f', '2f'],
      [
        'Main advantage',
        'Only one diode drop',
        'No center-tapped transformer needed'
      ],
    ];

    return Table(
      border: TableBorder.all(color: const Color(0xFFCBD5E1)),
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
                ? const Color(0xFF800000)
                : (index.isOdd ? Colors.white : const Color(0xFFF8FAFC)),
          ),
          children: row.map((cellText) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Text(
                cellText,
                style: TextStyle(
                  fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                  color: isHeader ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
