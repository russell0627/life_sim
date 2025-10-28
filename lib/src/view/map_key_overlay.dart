
import 'package:flutter/material.dart';

class MapKeyOverlay extends StatelessWidget {
  const MapKeyOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16.0,
      left: 16.0,
      child: Card(
        elevation: 4.0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Map Key',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              _buildKeyItem(Colors.blue[200]!, 'Water', isCircle: false),
              _buildKeyItem(Colors.lightGreen[300]!, 'Grassland', isCircle: false),
              _buildKeyItem(Colors.green[300]!, 'Forest', isCircle: false),
              _buildKeyItem(Colors.grey[600]!, 'Mountain', isCircle: false),
              const Divider(),
              _buildKeyItem(Colors.lightGreen, 'Grass', isCircle: true),
              _buildKeyItem(Colors.green[800]!, 'Berry Bush', isCircle: true, hasInnerCircle: true, innerCircleColor: Colors.red),
              const Divider(),
              _buildKeyItem(Colors.orange[700]!, 'Rabbit', isCircle: false),
              _buildKeyItem(Colors.red[900]!, 'Deer', isCircle: false),
              _buildKeyItem(Colors.grey[800]!, 'Wolf', isCircle: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyItem(Color color, String text, {bool isCircle = false, bool hasInnerCircle = false, Color? innerCircleColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
              border: Border.all(color: Colors.black26, width: 0.5),
            ),
            child: hasInnerCircle
                ? Center(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: innerCircleColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
