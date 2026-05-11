import 'package:fieldguard/core/responsive/size_config.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

class UploaddocsScreen extends StatefulWidget {
  const UploaddocsScreen({super.key});

  @override
  State<UploaddocsScreen> createState() => _UploadDocsScreenState();
}

class _UploadDocsScreenState extends State<UploaddocsScreen> {
  String? fileName;
  String? filePath;

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );

    if (result != null) {
      setState(() {
        fileName = result.files.single.name;
        filePath = result.files.single.path;
      });

      print(result.files.single.path);
    }
  }

  Future<void> openDocument() async {
    if (filePath != null) {
      await OpenFile.open(filePath!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: pickFile,
      child: Container(
        width: double.infinity,

        padding: EdgeInsets.symmetric(
          vertical: SizeConfig.scale(8),
          horizontal: SizeConfig.scale(8),
        ),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(SizeConfig.scale(14)),
          border: Border.all(color: Colors.grey.shade400),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(SizeConfig.scale(14)),
                border: Border.all(color: Colors.grey.shade400),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),

              child: IconButton(
                onPressed: pickFile,
                icon: const Icon(Icons.upload_file_outlined),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: SizeConfig.scale(10),
                  horizontal: SizeConfig.scale(10),
                ),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(SizeConfig.scale(14)),
                  border: Border.all(color: Colors.grey.shade400),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Expanded(
                      child: Text(
                        fileName ?? 'Upload Document',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    TextButton(
                      onPressed: openDocument,
                      child: Text(
                        'view',
                        style: TextStyle(
                          fontSize: SizeConfig.scaledFontSize(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
