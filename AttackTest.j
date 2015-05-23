//requires CombatSistem lol

/*
   Solo para probar
*/


function Trig_attack_Neutral_Actions takes nothing returns nothing
  local Combat combat =0
  if(ExtraData.get(GetTriggerUnit()).isLeader and  ExtraData.get(GetAttacker()).isLeader ) then
    set combat =Combat.start(GetTriggerUnit() , GetAttacker())
  endif
 // set t = null
endfunction

//===========================================================================
function InitTrig_Attack_Test takes nothing returns nothing
    set gg_trg_Attack_Test = CreateTrigger(  )
    call TriggerRegisterPlayerUnitEventSimple( gg_trg_Attack_Test, Player(PLAYER_NEUTRAL_PASSIVE), EVENT_PLAYER_UNIT_ATTACKED )
    call TriggerAddAction( gg_trg_Attack_Test, function Trig_attack_Neutral_Actions )
endfunction

