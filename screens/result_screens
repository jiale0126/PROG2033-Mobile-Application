import 'package:flutter/material.dart';
import 'dart:typed_data';

class ResultScreen extends StatelessWidget {
  final Uint8List? imageBytes;

  final Map<String, dynamic> planData;

  const ResultScreen({
    Key? key,
    required this.imageBytes,
    required this.planData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generated Event Poster')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (imageBytes != null)
              Image.memory(imageBytes!, fit: BoxFit.contain)
            else
              Container(
                height: 400,
                color: Colors.grey[300],
                alignment: Alignment.center,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    SizedBox(height: 10),
                    Text('Failed to generate poster'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
    
