import 'package:flutter/material.dart';
import 'package:smart_grow_code/auth/app_user.dart';

class StaffUserFormResult {
  const StaffUserFormResult({
    required this.name,
    required this.email,
    this.password,
  });

  final String name;
  final String email;
  final String? password;
}

class StaffUserFormDialog extends StatefulWidget {
  const StaffUserFormDialog({super.key, this.user});

  final AppUser? user;

  bool get isEditing => user != null;

  @override
  State<StaffUserFormDialog> createState() => _StaffUserFormDialogState();
}

class _StaffUserFormDialogState extends State<StaffUserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit Staff' : 'Create Staff'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a name.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty || !email.contains('@')) {
                    return 'Enter a valid email.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              if (!widget.isEditing)
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: 'Temporary Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _showPassword = !_showPassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (widget.isEditing) return null;
                    final password = value ?? '';
                    if (password.length < 6) {
                      return 'Use at least 6 characters.';
                    }
                    return null;
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(widget.isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      StaffUserFormResult(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: widget.isEditing ? null : _passwordController.text,
      ),
    );
  }
}
