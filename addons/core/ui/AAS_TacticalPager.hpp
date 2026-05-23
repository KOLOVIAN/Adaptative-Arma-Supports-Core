class AAS_Pager_HUD {
    idd = 8500;
    duration = 1e+011; 
    fadeIn = 0.1;
    fadeOut = 0.1;
    onLoad = "uiNamespace setVariable ['AAS_Pager_Display', _this select 0];";
    onUnload = "uiNamespace setVariable ['AAS_Pager_Display', displayNull];";

    class controlsBackground {
        class PagerImage: RscPicture {
            idc = 1200; 
            style = 2096; // ST_PICTURE + ST_KEEP_ASPECT_RATIO
            
            // This MUST be white to see the original colors of your .paa
            colorText[] = {1, 1, 1, 1}; 
            shadow = 0; // Disable engine-generated drop shadows
            
            text = "\z\aas\addons\core\data\tacticalpager_modern.paa"; 
            
            w = "0.316*safezoneW";
            h = "0.885*safezoneH";
            // Shifted 5% right
            x = "safezoneX+safezoneW-(0.276 * safezoneW)"; 
            y = "safezoneY+0.5*safezoneH-(0.442 * safezoneH)";
        };
    };

    class controls {
        class PagerStatusText: RscText {
            idc = 1000; 
            text = "COMMUNICATING..."; 
            font = "RobotoCondensed"; 
            sizeEx = 0.025; 
            colorText[] = {0, 0, 0, 1};
            colorBackground[] = {0, 0, 0, 0}; 
            w = "0.101*safezoneW";
            h = "0.025*safezoneH";
            // Shifted 5% right
            x = "safezoneX+safezoneW-(0.141*safezoneW)";
            y = "safezoneY+0.475*safezoneH";
        };

        class PagerListbox: RscListBox {
            idc = 1500;
            w = "0.101*safezoneW";
            h = "0.064*safezoneH";
            // Shifted 5% right
            x = "safezoneX+safezoneW-(0.167*safezoneW)";
            y = "safezoneY+0.495*safezoneH"; 
            font = "RobotoCondensed"; 
            sizeEx = 0.028; 
            rowHeight = 0.03; 
            colorBackground[] = {0, 0, 0, 0}; 
            colorText[] = {0, 0, 0, 1}; 
            colorSelectBackground[] = {0, 0, 0, 1};
            colorSelect[] = {0.792, 0.890, 0.776, 1}; 
            colorSelectBackground2[] = {0, 0, 0, 1};
            colorSelect2[] = {0.792, 0.890, 0.776, 1};

            class ScrollBar {
                // THE FIX: Alpha channel set to 0 to make the scrollbar completely invisible
                color[] = {1, 1, 1, 0}; 
                colorActive[] = {1, 1, 1, 0}; 
                colorDisabled[] = {1, 1, 1, 0}; 
                
                thumb = "\A3\ui_f\data\gui\rsccommon\rschtml\white_ca.paa";
                arrowEmpty = "\A3\ui_f\data\gui\rsccommon\rschtml\white_ca.paa";
                arrowFull = "\A3\ui_f\data\gui\rsccommon\rschtml\white_ca.paa";
                border = "\A3\ui_f\data\gui\rsccommon\rschtml\white_ca.paa";
                
                shadow = 0;
                scrollSpeed = 0.06;
                width = 0;
                height = 0;
                autoScrollEnabled = 0;
                autoScrollSpeed = -1;
                autoScrollDelay = 5;
                autoScrollRewind = 0;
            };
        };
    };
};
