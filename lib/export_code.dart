import 'dart:io';

void main() {
  // المجلد الذي نريد البحث فيه (مجلد الأكواد فقط)
  var dir = Directory('lib');
  // اسم الملف الذي سيتم إنشاؤه
  var outputFile = File('my_project_code.md');
  var output = StringBuffer();

  if (dir.existsSync()) {
    output.writeln('# KidCare Project Code\n');

    // جلب كل الملفات داخل مجلد lib
    var files = dir.listSync(recursive: true);
    for (var file in files) {
      // نأخذ فقط ملفات الدارت
      if (file is File && file.path.endsWith('.dart')) {
        output.writeln('### File: ${file.path}');
        output.writeln('```dart');
        output.writeln(file.readAsStringSync());
        output.writeln('```\n');
      }
    }

    outputFile.writeAsStringSync(output.toString());
    print('✅ تمت العملية بنجاح! تم إنشاء ملف my_project_code.md');
  } else {
    print('❌ مجلد lib غير موجود!');
  }
}