import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFF6F0DE);
  static const Color cardBg = Color(0xFFF2EADD);
  static const Color tagsBg = Color(0xFFEFA859);
  static const Color slotBorder = Color(0xFF697235);
  static const Color slotBg = Color(0xFFF9E0BB);
  static const Color buttonBg = Color(0xFFF4A64E);
  static const Color titleColor = Color(0xFF4D3208);
  static const Color subtitleColor = Color(0xFF6A7142);
  static const Color numberColor = Color(0xFF355244);

  static const Color tagGreenDark = Color(0xFF355244);
  static const Color tagBrown = Color(0xFF794634);
  static const Color tagGreenMid = Color(0xFF3D4318);
  static const Color tagOrange = Color(0xFFEFA859);
  static const Color tagGreenOlive = Color(0xFF697235);
  static const Color tagGreenLight = Color(0xFFC0CE67);
  static const Color tagBrownDark = Color(0xFF6F4A3E);
  static const Color tagGreenSage = Color(0xFF6A714A);
  static const Color tagReddish = Color(0xFF6A7142);
}

class ActivityTag {
  final String label;
  final Color color;
  final Color textColor;

  const ActivityTag({
    required this.label,
    required this.color,
    this.textColor = Colors.white,
  });
}

const List<ActivityTag> allTags = [
  ActivityTag(label: 'Playa', color: AppColors.tagGreenDark),
  ActivityTag(label: 'Extremo', color: AppColors.tagBrown),
  ActivityTag(label: 'Relajante', color: AppColors.tagGreenMid),
  ActivityTag(
    label: 'Aventura',
    color: AppColors.tagOrange,
    textColor: AppColors.titleColor,
  ),
  ActivityTag(label: 'Gastronomía', color: AppColors.tagGreenOlive),
  ActivityTag(
    label: 'Cultura',
    color: AppColors.tagGreenLight,
    textColor: AppColors.tagGreenDark,
  ),
  ActivityTag(label: 'Montaña', color: AppColors.tagGreenDark),
  ActivityTag(label: 'Naturaleza', color: AppColors.tagGreenSage),
  ActivityTag(label: 'Camping', color: AppColors.tagBrown),
];

class RankingScreen extends StatefulWidget {
  /// Callback que se llama al presionar "Terminé" con la lista ordenada
  final void Function(List<ActivityTag> ranked)? onFinish;

  const RankingScreen({super.key, this.onFinish});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  // Slots del ranking (máx 5)
  final List<ActivityTag?> _slots = List.filled(5, null);

  // Tags disponibles (los que aún no han sido colocados)
  late List<ActivityTag> _availableTags;

  // Tag actualmente siendo arrastrado
  ActivityTag? _draggingTag;

  // Si viene de un slot, guardamos el índice para devolverlo si se cancela
  int? _draggingFromSlot;

  @override
  void initState() {
    super.initState();
    _availableTags = List.from(allTags);
  }

  void _placeTagInSlot(int slotIndex, ActivityTag tag) {
    setState(() {
      // Si el slot ya tenía un tag, lo devolvemos a disponibles
      if (_slots[slotIndex] != null) {
        _availableTags.add(_slots[slotIndex]!);
      }
      _slots[slotIndex] = tag;
      // Quitamos de disponibles si viene de ahí
      _availableTags.remove(tag);
    });
  }

  void _removeFromSlot(int slotIndex) {
    setState(() {
      if (_slots[slotIndex] != null) {
        _availableTags.add(_slots[slotIndex]!);
        _slots[slotIndex] = null;
      }
    });
  }

