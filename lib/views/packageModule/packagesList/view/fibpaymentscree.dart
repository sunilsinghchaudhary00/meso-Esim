// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer';
// import 'package:esimtel/views/packageModule/packagesList/model/ordernowModel.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:sizer/sizer.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../../../../utills/global.dart' as global;
// import '../../../../utills/paymentUtils/fibpaymentservice.dart';

// class FIBPaymentScreen extends StatefulWidget {
//   final GatewayResponse? paymentResponse;
//   final String esimOrderId;
//   final String paymentOrderid;
//   final String amount;
//   final bool isTopUp;
//   final String? iccid;

//   const FIBPaymentScreen({
//     Key? key,
//     required this.paymentResponse,
//     required this.esimOrderId,
//     required this.paymentOrderid,
//     required this.amount,
//     this.isTopUp = false,
//     this.iccid,
//   }) : super(key: key);

//   @override
//   State<FIBPaymentScreen> createState() => _FIBPaymentScreenState();
// }

// class _FIBPaymentScreenState extends State<FIBPaymentScreen> {
//   bool _isProcessing = false;
//   bool _paymentVerified = false;
//   final fibPaymentService = FIBPaymentService();

//   @override
//   void initState() {
//     super.initState();
//   }



//   Future<void> _checkPaymentStatus({bool showLoading = true}) async {
//     if (showLoading) {
//       setState(() {
//         _isProcessing = true;
//       });
//     }
//     try {
//       final paymentId = widget.paymentOrderid;
//       log('paymentId is $paymentId');
//       final verificationResult = await fibPaymentService.checkPaymentStatus(
//         paymentId,
//       );
//       log('payment status is $verificationResult');
//       if (verificationResult['status'] == 'success') {
//         setState(() {
//           _paymentVerified = true;
//           _isProcessing = false;
//         });
//         global.showToastMessage(message: 'Payment verified successfully!');
//         Navigator.of(context).pop();
//       } else {
//         if (showLoading) {
//           _showErrorDialog(
//             'Payment not verified yet. Please try again in a moment.',
//           );
//         }
//         setState(() {
//           _isProcessing = false;
//         });
//       }
//     } catch (e) {
//       if (showLoading) _showErrorDialog('Error verifying payment: $e');
//       setState(() {
//         _isProcessing = false;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('FIB Payment'),
//         backgroundColor: Colors.blue[800],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             _buildPaymentInfo(),
//             const SizedBox(height: 30),
//             _buildQRCodeSection(),
//             const SizedBox(height: 30),
//             _buildPaymentCode(),
//             const SizedBox(height: 30),
//             _buildAppLinks(),
//             const SizedBox(height: 30),
//             _buildVerifyButton(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPaymentInfo() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.blue[50],
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.blue[100]!),
//       ),
//       child: Column(
//         children: [
//           Icon(Icons.info_outline_rounded, color: Colors.blue[700], size: 32),
//           const SizedBox(height: 12),
//           Text(
//             'Payment Instructions',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//               color: Colors.blue[800],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             '1. Scan the QR code with FIB app\n'
//             '2. Or use the payment code in FIB app\n'
//             '3. Complete payment in FIB app\n'
//             '4. Return here and verify payment',
//             style: TextStyle(color: Colors.blue[700]),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQRCodeSection() {
//     final qrCodeData = widget.paymentResponse?.qrCode;
//     return Column(
//       children: [
//         Text(
//           'Scan QR Code',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//         ),
//         const SizedBox(height: 16),
//         if (qrCodeData != null && qrCodeData.isNotEmpty)
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: Colors.grey[300]!),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.grey.withOpacity(0.1),
//                   blurRadius: 10,
//                   offset: const Offset(0, 5),
//                 ),
//               ],
//             ),
//             child: _buildBase64Image(qrCodeData),
//           )
//         else
//           SizedBox(
//             height: 200,
//             width: 200,
//             child: Center(child: Text('QR Code not available')),
//           ),
//       ],
//     );
//   }

//   Widget _buildBase64Image(String base64String) {
//     try {
//       // remove prefix if present
//       final cleaned = base64String.split(',').last;
//       final bytes = base64Decode(cleaned);
//       return Image.memory(bytes, height: 200, width: 200, fit: BoxFit.contain);
//     } catch (e) {
//       return SizedBox(
//         height: 200,
//         width: 200,
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error, color: Colors.red, size: 40),
//             const SizedBox(height: 8),
//             Text('Invalid QR code data'),
//           ],
//         ),
//       );
//     }
//   }

//  Widget _buildPaymentCode() {
//   final paymentCode = widget.paymentResponse?.readableCode;
  
//   return Column(
  
