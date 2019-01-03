Ruby Dice Roller
================

- Dice roller aimed at RPG tabletops.
- A little TCP server/client combination exists which uses ./dice_roller.rb.
- The client will eventually be in a TUI environment ([RuTui](https://github.com/b1nary/rutui)).

### Dependencies

The dice roller and client/server have no current dependencies.

RDR uses RuTui, a simple `bundle install` (provided one has [Bundler](https://bundler.io/)) should do the trick

### Usage

Usage currently changes with the three types of program bullet-pointed above:

#### Dice Roller

The roller itself, `dice_roller.rb`, can be called from the command line in the format:

    ./dice_roller.rb XdY + Z - ...

Sapces "` `" can be placed wherever, modifications `+ Z - ...` are not necessary.

Output is of the form:

    $ ./dice_roller.rb 2d20 + 5 - 1
    29 [9 + 16] (+ 5 - 1)

#### Client/Server

Both client and server, `server.rb`, and `client.rb`, can be given an address/port but default to `"loclahost"`, `8090`

The clients then provide a username and give roll command in the syntax given above.

#### TUI

Usage for the TUI will be given when it exists
