import 'package:educonnect/features/wallet/application/wallet_controller.dart';
import 'package:educonnect/features/tutor/presentation/widgets/tutor_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RequestPayoutSheet extends ConsumerStatefulWidget {
  const RequestPayoutSheet({super.key, required this.availableBalance});

  final double availableBalance;

  static Future<void> show(BuildContext context, double availableBalance) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => RequestPayoutSheet(availableBalance: availableBalance),
    );
  }

  @override
  ConsumerState<RequestPayoutSheet> createState() => _RequestPayoutSheetState();
}

class _RequestPayoutSheetState extends ConsumerState<RequestPayoutSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0;
    if (amount <= 0 || amount > widget.availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah penarikan tidak valid.')),
      );
      return;
    }

    try {
      await ref.read(walletControllerProvider).requestPayout(
            amount: amount,
            bankName: _bankNameController.text,
            accountNumber: _accountNumberController.text,
            accountHolder: _accountHolderController.text,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan penarikan dana berhasil dibuat.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengajukan penarikan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(walletLoadingProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tarik Dana (Withdraw)',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Saldo Tersedia: Rp ${widget.availableBalance.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Color(0xFF0F766E),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Jumlah Penarikan (Rp)',
                  hintText: 'Contoh: 500000',
                  filled: true,
                  fillColor: TutorUi.slate,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: TutorUi.ink, width: 2),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Wajib diisi';
                  final amount = double.tryParse(val.replaceAll('.', '')) ?? 0;
                  if (amount < 50000) return 'Minimal penarikan Rp 50.000';
                  if (amount > widget.availableBalance) return 'Saldo tidak mencukupi';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankNameController,
                decoration: InputDecoration(
                  labelText: 'Nama Bank / E-Wallet',
                  hintText: 'Contoh: BCA, Mandiri, GoPay',
                  filled: true,
                  fillColor: TutorUi.slate,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: TutorUi.ink, width: 2),
                  ),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nomor Rekening / No. HP',
                  filled: true,
                  fillColor: TutorUi.slate,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: TutorUi.ink, width: 2),
                  ),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accountHolderController,
                decoration: InputDecoration(
                  labelText: 'Nama Pemilik Rekening',
                  filled: true,
                  fillColor: TutorUi.slate,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: TutorUi.ink, width: 2),
                  ),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: TutorUi.ink,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Ajukan Penarikan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
