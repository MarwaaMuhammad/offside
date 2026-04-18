import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:offside/navbar.dart';

class PlayerInfoPage extends StatefulWidget {
  final String userName;
  const PlayerInfoPage({super.key, required this.userName});

  @override
  State<PlayerInfoPage> createState() => _PlayerInfoPageState();
}

class _PlayerInfoPageState extends State<PlayerInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nationalityController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  DateTime? selectedDob;
  String selectedPosition = "Forward";

  final List<String> positions = ["Goalkeeper", "Defender", "Midfielder", "Forward"];

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => selectedDob = picked);
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (selectedDob == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select your Date of Birth")),
        );
        return;
      }
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => OffsideShell(userRole: "player", userName: widget.userName)),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Colors.blue[900]!;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      appBar: AppBar(
        title: const Text("Player Details"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Complete your player profile",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primary),
              ),
              const SizedBox(height: 30),

              // Date of Birth Field
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: primary),
                      const SizedBox(width: 10),
                      Text(
                        selectedDob == null 
                          ? "Select Date of Birth" 
                          : DateFormat('yyyy-MM-dd').format(selectedDob!),
                        style: TextStyle(color: selectedDob == null ? Colors.grey[600] : Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              _buildTextField(
                controller: nationalityController,
                label: "Nationality",
                icon: Icons.flag,
                validator: (val) => val!.isEmpty ? "Enter nationality" : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: heightController,
                      label: "Height (cm)",
                      icon: Icons.height,
                      keyboardType: TextInputType.number,
                      validator: (val) => val!.isEmpty ? "Enter height" : null,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildTextField(
                      controller: weightController,
                      label: "Weight (kg)",
                      icon: Icons.monitor_weight,
                      keyboardType: TextInputType.number,
                      validator: (val) => val!.isEmpty ? "Enter weight" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedPosition,
                decoration: InputDecoration(
                  labelText: "Playing Position",
                  prefixIcon: Icon(Icons.sports_soccer, color: primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
                items: positions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (val) => setState(() => selectedPosition = val!),
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text(
                    "Finish Sign Up",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[900]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}