  void _onFinish() {
    final ranked = _slots.whereType<ActivityTag>().toList();
    if (ranked.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos una actividad para tu ranking'),
        ),
      );
      return;
    }
    widget.onFinish?.call(ranked);

    // Si no hay callback, mostramos un diálogo de ejemplo
    if (widget.onFinish == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Tu Top ranking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: ranked
                .asMap()
                .entries
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('${e.key + 1}. ${e.value.label}'),
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Contenido scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // Slots de ranking
                    ...List.generate(5, (i) => _buildSlot(i)),

                    const SizedBox(height: 24),

                    // Panel de tags disponibles
                    _buildTagsPanel(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Botón Terminé
            _buildFinishButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          const Text(
            '¡Tu aventura ideal!',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.titleColor,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Arrastra tus etiquetas favoritas para crear tu Top 5',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.subtitleColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSlot(int index) {
    final tag = _slots[index];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Número
          SizedBox(
            width: 28,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.numberColor,
              ),
            ),
          ),

          // Slot como DragTarget
          Expanded(
            child: DragTarget<ActivityTag>(
              onWillAcceptWithDetails: (_) => true,
              onAcceptWithDetails: (details) {
                _placeTagInSlot(index, details.data);
              },
              builder: (context, candidateData, rejectedData) {
                final isHovered = candidateData.isNotEmpty;

                return GestureDetector(
                  onTap: tag != null ? () => _removeFromSlot(index) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 52,
                    decoration: BoxDecoration(
                      color: isHovered
                          ? AppColors.slotBorder.withOpacity(0.15)
                          : (tag != null
                                ? tag.color.withOpacity(0.15)
                                : AppColors.slotBg),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isHovered
                            ? AppColors.slotBorder
                            : (tag != null
                                  ? tag.color
                                  : AppColors.slotBorder.withOpacity(0.4)),
                        width: isHovered ? 2 : 1.5,
                        style: tag == null
                            ? BorderStyle.solid
                            : BorderStyle.solid,
                      ),
                    ),
                    child: tag == null
                        ? Center(
                            child: Icon(
                              Icons.add,
                              color: AppColors.slotBorder.withOpacity(0.5),
                              size: 22,
                            ),
                          )
                        : _buildDraggableTag(tag, fromSlot: index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.tagsBg.withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: _availableTags.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Todos los tags han sido colocados',
                  style: TextStyle(color: AppColors.subtitleColor),
                ),
              ),
            )
          : Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: _availableTags
                  .map((tag) => _buildDraggableTag(tag))
                  .toList(),
            ),
    );
  }

  Widget _buildDraggableTag(ActivityTag tag, {int? fromSlot}) {
    return Draggable<ActivityTag>(
      data: tag,
      onDragStarted: () {
        setState(() {
          _draggingTag = tag;
          _draggingFromSlot = fromSlot;
          // Si viene de un slot, lo liberamos temporalmente
          if (fromSlot != null) {
            _slots[fromSlot] = null;
          } else {
            _availableTags.remove(tag);
          }
        });
      },
      onDraggableCanceled: (_, __) {
        // Si se cancela, devolvemos el tag a su lugar original
        setState(() {
          if (_draggingFromSlot != null) {
            _slots[_draggingFromSlot!] = tag;
          } else {
            _availableTags.add(tag);
          }
          _draggingTag = null;
          _draggingFromSlot = null;
        });
      },
      onDragCompleted: () {
        setState(() {
          _draggingTag = null;
          _draggingFromSlot = null;
        });
      },
      feedback: Material(
        color: Colors.transparent,
        child: _tagChip(tag, opacity: 0.85),
      ),
      childWhenDragging: _tagChip(tag, opacity: 0.3),
      child: _tagChip(tag),
    );
  }

  Widget _tagChip(ActivityTag tag, {double opacity = 1.0}) {
    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: tag.color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          tag.label,
          style: TextStyle(
            color: tag.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFinishButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _onFinish,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.buttonBg,
            foregroundColor: AppColors.titleColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: const Text('Terminé'),
        ),
      ),
    );
  }
}

// ── Ejemplo de uso ───────────────────────────────────────────────────────────

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Es hora de rankear',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: RankingScreen(
        onFinish: (ranked) {
          debugPrint('Ranking del usuario:');
          for (var i = 0; i < ranked.length; i++) {
            debugPrint('  ${i + 1}. ${ranked[i].label}');
          }
        },
      ),
    );
  }
}
