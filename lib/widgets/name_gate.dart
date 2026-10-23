import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../language.dart';
import '../services/auth_service.dart';

/// Агар корбар ном надошта бошад, диалог мекушояд ва номро нигоҳ медорад.
class NameGate {
  static Future<bool> check(BuildContext context) async {
    final auth = AuthService();
    await auth.loadProfile();
    if (auth.displayName.trim().isNotEmpty) return true;
    if (!context.mounted) return false;

    final lang = Provider.of<AppLanguage>(context, listen: false);
    final ctrl = TextEditingController();
    bool saved = false;
    bool busy = false;
    String? error;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.person, color: Color(0xFF6C63FF)),
                const SizedBox(width: 8),
                Expanded(child: Text(lang.t('enter_name'))),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lang.t('name_hint'),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  maxLength: 20,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: lang.t('your_name'),
                    errorText: error,
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: busy ? null : () => Navigator.pop(ctx),
                child: Text(lang.t('cancel')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                ),
                onPressed: busy
                    ? null
                    : () async {
                        final name = ctrl.text.trim();
                        if (name.isEmpty) {
                          setLocal(() => error = lang.t('field_required'));
                          return;
                        }
                        setLocal(() {
                          busy = true;
                          error = null;
                        });
                        try {
                          await auth.saveProfile(name);
                          saved = true;
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          setLocal(() {
                            busy = false;
                            error = '${lang.t('error')}: $e';
                          });
                        }
                      },
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(lang.t('save')),
              ),
            ],
          ),
        );
      },
    );

    ctrl.dispose();
    return saved;
  }
}
