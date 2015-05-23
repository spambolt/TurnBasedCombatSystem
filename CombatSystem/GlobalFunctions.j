//! zinc
/*
*   Solo un par de funciones que son accesadas desde cualquier parte del código
*   
*/

library GlobalFunctions
{
    public
    {
        constant real HIDE_UNIT_X = GetRectMinX(bj_mapInitialPlayableArea);
        constant real HIDE_UNIT_Y = GetRectMinY(bj_mapInitialPlayableArea);
        constant integer FPS = 24;
        constant real GAME_PERIOD = 1.0/I2R(FPS);
        constant string BLOOD_FX = "Objects\\Spawnmodels\\Human\\HumanBlood\\BloodElfSpellThiefBlood.mdl";
    
        function hideUnit(unit u)
        {
        
            ShowUnit(u,false);
            UnitAddAbility(u,'Aloc');
            UnitAddAbility(u,'Avul');
            SetUnitX(u,HIDE_UNIT_X);
            SetUnitY(u,HIDE_UNIT_Y);
            PauseUnit(u,true);
        }
        
        function showUnit( unit u , real x , real y)
        {
            SetUnitX(u,x);
            SetUnitY(u,y);
            ShowUnit(u,true);
            UnitRemoveAbility(u,'Aloc');
            UnitRemoveAbility(u,'Avul');
            PauseUnit(u,true);
            PauseUnit(u,false);
            IssueImmediateOrder(u, "stop");
        }
        
        function playDeath(unit u , real x , real y)
        {
            SetUnitX(u,x);
            SetUnitY(u,y);
            ShowUnit(u,true);

            PauseUnit(u,true);
            PauseUnit(u,false);
            IssueImmediateOrder(u, "stop");
            SetUnitAnimation(u , "death");
        }
        
        function cancelCurrentOrder(unit u)
        {
            PauseUnit(u,true);
            IssueImmediateOrder(u, "stop");
            PauseUnit(u,false);
        }
        
            //////////////////////////       (                  º________________________________________________º               )   
        //   º-º-º-ºº-º-ºº--º-º-º
        //                                              -º-_-----º--ºº--ºº--º-º-º-ºº-º-
        //-º-º-º-º-º-º-º-º-º-º-º-º-º
        //////////////////////////
         function cameraLock(player p,real x,real y,boolean b)->boolean
         {
              real minX = (x-150.0);// GetRectMinX(r)
              real minY = (y-150.0);//GetRectMinY(r)
              real maxX = (x+75.0);//GetRectMaxX(r)
              real maxY = (y+75.0);//GetRectMaxY(r)
                
              if ((p==GetLocalPlayer())&&(b))
              {
               PanCameraTo(x,y);
               SetCameraBounds(minX, minY, minX, maxY, maxX, maxY, maxX, minY);
                return true;
              }
              return false;
         }
         
         function cameraReset(player p)
         {
              if (p==GetLocalPlayer())
                SetCameraBoundsToRect(bj_mapInitialPlayableArea);
              
         }
         
         function setCameraTo(player p , real x , real y)
         {
              if (p==GetLocalPlayer())
              {
                 PanCameraToTimed(x,y , 0.1);
              }
         }
         
        public function DistanceXY(real x1 , real y1 , real x2 , real y2) -> real
        {
             return SquareRoot(((x2-x1)*(x2-x1))+((y2-y1)*(y2-y1)));
        }
    
        public  function AngleXY(real x1 , real y1 , real x2 , real y2) -> real
        {
            return  Atan2(y2-y1,x2-x1);
        }
        
        //calcula la altura para cada punto -> devuelve la altura actual
        public function ParabolaZ(real h, real d, real p )-> real
        {
          return (4 * h / d) * (d - p) * (p / d); 
        }
    }
}
//! endzinc