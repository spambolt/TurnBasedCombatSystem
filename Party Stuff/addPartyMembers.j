

//! zinc
    //
    // this library allows a leader to buy a unit if he has enough leadership ability
    //
    library addPartyMembers
    {
        function buyMember()
        {
            unit member = GetSoldUnit(); // unidad vendida
            unit leader = GetBuyingUnit();
            
            //ExtraData(GetUnitId(member)).unitConfig('I003',0,false,200, 1 ,'0000');    
            //this call loads the needed initial parameters pre set it for each type of unit been sold (if the `parameters exists) 
            //ExtraData(GetUnitId(member)).loadInitTypeParameters(GetUnitTypeId(member));
            //BJDebugMsg("desde compras ...id del lider del party "+ I2S(GetUnitId(leader)));
            Party(GetUnitId(leader)).addMember(member);
            hideUnit(member);
            member = null;
            leader = null; 
        }
        
        
        
        //funcion utilizada para agregar miembros personalizados a los parties manejados pro la computadora
        public function setUpCustomMembers(unit leader , unit member ,integer position)
        { 
            //this call loads the needed initial parameters pre set it for each type of unit been activated (if the `parameters exists) 
            Party party = Party(GetUnitId(leader));
            ExtraData(GetUnitId(member)).loadInitTypeParameters(GetUnitTypeId(member));
                
            if(party.totalMembers <= 5)
            {
                Party(GetUnitId(leader)).addMemberWithPos(member , position);
                hideUnit(member);
            }
        }
        
        
        
        function onInit()
        {
            trigger t = CreateTrigger();
            
            TriggerRegisterAnyUnitEventBJ( t, EVENT_PLAYER_UNIT_SELL );
            TriggerAddCondition(t,Condition(
            
            //funcion anónima <3
            function()->boolean{
                unit u = GetBuyingUnit();
                unit sold = GetSoldUnit(); // ojo falta verificar el reciclado de ids
                boolean flag = false;
                integer gold = 0;
                player p = GetOwningPlayer(u);
                integer actualGold = GetPlayerState(p , PLAYER_STATE_RESOURCE_GOLD); 
                
                Party party = Party(GetUnitId(u));
                //this call loads the needed initial parameters pre set it for each type of unit been sold (if the `parameters exists)
                //carga los parametros iniciales necesarios pre configurados para cada tipo de unidad vendida (si los parametros existen)
                ExtraData(GetUnitId(sold)).loadInitTypeParameters(GetUnitTypeId(sold));
                
                if(party.totalMembers <= 5)
                    flag = true;
                else
                {
                    DisplayTimedTextToPlayer(Player(GetPlayerId(GetOwningPlayer(party.leader))),0,0,15.00, "|caaff0000No puedes Llevar más unidades contigo llevar más unidades contigo...");
                    gold = ExtraData(GetUnitId(sold)).cost;
                    SetPlayerState( p ,PLAYER_STATE_RESOURCE_GOLD, actualGold + gold);
                    RemoveUnit(sold);
                }
                    
                u = null;
                sold = null;
                return flag;
            }));
            
            TriggerAddAction( t, function buyMember );
            
            //temp
            
        }
    }

//! endzinc

