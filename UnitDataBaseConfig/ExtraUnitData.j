//! zinc

library ExtraUnitData requires AutoIndex
{
    /*
    *  esta libreira permite almacenar valores por defecto para cada tipo de unidad ... lo valores se cargan desde una hastable
    * 
    *
    */
    hashtable unitTable;
    /*
    
    Combat Position :
            | 1 | 2 |
    front   | 3 | 4 |
            | 5 | 6 |
    
    */
    private type Spells extends integer[8];
    //should be added to a unit by auto index generated Id...
    public struct ExtraData []
    {
        integer unitTypeId;
        integer itemPortraitId;
        integer combatPosition;//1,2,3,4,5,6
        boolean isLeader;
        integer cost;
        integer sizeInParty;
        integer evolId;
        boolean isOnCombat;
        
        integer damage;
        integer defense; //calculo porcentual de defensa ... 
        integer currLife;   
        integer attackZoneType; //1 -> 1 unidad 2-> todos los enemigos
        integer initiative;  //determina el turno de ataque
        integer hitChance;
        //?????
        integer extraExperience;
        integer extraDamage;
        integer extraDefense;
        boolean counterAttack;
        boolean doubleAttack;
        
        Spells spells;
        
        /*public static method GetData(unit u) -> thistype;
        {
            
        }*/
        public static method get(unit u) -> thistype
        {
            return GetUnitId(u);
        }
        
        method generalConfig()
        {
            this.itemPortraitId = '0000';
            this.isLeader = false;
            this.cost = 200;
            this.sizeInParty = 1;
        }
        
        method unitConfig(integer portraitId , integer combatPosition, boolean isLeader , integer cost , integer sizeInParty , integer evolId)
        {
            this.itemPortraitId = portraitId;
            this.combatPosition = combatPosition;
            this.isLeader = isLeader;
            this.cost = cost;
            this.sizeInParty = sizeInParty;
            this.evolId = evolId;
        }
        //load de parameters for each unit of the same type ... 
        method loadInitTypeParameters( integer unitTypeId)
        {
            this.itemPortraitId = LoadInteger(unitTable , StringHash("portraitId"), unitTypeId);
            this.isLeader =       LoadBoolean(unitTable , StringHash("isLeader"), unitTypeId);
            this.cost =           LoadInteger(unitTable , StringHash("cost"), unitTypeId);
            this.sizeInParty =    LoadInteger(unitTable , StringHash("size"), unitTypeId);
            this.evolId =         LoadInteger(unitTable , StringHash("evolId"), unitTypeId);
            this.loadCombatParameters(unitTypeId);
        }
        
        method loadCombatParameters(integer unitTypeId)
        {
            this.damage = LoadInteger(unitTable , unitTypeId , StringHash("damage"));
            this.defense = LoadInteger(unitTable , unitTypeId , StringHash("defense"));
            this.currLife = LoadInteger(unitTable , unitTypeId , StringHash("life"));
            this.initiative = LoadInteger(unitTable , unitTypeId , StringHash("initiative"));
            this.attackZoneType = LoadInteger(unitTable , unitTypeId , StringHash("zoneAttack"));
            this.hitChance = LoadInteger(unitTable , unitTypeId , StringHash("hitChance"));
        }
        
    }
    
    
    
    
    
    
    
    
    
    ///////////////////////////////////////////////////
    //
    //       unit type configuration : 
    //
    //
    
    
    
    
    function saveUnitSetUp(integer unitTypeId , integer portraitId , boolean IsLeader , integer cost , integer sizeInParty , integer evolId)
    {
    
        //SaveInteger(unitTable, StringHash("UnitDataType") , StringHash("unitType") , unitTypeId);
        
        SaveInteger(unitTable,  StringHash("portraitId"), unitTypeId , portraitId);
        SaveBoolean(unitTable, StringHash("isLeader"), unitTypeId ,IsLeader);
        SaveInteger(unitTable,  StringHash("cost"), unitTypeId , cost);
        SaveInteger(unitTable,  StringHash("size"), unitTypeId , sizeInParty);
        SaveInteger(unitTable,  StringHash("evolId"), unitTypeId , evolId);
        
        //LoadInteger(
    }
    
    function unitCombatParametersSetUp(integer unitTypeId , integer damage , integer defense , integer initiative , integer zoneAttackType , real life , integer hitChance)
    {
        SaveInteger(unitTable, unitTypeId , StringHash("damage") , damage);
        SaveInteger(unitTable, unitTypeId , StringHash("defense") , defense);
        SaveInteger(unitTable, unitTypeId , StringHash("initiative") , initiative);
        SaveInteger(unitTable, unitTypeId , StringHash("zoneAttack") , zoneAttackType);
        SaveReal(unitTable , unitTypeId , StringHash("life") , life);
        SaveInteger(unitTable, unitTypeId , StringHash("hitChance") , hitChance);
    }
    //
    //una funcion para crearlas a todas ... una funcion para declararlas a todas y someterlas XDD
    //
    //
    function startUnitDataConfig()
    {
        //declarar aqui los tipos de unidades que se van a utilizar en el diseño del juego ...
        //cada unidad requiere de 2 funciones para ser correctamente declarada una funcion para delcarar parametros
        //una funcion para delcarar caracteristicas de combate ... 
        
        //temporales
 //     function saveUnitSetUp(integer unitTypeId , integer portraitId , boolean IsLeader , integer cost , integer sizeInParty , integer evolId)
//      function unitCombatParametersSetUp(integer unitTypeId , integer damage , integer defense , integer initiative , integer zoneAttackType , real life , integer hitChance)
        
        //paladin leader : !!!!
        saveUnitSetUp('H000' , 'I001',true , 500 , 3 , '0000');
        unitCombatParametersSetUp('H000' , 50 , 10 , 10 , 0 , 150.0  , 50);
        
        //figther !!!
        saveUnitSetUp('H001' , 'I002',false , 200 , 1 , 'H002');
        unitCombatParametersSetUp('H001' , 15 , 10 , 1 , 0 , 100.0  , 40);       
        
        //footman !!!
        saveUnitSetUp('H002' , 'I003',false , 500 , 2 , 'H003');
        unitCombatParametersSetUp('H002' , 30 , 10 , 15 , 0 , 100.0  , 50);  
        
        //knight
        saveUnitSetUp('H003' , 'I004',false , 3000 , 1 , '0000');
        unitCombatParametersSetUp('H003' , 100 , 50 , 10 , 0 , 100.0  , 65);
    }
    
    function onInit()
    {
        unitTable = InitHashtable();
        startUnitDataConfig();
    }
}

//! endzinc