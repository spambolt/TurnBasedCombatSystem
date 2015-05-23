//! zinc
library AICombatModule requires ListClass
{
    
    /*     respuestas de las unidades bajo el control de la computadora durante la batalla
     *      solo debe escoger un objetivo y una accion entre las que posee
     *
     */
     
     //constants
     private constant string MELEE_ATTACK_ACTION_ID = "shockwave"; 
     private constant string RANGED_ATTACK_ACTION_ID = "idorder"; 
     private constant string DEFEND_ACTION_ID = "idorder"; 
     
     public struct AIAction []
     {
        module Alloc;
        UnitList currCombatGroup;
        unit me;
        
        private method canTakeEnemyAction()->boolean
        {
            boolean flag = false;
            //analizar si posee abilidades para dañar al enemigo
            if(GetUnitAbilityLevel(this.me , ATTACK_ACTION) > 0 || GetUnitAbilityLevel(this.me , RANGED_ATTACK_ACTION) >  0)
            {
                flag = true;
            }
            
            return flag;
        }
        
        private method parseEnemyAction() -> boolean
        {
            boolean flag = false;
            unit target = null;
            player owner = GetOwningPlayer(this.me);
            player enemyPlayer = null;
            integer i;
            
            //attack the strongest
            
            //attack the weakest
            
            //attack the first able to attack
            for( i=0 ; i < this.currCombatGroup.getSize() ; i+=1)
            {
                target = this.currCombatGroup.get(i);
                enemyPlayer = GetOwningPlayer(target);

                if(owner != enemyPlayer)
                {
                    //ordenar a nuestra unidad tomar accion contra la unidad seleccionada
                    //IssueInstantTargetOrder(this.me , MELEE_ATTACK_ACTION_ID , target , target);
                    IssueTargetOrder(this.me , MELEE_ATTACK_ACTION_ID ,target);
                    
                    BJDebugMsg("Ordenando "+MELEE_ATTACK_ACTION_ID);
                    flag = true;
                    break;
                }
            }
            
            
            //buscar enemigo debilitado
            
            return flag;
        }
        
        private method parseAllyAction() -> boolean
        {
            boolean flag = false;
            
            
            //buscar aliado debilitado
            
            return flag;
        }
        
        public static method ParseDecision(UnitList combatGroup , unit me)
        {
            thistype this = thistype.allocate();
            this.currCombatGroup = combatGroup.clone();
            this.me = me;
            
            //tengo abilidades para accion enemiga?
            if(this.canTakeEnemyAction())
            {
                //si puede
                if(this.parseEnemyAction())
                {
                    //destruir
                    this.destroy();
                }
            }
            else
            {
                //no puede
                if(this.parseAllyAction())
                {
                    //destruir
                    this.destroy();
                }
            }
            
        }
        
        public method destroy()
        {
            BJDebugMsg("desicion destroyed");
            this.currCombatGroup.destroy();
            this.deallocate();
        }
     
     }
}
//! endzinc