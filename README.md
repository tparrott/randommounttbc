# Random Mount TBC
Addon that allows for random mount summoning in Classic TBC. Will choose between any of the mounts currently in your bags and in your spellbook (for paladins and warlocks). Prefers faster mounts over slower mounts and prefers flying mounts over ground mounts in flyable areas.

In the current version you'll first have to install the addon, then make a macro that looks something like the following (can be tweaked):
</br></br>
/run RnM_Randomize() </br>
/click [nomounted] RnM_Button </br>
/dismount [mounted]
</br></br>

Then finally bind this macro to a key using whatever method you prefer.

There's no UI for this, the premise is that any mount in your bags is a mount you'd like to use. If you'd like to exclude spell mounts there's a single variable you can change close to the top of RandomMount.lua
