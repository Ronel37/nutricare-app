import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nutricare_app/services/database.dart';
import 'package:nutricare_app/services/dataset_service.dart';

class ManageDatasetPage extends StatefulWidget {
  const ManageDatasetPage({super.key});

  @override
  State<ManageDatasetPage> createState() => _ManageDatasetPageState();
}

class _ManageDatasetPageState extends State<ManageDatasetPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ageGroupController = TextEditingController();
  final TextEditingController _goController = TextEditingController();
  final TextEditingController _growController = TextEditingController();
  final TextEditingController _glowVegController = TextEditingController();
  final TextEditingController _glowFruitController = TextEditingController();

  String _selectedSex = 'Not specified';
  bool _isSaving = false;

  @override
  void dispose() {
    _ageGroupController.dispose();
    _goController.dispose();
    _growController.dispose();
    _glowVegController.dispose();
    _glowFruitController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final data = PinggangPinoyData(
        ageGroup: _ageGroupController.text.trim(),
        sex: _selectedSex,
        goFoods: _goController.text.trim(),
        growFoods: _growController.text.trim(),
        glowVegetables: _glowVegController.text.trim(),
        glowFruits: _glowFruitController.text.trim(),
      );

      final adminId = FirebaseAuth.instance.currentUser?.uid;

      await DatasetService.addPinggangPinoyEntry(
        data,
        createdBy: adminId,
      );

      if (adminId != null) {
        await AuthServices().logAdminChange(
          adminId: adminId,
          changeType: 'dataset',
          description: 'Added nutrition guideline for ${data.ageGroup}',
          changeData: data.toJson(),
        );
      }

      _formKey.currentState!.reset();
      _selectedSex = 'Not specified';
      _ageGroupController.clear();
      _goController.clear();
      _growController.clear();
      _glowVegController.clear();
      _glowFruitController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dataset entry added and synced to AI'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save entry: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _refreshDataset() async {
    try {
      await DatasetService.refreshDataset();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dataset reloaded for AI'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to refresh dataset: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'AI Dataset Manager',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Reload dataset for AI',
            onPressed: _refreshDataset,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Color(0xFF0A3D00), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 16),
              _buildFormCard(),
              const SizedBox(height: 16),
              _buildExistingEntries(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.dataset, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Add Pinggang Pinoy data',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Entries saved here are merged with the built-in dataset and used immediately by the AI for recommendations.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New dataset entry',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageGroupController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Age group (e.g., 6-9 years - Kids)'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedSex,
                dropdownColor: Colors.grey.shade900,
                decoration: _inputDecoration('Sex'),
                items: const [
                  DropdownMenuItem(
                      value: 'Not specified',
                      child: Text('Not specified', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(
                      value: 'Male',
                      child: Text('Male', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(
                      value: 'Female',
                      child: Text('Female', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(
                      value: 'Male & Female',
                      child:
                          Text('Male & Female', style: TextStyle(color: Colors.white))),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSex = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildMultilineField(
                controller: _goController,
                label: 'Go (Rice & Alternatives)',
              ),
              const SizedBox(height: 12),
              _buildMultilineField(
                controller: _growController,
                label: 'Grow (Fish & Alternatives)',
              ),
              const SizedBox(height: 12),
              _buildMultilineField(
                controller: _glowVegController,
                label: 'Glow (Vegetables)',
              ),
              const SizedBox(height: 12),
              _buildMultilineField(
                controller: _glowFruitController,
                label: 'Glow (Fruits)',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveEntry,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save entry for AI',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A3D00),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExistingEntries() {
    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin-added entries',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<PinggangPinoyData>>(
              stream: DatasetService.streamRemoteDataset(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(
                        color: Color(0xFF0A3D00),
                      ),
                    ),
                  );
                }

                final entries = snapshot.data ?? [];
                if (entries.isEmpty) {
                  return const Text(
                    'No admin-added entries yet. Add one above to customize AI guidance.',
                    style: TextStyle(color: Colors.white70),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white12),
                  itemBuilder: (context, index) {
                    final item = entries[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        item.ageGroup,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          _entryLine('Sex', item.sex),
                          _entryLine('Go', item.goFoods),
                          _entryLine('Grow', item.growFoods),
                          _entryLine('Glow (Veg)', item.glowVegetables),
                          _entryLine('Glow (Fruits)', item.glowFruits),
                        ],
                      ),
                      trailing: const Icon(Icons.library_add_check,
                          color: Color(0xFF0A3D00)),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _entryLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultilineField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      minLines: 2,
      maxLines: 4,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label),
      validator: (value) =>
          (value == null || value.trim().isEmpty) ? 'Required' : null,
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0A3D00)),
      ),
      filled: true,
      fillColor: const Color.fromARGB(9, 158, 158, 158),
    );
  }
}

