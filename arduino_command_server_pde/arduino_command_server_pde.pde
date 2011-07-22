
#include "split.h"

typedef void (* CommandFuncPtr)(String args); // typedef to the command

struct Command {
  char code[5]; // the code used to call the command
  String help; // the snippet help version
  CommandFuncPtr cmd; // point to the command to be called
};

#define _VERSION "0.2"
#define MAX_COMMANDS 10

String command;

Command com[MAX_COMMANDS];


void setup() {
  Serial.begin(9600);
  sysprintln("Send a command to start. Help if you have questions");
  command = "";
  com[0]=(Command){"HELP", "Prints this. Try HELP <CMD> for more", command_help};
  com[1]=(Command){"LSA", "Lists status of all analog pins", command_list_analog};
  com[2]=(Command){"ANR", "Reads a specific analog pin", command_read_analog};
  com[3]=(Command){"ANW", "Writes to an analog pin", command_analog_write};
  com[4]=(Command){"PINM", "Sets the mode of a digital pin [pin IN|OUT]", command_setmode};
  com[5]=(Command){"DIGW", "Writes to the digital pin", command_digital_write};
}

void loop() {
  while (Serial.available() > 0) {
     char ch = Serial.read();
     if (ch == 10) {
       // new line so now we can attempt to process the line
       process_command(&command);
       command = "";
     } else {
       command += String(ch);
     }
  }
}

void process_command(String* command) {
  // this method takes the command string and then breaks it down
  // looking for the relevant command and doing something with it or erroring.
  String argv[2]; // we have 2 args, the command and the param
  split(' ', *command, argv, 1); // so split only once
  
  int cmd_index = command_item(argv[0]);
  if (cmd_index >= 0) {
    com[cmd_index].cmd(argv[1]);
  } else {
    sysprintln("500 Couldn't find command");
  }
  
  return;
}

int command_item(String cmd_code) {
  // this method does all of the comparison stuff to determine the id of a command
  // which it then passes back
  int i=0;
  boolean arg_found = false;
  // look through the array of commands until you find it or else you exhaust the list.
  while (!arg_found && i<MAX_COMMANDS) {
     if (cmd_code.equalsIgnoreCase((String)com[i].code)) {
       arg_found = true;
      } else {
        i++;
      }
  }
  
  if (arg_found) {
    return (i);
  } else {
    return (-1);
  }
  
}

void command_help(String args) {
  // this command spits out the help messages
  
  int cmd_index;
  if (args.length() >=2) {
    // we attempt to see if there is a command we should spit out instead.
    cmd_index = command_item(args);
    if (cmd_index < 0) sysprintln("Syntax error please use a command");
  } else {
    cmd_index = -1;
  }
  
  if (cmd_index < 0) {
    sysprint("System Help - Version: ");
    sysprintln(_VERSION);
    sysprintln("Available commands");
    sysprintln("------------------");
    for (int i=0; i<MAX_COMMANDS; i++){
      if (com[i].help != ""){
        sysprint(com[i].code);
        sysprint(" ");
        sysprintln(com[i].help);
      }
    }
  } else {
    sysprintln("HELP");
    sysprint(com[cmd_index].code);
    sysprint(": ");
    sysprintln(com[cmd_index].help);
  }
}

void command_list_analog(String args) {
  // list the current status of all the analog pins.
  sysprintln("200 Analog Read all pins");
  for (int i=0; i<6; i++) {
    sysprint("211 A");
    sysprint(i);
    sysprint(" ");
    sysprintln(analogRead(i));
  }
}

void command_read_analog(String args) {
    // reads a specified analog pin
    // argument passed in should simply be a number and it's that one we read.
    // we only need to grab the first char too because it's a number from 0-5
    if (args.length() <= 0) {
      sysprintln("501 Pin number not supplied");
      return;
    }
    if (args.length() > 1) {
      sysprintln("502 Pin range too high or incorrect");
      return;
    }
    // just convert it and if it gets something nasty it will go to zero.
    int pin = atoi(&args[0]);
    sysprint("200 Analog read pin #");
    sysprintln(pin);
    sysprint("211 ");
    sysprintln(analogRead((pin)));
}

void command_setmode(String args) {
  // this method sets the mode of the particular digital pin as either input or output
  // args comes in as "[pin no] [IN\OUT]" where pin no can be double digit so needs to be processed.
  if (args.length() < 4) {
    sysprintln("501 Arguments not supplied");
    return;
  }
  String argv[2];
  split(' ', args, argv, 1);
  if (argv[0].length() < 1 || argv[0].length() > 2) {
      sysprintln("502 Pin number incorrect");
      return;
  }
  // now we get the proper pin number which can be a maximum of 2 chars
  // note anything dodgey and it bails to 0
  int pin = atoi(&argv[0][0]);
  
  // now we determine the mode.
  if (argv[1].length() > 3) {
    sysprintln("503 Please use IN or OUT only");
    return;
  }
  if (argv[1].equalsIgnoreCase("IN")) {
    pinMode(pin, INPUT);
    sysprint("210 set pin #");
    sysprint(pin);
    sysprintln(" to INPUT");
    return;
  }
  if (argv[1].equalsIgnoreCase("OUT")) {
    pinMode(pin, OUTPUT);
    sysprint("210 set pin #");
    sysprint(pin);
    sysprintln(" to OUTPUT");
    return;
  }
  // if you've dropped through to here then the command was mush.
  sysprintln("503 Please use IN or OUT only");
}

void command_digital_write (String args) {
  // sets a digital pin high or low based on what value is passed.
  // params are the pin number then HIGH or LOW
  if (args.length() < 5) { // single digit pin + space + LOW
    sysprintln("Pin # and state not supplied");
    return;
  }
  String argv[2];
  split(' ', args, argv, 1);
  if (argv[0].length() < 1 || argv[0].length() > 2) {
      sysprintln("502 Pin number incorrect");
      return;
  }
  int pin = atoi(&argv[0][0]);

  // now we determine the mode.
  if (argv[1].length() > 4) {
    sysprintln("503 Please use HIGH or LOW only");
    return;
  }
  if (argv[1].equalsIgnoreCase("HIGH")) {
    digitalWrite(pin, HIGH);
    sysprint("210 set pin #");
    sysprint(pin);
    sysprintln(" HIGH");
    return;
  }
  if (argv[1].equalsIgnoreCase("LOW")) {
    digitalWrite(pin, LOW);
    sysprint("210 set pin #");
    sysprint(pin);
    sysprintln(" LOW");
    return;
  }
  // if you've dropped through to here then the command was mush.
  sysprintln("503 Please use HIGH or LOW only");  
}

void command_analog_write(String args) {
  // this function takes the pin and a value to set for PWM and then does it.
  if (args.length() < 3) { // single digit pin + space + at least one digit
    sysprintln("Pin # and value not supplied");
    return;
  }
  String argv[2];
  split(' ', args, argv, 1);
  if (argv[0].length() < 1 || argv[0].length() > 2) {
      sysprintln("502 Pin number is incorrect");
      return;
  }
  int pin = atoi(&argv[0][0]);
  // now we determine the mode.
  if (argv[1].length() > 3) {
    sysprintln("503 Please use a value 0-255");
    return;
  }
  int pwm = atoi(&argv[1][0]);
  if (pwm > 255) {
    sysprintln("503 Please use a value 0-255");
    return;
  }
  // if you've made it here then do the job.
  analogWrite(pin, pwm);
}

void sysprint(String str) {
   // prints out the string to the relevant location
  Serial.print(str); 
}
void sysprintln(String str) {
   // prints out the string to the relevant location
  Serial.println(str); 
}

