Arduino Command Server
======================

Overview
--------

This library is designed to make it easy to set up a command line server on an arduino that can respond to commands over the wire similar to telnet, FTP or other command line protocols.

Additionally the library is designed to be generic enough to add additional commands to those in the base library in order to extend the server out.

Requirements
------------

A stock Arduino Duemilanove or Uno are only supported at this time Arduino Mega is not properly supported (ie none of the pin counts are correct).

If you want to use this over ethernet then you'll need an ethernet shield or something like a Freetronics EtherTen.

Use
---

At this point, fire up the sketch, load it on the Arduino and connect via telnet. From there start issuing commands and see what happens. 

Contribution
------------

Contribution is via the GitHub repo at https://github.com/ajfisher/arduino-command-server plase fork and hack away as much as you like - the more the merrier!

Issues should be raised as via the issue tracker at GitHub on the link above.

To Do:
------

* Add digital read
* add ability to cycle from one state to another via pwm shifting
* be able to set network params
* move everything to a library to make it more useful
