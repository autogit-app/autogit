# MediaPipe proto classes are referenced by optional/reflection code but not always
# on the classpath (e.g. flutter_gemma). Tell R8 to ignore missing references.
-dontwarn com.google.mediapipe.proto.CalculatorProfileProto$CalculatorProfile
-dontwarn com.google.mediapipe.proto.GraphTemplateProto$CalculatorGraphTemplate
