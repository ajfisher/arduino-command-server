#if defined(ARDUINO) && ARDUINO >= 100
  #include "Arduino.h"
#else
  #include "WProgram.h"
#endif

void split(char delim, String str, String *str_array);
void split(char delim, String str, String *str_array, int limit);
