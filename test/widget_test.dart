import 'package:flutter_test/flutter_test.dart';
import 'package:smart_grow_code/dashboard/admin/user_form_dialog.dart';

void main() {
  test('StaffUserFormResult stores staff account fields', () {
    const result = StaffUserFormResult(
      name: 'Staff User',
      email: 'staff@example.com',
      password: 'temporary123',
    );

    expect(result.name, 'Staff User');
    expect(result.email, 'staff@example.com');
    expect(result.password, 'temporary123');
  });
}
