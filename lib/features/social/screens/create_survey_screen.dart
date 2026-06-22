// =============================================================================
// lib/features/social/screens/create_survey_screen.dart
// -----------------------------------------------------------------------------
// PHASE 11 — SURVEY BUILDER
// =============================================================================
//
// This is the screen an author uses to compose a survey, top to bottom:
//   ABOUT      — title + optional description/caption.
//   QUESTIONS  — add/edit/remove questions of any of the 5 types. Each question
//                is a small card whose body changes with its type (option editor
//                for choice, min/max + labels for scale, nothing for short text).
//   AUDIENCE   — who may answer (everyone / followers / Nigeria only).
//   RESULTS    — who sees results, and whether responses are anonymous.
//   REWARD     — optional: pay each completer coins (escrowed on publish).
//
// HOW THE LOCAL STATE MAPS TO THE BACKEND
// ---------------------------------------
// We hold each question as a `_QuestionDraft` (mutable, with its own
// TextEditingControllers). On publish we convert the drafts into the exact JSON
// the backend expects via `_toPayload()` — that conversion is the single bridge
// between "what the form holds" and "what the API wants". Read `_toPayload()`
// alongside surveyController.createSurvey to see the two ends line up.
//
// VALIDATION
// ----------
// We validate on the CLIENT first (instant feedback) with the SAME rules the
// server enforces (title required, ≥1 question, choice needs ≥2 options, scale
// needs min<max). The server re-validates regardless — never trust the client —
// but catching it here means the user isn't bounced after a network round-trip.
//
// STYLING
// -------
// Pure VendorTheme: slate surfaces, cyan/teal accents, Poppins for section
// titles, Inter for body. Helper builders (`_sectionTitle`, `_field`, `_pill`)
// keep every input visually identical so the form reads as one coherent screen.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constraints/vendor_theme.dart';
import '../models/survey_model.dart';
import '../services/survey_api_service.dart';

class CreateSurveyScreen extends StatefulWidget {
  const CreateSurveyScreen({super.key});

  @override
  State<CreateSurveyScreen> createState() => _CreateSurveyScreenState();
}

class _CreateSurveyScreenState extends State<CreateSurveyScreen> {
  final _api = SurveyApiService();

  // ABOUT
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // QUESTIONS — start with one single-choice question so the screen is never
  // empty (an empty form is a dead end; give them something to edit).
  final List<_QuestionDraft> _questions = [
    _QuestionDraft(type: SurveyQuestionType.singleChoice),
  ];

  // SETTINGS
  String _audience = SurveyAudience.everyone;
  String _visibility = SurveyResultVisibility.afterVote;
  bool _anonymous = true;
  DateTime? _closesAt;

  // REWARD
  bool _rewardOn = false;
  final _rewardCoinsCtrl = TextEditingController(text: '5');
  final _responsesCtrl = TextEditingController(text: '50');

  bool _publishing = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _rewardCoinsCtrl.dispose();
    _responsesCtrl.dispose();
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  // ── computed: coins escrowed now = perResponse × responsesFunded ────────────
  int get _rewardCoins =>
      _rewardOn ? (int.tryParse(_rewardCoinsCtrl.text.trim()) ?? 0) : 0;
  int get _responsesFunded => int.tryParse(_responsesCtrl.text.trim()) ?? 0;
  int get _rewardBudget => _rewardOn ? _rewardCoins * _responsesFunded : 0;

  // ── add a question: pick a type first ───────────────────────────────────────
  Future<void> _addQuestion() async {
    final type = await _pickQuestionType();
    if (type == null) return;
    setState(() => _questions.add(_QuestionDraft(type: type)));
  }

