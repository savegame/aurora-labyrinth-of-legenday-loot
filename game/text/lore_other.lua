local LORE_OTHER = {  }
local Array = require("utils.classes.array")
LORE_OTHER.INTRO_INITIAL = "The {C:PROPER_NOUN}Labyrinth is a dangerous place. It is filled with monsters, traps, and darkness. And yet it attracts a lot of foolhardy adventurers, for it contains {B:STAT_LINE}legendary items {B:NORMAL}that grant {B:NUMBER}magical powers {B:NORMAL}simply by wearing them. {FORCE_NEWLINE} {FORCE_NEWLINE} It is rumored however that at very bottom of the {C:PROPER_NOUN}Labyrinth, resides something greater. Certain amulets of power {B:STAT_LINE}even more legendary than usual {B:NORMAL}- held by a {B:DOWNGRADED}powerful, evil and hideous demon lord. {FORCE_NEWLINE} {FORCE_NEWLINE} {B:NORMAL}No one has been able to reach the very bottom, let alone find one of these {B:STAT_LINE}legendary amulets. {B:NORMAL}Are you going to be the first one? Or will you die "
LORE_OTHER.INTRO_FIRST_TIME = "to a {C:NUMBER}Slime at the very first floor?"
LORE_OTHER.INTRO_SUBSEQUENT = "again to %s {B:NORMAL}at the {C:NUMBER}%s floor?"
LORE_OTHER.OUTRO = "You have defeated the demon lord {C:ELITE_BOSS_RANGED}Baphomet and acquired the amulet {B:LEGENDARY_AMULET}%s. {FORCE_NEWLINE} {FORCE_NEWLINE} {B:STAT_LINE}%s {FORCE_NEWLINE} {FORCE_NEWLINE} {B:NORMAL}This feat has made your name known throughout the world - the very first person to conquer the {C:PROPER_NOUN}Labyrinth. {FORCE_NEWLINE} {FORCE_NEWLINE} It was quite {C:STAT_LINE}legendary."
return LORE_OTHER

