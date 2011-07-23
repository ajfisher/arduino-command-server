#include <SPI.h>
#include <Ethernet.h>

#include "split.h"

typedef void (* CommandFuncPtr)(String args); // typedef to the command

struct Command {
  char code[5]; // the code used to call the command
  String help; // the snippet help version
  CommandFuncPtr cmd; // point to the command to be called
};

#define _VERSION "0.3"
#define MAX_COMMANDS 10

// Enter a MAC address and IP address for your controller below.
// The IP address will be dependent on your local network.
// gateway and subnet are optional:
byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte ip[] =   { 10,  0,  1,  52 };
byte ip2[] =  { 10,  0,  1,  53 };
byte gateway[] = { 10,0,1,1 };
byte subnet[] = { 255, 255, 0, 0 };

// telnet defaults to port 23
Server server(23);
boolean newClient = false;

boolean debug = true;

String command;

Command com[MAX_COMMANDS];

Print *client = &Serial;
Client *ethcl = NULL;

void setup() {
  Serial.begin(9600);
  client = &Serial;
  client->println("send a command to start");
  Ethernet.begin(mac, ip, gateway, subnet);
  // start listening for clients
  server.begin(); 

  command = "";
  com[0]=(Command){"HELP", "Prints this. Try HELP <CMD> for more", command_help};
  com[1]=(Command){"LSA", "Lists status of all analog pins", command_list_analog};
  com[2]=(Command){"ANR", "Reads a specific analog pin", command_analog_read};
  com[3]=(Command){"ANW", "Writes to an analog pin", command_analog_write};
  com[4]=(Command){"PINM", "Sets the mode of a digital pin [pin IN|OUT]", command_setmode};
  com[5]=(Command){"LSD", "Lists status of all digital pins", command_list_digital};
  com[6]=(Command){"DIGW", "Writes to the digital pin", command_digital_write};
  com[7]=(Command){"DIGR", "Reads the specified digital pin", command_digital_read};
  com[8]=(Command){"QUIT", "Quits this session gracefully", command_quit};
  
}

void loop() {
  
  Client eclient = server.available();
  if (eclient) {
    if (debug) Serial.println("We have a new client");
    client = &eclient;
    ethcl = &eclient; // set the global to use later
    client->println("230 CONNECTED OK");
    client->println("ARDUINO COMMAND SERVER. SEND COMMAND OR HELP");    
    newClient = true;
    eclient.flush();
    
    while(eclient.connected()) {
      if (eclient.available()){
         char ch = eclient.read();
         //Serial.println(ch, DEC);
         if (ch == 10) {
           // new line so now we can attempt to process the line
           //eclient.println(command);
           process_command(&command);
           command = "";
         } else if ((ch < 10 && ch > 0) || (ch > 10 && ch < 32)) {
          // ignore control chars up to space and allow nulls to pass through
         ; 
         } else {
           command += String(ch);
         }
      }
    }
    
    if (!eclient.connected() && newClient) {
      eclient.stop();
      newClient = false;
      if (debug) Serial.println("disconnecting");
    }
  }
  
/**  while (Serial.available() > 0) {
     char ch = Serial.read();
     if (ch == 10) {
       // new line so now we can attempt to process the line
       process_command(&command);
       command = "";
     } else {
       command += String(ch);
     }
  }**/
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
    client->println("500 Couldn't find command");
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
    if (cmd_index < 0) client->println("Syntax error please use a command");
  } else {
    cmd_index = -1;
  }
  
  if (cmd_index < 0) {
    client->print("System Help - Version: ");
    client->println(_VERSION);
    client->println("Try help <cmd> for more info");
    client->println("Available commands");
    client->println("------------------");
    for (int i=0; i<MAX_COMMANDS; i++){
      if (com[i].help != ""){
        client->print(com[i].code);
        if (i % 3 == 0) {
          client->println();
        } else {
          client->print("\t");
        }
      }
    }
    client->println();
  } else {
    client->println("HELP");
    client->print(com[cmd_index].code);
    client->print(": ");
    client->println(com[cmd_index].help);
  }
}

void command_list_analog(String args) {
  // list the current status of all the analog pins.
  client->println("200 Analog Read all pins");
  for (int i=0; i<6; i++) {
    client->print("211 A");
    client->print(i);
    client->print(" ");
    client->println(analogRead(i));
  }
}

void command_analog_read(String args) {
    // reads a specified analog pin
    // argument passed in should simply be a number and it's that one we read.
    // we only need to grab the first char too because it's a number from 0-5
    if (args.length() <= 0) {
      client->println("501 Pin number not supplied");
      return;
    }
    if (args.length() > 1) {
      client->println("502 Pin range too high or incorrect");
      return;
    }
    // just convert it and if it gets something nasty it will go to zero.
    int pin = atoi(&args[0]);
    client->print("200 Analog read pin #");
    client->println(pin);
    client->print("211 ");
    client->println(analogRead((pin)));
}