  Future<SurveyQuestionType?> _pickQuestionType() {
    return showModalBottomSheet<SurveyQuestionType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: VendorTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            for (final t in SurveyQuestionType.values)
              ListTile(
                leading: Icon(_iconForType(t), color: VendorTheme.primary),
                title: Text(t.label,
                    style: GoogleFonts.inter(
                        color: VendorTheme.textPrimary,
                        fontWeight: FontWeight.w500)),
                subtitle: Text(_hintForType(t),
                    style: GoogleFonts.inter(
                        color: VendorTheme.textMuted, fontSize: 12)),
                onTap: () => Navigator.pop(context, t),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── PUBLISH ─────────────────────────────────────────────────────────────────
  Future<void> _publish() async {
    final error = _validate();
    if (error != null) {
      _snack(error, isError: true);
      return;
    }

    setState(() => _publishing = true);
    try {
      await _api.createSurvey(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        anonymous: _anonymous,
        audience: _audience,
        resultVisibility: _visibility,
        closesAt: _closesAt,
        rewardCoins: _rewardCoins,
        rewardBudget: _rewardBudget,
        text: _descCtrl.text.trim(), // host-post caption = description
        questions: _toPayload(),
      );
      if (!mounted) return;
      Navigator.pop(context, true); // tell the feed to refresh
      _snack('Survey published', isError: false);
    } on SurveyApiException catch (e) {
      // Precise server message (e.g. "Not enough coins to fund the reward budget")
      if (!mounted) return;
      _snack(e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      _snack('Could not publish. Check your connection and try again.',
          isError: true);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  /// Client-side mirror of the server's validation (instant feedback).
  String? _validate() {
    if (_titleCtrl.text.trim().isEmpty) return 'Give your survey a title.';
    if (_questions.isEmpty) return 'Add at least one question.';
    for (var i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.promptCtrl.text.trim().isEmpty) {
        return 'Question ${i + 1} needs a prompt.';
      }
      if (q.type.isChoice) {
        final labels =
        q.optionCtrls.map((c) => c.text.trim()).where((t) => t.isNotEmpty);
        if (labels.length < 2) {
          return 'Question ${i + 1} needs at least 2 options.';
        }
      }
      if (q.type == SurveyQuestionType.scale && q.scaleMin >= q.scaleMax) {
        return 'Question ${i + 1}: the scale minimum must be less than the maximum.';
      }
    }
    if (_rewardOn) {
      if (_rewardCoins <= 0) return 'Set a reward of at least 1 coin, or turn rewards off.';
      if (_responsesFunded <= 0) return 'Choose how many responses to fund.';
    }
    return null;
  }

  /// Convert the local drafts into the exact JSON the backend expects.
  List<Map<String, dynamic>> _toPayload() {
    return _questions.map((q) {
      final m = <String, dynamic>{
        'type': q.type.toApi(),
        'prompt': q.promptCtrl.text.trim(),
        'required': q.required,
      };
      if (q.type.isChoice) {
        m['options'] = q.optionCtrls
            .map((c) => c.text.trim())
            .where((t) => t.isNotEmpty)
            .toList();
      }
      if (q.type == SurveyQuestionType.scale) {
        m['scaleMin'] = q.scaleMin;
        m['scaleMax'] = q.scaleMax;
        if (q.minLabelCtrl.text.trim().isNotEmpty) {
          m['scaleMinLabel'] = q.minLabelCtrl.text.trim();
        }
        if (q.maxLabelCtrl.text.trim().isNotEmpty) {
          m['scaleMaxLabel'] = q.maxLabelCtrl.text.trim();
        }
      }
      // nps needs no config (backend fixes it to 0..10); short_text needs none.
      return m;
    }).toList();
  }

  // ── build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorTheme.background,
      appBar: AppBar(
        backgroundColor: VendorTheme.background,
        elevation: 0,
        title: Text('New survey',
            style: GoogleFonts.poppins(
                color: VendorTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        actions: [
          // Publish lives in the app bar (primary action), with an inline
          // spinner so the button never "disappears" while submitting.
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _publishing ? null : _publish,
              child: _publishing
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: VendorTheme.primary),
              )
                  : Text('Publish',
                  style: GoogleFonts.inter(
                      color: VendorTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ),
          ),
        ],
      ),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // ABOUT ----------------------------------------------------------------
          _sectionTitle('About'),
          _field(
            controller: _titleCtrl,
            hint: 'Survey title — what are you asking?',
            maxLines: 1,
          ),
          const SizedBox(height: 10),
          _field(
            controller: _descCtrl,
            hint: 'Add context (optional). This shows on the post.',
            maxLines: 3,
          ),

          // QUESTIONS ------------------------------------------------------------
          const SizedBox(height: 24),
          _sectionTitle('Questions'),
          for (var i = 0; i < _questions.length; i++)
            _QuestionEditor(
              key: ValueKey(_questions[i]),
              index: i,
              draft: _questions[i],
              canDelete: _questions.length > 1,
              iconForType: _iconForType,
              onChanged: () => setState(() {}),
              onDelete: () => setState(() {
                _questions.removeAt(i).dispose();
              }),
              onChangeType: () async {
                final t = await _pickQuestionType();
                if (t != null) setState(() => _questions[i].changeType(t));
              },
            ),
          const SizedBox(height: 4),
          _addQuestionButton(),

          // AUDIENCE -------------------------------------------------------------
          const SizedBox(height: 24),
          _sectionTitle('Who can answer'),
          _choiceRow(
            values: SurveyAudience.all,
            current: _audience,
            label: SurveyAudience.label,
            onSelect: (v) => setState(() => _audience = v),
          ),

          // RESULTS --------------------------------------------------------------
          const SizedBox(height: 24),
          _sectionTitle('Results & privacy'),
          _dropdownTile(
            label: 'Who sees results',
            value: _visibility,
            values: SurveyResultVisibility.all,
            display: SurveyResultVisibility.label,
            onChanged: (v) => setState(() => _visibility = v),
          ),
          const SizedBox(height: 10),
          _switchTile(
            title: 'Anonymous responses',
            subtitle:
            'You see totals only — never who answered. (We still prevent double-voting.)',
            value: _anonymous,
            onChanged: (v) => setState(() => _anonymous = v),
          ),
          const SizedBox(height: 10),
          _closeDateTile(),

          // REWARD ---------------------------------------------------------------
          const SizedBox(height: 24),
          _sectionTitle('Reward responders (optional)'),
          _switchTile(
            title: 'Pay coins for each response',
            subtitle:
            'Boost responses by rewarding people. Coins are held now and unused coins are refunded when you close the survey.',
            value: _rewardOn,
            onChanged: (v) => setState(() => _rewardOn = v),
          ),
          if (_rewardOn) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _field(
                    controller: _rewardCoinsCtrl,
                    hint: 'Coins / response',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    controller: _responsesCtrl,
                    hint: 'Responses to fund',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _escrowNote(),
          ],
        ],
      ),
      ),
    ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SMALL STYLED BUILDERS (one definition → every input looks identical)
  // ───────────────────────────────────────────────────────────────────────────

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(t,
        style: GoogleFonts.poppins(
            color: VendorTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700)),
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: GoogleFonts.inter(color: VendorTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
        GoogleFonts.inter(color: VendorTheme.textMuted, fontSize: 13.5),
        filled: true,
        fillColor: VendorTheme.surface,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: VendorTheme.surfaceVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: VendorTheme.surfaceVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: VendorTheme.primary),
        ),
      ),
    );
  }

  /// Horizontal pill selector (used for audience).
  Widget _choiceRow({
    required List<String> values,
    required String current,
    required String Function(String) label,
    required ValueChanged<String> onSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((v) {
        final selected = v == current;
        return GestureDetector(
          onTap: () => onSelect(v),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? VendorTheme.primary.withOpacity(0.15)
                  : VendorTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? VendorTheme.primary
                    : VendorTheme.surfaceVariant,
              ),
            ),
            child: Text(label(v),
                style: GoogleFonts.inter(
                    color: selected
                        ? VendorTheme.primary
                        : VendorTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
        );
      }).toList(),
    );
  }

  Widget _dropdownTile({
    required String label,
    required String value,
    required List<String> values,
    required String Function(String) display,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: VendorTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VendorTheme.surfaceVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: GoogleFonts.inter(
                    color: VendorTheme.textSecondary, fontSize: 13.5)),
          ),
          DropdownButton<String>(
            value: value,
            dropdownColor: VendorTheme.surface,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.keyboard_arrow_down,
                color: VendorTheme.textMuted),
            style: GoogleFonts.inter(
                color: VendorTheme.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600),
            items: values
                .map((v) =>
                DropdownMenuItem(value: v, child: Text(display(v))))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: VendorTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VendorTheme.surfaceVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        color: VendorTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.inter(
                        color: VendorTheme.textMuted,
                        fontSize: 11.5,
                        height: 1.3)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: VendorTheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _closeDateTile() {
    final has = _closesAt != null;
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: _closesAt ?? now.add(const Duration(days: 7)),
          firstDate: now,
          lastDate: now.add(const Duration(days: 365)),
        );
        if (picked != null) setState(() => _closesAt = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: VendorTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VendorTheme.surfaceVariant),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_outlined,
                color: VendorTheme.textMuted, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                has
                    ? 'Closes on ${_closesAt!.day}/${_closesAt!.month}/${_closesAt!.year}'
                    : 'Set a close date (optional)',
                style: GoogleFonts.inter(
                    color: has
                        ? VendorTheme.textPrimary
                        : VendorTheme.textMuted,
                    fontSize: 13.5),
              ),
            ),
            if (has)
              GestureDetector(
                onTap: () => setState(() => _closesAt = null),
                child: const Icon(Icons.close,
                    color: VendorTheme.textMuted, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _escrowNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VendorTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VendorTheme.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.savings_outlined,
              color: VendorTheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You\'ll hold $_rewardBudget coins now ($_rewardCoins × $_responsesFunded). '
                  'Unused coins are refunded when you close the survey.',
              style: GoogleFonts.inter(
                  color: VendorTheme.textSecondary,
                  fontSize: 12,
                  height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addQuestionButton() {
    return GestureDetector(
      onTap: _addQuestion,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: VendorTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: VendorTheme.primary.withOpacity(0.4),
            // dashed feel via a lighter ring; keeps it clearly an "add" affordance
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: VendorTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text('Add question',
                style: GoogleFonts.inter(
                    color: VendorTheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _snack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: isError ? VendorTheme.error : VendorTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // type → icon / hint (used by the picker + each question header)
  IconData _iconForType(SurveyQuestionType t) {
    switch (t) {
      case SurveyQuestionType.singleChoice:
        return Icons.radio_button_checked;
      case SurveyQuestionType.multiChoice:
        return Icons.check_box_outlined;
      case SurveyQuestionType.scale:
        return Icons.linear_scale;
      case SurveyQuestionType.shortText:
        return Icons.short_text;
      case SurveyQuestionType.nps:
        return Icons.recommend_outlined;
    }
  }

  String _hintForType(SurveyQuestionType t) {
    switch (t) {
      case SurveyQuestionType.singleChoice:
        return 'Respondents pick one option';
      case SurveyQuestionType.multiChoice:
        return 'Respondents pick one or more';
      case SurveyQuestionType.scale:
        return 'Rate on a number scale';
      case SurveyQuestionType.shortText:
        return 'A free-text answer';
      case SurveyQuestionType.nps:
        return 'How likely to recommend (0–10)';
    }
  }
}

// =============================================================================
// _QuestionDraft — the mutable local state for ONE question
// =============================================================================
//
// Holds its own controllers so each question's text persists independently. When
// the type changes we add/remove the bits that type needs (e.g. two starter
// options for a choice question). dispose() frees every controller it owns.
// =============================================================================
class _QuestionDraft {
  SurveyQuestionType type;
  final promptCtrl = TextEditingController();
  bool required;

  // choice
  List<TextEditingController> optionCtrls;

  // scale
  int scaleMin;
  int scaleMax;
  final minLabelCtrl = TextEditingController();
  final maxLabelCtrl = TextEditingController();

  _QuestionDraft({required this.type, this.required = true})
      : optionCtrls = type.isChoice
      ? [TextEditingController(), TextEditingController()]
      : [],
        scaleMin = 1,
        scaleMax = 5;

  void changeType(SurveyQuestionType t) {
    type = t;
    // Ensure a choice question always starts with 2 editable options.
    if (t.isChoice && optionCtrls.length < 2) {
      while (optionCtrls.length < 2) {
        optionCtrls.add(TextEditingController());
      }
    }
    if (!t.isChoice) {
      for (final c in optionCtrls) {
        c.dispose();
      }
      optionCtrls = [];
    }
  }

  void addOption() => optionCtrls.add(TextEditingController());
  void removeOption(int i) => optionCtrls.removeAt(i).dispose();

  void dispose() {
    promptCtrl.dispose();
    minLabelCtrl.dispose();
    maxLabelCtrl.dispose();
    for (final c in optionCtrls) {
      c.dispose();
    }
  }
}

// =============================================================================
// _QuestionEditor — the card UI for one _QuestionDraft
// =============================================================================
class _QuestionEditor extends StatelessWidget {
  final int index;
  final _QuestionDraft draft;
  final bool canDelete;
  final VoidCallback onChanged;
  final VoidCallback onDelete;
  final VoidCallback onChangeType;
  final IconData Function(SurveyQuestionType) iconForType;

  const _QuestionEditor({
    super.key,
    required this.index,
    required this.draft,
    required this.canDelete,
    required this.onChanged,
    required this.onDelete,
    required this.onChangeType,
    required this.iconForType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VendorTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VendorTheme.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header: "Q1" + type chip (tap to change) + delete
          Row(
            children: [
              Text('Q${index + 1}',
                  style: GoogleFonts.poppins(
                      color: VendorTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onChangeType,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: VendorTheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(iconForType(draft.type),
                          color: VendorTheme.primary, size: 14),
                      const SizedBox(width: 6),
                      Text(draft.type.label,
                          style: GoogleFonts.inter(
                              color: VendorTheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                      const Icon(Icons.expand_more,
                          color: VendorTheme.primary, size: 16),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (canDelete)
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.delete_outline,
                      color: VendorTheme.textMuted, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // prompt
          _bareField(draft.promptCtrl, 'Type your question…', onChanged),

          const SizedBox(height: 10),

          // type-specific body
          if (draft.type.isChoice) _optionsEditor(),
          if (draft.type == SurveyQuestionType.scale) _scaleEditor(),
          if (draft.type == SurveyQuestionType.nps)
            _hintBox('Respondents answer 0–10. We compute your NPS automatically.'),
          if (draft.type == SurveyQuestionType.shortText)
            _hintBox('Respondents type a free-text answer.'),
        ],
      ),
    );
  }

  // option list with add/remove (StatefulBuilder so add/remove rebuild locally)
  Widget _optionsEditor() {
    return StatefulBuilder(
      builder: (context, setLocal) {
        return Column(
          children: [
            for (var i = 0; i < draft.optionCtrls.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      draft.type == SurveyQuestionType.singleChoice
                          ? Icons.radio_button_off
                          : Icons.check_box_outline_blank,
                      color: VendorTheme.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _bareField(
                        draft.optionCtrls[i],
                        'Option ${i + 1}',
                        onChanged,
                      ),
                    ),
                    if (draft.optionCtrls.length > 2)
                      GestureDetector(
                        onTap: () => setLocal(() {
                          draft.removeOption(i);
                          onChanged();
                        }),
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.close,
                              color: VendorTheme.textMuted, size: 18),
                        ),
                      ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setLocal(() {
                  draft.addOption();
                  onChanged();
                }),
                icon: const Icon(Icons.add,
                    color: VendorTheme.primary, size: 18),
                label: Text('Add option',
                    style: GoogleFonts.inter(
                        color: VendorTheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _scaleEditor() {
    return StatefulBuilder(
      builder: (context, setLocal) {
        Widget stepper(String label, int value, ValueChanged<int> onSet) {
          return Row(
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      color: VendorTheme.textSecondary, fontSize: 13)),
              const SizedBox(width: 8),
              _roundIcon(Icons.remove, () => setLocal(() {
                onSet(value - 1);
                onChanged();
              })),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('$value',
                    style: GoogleFonts.poppins(
                        color: VendorTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ),
              _roundIcon(Icons.add, () => setLocal(() {
                onSet(value + 1);
                onChanged();
              })),
            ],
          );
        }

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                stepper('Min', draft.scaleMin,
                        (v) => draft.scaleMin = v.clamp(0, draft.scaleMax - 1)),
                stepper('Max', draft.scaleMax,
                        (v) => draft.scaleMax = v.clamp(draft.scaleMin + 1, 10)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _bareField(
                        draft.minLabelCtrl, 'Low label (optional)', onChanged)),
                const SizedBox(width: 10),
                Expanded(
                    child: _bareField(draft.maxLabelCtrl,
                        'High label (optional)', onChanged)),
              ],
            ),
          ],
        );
      },
    );
  }

  // a quieter input used inside question cards (no heavy border)
  Widget _bareField(
      TextEditingController c, String hint, VoidCallback onChanged) {
    return TextField(
      controller: c,
      onChanged: (_) => onChanged(),
      style: GoogleFonts.inter(color: VendorTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle:
        GoogleFonts.inter(color: VendorTheme.textMuted, fontSize: 13),
        filled: true,
        fillColor: VendorTheme.background,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: VendorTheme.surfaceVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: VendorTheme.surfaceVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: VendorTheme.primary),
        ),
      ),
    );
  }

  Widget _roundIcon(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: VendorTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: VendorTheme.textPrimary, size: 16),
    ),
  );

  Widget _hintBox(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: VendorTheme.background,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(text,
        style: GoogleFonts.inter(
            color: VendorTheme.textMuted, fontSize: 12, height: 1.3)),
  );
}