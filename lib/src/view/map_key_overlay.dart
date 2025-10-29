
import 'package:flutter/material.dart';
import 'package:life_sim/src/model/animal.dart';
import 'package:life_sim/src/model/plant.dart';
import 'package:life_sim/src/model/terrain.dart';

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
              _buildKeyItem(color: Colors.blue[200]!, text: 'Water', isCircle: false),
              _buildKeyItem(color: Colors.lightGreen[300]!, text: 'Grassland', isCircle: false),
              _buildKeyItem(color: Colors.green[300]!, text: 'Forest', isCircle: false),
              _buildKeyItem(color: Colors.brown[300]!, text: 'Hill', isCircle: false), // Updated hill color
              const Divider(),
              _buildKeyItem(color: Colors.yellow, text: 'Grass', isCircle: true),
              _buildKeyItem(color: Colors.green[800]!, text: 'Berry Bush', isCircle: true, hasInnerCircle: true, innerCircleColor: Colors.red),
              _buildKeyItem(color: Colors.brown, text: 'Tree', isCircle: false),
              const Divider(),
              _buildKeyItem(iconData: Icons.pets, iconColor: Colors.grey[700]!, text: 'Rabbit'),
              _buildKeyItem(iconData: Icons.forest, iconColor: Colors.brown[700]!, text: 'Deer'),
              _buildKeyItem(iconData: Icons.coronavirus, iconColor: Colors.blueGrey[900]!, text: 'Wolf'),
              _buildKeyItem(iconData: Icons.person, iconColor: Colors.purple[400]!, text: 'Villager'), // Added Villager
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyItem({Color? color, String? text, bool isCircle = false, bool hasInnerCircle = false, Color? innerCircleColor, IconData? iconData, Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: iconData != null
                ? Icon(
                    iconData,
                    color: iconColor,
                    size: 16,
                  )
                : Container(
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
          ),
          const SizedBox(width: 8),
          Text(text ?? ''),
        ],
      ),
    );
  }
}
