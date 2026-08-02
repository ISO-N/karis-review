import 'package:flutter/widgets.dart';

Duration reducedDuration(BuildContext context, Duration duration) {
  return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
