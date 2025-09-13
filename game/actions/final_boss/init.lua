local FINAL_BOSS_ACTIONS = {  }
FINAL_BOSS_ACTIONS.ARRIVAL = require("actions.final_boss.arrival")
FINAL_BOSS_ACTIONS.DEATH = require("actions.final_boss.death")
FINAL_BOSS_ACTIONS.TRIPLE_CLAW = require("actions.final_boss.triple_claw")
FINAL_BOSS_ACTIONS.RANGED_ATTACK = require("actions.final_boss.ranged_attack")
FINAL_BOSS_ACTIONS.ARCANE_SHOWER = require("actions.final_boss.arcane_shower")
return FINAL_BOSS_ACTIONS

