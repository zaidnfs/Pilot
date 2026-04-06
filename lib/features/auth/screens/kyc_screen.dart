import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/aadhaar_parser.dart';
import '../../../services/aadhaar_kyc_service.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  Uint8List? _xmlBytes;
  String? _fileName;
  final _shareCodeController = TextEditingController();
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
      // Optionally mock Aadhaar parsing here if needed
      final mockData = AadhaarParser.parseQr('xml_data');
      if (mockData != null) {
        print('Aadhaar data parsed locally (mock)');
      }
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
      final result = await AadhaarKycService.processKyc(
        xmlBytes: _xmlBytes!,
        shareCode: shareCode,
      );

      await AadhaarKycService.completeVerification(result: result);

      setState(() {
        _successMessage = 'KYC verified as ${result.maskedName}';
      });

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) context.goNamed('home');
    } on KycException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Verification failed. Please try again.');
    } finally {
      _xmlBytes = null;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Identity Verification'),
        backgroundColor: AppColors.backgroundLight,
        actions: [
          TextButton(
            onPressed: () => context.goNamed('home'),
            child: const Text('Skip',
                style: TextStyle(color: AppColors.primaryLight)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Bank-like Header ──────────────────────────────
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: const Icon(Icons.verified_user_rounded,
                      size: 40, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Secure Verification',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryLight,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Your data is encrypted and handled securely.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondaryLight),
                ),
              ),
              const SizedBox(height: 32),

              // ─── Step 1: Upload XML ────────────────────────────
              Text(
                'Step 1: Upload Offline Aadhaar',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryLight,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select the downloaded XML file',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: _pickXmlFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    border: Border.all(
                      color: _fileName != null
                          ? AppColors.success
                          : AppColors.borderLight,
                      width: _fileName != null ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _fileName != null
                            ? Icons.check_circle_rounded
                            : Icons.cloud_upload_rounded,
                        size: 48,
                        color: _fileName != null
                            ? AppColors.success
                            : AppColors.primaryLight,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _fileName ?? 'Tap to select file',
                        style: TextStyle(
                          color: _fileName != null
                              ? AppColors.success
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ─── Step 2: Share Code ────────────────────────────
              Text(
                'Step 2: Enter Passcode',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryLight,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 4-digit code to unlock your file',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: TextField(
                  controller: _shareCodeController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 16,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: '••••',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
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
                    borderRadius: BorderRadius.circular(12),
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

              const SizedBox(height: 48),

              // ─── Verify Button ────────────────────────────────
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processKyc,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text(
                          'Securely Verify Identity',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
