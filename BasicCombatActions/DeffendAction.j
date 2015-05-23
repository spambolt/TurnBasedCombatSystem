//! zinc
library DeffendAction requires BasicCombatActions
{

    /*
    *   este spell incrementa la defensa de la unidad en un 50% y finaliza el turno
    **/
    
    private constant string DEFEND_FX = "Abilities\\Spells\\Human\\InnerFire\\InnerFireTarget.mdl";//"Abilities\\Spells\\Human\\Defend\\DefendCaster.mdl";
    private constant real WAIT_VALUE = 0.5;//tiempo de espera antes de pasar a la siguiente accion ...
    
    public struct Defend  extends TurnBasedAction //hereda un par de metodos de la clase base TurnBasedACtion
    {
        unit caster;
        integer incDef;//defensa incrementada
        effect  defFx; //efecto de defensa
        CombatControl combatControl;
        
        //esta clase es llamada al finalizar la duracion del spell ... 
        private method onDestroy()
        {
            //BJDebugMsg("destruyendo instancia de defensa "+I2S(this));
            //BJDebugMsg("defensa anterior "+I2S(ExtraData.get(this.caster).defense));
            ExtraData.get(this.caster).defense -= this.incDef;//decrementa a la defensa el 50% de la defesa actual para volver al estado anterior
           // BJDebugMsg("defensa actual "+I2S(ExtraData.get(this.caster).defense));
            DestroyEffect(this.defFx);
            
            this.remove();
            //this.deallocate();
        }
        
        public method endingActions()
        {
            this.combatControl.onActionEnd(); // notifica al control de combate que ha finalizados sus acciones
        }
        
        public static method create(unit uCast , CombatControl cc) -> thistype
        {
            thistype this = thistype.allocate();
            timer t = NewTimer();
            this.caster = uCast;
            
            this.ParentId = GetUnitId(this.caster); //id de la unidad responsable de la accion
            
            this.combatControl = cc;
            this.incDef = R2I((ExtraData.get(uCast).defense)/2);
            this.turnDuration = 1; //regresarà despues de una vuelta de la unidad
            ExtraData.get(uCast).defense += this.incDef;//incrementa a la defensa el 50% de la defesa actual 
            this.defFx = AddSpecialEffectTarget(DEFEND_FX , this.caster , "overhead");
            
            //agregar este spell a la cola
            this.add();
            this.combatControl.onActionStart();
            
            cancelCurrentOrder(this.caster);
            
            SetTimerData(t, this);
            //pasa a la siguiente accion ... despues de un breve lapso de tiempo
            TimerStart(t , WAIT_VALUE , false , function()
            {
                timer t = GetExpiredTimer();
                thistype instance = GetTimerData(t);
                
                instance.endingActions();
                ReleaseTimer(t);
                
                t = null;
            });
            //finalizar el turno
            BJDebugMsg("|cff00ffffInstancia Iniciada en "+I2S(this)+"|r");
            t=null;
            return this;
        }
    }
}
//! endzinc