void command_analog_write(String args) {
  // this function takes the pin and a value to set for PWM and then does it.
  if (args.length() < 3) { // single digit pin + space + at least one digit
    client->println("Pin # and value not supplied");
    return;
  }
  String argv[2];
  split(' ', args, argv, 1);
  if (argv[0].length() < 1 || argv[0].length() > 2) {
      client->println("502 Pin number is incorrect");
      return;
  }
  int pin = atoi(&argv[0][0]);
  // now we determine the mode.
  if (argv[1].length() > 3) {
    client->println("503 Please use a value 0-255");
    return;
  }
  int pwm = atoi(&argv[1][0]);
  if (pwm > 255) {
    client->println("503 Please use a value 0-255");
    return;
  }
  // if you've made it here then do the job.
  analogWrite(pin, pwm);
  client->print("200 Pin #");
  client->print(pin);
  client->print(" set to ");
  client->println(pwm);
}


void command_setmode(String args) {
  // this method sets the mode of the particular digital pin as either input or output
  // args comes in as "[pin no] [IN\OUT]" where pin no can be double digit so needs to be processed.
  if (args.length() < 4) {
    client->println("501 Arguments not supplied");
    return;
  }
  String argv[2];
  split(' ', args, argv, 1);
  if (argv[0].length() < 1 || argv[0].length() > 2) {
      client->println("502 Pin number incorrect");
      return;
  }
  // now we get the proper pin number which can be a maximum of 2 chars
  // note anything dodgey and it bails to 0
  int pin = atoi(&argv[0][0]);
  
  // now we determine the mode.
  if (argv[1].length() > 3) {
    client->println("503 Please use IN or OUT only");
    return;
  }
  if (argv[1].equalsIgnoreCase("IN")) {
    pinMode(pin, INPUT);
    client->print("210 set pin #");
    client->print(pin);
    client->println(" to INPUT");
    return;
  }
  if (argv[1].equalsIgnoreCase("OUT")) {
    pinMode(pin, OUTPUT);
    client->print("210 set pin #");
    client->print(pin);
    client->println(" to OUTPUT");
    return;
  }
  // if you've dropped through to here then the command was mush.
  client->println("503 Please use IN or OUT only");
}

void command_list_digital(String args) {
  // list the current status of all the analog pins.
  client->println("200 Digital Read all pins");
  client->println("210 If using ethernet pins 10-13 are used");
  for (int i=0; i<20; i++) {
    client->print("211 D");
    client->print(i);
    client->print(" ");
    client->println(digitalRead(i));
  }
}

void command_digital_read(String args) {
    // reads a specified digital pin
    // argument passed in should simply be a number and it's that one we read.
    // we do need to get both chars though because it can be 2 digits
    if (args.length() <= 0) {
      client->println("501 Pin number not supplied");
      return;
    }
    if (args.length() > 2) {
      client->println("502 Pin range too high or incorrect");
      return;
    }
    // just convert it and if it gets something nasty it will go to zero.
    int pin = atoi(&args[0]);
    client->print("200 Digital read pin #");
    client->println(pin);
    client->print("211 ");
    client->println(digitalRead((pin)));
}

void command_digital_write (String args) {
  // sets a digital pin high or low based on what value is passed.
  // params are the pin number then HIGH or LOW
  if (args.length() < 5) { // single digit pin + space + LOW
    client->println("Pin # and state not supplied");
    return;
  }
  String argv[2];
  split(' ', args, argv, 1);
  if (argv[0].length() < 1 || argv[0].length() > 2) {
      client->println("502 Pin number incorrect");
      return;
  }
  int pin = atoi(&argv[0][0]);

  // now we determine the mode.
  if (argv[1].length() > 4) {
    client->println("503 Please use HIGH or LOW only");
    return;
  }
  if (argv[1].equalsIgnoreCase("HIGH")) {
    digitalWrite(pin, HIGH);
    client->print("210 set pin #");
    client->print(pin);
    client->println(" HIGH");
    return;
  }
  if (argv[1].equalsIgnoreCase("LOW")) {
    digitalWrite(pin, LOW);
    client->print("210 set pin #");
    client->print(pin);
    client->println(" LOW");
    return;
  }
  // if you've dropped through to here then the command was mush.
  client->println("503 Please use HIGH or LOW only");  
}



// ETHERNET FUNCTIONS HERE.
void command_quit(String args) {
  // this method closes down the network connection.
  client->println("200 QUIT");
  client->println("Goodbye");
  ethcl->stop();
}
