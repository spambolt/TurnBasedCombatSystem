//! zinc
library RangedAttackAction requires BasicCombatActions
{
    
    /*
    *  Ataque a distancia de la unidad
    *
    */
    private constant real MISILE_VELOCITY = 55.0;
    private constant real ELEVATION_ANGLE = Tan(30*bj_DEGTORAD);
    
    
    public struct RangedAttack extends BaseAttack
    {
        integer ticks;
        xefx missile;
        

        private method damage()
        {
            real dmg = ExtraData(GetUnitId(this.caster)).damage;
            //hacer daño
            //UnitDamageTarget(this.caster ,this.target , 100 , true , false , ATTACK_TYPE_HERO , DAMAGE_TYPE_NORMAL , WEAPON_TYPE_METAL_HEAVY_BASH); //temporal
            if(Damage_Pure( this.caster, this.target  , dmg ))
            {
                DestroyEffect(AddSpecialEffectTarget( BLOOD_FX , this.target , "origin"));
                //BJDebugMsg(GetUnitName(this.caster) + " ha atacado a "+GetUnitName(this.target)+" inflingiendo "+ I2S(R2I(dmg)) +" de daño.");
                this.showDamageInfo(dmg);
            }
                
        }
        
        //falta implementar el calculo de la orientacion del misil
        private  static method move()
        {
            boolean flag = true;
            timer t = GetExpiredTimer();
            thistype this = GetTimerData(t);
            
            real x = this.missile.x+MISILE_VELOCITY*Cos(this.a);
            real y = this.missile.y+MISILE_VELOCITY*Sin(this.a);

            real d = DistanceXY(x , y , this.tx , this.ty);
            real z =  ParabolaZ( ELEVATION_ANGLE*this.distance/2 , this.distance, d);
            
            
            if(this.ticks > 0)
            {
                this.missile.x = this.missile.x+MISILE_VELOCITY*Cos(this.missile.f);
                this.missile.y = this.missile.y+MISILE_VELOCITY*Sin(this.missile.f);
                this.missile.z = z;
                
                this.ticks -= 1;
            }
            else
            {
                this.damage();
                this.missile.destroy();
                ReleaseTimer(t);
                this.combatControl.onActionEnd();
                this.destroy();
            }
                

            t= null;
        }
        
        public static method create(unit tar , unit cast , CombatControl cc)->thistype
        {
            thistype this = thistype.allocate();
            timer t = NewTimer();
            real f = 0.0;

            this.combatControl = cc; //es la unica asignacion necesaria para la clase base... 
            this.getData();  // llama el metodo desde la clase base
            this.distance -= 60.0;
            this.ticks = R2I( (this.distance)/MISILE_VELOCITY); 

            cancelCurrentOrder(this.caster);
            PauseUnit(this.caster, true);
            
            this.missile = xefx.create(this.cx+60.0*Cos(this.a) , this.cy+60.0*Sin(this.a) , this.a);
            this.missile.fxpath = "Abilities\\Weapons\\Arrow\\ArrowMissile.mdx";//deberia cargarlo de los datos de la unidad lanzadora
            this.missile.z = 80.0;

            this.combatControl.onActionStart(); //notifica inicio de accion para detener temporizador de abandono de turno
            
            SetTimerData(t, this);
            TimerStart(t,GAME_PERIOD,true, function thistype.move );
            BJDebugMsg("Lanzando iunstancia de ataque de rango");
            t=null;
            return this;
        }
    }
}
//! endzinc