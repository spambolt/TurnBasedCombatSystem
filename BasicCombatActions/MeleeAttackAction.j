//! zinc
library MeleeAttackAction requires BasicCombatActions
{

        private constant real VELOCITY = 35.0;
        
        /*
        *
        *   por hacer - Analizar grilla frontal para evitar que se pueda atacar a las unidades de atrás
        *
        */
        public struct MelleAttack extends BaseAttack//[]
        {
            //module Alloc;
            integer ticks;
            
            boolean isReturning;
            boolean attackEnded;

            private method destroy()
            {
                this.deallocate();
            }
            
            private method damage()
            {
                real dmg = ExtraData(GetUnitId(this.caster)).damage;
                //hacer daño
                //UnitDamageTarget(this.caster ,this.target , 100 , true , false , ATTACK_TYPE_HERO , DAMAGE_TYPE_NORMAL , WEAPON_TYPE_METAL_HEAVY_BASH); //temporal
                if(Damage_Pure( this.caster, this.target  , dmg ))
                {
                    DestroyEffect(AddSpecialEffectTarget( BLOOD_FX , this.target , "origin"));
                    BJDebugMsg(GetUnitName(this.caster) + " ha atacado a "+GetUnitName(this.target)+" inflingiendo "+ I2S(R2I(dmg)) +" de daño.");
                    this.showDamageInfo(dmg);
                }
                    
            }
            
            //periodic function
            private static method move() -> boolean
            {
                boolean flag = true;
                timer t = GetExpiredTimer();
                thistype this = GetTimerData(t);
                //avanza
                if(this.ticks > 0 && !this.isReturning)
                {
                    this.cx = this.cx+VELOCITY*Cos(a);
                    this.cy = this.cy+VELOCITY*Sin(a);
                    
                    SetUnitX(this.caster , this.cx);
                    SetUnitY(this.caster , this.cy);
                    
                    
                    if(this.ticks == 1)
                    {
                        //poner animacion de ataque
                        SetUnitAnimation(this.caster,"attack");
                        //dañar unidad objetivo
                        this.ticks = 15;//ticks de espera
                        this.isReturning = true;
                    }
                    
                    this.ticks -= 1;
                    return false;
                }
                
                if(this.ticks > 0 && !this.attackEnded && this.isReturning)
                {
                    //cambiar el estado de ataque
                    
                    if(this.ticks == 1)
                    {
                        this.damage();
                        this.attackEnded = true;
                        //cambiar la direccion
                        this.a -= bj_PI;
                        this.ticks = R2I((this.distance-100)/VELOCITY); // recalcular ticks de regreso
                        //this.isReturning = true;
                    }
                    this.ticks -=1;
                    return false;
                }
                
                else if(this.ticks > 0 && this.isReturning && this.attackEnded)
                {
                    this.cx = this.cx+VELOCITY*Cos(a);
                    this.cy = this.cy+VELOCITY*Sin(a);
                    
                    SetUnitX(this.caster , this.cx);
                    SetUnitY(this.caster , this.cy);
                
                    //flag = false;
                    if(this.ticks == 1)
                    {
                        //ending spell
                        ReleaseTimer(t);
                        this.combatControl.onActionEnd();
                        
                        //restablecer valores de la unidad ...
                        SetUnitX(this.caster ,this.oX);
                        SetUnitY(this.caster ,this.oY);
                        SetUnitFacing(this.caster ,this.facing);
                        this.destroy();
                    }
                        
                    this.ticks -=1;
                }
                t=null;
                
                return flag;
            }
            
            public static method create(unit tar , unit cast , CombatControl cc)->thistype
            {
                thistype this = thistype.allocate();
                timer t = NewTimer();

                this.combatControl = cc; //es la unica asignacion necesaria para la clase base... 
                this.getData();  // llama el metodo desde la clase base
                this.ticks = R2I( (this.distance-100)/VELOCITY); 
                
                this.isReturning = false;
                this.attackEnded = false;
                //PauseUnit(this.caster , true);
                cancelCurrentOrder(this.caster);
                PauseUnit(this.caster, true);
                //SetUnitAnimation(this.caster , "walk");

                this.combatControl.onActionStart();
                SetTimerData(t, this);
                TimerStart(t,GAME_PERIOD,true, function thistype.move );
                t=null;
                return this;
            }
        }

    
}
//! endzinc