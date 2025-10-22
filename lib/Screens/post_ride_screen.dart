// lib/screens/post_ride_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rideshare_app/models/ride_model.dart'; // CORRECTED

enum RideType { available, need }

class PostRideScreen extends StatefulWidget {
  final Ride? rideToEdit;
  final String currentUserName;
  const PostRideScreen({super.key, this.rideToEdit, required this.currentUserName});

  @override
  State<PostRideScreen> createState() => _PostRideScreenState();
}

// --- ALL YOUR ORIGINAL CODE REMAINS UNCHANGED FROM HERE ---
// (The rest of your provided code for PostRideScreen goes here)
class _PostRideScreenState extends State<PostRideScreen> {
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();
  final _moreInfoController = TextEditingController();
  final _nameController = TextEditingController();
  final _seatsController = TextEditingController();
  RideType? _rideType = RideType.available;
  
  static const String _baseUrl = 'https://69slj1azc3.execute-api.us-east-1.amazonaws.com/dev';
  bool get isEditMode => widget.rideToEdit != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      final ride = widget.rideToEdit!;
      _pickupController.text = ride.startLocation;
      _destinationController.text = ride.endLocation;
      _nameController.text = ride.userId;
      _dateController.text = ride.rideDate ?? '';
      _timeController.text = ride.rideTime ?? '';
      _seatsController.text = ride.seatsAvailable ?? '';
      _moreInfoController.text = ride.moreInfo ?? '';
      _rideType = ride.rideType == 'AVAILABLE' ? RideType.available : RideType.need;
    } else {
      _nameController.text = widget.currentUserName;
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _pickupController.dispose();
    _destinationController.dispose();
    _moreInfoController.dispose();
    _nameController.dispose();
    _seatsController.dispose();
    super.dispose();
  }

  void _submitRide() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) { return; }
    setState(() { _isSubmitting = true; });
    try {
      if (isEditMode) { await _updateRide(); } else { await _createRide(); }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ride ${isEditMode ? 'updated' : 'posted'} successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) { 
        String errorMessage = 'Error: $e';
        if (e.toString().contains('Failed host lookup') || e.toString().contains('No address associated with hostname')) {
          errorMessage = 'Unable to connect to server. Please check your internet connection and try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        ); 
      }
    } finally {
      if (mounted) { setState(() { _isSubmitting = false; }); }
    }
  }

  Future<void> _createRide() async {
    final rideTypeString = _rideType == RideType.available ? 'AVAILABLE' : 'NEEDED';
    final queryParams = {
      'userName': _nameController.text,
      'startLocation': _pickupController.text,
      'endLocation': _destinationController.text,
      'rideType': rideTypeString,
      'rideDate': _dateController.text,
      'rideTime': _timeController.text,
      'seatsAvailable': _seatsController.text,
      'moreInfo': _moreInfoController.text,
    };
    final uri = Uri.parse('$_baseUrl/rides').replace(queryParameters: queryParams);
    final response = await http.post(uri, headers: {'Content-Type': 'application/json; charset=UTF-8'});
    if (response.statusCode != 201) {
      throw Exception('Failed to post ride. Server responded with: ${response.body}');
    }
  }

  Future<void> _updateRide() async {
    final ride = widget.rideToEdit!;
    final rideTypeString = _rideType == RideType.available ? 'AVAILABLE' : 'NEEDED';
    final body = json.encode({
      'startLocation': _pickupController.text,
      'endLocation': _destinationController.text,
      'rideType': rideTypeString,
      'rideDate': _dateController.text,
      'rideTime': _timeController.text,
      'seatsAvailable': _seatsController.text,
      'moreInfo': _moreInfoController.text,
    });
    final uri = Uri.parse('$_baseUrl/rides/${ride.rideId}').replace(queryParameters: {'userId': ride.userId});
    final response = await http.put(uri, headers: {'Content-Type': 'application/json; charset=UTF-8'}, body: body);
    if (response.statusCode != 200) {
      throw Exception('Failed to update ride. Server responded with: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: _buildHeader(context, isEditMode ? 'Edit Ride' : 'Post Ride'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateField(context),
              const SizedBox(height: 16),
              _buildTimeField(context),
              const SizedBox(height: 16),
              _buildTextFieldWithValidation(
                controller: _pickupController,
                hint: 'Pickup Location',
                icon: Icons.location_on,
              ),
              const SizedBox(height: 16),
              _buildTextFieldWithValidation(
                controller: _destinationController,
                hint: 'Destination',
                icon: Icons.flag,
              ),
              const SizedBox(height: 16),
              _buildTextFieldWithValidation(
                controller: _nameController,
                hint: 'Your Name',
                icon: Icons.person,
                enabled: !isEditMode,
              ),
              const SizedBox(height: 16),
              _buildTextFieldWithValidation(
                controller: _seatsController,
                hint: 'Seats Available',
                icon: Icons.event_seat,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              _buildRideTypeSelector(),
              const SizedBox(height: 32),
              const Text(
                'More Info',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildMultilineTextField(controller: _moreInfoController),
              const SizedBox(height: 40),
              _buildPostRideButton(
                onPressed: _submitRide,
                text: isEditMode ? 'Update Ride' : 'Post Ride',
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.only(top: 40, bottom: 10, left: 16, right: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.6),
            Colors.orange.withOpacity(0.2),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 20),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(BuildContext context) {
    return TextFormField(
      controller: _dateController,
      readOnly: true,
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2101),
        );
        if (pickedDate != null && mounted) {
          setState(() {
            _dateController.text = "${pickedDate.month}/${pickedDate.day}/${pickedDate.year}";
          });
        }
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'Date',
        suffixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.grey),
        ),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Please select a date' : null,
    );
  }

  Widget _buildTimeField(BuildContext context) {
    return TextFormField(
      controller: _timeController,
      readOnly: true,
      onTap: () async {
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (pickedTime != null && mounted) {
          setState(() {
            _timeController.text = pickedTime.format(context);
          });
        }
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'Time',
        suffixIcon: const Icon(Icons.access_time),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.grey),
        ),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Please select a time' : null,
    );
  }

  Widget _buildTextFieldWithValidation({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.grey),
        ),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Please enter a $hint' : null,
    );
  }

  Widget _buildRideTypeSelector() {
    return Row(
      children: [
        Radio<RideType>(
          value: RideType.available,
          groupValue: _rideType,
          onChanged: (v) => setState(() => _rideType = v),
        ),
        const Text('Available'),
        const SizedBox(width: 24),
        Radio<RideType>(
          value: RideType.need,
          groupValue: _rideType,
          onChanged: (v) => setState(() => _rideType = v),
        ),
        const Text('Need'),
      ],
    );
  }

  Widget _buildMultilineTextField({required TextEditingController controller}) {
    return TextFormField(
      controller: controller,
      maxLines: 5,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildPostRideButton({required VoidCallback onPressed, required String text}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                text,
                style: const TextStyle(fontSize: 16),
              ),
      ),
    );
  }
} 