//     children: [
//       // Header with icon
//       Row(
//         mainAxisAlignment: MainAxisAlignment.start,
//         children: [
//           Icon(Icons.payment, color: Colors.blue[700], size: 20),
//           const SizedBox(width: 8),
//           Text(
//             'Payment Code',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.w700,
//               color: Colors.grey[800],
//             ),
//           ),
//         ],
//       ),
//       const SizedBox(height: 16),
      
//       // Main code container
//       Container(
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Colors.blue[50]!,
//               Colors.green[50]!,
//             ],
//           ),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: Colors.blue[100]!, width: 1.5),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           children: [
//             // Code display row
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.confirmation_number_outlined, 
//                      color: Colors.blue[700], size: 24),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     paymentCode ?? 'N/A',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 20.sp,
//                       fontWeight: FontWeight.w800,
//                       color: Colors.blue[900],
//                       letterSpacing: 3,
//                       fontFamily: 'Monospace',
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
            
//             // Copy button
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 onPressed: paymentCode != null ? () {
//                   Clipboard.setData(ClipboardData(text: paymentCode));
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text('Payment code copied to clipboard'),
//                       backgroundColor: Colors.green[600],
//                       behavior: SnackBarBehavior.floating,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                   );
//                 } : null,
//                 icon: Icon(Icons.content_copy, size: 18),
//                 label: Text(
//                   'COPY CODE',
//                   style: TextStyle(
//                     fontWeight: FontWeight.w600,
//                     fontSize: 14,
//                   ),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue[600],
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   elevation: 0,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//       const SizedBox(height: 12),
      
//       // Helper text
//       Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         decoration: BoxDecoration(
//           color: Colors.orange[50],
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: Colors.orange[100]!),
//         ),
//         child: Row(
//           children: [
//             Icon(Icons.info_outline, color: Colors.orange[700], size: 16),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Text(
//                 'Use this code in FIB app if QR code fails',
//                 style: TextStyle(
//                   color: Colors.orange[800],
//                   fontSize: 13,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     ],
//   );
// }
//   Widget _buildAppLinks() {
//     return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//     mainAxisAlignment: MainAxisAlignment.start,
//       children: [
//         Text(
//           'Open FIB App',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//         ),
//         const SizedBox(height: 16),
//         Column(
//           children: [
//             _buildAppLinkButton(
//               'Open Personal Banking',
//               widget.paymentResponse?.personalAppLink ?? '',
//               Icons.person,
//               Colors.blue,
//             ),
//             const SizedBox(height: 12),
//             _buildAppLinkButton(
//               'Open Business Banking',
//               widget.paymentResponse?.businessAppLink ?? '',
//               Icons.business,
//               Colors.green,
//             ),
//             const SizedBox(height: 12),
//             _buildAppLinkButton(
//               'Open Corporate Banking',
//               widget.paymentResponse?.corporateAppLink ?? '',
//               Icons.corporate_fare,
//               Colors.purple,
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildAppLinkButton(
//     String text,
//     String url,
//     IconData icon,
//     Color color,
//   ) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: () async {
//           if (url.isNotEmpty && await canLaunchUrl(Uri.parse(url))) {
//             await launchUrl(Uri.parse(url));
//           } else {
//             _showErrorDialog(
//               "Cannot open FIB app. Please install the FIB app from Play Store.",
//             );
//           }
//         },
//         borderRadius: BorderRadius.circular(10),
//         child: Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.05),
//             borderRadius: BorderRadius.circular(10),
//             border: Border.all(color: color.withOpacity(0.2)),
//           ),
//           child: Row(
//             children: [
//               Icon(icon, color: color, size: 20),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Text(
//                   text,
//                   style: TextStyle(
//                     fontWeight: FontWeight.w500,
//                     color: Colors.grey.shade800,
//                   ),
//                 ),
//               ),
//               Icon(
//                 Icons.arrow_forward_ios_rounded,
//                 color: Colors.grey.shade400,
//                 size: 16,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildVerifyButton() {
//     return Column(
//       children: [
//         Text(
//           'After completing payment in FIB app:',
//           style: TextStyle(fontSize: 16, color: Colors.grey[600]),
//         ),
//         const SizedBox(height: 16),
//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton(
//             onPressed: _isProcessing ? null : () => _checkPaymentStatus(),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.green,
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             child: _isProcessing
//                 ? SizedBox(
//                     height: 20,
//                     width: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       color: Colors.white,
//                     ),
//                   )
//                 : Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(Icons.verified, size: 20),
//                       const SizedBox(width: 8),
//                       Text(
//                         'Verify Payment',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//           ),
//         ),
//       ],
//     );
//   }

//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text("Payment Error"),
//           content: Text(message),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: Text("OK"),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
