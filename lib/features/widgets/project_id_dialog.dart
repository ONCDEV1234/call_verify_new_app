
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProjectIdDialog extends StatefulWidget {
  const ProjectIdDialog({super.key});

  static Future<String?> show() async {
    return await Get.dialog<String>(
      const ProjectIdDialog(),
      barrierDismissible: true,
    );
  }

  @override
  State<ProjectIdDialog> createState() => _ProjectIdDialogState();
}

class _ProjectIdDialogState extends State<ProjectIdDialog> {
  static const Color _primaryRed = Color(0xFFD71920);
  static const Color _textBlack = Color(0xFF222222);
  static const Color _textGrey = Color(0xFF777777);
  static const Color _textLightGrey = Color(0xFF9E9E9E);
  static const Color _borderGrey = Color(0xFFE5E5E5);
  static const Color _softRedBg = Color(0xFFFCE9E9);

  final _formKey = GlobalKey<FormState>();
  final _textCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prefillLastCode();
  }

  Future<void> _prefillLastCode() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString('last_project_code');
    if (last != null && last.isNotEmpty && mounted) {
      setState(() => _textCtrl.text = last);
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final code = _textCtrl.text.trim();
    Get.back(result: code);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: _softRedBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.folder_rounded,
                    color: _primaryRed,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 2),
                      Text(
                        'Open Project',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _textBlack,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Enter a project code to continue',
                        style: TextStyle(
                          fontSize: 12,
                          color: _textGrey,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                InkWell(
                  onTap: () => Get.back(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F3F3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: _textGrey,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            Form(
              key: _formKey,
              child: TextFormField(
                controller: _textCtrl,
                autofocus: true,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                maxLength: 20,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _textBlack,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'e.g. DEL-SUR-Proj',
                  hintStyle: const TextStyle(
                    fontSize: 13.5,
                    color: _textLightGrey,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 8),
                    child: Icon(
                      Icons.grid_view_rounded,
                      size: 18,
                      color: _textGrey.withOpacity(0.7),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: _borderGrey,
                      width: 1.2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: _primaryRed,
                      width: 1.3,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: _primaryRed,
                      width: 1.6,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: _primaryRed,
                      width: 1.3,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: _primaryRed,
                      width: 1.6,
                    ),
                  ),
                  errorStyle: const TextStyle(fontSize: 11),
                ),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return 'Project code is required';
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
            ),

            const SizedBox(height: 22),

            Row(
              children: [
                // Cancel
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textBlack,
                        backgroundColor: Colors.white,
                        side: const BorderSide(
                          color: _borderGrey,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: _textBlack,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Fetch
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_rounded, size: 17),
                          SizedBox(width: 8),
                          Text(
                            'Fetch',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}