//! zinc
/*
* La referencia a auto index fue reemplazada en el Modulo del AIDS
*esta clase maneja las posiciones y otros datos relacionadas
*a las unidades en el party
**/
    library Party requires AutoIndex , ListClass
    {
            
        combatGrid TEMP_COMBAT_GRID;
        boolean TEMP_TOKEN_COMBAT_SIDE;
        boolean TEMP_PARTY_ALIVE; //alguien en el party sigue vivo
        UnitList TEMP_LIST;
        //solo se puede crear una instancia temporal
        struct CombatPos[]
        {
            static boolean isFull[];
            
            
            method push(integer i)
            {
                if(i <= 5)
                    thistype.isFull[i] = true;
                else
                    BJDebugMsg("Asigancion fuera del rango de parametro");
            }
            
            method getFreePosition() -> integer
            {
                integer i = 0;
                while( i <= 5)
                {
                    if(!thistype.isFull[i])
                    {
                        return i;
                    }
                    i+=1;
                }
                return -1;
            }
            
            method clear()
            {
                integer i = 0;
                while(i <= 5)
                {
                    thistype.isFull[i] = false;
                    i += 1;
                } 
            }
        }

        
        
        
        // objeto publico recupera los datos del party
        //estos datos estan asociados al UnitId de la unidad lider del party
        public struct Party []
        {
            integer leaderShip;
            boolean canBeLeader;
            integer totalMembers;
            unit leader;
            integer freeSlot;
            
            public boolean isAIParty;
            public group members; 
            
            static method get(unit u)-> thistype
            {
                return  GetUnitId(u);
            }
            
            static method create(unit u) -> thistype
            {
                thistype this = GetUnitId(u);
                this.members = CreateGroup();
                this.addMember(u);
                this.leaderShip = 2;
                this.leader  = u;
                return this;
            }
            
            method addMember(unit u)
            {
                GroupAddUnit(this.members, u );
                ExtraData(GetUnitId(u)).combatPosition = 'UNAS';
                this.totalMembers += 1;
                this.assignCombatPosition(u);
                DisplayTimedTextToPlayer(Player(GetPlayerId(GetOwningPlayer(this.leader))),0,0,15.00, "|caaff0000"+GetUnitName(u)+"|r se ha agregado al grupo");
            }
            
            //
            method addMemberWithPos(unit u , integer position)
            {
                GroupAddUnit(this.members, u );
                ExtraData(GetUnitId(u)).combatPosition = position;
                this.totalMembers += 1;
                //this.assignCombatPosition(u);
                DisplayTimedTextToPlayer(Player(GetPlayerId(GetOwningPlayer(this.leader))),0,0,15.00, "|caaff0000"+GetUnitName(u)+"|r se ha agregado al grupo");
            }
            

            
            method assignCombatPosition(unit u)
            {
                 integer i = 0;
                 integer j = 0;
                 integer pos = 0; 
                 integer ass = -1;
                 
                 ForGroup(this.members, function()
                 {
                    
                    unit enum = GetEnumUnit();
                    integer uId = GetUnitId(enum);
                    integer itId = 0; // item Id
                    integer i =0;
                    integer pos = 0;
                    
                    if(enum != null)
                    {
                        pos = ExtraData(uId).combatPosition;
                        
                        if(pos != 'UNAS')
                            CombatPos(0).push(pos);
                    }
                    enum = null;
                 });
                 
                 
                 if(CombatPos(0).getFreePosition() != -1)
                    ExtraData(GetUnitId(u)).combatPosition =  CombatPos(0).getFreePosition();
                 else
                    BJDebugMsg("Error en la asignacion de posicion de combate");
                    
                CombatPos(0).clear();

            }
            
            method removeMember(unit u)
            {
                GroupRemoveUnit(this.members , u);
            }
            
            method hideAllMembers()
            {
                ForGroup(this.members , function()
                {
                    hideUnit(GetEnumUnit());
                });
            }
            //recordar que las listas deben ser destruidas siempre
            public method getMembersListed() -> UnitList
            {
                UnitList list = UnitList.create(); //las listas deben ser destruidas ...
                
                TEMP_LIST = list;
                ForGroup(this.members , function()
                {
                    unit enum = GetEnumUnit();
                    TEMP_LIST.add(enum);
                    
                    enum = null;
                });
                
                return list;
            }
            
            //on construction
            method placeAllMembers(combatGrid cG , boolean sideA)
            {
                integer i = 0;
                integer j = 0;
                integer pos = 0; 
                integer ass = -1;
                
                TEMP_COMBAT_GRID = cG;
                TEMP_TOKEN_COMBAT_SIDE = sideA;
                ForGroup(this.members, function()
                {
                    unit enum = GetEnumUnit();
                    integer uId = GetUnitId(enum);
                    integer itId = 0; // item Id
                    integer i =0;
                    integer pos = 0;
                    real x , y ;
                    //para hallar la coordenada n+n -> x n+n+1-> y <A ! 
                    if(enum != null)
                    {
                        if(TEMP_TOKEN_COMBAT_SIDE)
                        {
                            pos = ExtraData(uId).combatPosition;
                            x = TEMP_COMBAT_GRID[pos+pos];
                            y = TEMP_COMBAT_GRID[pos+pos+1];
                            showUnit(enum , x , y);
                            SetUnitFacing(enum,0.0 );
                            
                        }
                        else
                        {
                            pos = ExtraData(uId).combatPosition;
                            x = TEMP_COMBAT_GRID[pos+pos+12];
                            y = TEMP_COMBAT_GRID[pos+pos+12+1];
                            showUnit(enum , x , y);
                            SetUnitFacing(enum,180.0 );
                        }
                    }
                    PauseUnit(enum,true);
                    enum = null;
                });
            }
            
            //cierto cuando todo el party esta muerto
            //nota personal cambiar para detectar unidad que huye...
            public method isAllPartyDefeated() -> boolean
            {
                boolean flag;
                TEMP_PARTY_ALIVE = true;

                ForGroup(this.members , function()
                {
                    if(GetUnitState(GetEnumUnit() , UNIT_STATE_LIFE) > 0.403)
                    {
                        
                        TEMP_PARTY_ALIVE = false;
                    }
                });
                
                flag = TEMP_PARTY_ALIVE;
                return flag;
            }
            
            method onDestroyParty()
            {
                DestroyGroup(this.members);
            }
        
        }
       // method unitConfig(integer portraitId , integer combatPosition, boolean isLeader , integer cost , integer sizeInParty , integer evolId)
        function tempUnitConfigAI(unit leader)
        {
            unit u = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE),'H002',0,0,0);
            unit u1 = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE),'H002',0,0,0);
            unit u2 = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE),'H002',0,0,0);
            unit u3 = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE),'H002',0,0,0);
            unit u4 = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE),'H002',0,0,0);
            Party party = Party.create(leader);
            
            party.isAIParty = true;
            
            setUpCustomMembers(leader , u ,1);
            setUpCustomMembers(leader , u1 ,2);
            setUpCustomMembers(leader , u2 ,3);
            setUpCustomMembers(leader , u3 ,4);
            setUpCustomMembers(leader , u4 ,5);
        }
       
        function onInit()
        {
            unit u = CreateUnit(Player(0),'H000',0,0,0);
            unit u2 = CreateUnit(Player(0),'H000',0,0,0);
            unit uEnemy = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE),'H000',0,0,0);
            unit uEnemy2 = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE),'H000',300,0,0);
            unit uEnemy3 = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE),'H000',900,0,0);
            
            
            Party.create(u);
            Party.create(u2);
            Party.create(uEnemy);
            
            ExtraData(GetUnitId(u)).loadInitTypeParameters('H000');
            //ExtraData(GetUnitId(u)).loadCombatParameters('H000');
            //ExtraData(GetUnitId(u)).initiative = 5;
            
            ExtraData(GetUnitId(u2)).loadInitTypeParameters('H000');
            
            //ExtraData(GetUnitId(u2)).initiative = 5;
            ExtraData(GetUnitId(uEnemy)).unitConfig('I001',0,true,200, 1 ,'0000');
            ExtraData(GetUnitId(uEnemy2)).unitConfig('I001',0,true,200, 1 ,'0000');
            ExtraData(GetUnitId(uEnemy3)).unitConfig('I001',0,true,200, 1 ,'0000');
            
            //llamada a funcion temporal solo para pruebas
            tempUnitConfigAI(uEnemy);
            tempUnitConfigAI(uEnemy2);
            tempUnitConfigAI(uEnemy3);
            
            ExtraData(GetUnitId(uEnemy)).loadInitTypeParameters('H000');
            ExtraData(GetUnitId(uEnemy2)).loadInitTypeParameters('H000');
            ExtraData(GetUnitId(uEnemy3)).loadInitTypeParameters('H000');
            
            
            //ExtraData(GetUnitId(uEnemy)).initiative = 5;
            
            
            u = null;
        }
    }
//! endzinc
