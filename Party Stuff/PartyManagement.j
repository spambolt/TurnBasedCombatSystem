//! zinc

// this library allows the party leader to select all members in party combat's position
//
//
library PartyManagement requires AutoIndex
{
    constant integer ABIL_ID = 'A000';
    constant integer CANCEL_ABIL_ID = 'A001';
    constant integer SAVE_CHANGES_ABIL_ID = 'A004';
    constant integer DUMMY_ID = 'e000';
    
    
    
    //one instance for each player
    // funtions:
    /**
        - Load Leader Data
        - Load Members Data
        - Save the Asigned Position
        - lock the UI during process duration
    */

    unit TEMP_DUMMY;
    PartyManager TEMP_PARTY_MANAGER;
    
    
    
    //clase MPI -> carga los datos del party temporalmente al gestor de party
    struct Portrait[]{
        static integer PORTRAIT_ID[];
        static integer UNIT_OWNER_ID[];
        
        integer index;
        
        method push(integer item_id)
        {
            integer stepIndex = this*6; //step per player
            integer realIndex = stepIndex+this.index;
            thistype.PORTRAIT_ID[realIndex] = item_id;
            this.index += 1;
        }
        
        method pushByPlace(integer item_id , integer place , integer unit_owner_Id)
        {
            integer stepIndex = this*6; //step per player
            integer realIndex = stepIndex+place;
            thistype.PORTRAIT_ID[realIndex] = item_id;
            thistype.UNIT_OWNER_ID[realIndex] = unit_owner_Id;
        }
        
        method getItemIdByIndex(integer index) -> integer
        {
            integer stepIndex = this*6; //step per player
            integer res = 0;
            if(index <=5 )
                res = thistype.PORTRAIT_ID[stepIndex+index];
            else
                BJDebugMsg("Error , el rango del index debe estar entre 0 y 5");
            return  res;
        }
        
        method getItemOwnerIdByIndex(integer index) -> integer
        {
            integer stepIndex = this*6; //step per player
            integer res = 0;
            if(index <=5 )
                res = thistype.UNIT_OWNER_ID[stepIndex+index];
            else
                BJDebugMsg("Error , el rango del index debe estar entre 0 y 5");
            return  res;
        }
        
        method clear()
        {
            integer stepIndex = this*6; //step per player
            integer max = stepIndex+5;
            while(stepIndex <= max)
            {
                thistype.PORTRAIT_ID[stepIndex] = -1;
                stepIndex += 1;
            }
            this.index = 0;
        }
    
    }
    
    
    // Miembro MPI -> carga los datos del party temporalmente mediante la unidad dummy de gestion 
    //
    //
    struct PartyManager extends array
    {
        unit dummy;
        boolean open;
        unit uL ; //referencia al lider que  llamo al inventario
        Party party;
        
        static integer PORTRAIT_ID[];
        
        method start(unit u)
        {
            this.party = Party(GetUnitId(u));
            this.uL = u; //de -> "unit leader"
            this.open = true;
            //crear o mostrar el dummy de gestión
            if(this.dummy == null)
            {
                this.dummy = CreateUnit(Player(this), DUMMY_ID , GetUnitX(u), GetUnitY(u),0);
            }
            else
            {
                showUnit(this.dummy, GetUnitX(u), GetUnitY(u));
            }
            
            if(Player(this) == GetLocalPlayer())
            {
                ClearSelection();
                SelectUnit(this.dummy,true);
                SetCameraTargetController(this.dummy, 0.0, 0.0, true);
            }
            
            this.loadPartyData();
            
        }
        
        //cargar data desde el lider
        method loadPartyData()
        {
            integer i = 0;
            integer uId =0; //unit Id
            unit u = null;
            item pItem = null;
            uId = GetUnitId(this.uL);
            //
            if(this.dummy != null)
            {
                TEMP_DUMMY = this.dummy;
                TEMP_PARTY_MANAGER = this;
            }
            ForGroup(Party(uId).members, function()
             {
                PartyManager tempInstance = TEMP_PARTY_MANAGER; //para tomar la instancia MPI de cada jugador
                unit enum = GetEnumUnit();
                integer uId = GetUnitId(enum);
                integer itId = 0; // item Id
                integer pos = 0;
                
                if(enum != null)
                {
                    itId = ExtraData(uId).itemPortraitId;
                    pos = ExtraData(uId).combatPosition;
                    Portrait(tempInstance).pushByPlace(itId , pos , uId);
                }

                TEMP_DUMMY = null;
                enum = null;
               
             });
             //
           
            while(i <= 5){
            
                if( UnitAddItemToSlotById(this.dummy , Portrait(this).getItemIdByIndex(i),i))
                {
                    pItem = UnitItemInSlot(this.dummy , i );
                    SetItemUserData(pItem, Portrait(this).getItemOwnerIdByIndex(i));
                }
                i+=1;
            }
            
            Portrait(this).clear();
            
        }
        
        method saveCombatPositions()
        {
            integer i = 0;
            item it = null;
            integer uId = 0;
            while(i <= 5)
            {
                it = UnitItemInSlot(this.dummy , i );
                if( it != null)
                {
                    uId = GetItemUserData(it);
                    ExtraData(uId).combatPosition = i;
                }
                i+=1;
           }
        }
        
        //formas de salir
        /*
         - boton de salida
         - presionar esc
         - Seleccionar otra unidad
        */
        
        method clearSlots()
        {
            integer i = 0;
            while(i < 6)
            {
                RemoveItem(UnitRemoveItemFromSlot(this.dummy,i));
                i+=1;
            }
        }
        
        
        method onClose()
        {
            if(Player(this) == GetLocalPlayer())
            {
                ClearSelection();
                SelectUnit(this.uL,true);
                ResetToGameCamera(0.0);
            }
            this.clearSlots();
            hideUnit(this.dummy);
            this.open = false;
        }
    }
    
    
    
    
    
    function startManager()
    {
        integer playerId = GetPlayerId(GetOwningPlayer(GetTriggerUnit()));
        if(!PartyManager(playerId).open)
        {
            PartyManager(playerId).start(GetTriggerUnit());
        } 
    }
    
    function onInit()
    {
        trigger t =  CreateTrigger();
        trigger t2 = CreateTrigger();
        trigger t3 = CreateTrigger();
        trigger t4 = CreateTrigger();
        trigger t5 = CreateTrigger();
        
        integer i = 0;
        


        
        while( i < bj_MAX_PLAYER_SLOTS)
        {
            if(GetPlayerSlotState(Player(i)) == PLAYER_SLOT_STATE_PLAYING)
            {
                TriggerRegisterPlayerUnitEvent(t, Player(i), EVENT_PLAYER_UNIT_SPELL_EFFECT, null);
                TriggerRegisterPlayerEvent(t2, Player(i), EVENT_PLAYER_END_CINEMATIC);
                TriggerRegisterPlayerUnitEvent(t3, Player(i), EVENT_PLAYER_UNIT_SELECTED, null);
                TriggerRegisterPlayerUnitEvent(t4, Player(i), EVENT_PLAYER_UNIT_SPELL_EFFECT, null);
                TriggerRegisterPlayerUnitEvent(t5, Player(i), EVENT_PLAYER_UNIT_SPELL_EFFECT, null);
            }
            
            
            i += 1;
        }

        //para lanzar habilidad de mostrar dummy
        TriggerAddCondition(t, Condition(function ()-> boolean {return GetSpellAbilityId() == ABIL_ID;}));
        //lanzar el gestor de grupo
        TriggerAddAction(t , function startManager);
        //para recibir esc presionado y cerrar el dummy de gestión
        TriggerAddAction(t2, function ()
        { 
            integer id = GetPlayerId(GetTriggerPlayer());
            if(PartyManager(id).open)
            {
                PartyManager(id).onClose();
            }
        });
        //para cerrar al deseleccionar el dummy
        TriggerAddAction(t3 , function ()
        { 
            integer id = GetPlayerId(GetOwningPlayer(GetTriggerUnit()));
            
            if(PartyManager(id).open && GetTriggerUnit() != PartyManager(id).dummy)
            {
                PartyManager(id).onClose();
            }
            
        });
        //para cerrar el dummy de gestion mediante habilidad cerrar previamente asignada al dummy
        TriggerAddCondition(t4, Condition(function ()-> boolean {return GetSpellAbilityId() == CANCEL_ABIL_ID;}));
        TriggerAddAction(t4, function ()
        {
            integer id = GetPlayerId(GetTriggerPlayer());
            if(PartyManager(id).open)
            {
                PartyManager(id).onClose();
            }
        });
        
        //para guardar cambios en la formacon
        TriggerAddCondition(t5, Condition(function ()-> boolean {return GetSpellAbilityId() == SAVE_CHANGES_ABIL_ID;}));
        TriggerAddAction(t5, function ()
        {
            integer id = GetPlayerId(GetTriggerPlayer());
            
            if(PartyManager(id).open)
            {
                PartyManager(id).saveCombatPositions();
                DisplayTimedTextToPlayer(Player(id),0,0,15.00, "|caa10aa00Posiciones Guardadas");

                //PartyManager(id).onClose();
            }
            else
             BJDebugMsg("error gestor cerrado");
        });
        
        t = null;
    }

}
//! endzinc