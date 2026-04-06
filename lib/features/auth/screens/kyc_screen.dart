import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/aadhaar_kyc_service.dart';

/// Aadhaar Offline e-KYC screen.
/// User uploads their encrypted Aadhaar XML + 4-digit Share Code.
class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final _shareCodeController = TextEditingController();
  Uint8List? _xmlBytes;
  String? _fileName;
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  @override
  void dispose() {
    _shareCodeController.dispose();
    super.dispose();
  }

  Future<void> _pickXmlFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xml', 'zip'],
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _xmlBytes = result.files.single.bytes!;
        _fileName = result.files.single.name;
        _error = null;
      });
    }
  }

  Future<void> _processKyc() async {
    if (_xmlBytes == null) {
      setState(() => _error = 'Please select your Aadhaar XML file');
      return;
    }

    final shareCode = _shareCodeController.text.trim();
    if (shareCode.length != 4) {
      setState(() => _error = 'Share Code must be exactly 4 digits');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Parse the XML
      final result = await AadhaarKycService.processKyc(
        xmlBytes: _xmlBytes!,
        shareCode: shareCode,
      );

      // Upload photo & update profile
      await AadhaarKycService.completeVerification(result: result);

      setState(() {
        _successMessage = 'KYC verified as ${result.maskedName}';
      });

      // Navigate to home after delay
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) context.goNamed('home');
    } on KycException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Verification failed. Please try again.');
    } finally {
      // CRITICAL: Purge XML bytes from memory regardless of success/failure.
      // Raw Aadhaar data must never persist beyond this operation.
      _xmlBytes = null;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Identity Verification'),
        actions: [
          TextButton(
            onPressed: () => context.goNamed('home'),
            child: const Text('Skip for now'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Instructions ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield_rounded,
                            color: AppColors.info, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Why verify?',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Aadhaar verification builds trust in the community. '
                      'Your verified photo is shown to Requesters during delivery. '
                      'No raw Aadhaar data is stored on our servers.',
                      style: TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ─── Step 1: Upload XML ────────────────────────────
              Text(
                'Step 1: Upload Aadhaar XML',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Download your Aadhaar XML from mAadhaar app or myaadhaar.uidai.gov.in',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: _pickXmlFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _fileName != null
                          ? AppColors.success
                          : AppColors.borderLight,
                      width: _fileName != null ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _fileName != null
                            ? Icons.check_circle_rounded
                            : Icons.upload_file_rounded,
                        size: 40,
                        color: _fileName != null
                            ? AppColors.success
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _fileName ?? 'Tap to select XML file',
                        style: TextStyle(
                          color: _fileName != null
                              ? AppColors.success
                              : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ─── Step 2: Share Code ────────────────────────────
              Text(
                'Step 2: Enter Share Code',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The 4-digit code you set when downloading the XML',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _shareCodeController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 8,
                ),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '• • • •',
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_successMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _successMessage!,
                        style: const TextStyle(
                            color: AppColors.success, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // ─── Verify Button ────────────────────────────────
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processKyc,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Verify Identity'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
