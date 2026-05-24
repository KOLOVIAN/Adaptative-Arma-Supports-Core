class AAS_LOG_Tablet_Dialog {
    idd = 8990; 
    movingEnable = 0;
    enableSimulation = 1;

    class controls {
        // --- 1. THE TABLET FRAME ---
        class TabletFrame {
            idc = 8992;         
            type = 0;           
            style = 2096;       // ST_PICTURE + ST_KEEP_ASPECT_RATIO
            text = "";          
            colorText[] = {1, 1, 1, 1};
            colorBackground[] = {0, 0, 0, 0};
            font = "RobotoCondensed";
            sizeEx = 0.04;
            lineSpacing = 0;
            fixedWidth = 0;
            shadow = 0;
            
            // THE FIX: Lock the frame's bounding box to exactly 16:9 width
            w = "1.3333 * safezoneH"; // Replaces safezoneW
            h = "safezoneH";
            
            // Center this rigid bounding box perfectly on the screen
            x = "safezoneX + (safezoneW / 2) - (0.6666 * safezoneH)"; 
            y = "safezoneY";
        };

        // --- 2. THE INTERACTIVE MAP ---
        class TabletMap {
            idc = 8991; 
            type = 101;         
            style = 0;          
            
            // THE FIX: Width locked to safezoneH (Original 0.48 * 1.3333 factor)
            w = "0.64 * safezoneH"; 
            h = "0.459 * safezoneH"; 

            // THE FIX: Anchored to dead-center, offset to perfectly fit the bezel
            x = "safezoneX + (safezoneW / 2) - (0.3226 * safezoneH)"; 
            y = "safezoneY + 0.251 * safezoneH";

            // --- MANDATORY ENGINE PROPERTIES ---
            
            // Map Colors
            colorOutside[] = {0, 0, 0, 1};
            colorBackground[] = {0.9, 0.9, 0.9, 1};
            colorText[] = {0, 0, 0, 1};
            colorSea[] = {0.4, 0.6, 0.8, 0.5};
            colorForest[] = {0.6, 0.8, 0.5, 0.5};
            colorRocks[] = {0, 0, 0, 0.3};
            colorCountlines[] = {0.57, 0.33, 0.13, 0.25};
            colorMainCountlines[] = {0.57, 0.33, 0.13, 0.5};
            colorCountlinesWater[] = {0.49, 0.51, 0.89, 0.31};
            colorMainCountlinesWater[] = {0.49, 0.51, 0.89, 0.61};
            colorForestBorder[] = {0, 0, 0, 0};
            colorRocksBorder[] = {0, 0, 0, 0};
            colorGrid[] = {0.1, 0.1, 0.1, 0.6};
            colorGridMap[] = {0.1, 0.1, 0.1, 0.6};
            colorPowerLines[] = {0.1, 0.1, 0.1, 1}; 
            colorRailWay[] = {0.8, 0.2, 0, 1};      
            colorNames[] = {0.1, 0.1, 0.1, 0.9};    
            colorInactive[] = {1, 1, 1, 0.5};       
            colorLevels[] = {0.28, 0.17, 0.09, 0.5}; 
            colorNavigMark[] = {0.8, 0.8, 0.8, 1};
            colorTracks[] = {0.84, 0.76, 0.65, 1.0};
            colorTracksFill[] = {0.84, 0.76, 0.65, 1.0};
            colorRoads[] = {0.7, 0.7, 0.7, 1.0};
            colorRoadsFill[] = {1.0, 1.0, 1.0, 1.0};
            colorMainRoads[] = {0.9, 0.5, 0.3, 1.0};
            colorMainRoadsFill[] = {1.0, 0.6, 0.4, 1.0};
            colorTrails[] = {0.84, 0.76, 0.65, 1.5};
            colorTrailsFill[] = {0.84, 0.76, 0.65, 1.5};

            // Line Thicknesses
            widthRailWay = 1;
            widthPowerLines = 1;

            // Font/Text Config
            font = "TahomaB";
            sizeEx = 0.05;
            fontLabel = "TahomaB";
            sizeExLabel = 0.03;
            fontGrid = "TahomaB";
            sizeExGrid = 0.03;
            fontUnits = "TahomaB";
            sizeExUnits = 0.03;
            fontNames = "TahomaB";
            sizeExNames = 0.03;
            fontInfo = "TahomaB";
            sizeExInfo = 0.03;
            fontLevel = "TahomaB";
            sizeExLevel = 0.03;

            // Operational Logic
            moveOnEdges = 1;
            shadow = 0;
            ptsPerSquareSea = 5;
            ptsPerSquareTxt = 20;
            ptsPerSquareCLn = 10;
            ptsPerSquareExp = 10;
            ptsPerSquareCost = 10;
            ptsPerSquareFor = 9;
            ptsPerSquareForEdge = 9;
            ptsPerSquareRoad = 6;
            ptsPerSquareObj = 9;
            showCountourInterval = 0;
            scaleMin = 0.001;
            scaleMax = 1.0;
            scaleDefault = 0.16;
            alphaFadeStartScale = 1;
            alphaFadeEndScale = 1.1;
            maxSatelliteAlpha = 0; 
            text = "#(argb,8,8,3)color(1,1,1,1)";

            // --- MANDATORY SUB-CLASSES (The RPT Fixes) ---
            
            // Utility markers
            class ActiveMarker { color[] = {0.3, 0.1, 0.9, 1}; size = 50; };
            class LineMarker { lineDistanceMin = 3e-05; lineLengthMin = 5; lineWidthThick = 0.014; lineWidthThin = 0.008; textureComboBoxColor = "#(argb,8,8,3)color(1,1,1,1)"; };
            class Legend { x = 0; y = 0; w = 0; h = 0; font = "RobotoCondensed"; sizeEx = 0; colorBackground[] = {0,0,0,0}; color[] = {0,0,0,0}; };
            
            // Map Waypoints & Tasks
            class Task { icon = "\A3\ui_f\data\map\mapcontrol\taskIcon_ca.paa"; color[] = {1,1,0,1}; iconCreated = ""; iconCanceled = ""; iconDone = ""; iconFailed = ""; iconAssigned = ""; size = 27; importance = 1; coefMin = 1; coefMax = 1; condition = "true"; };
            class CustomMark { icon = "\A3\ui_f\data\map\mapcontrol\custommark_ca.paa"; color[] = {0,0,0,1}; size = 24; importance = 1; coefMin = 1; coefMax = 1; condition = "true"; };
            class Waypoint { icon = "\A3\ui_f\data\map\mapcontrol\waypoint_ca.paa"; color[] = {0,0,0,1}; size = 24; importance = 1; coefMin = 1; coefMax = 1; condition = "true"; };
            class WaypointCompleted { icon = "\A3\ui_f\data\map\mapcontrol\waypointCompleted_ca.paa"; color[] = {0,0,0,1}; size = 24; importance = 1; coefMin = 1; coefMax = 1; condition = "true"; };
            class WaypointSetter { icon = "\A3\ui_f\data\map\mapcontrol\waypointsetter_ca.paa"; color[] = {0,0,0,1}; size = 24; importance = 1; coefMin = 1; coefMax = 1; condition = "true"; };
            class Command { icon = "\A3\ui_f\data\map\mapcontrol\waypoint_ca.paa"; color[] = {1,1,1,1}; size = 18; importance = 1; coefMin = 1; coefMax = 1; condition = "true"; };
            
            // Terrain Objects
            class Bunker { icon = "\A3\ui_f\data\map\mapcontrol\bunker_ca.paa"; color[] = {0,0,0,1}; size = 14; importance = 1.5; coefMin = 0.25; coefMax = 4; condition = "true"; };
            class Bush { icon = "\A3\ui_f\data\map\mapcontrol\bush_ca.paa"; color[] = {0.45,0.64,0.33,0.4}; size = 14; importance = 0.2; coefMin = 0.25; coefMax = 4; condition = "true"; };
            class BusStop { icon = "\A3\ui_f\data\map\mapcontrol\busstop_ca.paa"; color[] = {1,1,1,1}; size = 24; importance = 1; coefMin = 0.25; coefMax = 4; condition = "true"; };
            class Business { icon = "\A3\ui_f\data\map\mapcontrol\business_ca.paa"; color[] = {0,0,0,1}; size = 24; importance = 1; coefMin = 0.25; coefMax = 4; condition = "true"; };
            class Cave { icon = "\A3\ui_f\data\map\mapcontrol\cave_ca.paa"; color[] = {0,0,0,1}; size = 24; importance = 1; coefMin = 0.25; coefMax = 4; condition = "true"; };
            class Chapel { icon = "\A3\ui_f\data\map\mapcontrol\chapel_ca.paa"; color[] = {0,0,0,1}; size = 24; importance = 1; coefMin = 0.25; coefMax = 4; condition = "true"; };
            class Church { icon = "\A3\ui_f\data\map\mapcontrol\church_ca.paa"; color[] = {0,0,0,1}; size = 24; importance = 1; coefMin = 0.25; coefMax = 4; condition = "true"; };
            class Cross { icon = "\A3\ui_f\data\map\mapcontrol\cross_ca.paa"; color[] = {0,0,0,1}; size = 24; importance = 1; coefMin = 0.25; coefMax = 4; condition = "true"; };
            class Fortress { icon = "\A3\ui_f\data\map\mapcontrol\fortress_ca.paa"; color[] = {0,0,0,1}; size = 24; importance = 2; coefMin = 0.25; coefMax = 4; condition = "true"; };
            class Fuelstation { icon = "\A3\ui_f\data\map\mapcontrol\fuelstation_ca.paa"; color[] = {0,0,0,1}; size = 24; importance = 1; coefMin = 0.25; coefMax = 4; condition = "true"; };
            class Fountain { icon = "\A3\ui_f\data\map\mapcontrol\fountain_ca.paa"; color[] = {0,0,0,1}; size = 24; importance = 1; coefMin = 0.25; coefMax = 4; condition = "true"; };
            class Hospital { icon = "\A3\ui_f\data\map\mapcontrol\hospital_ca.paa"; color[] = {0,0,0,1}; size = 24; importance = 1; coefMin = 0.25; coefMax = 4; condition = "true"; };
            class Lighthouse { icon = "\A3\ui_f\data\map\mapcontrol\lighthouse_ca.paa"; color[] = {0,0,0,1}; size = 24; importance = 1; coefMin = 0.25; coefMax = 4; condition = "true"; };
            class PowerSolar { icon = "\A3\ui_f\data\map\mapcontrol\powersolar_ca.paa"; color[] = {1,1,1,1}; size = 24; importance = 1; coefMin = 0.25; coefMax = 4; condition = "true"; };
            class PowerWave { icon = "\A3\ui_f\data\map\mapcontrol\powerwave_ca.paa"; color[] = {1,1,1,1}; size = 24; importance = 1; coefMin = 0.25; coefMax = 4; condition = "true"; };
            class PowerWind { icon = "\A3\ui_f\data\map\mapcontrol\powerwind_ca.paa"; color[] = {1,1,1,1}; size = 24; importance = 1; coefMin = 0.25; coefMax = 4; condition = "true"; };
            class Quay { icon = "\A3\ui_f\data\map\mapcontrol\quay_ca.paa"; color[] = {0,0,0,1}; size = 24; importance = 1; coefMin = 0.25; coefMax = 4; condition = "true"; };
            class Rock { icon = "\A3\ui_f\data\map\mapcontrol\rock_ca.paa"; color[] = {0.1,0.1,0.1,0.8}; size = 12; importance = 0.5; coefMin = 0.25; coefMax = 4; condition = "true"; };
            class Ruin { icon = "\A3\ui_f\data\map\mapcontrol\ruin_ca.paa"; color[] = {0,0,0,1}; size = 24; importance = 1; coefMin = 0.25; coefMax = 4; condition = "true"; };
            class Shipwreck { icon = "\A3\ui_f\data\map\mapcontrol\shipwreck_ca.paa"; color[] = {0,0,0,1}; size = 24; importance = 1; coefMin = 0.25; coefMax = 4; condition = "true"; };
            class Stack { icon = "\A3\ui_f\data\map\mapcontrol\stack_ca.paa"; color[] = {0,0,0,1}; size = 24; importance = 1; coefMin = 0.25; coefMax = 4; condition = "true"; };
            class Tree { icon = "\A3\ui_f\data\map\mapcontrol\tree_ca.paa"; color[] = {0.45,0.64,0.33,0.4}; size = 12; importance = 0.9; coefMin = 0.25; coefMax = 4; condition = "true"; };
            class SmallTree { icon = "\A3\ui_f\data\map\mapcontrol\bush_ca.paa"; color[] = {0.45,0.64,0.33,0.4}; size = 12; importance = 0.6; coefMin = 0.25; coefMax = 4; condition = "true"; };
            class Tourism { icon = "\A3\ui_f\data\map\mapcontrol\tourism_ca.paa"; color[] = {0,0,0,1}; size = 24; importance = 1; coefMin = 0.25; coefMax = 4; condition = "true"; };
            class Transmitter { icon = "\A3\ui_f\data\map\mapcontrol\transmitter_ca.paa"; color[] = {0,0,0,1}; size = 24; importance = 1; coefMin = 0.25; coefMax = 4; condition = "true"; };
            class ViewTower { icon = "\A3\ui_f\data\map\mapcontrol\viewtower_ca.paa"; color[] = {0,0,0,1}; size = 24; importance = 1; coefMin = 0.25; coefMax = 4; condition = "true"; };
            class Watertower { icon = "\A3\ui_f\data\map\mapcontrol\watertower_ca.paa"; color[] = {0,0,0,1}; size = 24; importance = 1; coefMin = 0.25; coefMax = 4; condition = "true"; };
        };
    };
};