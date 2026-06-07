import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class AddTaskScreen extends StatefulWidget {
  final int userId;
  final Map<String, dynamic>? existing;

  const AddTaskScreen({super.key, required this.userId, this.existing});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedType = 'Task';
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.existing!['title'] as String;
      _descController.text = (widget.existing!['description'] as String?) ?? '';
      _selectedType = widget.existing!['type'] as String;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    if (_isEditing) {
      await DatabaseHelper.updateTask(
        widget.existing!['id'] as int,
        _titleController.text,
        _descController.text,
      );
    } else {
      await DatabaseHelper.addTask(
        userId: widget.userId,
        title: _titleController.text,
        description: _descController.text,
        type: _selectedType,
      );
    }

    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Item' : 'Add New',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isEditing) ...[
                const Text('Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                const SizedBox(height: 10),
                Row(
                  children: ['Task', 'Event', 'Note'].map((type) {
                    final selected = _selectedType == type;
                    Color color;
                    switch (type) {
                      case 'Event': color = const Color(0xFF7B1FA2); break;
                      case 'Note': color = const Color(0xFF00695C); break;
                      default: color = const Color(0xFF1565C0);
                    }
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selected ? color : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: selected ? color : Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                type == 'Task'
                                    ? Icons.check_circle_outline
                                    : type == 'Event'
                                        ? Icons.event
                                        : Icons.sticky_note_2_outlined,
                                color: selected ? Colors.white : color,
                                size: 22,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                type,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? Colors.white : color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
              const Text('Title', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                style: const TextStyle(fontSize: 15),
                decoration: _inputDecoration(_isEditing ? 'Title' : 'Enter a title for this $_selectedType'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 20),
              Text(
                _selectedType == 'Note' ? 'Note Content' : 'Description (optional)',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 5,
                style: const TextStyle(fontSize: 15),
                decoration: _inputDecoration(
                  _selectedType == 'Note'
                      ? 'Write your note here...'
                      : 'Add more details...',
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          _isEditing ? 'Save Changes' : 'Add $_selectedType',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
    );
  }
}
