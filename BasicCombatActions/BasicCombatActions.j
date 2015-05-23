//! zinc
library BasicCombatActions requires Damage
{
    //clase que diseña e implementa las acciones basicas durante un combate de las unidades

    /*
    *  esta clase es la base de cualquier spell basado en turnos de la unidad
    * --por hacer -> destruir instancia si la unidad responsable muere...done
    */
    public struct TurnBasedAction
    {
         integer turnDuration;
         integer ParentId; //el id de  la unidad propietaria de la accion 

         private static thistype cntrlList[];
         private static integer ctrlIndex;
        
        public method add()
        {
            thistype.cntrlList[thistype.ctrlIndex] = this;
            thistype.ctrlIndex +=1;
            
        }
        
        //elimina esta instancia de la cola de proceso
        public method remove()
        {
            integer i;
            //tomar el ultimo elemento de la cola .last 
            //asignarle la posicion que vamos a liberar .this
            //thistype.cntrlList[this] = thistype.cntrlList[thistype.ctrlIndex];
            //decrementar el el index en 1
            //thistype.ctrlIndex -= 1;
            //shift to left
            for(i=0 ; i < thistype.ctrlIndex ; i+=1)
            {
                 thistype.cntrlList[i] = thistype.cntrlList[i+1];
            }
            
           thistype.ctrlIndex -=1;
        }
        
        public static method EndAllUnitPendingActions(unit u)
        {
            integer parentId = GetUnitId(u);
            integer i;
            for(i=0 ; i< thistype.ctrlIndex ; i+=1)
            {
                if(thistype(0).cntrlList[i].ParentId == parentId )
                {
                    thistype(thistype(0).cntrlList[i]).destroy();
                }
            }
        }
        

        //esta funcion es llamada en cada turno y verifica el final del spell;
        public static method OnTurnCheck(unit u)
        {
            integer parentId = GetUnitId(u);
            integer pendingActions[];
            integer actionId[];
            integer pendingIndex =0;
            integer i;
            integer leftTurns = 0;
            integer action =0;
            BJDebugMsg("|cffff0000Analizando Turno para "+GetUnitName(u)+"|r");
            //encuentra todas las acciones pendientes de la unidad y las agrega a una lista
            for(i=0 ; i< thistype.ctrlIndex ; i+=1)
            {
                if(thistype(0).cntrlList[i].ParentId == parentId )
                {
                    pendingActions[pendingIndex] = thistype(0).cntrlList[i];
                    actionId[pendingIndex] = i;
                    pendingIndex += 1;
                }
            }
            
            if(pendingIndex > 0)
            {
                BJDebugMsg("|cff00ffff"+I2S(pendingIndex)+" instancias encontradas para esta unidad|r");
                 //iterar en la lista de acciones pendientes para realizar acciones en cada lista
                for(i=0 ; i < pendingIndex ; i+=1)
                {
                    action = pendingActions[i]; //@_@
                    leftTurns = thistype(action).turnDuration; //turnos restantes para cada accion ...
                    BJDebugMsg("|cff00ffff Analizando Instancia " + I2S(action)+ "|r");
                   // BJDebugMsg("|cff00ffffValor de Action = "+action+"|r");
                    if(leftTurns <= 1) //detecta que la accion pendiente ha terminado
                    {
                        //destruir instancia
                        BJDebugMsg("|cff00ffff ordenando destruir Instancia"+I2S(thistype(action))+"|r");
                        thistype(action).destroy();
                    }
                    else
                    {
                        BJDebugMsg("|cff00ffff Restando a Instancia"+I2S(thistype(action))+"|r");
                        thistype(action).turnDuration -= 1;
                    }
                    
                }
            }
            else
                BJDebugMsg("|cffff0000No hay acciones pendientes para esta unidad|r");
           
        }
        
        
        private static method onInit()
        {
            thistype.ctrlIndex = 0; // valor necesario para evitar crash
        }
    }
    
    /*
    *
    *     el ataque basico de la unidad durante su turno ...
    *
    */
    
    public struct BaseAttack
    {
        unit caster;
        unit target;
        
        CombatControl combatControl;
        
        real cx;
        real cy;
        
        real tx;
        real ty;
        
        real a;
        real distance;
        
        real oX;
        real oY;
        real facing;
        
        //no asigna el control de combate
        public method getData() //no deberia ser publico realmente ... :(
        {
            real dx;
            real dy;
            
            //this.combatControl = cc;

            this.caster = GetTriggerUnit();
            this.target = GetSpellTargetUnit();
            
            
            this.cx = GetUnitX(this.caster);
            this.cy = GetUnitY(this.caster);
            
            if(this.target != null)
            {
                this.tx = GetUnitX(this.target);
                this.ty = GetUnitY(this.target);
            }
            else
            {
                this.tx = GetSpellTargetX();
                this.ty = GetSpellTargetY();
            }
            
            this.a = Atan2((ty-cy),(tx-cx)); //angulo entre c y t
            
            //guardando parametros originales
            this.oX = this.cx;
            this.oY = this.cy;
            this.facing = GetUnitFacing(this.caster);
            
            dx = tx - cx;
            dy = ty - cy;
            
            this.distance = SquareRoot(dx*dx + dy*dy);
        }

        public method showDamageInfo(real dmg)
        {
            TextTag_DamageShow(this.target ,I2S(R2I(dmg)) , GetOwningPlayer(this.caster));
        }
    }
    
}



    

//! endzinc