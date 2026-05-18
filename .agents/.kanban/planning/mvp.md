# N1B MVP (POC)

Needed:

* Main scene for testing
* Hex Utils class for handling hex math
* Hexagon tiles (3d primitives) are generated in a grid at start
  * Inspector: POINTY_TOP || FLAT_TOP
  * Inspector: hex size
  * Need to handle symmetry on both sides
* AP Tracker
  * Logic and UI
* Card
  * could be pretty empty right now.  just using one makes the hex "populated"
* Deck of cards.    Will be simple, make the hex tiles populated / can play guys
* Can draw a hand from deck of cards.    Cards get shuffled
* Guys
  * Stats
    * Attack
    * Defense
  * box of guys
  * can spend 1 AP to play a guy on any tile
  * hover guy highlights them
  * click guy in box -> highlight locks -> click populated tile -> guy moves to tile
  * click guy on tile -> highlight locks -> can spend 1 AP to move to neighbor tile
  * if guy moves into enemy guy's tile: combat
* Combat
  * Inspector: 
    * Mapping of numbers (1-6) to hit or miss (5 and 6 is hit by default)
    * Mapping of number (1-6) to successful block (4,5,6 default)
    * Logic to roll X attack dice for attacker where X is attack stat
    * Logic to roll Y defense dice for defender where Y is defense stat
    * Logic to compare the results and signal out
    * Logic in game manager to appropriately deal with handling health and removing killed units from board.


More, but this is where I am right now and will go from this and see how it feels
