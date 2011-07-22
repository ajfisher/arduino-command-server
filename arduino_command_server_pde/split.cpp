#include "split.h"

void split(char delim, String str, String *str_array) {
  // this method takes a string, chops it up at the point of delim and drops each piece
  // into str_array.
  split(delim, str, str_array, 0);
}

void split(char delim, String str, String *str_array, int limit) {
  // this method takes a string, chops it up at the point of delim and drops each piece
  // into str_array.
  int i = 0;
  while (str.indexOf(delim) >= 0) {
    str_array[i] = str.substring(0, str.indexOf(delim));
    str = str.substring(str.indexOf(delim)+1);
    i++;
    // this should set the limit now.
    if (limit != 0 && i >= limit) {
      break;
    }
      
  }
  // dump in the last part.
  str_array[i] = str;
  return;
}

