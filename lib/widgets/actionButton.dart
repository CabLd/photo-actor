import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  const ActionButton({super.key, required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 85,
        // 整体尺寸
        height: 85,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // 外层白色圆环
          border: Border.all(
            color: Colors.white,
            width: 4, // 圆环的粗细
          ),
        ),
        // 通过 padding 控制外环与内圆之间的黑色间隙
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white, // 中心白色实心圆
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
