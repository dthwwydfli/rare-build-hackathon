import 'package:flutter/material.dart';

import '../../domain/models/enums.dart';

IconData commitmentIcon(CommitmentType type) {
  switch (type) {
    case CommitmentType.location:
      return Icons.location_on_outlined;
    case CommitmentType.spending:
      return Icons.payments_outlined;
    case CommitmentType.online:
      return Icons.phone_android_outlined;
  }
}
