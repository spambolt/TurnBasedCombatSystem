//! zinc
//Funciones de esta libreria
/*   Struct Arena
*       
*
*    Objetos de Esta Librería
*           Struct -> Arena (controla la disposicion  y asignaciònde las arenas de combate)
*
*           Struct -> Combat  (controla los estados de los jugadores y los lideres de grupo implicados en el combate , acciones de control de cámara)  
*                       - tiene a su cargo la inicialización de todo el sistema (arena y combat control)
*           Struct -> CombatControl (Captura y controla los  eventos dentro del combate ,la asignacion de los turnos , y las reglas del combate)
*
*
*/          
library CombatSystem 
    requires 
        TimerUtils , 
        ListClass , 
        CombatBehavior , 
        Utils , 
        BasicCombatActions , 
        Damage
{

     rect arena [];
     
     //constants
     real ARENA_WIDTH = 1000.0;
     real ARENA_HEIGHT = 800.0;
     real SEPARATION   = 200.0;
     
     real WAIT_FOR_ACTION = 8.0; //tiempo que espera el temporizador antes de pasar el turno
     real WAIT_FOR_FILTER = 1.1; // pequeño tiempo de espera antes de finalizar el combate
     real WAIT_FOR_ENDING = 1.1; // pequeño tiempo de espera antes de finalizar el combate
     string FX_PATH_START_TURN = "Abilities\\Spells\\Other\\Aneu\\AneuCaster.mdl";
 
    

    public type combatGrid extends real[24];
 
     struct Arena extends array
     {
          private static integer list=0;
          private static thistype stack[];
          private static thistype recycler[];
          private static integer listRecycler=0;
          
          
          private boolean isWorking;
          rect arenas;
          combatGrid dataPoints;
          real xa;
          real ya;
          real xb;
          real yb;
          real cX;
          real cY;
          
          static method assign() ->thistype
          {
           thistype this =0;
           // BJDebugMsg("assigning arena");
            if(thistype.list < 10){
                if(thistype.listRecycler == 0){
                 thistype.list +=1;
                 thistype.stack[thistype.list]=thistype.list;
                 this = thistype.list;
                 }
                 else{
                 thistype.list +=1;
                 thistype.stack[thistype.list]=thistype.recycler[thistype.listRecycler];
                 thistype.listRecycler -=1;
                 this = thistype.stack[thistype.list];
                 }
             
             this.arenas = arena[this];
             
             this.xa= GetRectCenterX(this.arenas)-500;
             this.ya= GetRectCenterY(this.arenas);
             this.xb= GetRectCenterX(this.arenas)+500;
             this.yb=this.ya;
             this.cX=GetRectCenterX(this.arenas);
             this.cY=GetRectCenterY(this.arenas);
             this.isWorking=true;
             
             this.dataPoints.create();
             this.CombatGrid();

            }
            
            
             return this;
           }
           
           
           method forExit()
           {
            this.arenas=null;
            this.isWorking=false;
            this.dataPoints.destroy();
            thistype.listRecycler +=1;
            thistype.recycler[thistype.listRecycler]=this;
            thistype.list -= 1;
           
           }
           
           //grilla de combate

            
         method CombatGrid()
         {
            integer i =0;
            integer j =0;
            integer n =0;
            
            real stepX = 0 ;
            real stepY = 0 ;
            
            real originX = GetRectCenterX(this.arenas)-256.0;
            real originY = GetRectCenterY(this.arenas)+180.0;
            
            //12 pares de puntos almacenados correlativamente 
            //lado A
            while(i<3)
            {
                while(j<2)
                {
                    this.dataPoints[n] = originX +stepX;
                    this.dataPoints[n+1] = originY +stepY;
                    
                   // CreateDestructable('FTtw' , this.dataPoints[n], this.dataPoints[n+1], 0.0 , 1 , 0 );
                   // BJDebugMsg("placing X = "+R2S(this.dataPoints[n])+" Placement Y = "+R2S(this.dataPoints[n+1]));
                    stepX -=128.0;
                    n += 2;
                    j +=1;
                }                                                                                                                                                                              
                i +=1;
                j = 0;
                stepY -= 256.00;
                stepX = 0.0;
            }
            
            //lado b
            stepX = 0 ;
            stepY = 0 ;
            i =0;
            j =0;
            originX = GetRectCenterX(this.arenas)+256.0;
            //originY = GetRectCenterY(this.arenas)+128.0;
            
            while(i<3)
            {
                while(j<2)
                {
                    this.dataPoints[n] = originX +stepX;
                    this.dataPoints[n+1] = originY +stepY;
                    
                    //CreateDestructable('FTtw' , this.dataPoints[n], this.dataPoints[n+1], 0.0 , 1 , 0 );
                   // BJDebugMsg("placing X = "+R2S(this.dataPoints[n])+" Placement Y = "+R2S(this.dataPoints[n+1]));
                    stepX +=128.0;
                    n += 2;
                    j +=1;
                }
                i +=1;
                j = 0;
                stepY -= 256.00;
                stepX = 0.0;
            }
            
         }
         
     }
     
     

     /*
     *     maneja el emplazamiento de la arena y la inicializacion de y finalizacion del combate
     *
     *
     */

     Combat TEMP_COMBAT; //utilizado para pasar valores
     
     public struct Combat []
     {
       player pA;
       player pB;
       Arena ar;
       unit uA; //party Leader A
       unit uB; //party leader B
       real aPosX , aPosY , bPosX , bPosY;
       fogmodifier fogModA;
       fogmodifier fogModB;
       
       UnitList unitList; //esta siendo destruido en la instancia de combatControl ...
       CombatControl combatControl;
       
    
          private method sortByInitiative()
          {
                integer i,j;
                unit curr , next;
                for(i=0 ; i < this.unitList.getSize()  ; i+=1)
                {
                    curr = this.unitList.get(i);
                    
                    for(j=0 ; j < this.unitList.getSize() ; j +=1)
                    {
                        next = this.unitList.get(j); 
                        //tratar de insertar i en el slot que le corresponda
                        if(ExtraData(GetUnitId(curr)).initiative < ExtraData(GetUnitId(next)).initiative)
                        {
                            //si es mayor intercambiar posiciones
                            this.unitList.members[j] = curr;
                            this.unitList.members[i] = next;
                            break;
                        }
                    }
                }
                curr = null;
                next = null;
          }
          
          public method endingCombatActions()
          {
                
                //guardar party
                Party.get(this.uA).hideAllMembers();
                Party.get(this.uB).hideAllMembers();
                
                //desbloquear camara
                cameraReset(this.pA);
                cameraReset(this.pB);
                //poner liders a su posicion original
                //mostrar lideres
                //AGREGAR LIDIAR CON LIDER MUERTO EN batalla mostrar avatar alternativo o tumba si murió
                showUnit( this.uA , this.aPosX , this.aPosY);
                showUnit( this.uB , this.bPosX , this.bPosY);
                
                // poner cámara en el lider
                setCameraTo(this.pA , this.aPosX , this.aPosY);
                setCameraTo(this.pB , this.bPosX , this.bPosY);
                //destruir todo
                
                this.ar.forExit(); // libera la arena 
                
                //destruir el combatControl
                if (GetLocalPlayer() == this.pA)
                {
                    // call CinematicFilterGenericBJ( 1.00, BLEND_MODE_BLEND, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0.00, 0.00, 0.00, 0.00, 100.00, 100.00, 100.00, 100.00 )
                    CinematicFilterGenericBJ(WAIT_FOR_FILTER, BLEND_MODE_BLEND, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0.00, 0.00, 0.00, 0.00, 100.00, 100.00, 100.00, 100.00 );
                }
                
                if (GetLocalPlayer() == this.pB)
                {
                    // call CinematicFilterGenericBJ( 1.00, BLEND_MODE_BLEND, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0.00, 0.00, 0.00, 0.00, 100.00, 100.00, 100.00, 100.00 )
                    CinematicFilterGenericBJ( WAIT_FOR_FILTER, BLEND_MODE_BLEND, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0.00, 0.00, 0.00, 0.00, 100.00, 100.00, 100.00, 100.00 );
                }
                
                //activar la capacidad de las unidades lider para la batalla
                ExtraData.get(this.uA).isOnCombat = false;
                ExtraData.get(this.uB).isOnCombat = false;
                
                //this.combatControl.destroy();
                //this.destroy();
          }
          
          private method startingCombatActions()
          {
            if (GetLocalPlayer() == this.pA)
            {
                // call CinematicFilterGenericBJ( 1.00, BLEND_MODE_BLEND, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0.00, 0.00, 0.00, 0.00, 100.00, 100.00, 100.00, 100.00 )
                CinematicFilterGenericBJ(WAIT_FOR_FILTER, BLEND_MODE_BLEND, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0.00, 0.00, 0.00, 0.00, 100.00, 100.00, 100.00, 100.00 );
            }
            
            if (GetLocalPlayer() == this.pB)
            {
                // call CinematicFilterGenericBJ( 1.00, BLEND_MODE_BLEND, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0.00, 0.00, 0.00, 0.00, 100.00, 100.00, 100.00, 100.00 )
                CinematicFilterGenericBJ( WAIT_FOR_FILTER, BLEND_MODE_BLEND, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0.00, 0.00, 0.00, 0.00, 100.00, 100.00, 100.00, 100.00 );
            }
            cameraLock(this.pA,this.ar.cX,this.ar.cY,true);
            cameraLock(this.pB,this.ar.cX,this.ar.cY,true);
            //leer la formacion del party del lider
            //emplazar las unidades de acuerdo a su posicion en el party
            //cambiar el estado de las unidades
            Party(GetUnitId(this.uA)).placeAllMembers( this.ar.dataPoints,true);
            Party(GetUnitId(this.uB)).placeAllMembers( this.ar.dataPoints,false);
            //registrar las unidades en el Combat Control

            //ordenar de acuerdo a su indice de iniciativa
            this.unitList = UnitList.create();
            TEMP_COMBAT = this;
            
            //Agrega las unidades del lider B
            ForGroup(Party(GetUnitId(this.uB)).members , function()
            {
                if( GetEnumUnit() != null &&  GetUnitState(GetEnumUnit() , UNIT_STATE_LIFE)> 0.0 )
                    TEMP_COMBAT.unitList.add( GetEnumUnit());
                
            });
            
            //agrega las unidades del lider A
            ForGroup(Party(GetUnitId(this.uA)).members , function()
            {
                if(GetEnumUnit() != null  &&  GetUnitState(GetEnumUnit() , UNIT_STATE_LIFE)> 0.0)
                    TEMP_COMBAT.unitList.add(GetEnumUnit());
            });
            
            
            TEMP_COMBAT = 0;
            
            //this.unitList.listAllUnits(); //helper temporal XD
            
            //this.sortByInitiative();
            //BJDebugMsg("|cffffAnalizadas y supuestamente ordenadas por iniciativa|r");
            //this.unitList.listAllUnits(); //helper temporal XD
            

            //this.SortUnitsByInitiative();
            //Iniciar el CombatControl y pasarle la ejecución
            this.combatControl.create(this ,this.unitList  ,  Party.get(this.uA) , Party.get(this.uB) );
            
            //this.combatControl.partySideA = Party.get(this.uA);   ------->> bug raro no le llega a pasar los valores a la instancia
           //this.combatControl.partySideB = Party.get(this.uB);
            BJDebugMsg("Valores de Conjunto " +I2S(Party.get(this.uA)) +" , "+I2S(Party.get(this.uB)));

          }
        

         
           static method start(unit a,unit b) -> thistype
           {
             thistype this = GetPlayerId(GetOwningPlayer(a));// el player a siempre tiene el combat mode
             
             // que a y b no esten en combate 
             if( !ExtraData(GetUnitId(a)).isOnCombat && !ExtraData(GetUnitId(b)).isOnCombat)
             {
                 this.uA=a;
                 this.uB=b;
                 this.pA=GetOwningPlayer(a);
                 this.pB=GetOwningPlayer(b);
                 this.ar = Arena.assign();
                 this.aPosX=GetUnitX(a); this.aPosY=GetUnitY(a);
                 this.bPosX=GetUnitX(b); this.bPosY=GetUnitY(b);
                 this.startingCombatActions();

                 this.fogModA = CreateFogModifierRect(this.pA, FOG_OF_WAR_VISIBLE , this.ar.arenas , false , true);
                 this.fogModB = CreateFogModifierRect(this.pB, FOG_OF_WAR_VISIBLE , this.ar.arenas , false , true);
                 FogModifierStart(this.fogModA);
                 FogModifierStart(this.fogModB);
                 
                 //cambiar a estado de combate
                 ExtraData(GetUnitId(a)).isOnCombat = true;
                 ExtraData(GetUnitId(b)).isOnCombat = true;
             }
             return this;
           }
           
          method destroy()
          {
               // this.deallocate();
                
          
          }
     
     
     }  
     
     //funciones
     /*
     *
     *    esta clase maneja los eventos de combate y todas las acciones que se dan detro del combate ... 
     *    cada accion en el combate debe ser registrada para cada unidad
     *
     */
     public struct CombatControl[]
     {
         module Alloc;
         Combat combat; // referencia al objeto combate
         UnitList combatGroup;
         UnitList procesingCombatGroup;
         timer waitingForAction; //temporizador que debera ser destruido si la unidad ya ha ejecutado accion alguna
         boolean turnExpired; // indica si el turno termino sin acciones o con ellas
         effect turnEffect;
         integer turnCounter;
         
         boolean isAIParty;
         player AIOwner;
         
         // acciones ...
         trigger combatBehaviorTrigger; //asociar a este detonador cualquier evento de combate
         
         public Party partySideA;
         public Party partySideB;
         
         public static method create(Combat refCombat , UnitList cg , Party partya , Party partyb) -> thistype
         {
            thistype this = thistype.allocate();
            
            this.combat = refCombat;
            this.combatGroup = cg; //le pasamos la misma referencia (queda como grupo de respaldo)
            this.partySideA = partya;
            this.partySideB = partyb;
            
            //
            if(this.partySideA.isAIParty || this.partySideB.isAIParty)
            {
                if(this.partySideA.isAIParty)
                    this.AIOwner = GetOwningPlayer(this.partySideA.leader);
                else
                    this.AIOwner = GetOwningPlayer(this.partySideB.leader);
                    
                this.isAIParty = true;
                BJDebugMsg("Tomando Accion contra party AI");
            }
            else
                this.isAIParty = false;
            
            this.procesingCombatGroup = cg.clone(); // clonamos a un nuevo grupo
            
            BJDebugMsg("|cffff0000Desde el grupo de control");
            //this.combatGroup.listAllUnits();
            //registra todas las unidades al detonador de combate que escucha los eventos de batalla...
            this.registerAnyCombatBehavior();

            //asocia las unidades con los detonadores
            this.fetchUnits();
            
            //inicia pelea ...
            this.turnCounter = 0;
            this.unitStartTurn();
            return this;
         }
         
         //verificar eventos de derrota total ... 
         private method combatEnded() -> boolean
         {
            boolean flag = false;

            if(this.partySideA.isAllPartyDefeated())
            {
                BJDebugMsg("Pierde Party A");
                flag = true;
            }
            else if(this.partySideB.isAllPartyDefeated())
            {
                BJDebugMsg("Pierde Party B");
                flag = true;
            }
            return flag;
         }
         //codigo ejecutado cuando el temporizador alcanza 0... y no han habido acciones
         public method onTimerEnd()
         {
            this.unitEndTurn();
            this.turnExpired = true;
         }
         
         public method onActionStart()
         {
            //PauseTimer(this.waitingForAction);
            BJDebugMsg("Action started timer released");
            ReleaseTimer(this.waitingForAction);
         }
         
         public method onActionEnd()
         {
            BJDebugMsg("Action ended");
            this.unitEndTurn();
         }
         
         private method unitEndTurn()
         {
            unit u = this.combatGroup.get(0); //toma la primera unidad de la lista
            DestroyEffect(this.turnEffect);
            
            //BJDebugMsg("|cffff0000Finaliza turno de "+GetUnitName(u));
            if(GetUnitState(u, UNIT_STATE_LIFE) > 0.0403 )
            {
                PauseUnit(u,true);
                this.combatGroup.add(u);
            }
            
            this.combatGroup.removeIndex(0); //quita la unidad ya procesada
            //siguiente unidad
            this.unitStartTurn();
            
            u = null;
         }
         
         //corre despues de un pequeño tiempo transcurrido ...
         private method finalCombatActions()
         {
             this.combat.endingCombatActions();
             this.destroy();
         }
         
         private method unitStartTurn()
         {
            unit u = this.combatGroup.get(0); //toma la primera unidad de la lista
            timer t = null;
            TurnBasedAction.OnTurnCheck(u); //debe verificar si la unidad tiene acciones pendientes de turno
            
            if(!this.combatEnded()) //verifica si alguno de los 2 equipos ha sido abatido ...
            {
                
                 PauseUnit(u,false);//descongela unidad
                //BJDebugMsg("|cff00ff00Inicia turno de "+GetUnitName(u));
                this.turnCounter +=1;
                //DisplayTimedTextToPlayer(Player(0) , 0.0 , 0.0 , 0.1,"|cffffcc00Turno Numero"+I2S(this.turnCounter)+"|r");
                this.turnEffect = AddSpecialEffectTarget(FX_PATH_START_TURN, u,"overhead");
                //obtiene el temporizador que espera
                this.waitingForAction = NewTimer();
                SetTimerData(this.waitingForAction , this); //asociamos esta instancia al timer
                //inicia timer
                TimerStart(this.waitingForAction , WAIT_FOR_ACTION , false , function()
                    {
                        timer t = GetExpiredTimer();
                        thistype instance = GetTimerData(t);
                        //esto se ejecuta si el temporizador llega al final de la cuenta
                        instance.onTimerEnd();
                        
                        ReleaseTimer(t);
                        t= null;
                    }) ; 
                
                //acciones para party manejado por pc
                if(this.isAIParty)
                {
                    if( GetOwningPlayer(u) == this.AIOwner)
                    {
                        BJDebugMsg("Analizando acciones de unidad AI");
                        AIAction.ParseDecision(this.combatGroup , u);
                    }
                }
                
            }
            else
            {
                t = NewTimer();
                SetTimerData(t , this);
                
                TimerStart(t , WAIT_FOR_ENDING , false ,function()
                {
                    timer t = GetExpiredTimer();
                    thistype instance = GetTimerData(t);
                    
                    instance.finalCombatActions();
                    
                    ReleaseTimer(t);
                    t=null;
                });

                t = null;
            }
            u = null;
         }
         
         //asocia las unidades de combate con los detonadores necesarios debe ser llamada luego de crear los detonadores
         private method fetchUnits()
         {
            integer i;
            unit u; 
            
            for(i=0 ; i < this.combatGroup.getSize() ; i+=1)
            {
                u = this.combatGroup.get(i);
                
                TriggerRegisterUnitEvent(this.combatBehaviorTrigger, u , EVENT_UNIT_SPELL_EFFECT);
                TriggerRegisterUnitEvent(this.combatBehaviorTrigger, u , EVENT_UNIT_DEATH); //asociar a un evento de unidad que muere
            }
            
            u=null;
         }
         
         private method registerAnyCombatBehavior()
         {
            unit u;
            
            if(this.combatBehaviorTrigger != null)
            {
                TriggerAddCondition(this.combatBehaviorTrigger , Condition(function()->boolean
                    {
                        trigger t = GetTriggeringTrigger();
                        thistype instance = GetTriggerData(t);
                        unit target = GetSpellTargetUnit();
                        unit caster = GetTriggerUnit();
                        integer spellId = GetSpellAbilityId();
                       // BJDebugMsg("analizando condicion"+GetUnitName(caster)+GetUnitName(target));
                        if(spellId == ATTACK_ACTION)
                        {
                            instance.onAttack( target , caster);
                          //  BJDebugMsg("Lanzando instancia de ataque");
                        }
                        else if(spellId == RANGED_ATTACK_ACTION)
                        {
                            instance.onRangedAttack( target , caster);
                          //  BJDebugMsg("Lanzando instancia de ataque");
                        }
                        else if(spellId == DEFEND_ACTION)
                        {
                            instance.onDefend(caster);
                           // BJDebugMsg("Lanzando instancia de defensa");
                        }
                        else if(spellId == 0 && GetDyingUnit() != null && target == null)
                        {
                            instance.onDeath(caster); //corre cuando una unidad registrada muere
                        }
                        
                        t=null;
                        target = null;
                        caster = null;
                        
                        return false;
                    }));
            }
            else
            {
                this.combatBehaviorTrigger = CreateTrigger();
                SetTriggerData(this.combatBehaviorTrigger , this);
                this.registerAnyCombatBehavior();
            }
            
            u = null;
         }
         

         private method releaseAllUnitsPendingActions()
         {
            integer i;
            unit u=null;
            
            for(i=0 ; i < this.combatGroup.getSize() ; i+=1 )
            {
                u = this.combatGroup.get(i);
                TurnBasedAction.EndAllUnitPendingActions(u);
            }
         }
   
         ////
        method onAttack(unit target , unit caster)
        {
            //faltaria analizar si puede o no atacar a esta unidad entre otras cosas
            MelleAttack.create(target , caster , this); //nota personal diseñar para que acepte cada tipo de ataque ... segun la unidad
            //BJDebugMsg("Atacado...");
        }
        
        method onRangedAttack(unit target , unit caster)
        {
            RangedAttack.create(target , caster , this);
        }
        
        //Combat Events Events
        method onDeath(unit u)
        {
          //acciones al morir entidad
          //retirar la unidad del grupo de combate?? (y si la reviven?) - R-> las vuelves a agregar no?
          this.combatGroup.remove(u);
          
          TurnBasedAction.EndAllUnitPendingActions(u);//remover acciones basadas en turnos pendientes
         // BJDebugMsg("|cffff00acLiberando "+GetUnitName(u));
          //BJDebugMsg("Unidad removida del combate");
       }
       
       method onDefend(unit uCast)
       {
            Defend.create(uCast, this);
       }
       
       public method  destroy()
       {
            //limpiar y destruir detonadores
            TriggerClearConditions(this.combatBehaviorTrigger);
            DestroyTrigger(this.combatBehaviorTrigger);
            
            //libera las acciones pendientes de todas las unidades 
            this.releaseAllUnitsPendingActions();

            //liberar listas utilizadas
            this.combatGroup.destroy();
            this.procesingCombatGroup.destroy();
            
            this.combatBehaviorTrigger = null;
            this.deallocate();
            BJDebugMsg("instancia combat control "+I2S(this)+" destruida..." );
        
       }
     }
     
     
     function createArenaRect(){
        real width = ARENA_WIDTH;
        real height= ARENA_HEIGHT;
        
        real sepX=200.0;
        real sepY=200.0;
        
        real mx =0.0, Mx =0.0;
        real my =0.0, My =0.0;
        
        integer i = 0 ,j=0, n =1;
        //punto inicial para configurar los rectangulos
        real originX = GetRectMaxX(bj_mapInitialPlayableArea)-100.0;
        real originY = GetRectMaxY(bj_mapInitialPlayableArea)-100.0;
        
        while(i <= 1)
        {
            
            while(j <= 5)
            {
                arena[n] = Rect(originX-width , originY-height ,originX,originY);
                /*CreateDestructable('FTtw' ,GetRectCenterX(arena[n])-(width/2) , GetRectCenterY(arena[n])+(height/2),0.0,1.0,0);
                CreateDestructable('FTtw' ,GetRectCenterX(arena[n])-(width/2) , GetRectCenterY(arena[n])-(height/2),0.0,1.0,0);
                CreateDestructable('FTtw' ,GetRectCenterX(arena[n])+(width/2) , GetRectCenterY(arena[n])+(height/2),0.0,1.0,0);
                CreateDestructable('FTtw' ,GetRectCenterX(arena[n])+(width/2) , GetRectCenterY(arena[n])-(height/2),0.0,1.0,0);*/
                originY -= (height+SEPARATION);
                j +=1;
                n +=1;
            }
            
            originX -= (width+SEPARATION);
            originY = GetRectMaxY(bj_mapInitialPlayableArea)-100.0;
            j=0;
            i+=1;
        }
        
     }

     
     
     function onInit()
     {
          createArenaRect();
     }


}
//! endzinc