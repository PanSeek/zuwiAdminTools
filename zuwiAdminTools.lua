script_name('AdminTools')
script_authors('PanSeek')
version_script = '1.2'
require 'lib.moonloader'
local imgui = require 'mimgui'
local vkeys = require 'vkeys'
local ffi = require 'ffi'
local mem = require 'memory'
local sampev = require 'lib.samp.events'
local inicfg = require 'inicfg'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8
local new, str, sizeof = imgui.new, ffi.string, ffi.sizeof

ffi.cdef[[
struct stKillEntry
{
	char					szKiller[25];
	char					szVictim[25];
	uint32_t				clKillerColor; // D3DCOLOR
	uint32_t				clVictimColor; // D3DCOLOR
	uint8_t					byteType;
} __attribute__ ((packed));

struct stKillInfo
{
	int						iEnabled;
	struct stKillEntry		killEntry[5];
	int 					iLongestNickLength;
  	int 					iOffsetX;
  	int 					iOffsetY;
	void			    	*pD3DFont; // ID3DXFont
	void		    		*pWeaponFont1; // ID3DXFont
	void		   	    	*pWeaponFont2; // ID3DXFont
	void					*pSprite;
	void					*pD3DDevice;
	int 					iAuxFontInited;
    void 		    		*pAuxFont1; // ID3DXFont
    void 			    	*pAuxFont2; // ID3DXFont
} __attribute__ ((packed));
]]
local getBonePosition = ffi.cast("int (__thiscall*)(void*, float*, int, bool)", 0x5E4280)

local mainIni = inicfg.load({
	cheats = {
        airbrake 				= false,
        airbrakeSpeed           = 0.8,
        clickwarp               = false,
		nametag                 = true,
		skeleton				= false,
		whKey					= false,
        sh                      = false,
        shMaxSpeed              = 100.0,
		shSmooth                = 85,
		traserBullets			= false,
		traserBulletsSpec		= false,
		GM_actor				= false,
		GM_vehicle				= false,
		infammo					= false,
		flip					= false
	},
	admintools = {
		Chat 					= true,
		WTChat					= true,
		klistid					= true,
		NewCmd 				    = false,
		ShortCmd 				= true,
		aPuns					= false,
		aReq					= false,
		aSpec					= false,
		autoSpawn				= false,
		frakOnChat				= false
	}
}, "..\\config\\admintools\\cfg.ini")

local statsIni = inicfg.load({
	stats = {
		passAdmin				= '',
		passAcc					= '',
		ALVL					= '0',
		answers					= 0
	}
}, "..\\config\\admintools\\stats.ini")

local secondIni = inicfg.load({
	server = {
		address					= nil
	}
}, "..\\config\\admintools\\rememberserver.ini")

local BulletSync = {lastId = 0, maxLines = 15}
for i = 1, BulletSync.maxLines do
	BulletSync[i] = {enable = false, o = {x, y, z}, t = {x, y, z}, time = 0, tType = 0}
end

local sizeX, sizeY = getScreenResolution()
local srX, srY = 785, 300

--colors
local main_color = 16153390   -- {F67B2E}
local main2_color = 623826		-- {0984d2}
local yellow_color = 16373807 	-- {F9D82F}
local grey_color = 8949408  	-- {888EA0}

listColorFrac = {
	[0x32007788] = '{007788}[RLV]',
	[0x32FF8000] = '{ff8000}[RLS]',
	[0x328683A3] = '{8683a3}[GOV]',
	[0x32FF6347] = '{ff6347}[HLS]',
	[0x32FF6347] = '{ff6347}[HSF]',
	[0x32FF6347] = '{ff6347}[HLV]',
	[0x322641FE] = '{2641fe}[LSPD]',
	[0x322641FE] = '{2641fe}[SFPD]',
	[0x322641FE] = '{2641fe}[LVPD]',
	[0x324B00B0] = '{4b00b0}[FBI]',
	[0x32ADFF2F] = '{adff2f}[NGSA]',
	[0x32FFFF82] = '{ffff82}[COMRADES]',
	[0x32DC143C] = '{dc143c}[WARLOCK]',
	[0x3231318E] = '{31318e}[RM]',
	[0x32752A2A] = '{752a2a}[YAKUZA]',
	[0x32009900] = '{009900}[GROVE]',
	[0x32E6CE00] = '{e6ce00}[VAGOS]',
	[0x3233CCFF] = '{33ccff}[AZTEC]',
	[0x3283BFBF] = '{83bfbf}[RIFA]',
	[0x32CC00CC] = '{cc00cc}[BALLAS]'
}
--teleportes
tpListMain = {
	["Телепорты в интерьеры"] = {
		["Interior: Burning Desire House"] = {2338.32, -1180.61, 1027.98, 5},
		["Interior: RC Zero's Battlefield"] = {-975.5766, 1061.1312, 1345.6719, 10},
		["Interior: Liberty City"] = {-750.80, 491.00, 1371.70, 1},
		["Interior: Unknown Stadium"] = {-1400.2138, 106.8926, 1032.2779, 1},
		["Interior: Secret San Fierro Chunk"] = {-2015.6638, 147.2069, 29.3127, 14},
		["Interior: Jefferson Motel"] = {2220.26, -1148.01, 1025.80, 15},
		["Interior: Jizzy's Pleasure Dome"] = {-2660.6185, 1426.8320, 907.3626, 3},
		["Four Dragons' Managerial Suite"] = {2003.1178, 1015.1948, 33.008, 11},
		["Ganton Gym"] = {770.8033, -0.7033, 1000.7267, 5},
		["Brothel"] = {974.0177, -9.5937, 1001.1484, 3},
		["Brothel2"] = {961.9308, -51.9071, 1001.1172, 3},
		["Inside Track Betting"] = {830.6016, 5.9404, 1004.1797, 3},
		["Blastin' Fools Records"] = {1037.8276, 0.397, 1001.2845, 3},
		["The Big Spread Ranch"] = {1212.1489, -28.5388, 1000.9531, 3},
		["Stadium: Bloodbowl"] = {-1394.20, 987.62, 1023.96, 15},
		["Stadium: Kickstart"] = {-1410.72, 1591.16, 1052.53, 14},
		["Stadium: 8-Track Stadium"] = {-1417.8720, -276.4260, 1051.1910, 7},
		["24/7 Store: Big - L-Shaped"] = {-25.8844, -185.8689, 1003.5499, 17},
		["24/7 Store: Big - Oblong"] = {6.0911, -29.2718, 1003.5499, 10},
		["24/7 Store: Med - Square"] = {-30.9469, -89.6095, 1003.5499, 18},
		["24/7 Store: Med - Square"] = {-25.1329, -139.0669, 1003.5499, 16},
		["Warehouse 1"] = {1290.4106, 1.9512, 1001.0201, 18},
		["Warehouse 2"] = {1412.1472, -2.2836, 1000.9241, 1},
		["B Dup's Apartment"] = {1527.0468, -12.0236, 1002.0971, 3},
		["B Dup's Crack Palace"] = {1523.5098, -47.8211, 1002.2699, 2},
		["Wheel Arch Angels"] = {612.2191, -123.9028, 997.9922, 3},
		["OG Loc's House"] = {512.9291, -11.6929, 1001.5653, 3},
		["Barber Shop"] = {418.4666, -80.4595, 1001.8047, 3},
		["24/7 Store: Sml - Long"] = {-27.3123, -29.2775, 1003.5499, 4},
		["24/7 Store: Sml - Square"] = {-26.6915, -55.7148, 1003.5499, 6},
		["Airport: Ticket Sales"] = {-1827.1473, 7.2074, 1061.1435, 14},
		["Airport: Baggage Claim"] = {-1855.5687, 41.2631, 1061.1435, 14},
		["Airplane: Shamal Cabin"] = {2.3848, 33.1033, 1199.8499, 1},
		["Airplane: Andromada Cargo hold"] = {315.8561, 1024.4964, 1949.7973, 9},
		["Planning Department"] = {386.5259, 173.6381, 1008.3828, 3},
		["Las Venturas Police Department"] = {288.4723, 170.0647, 1007.1794, 3},
		["Pro-Laps"] = {206.4627, -137.7076, 1003.0938, 3},
		["Sex Shop"] = {-100.2674, -22.9376, 1000.7188, 3},
		["Las Venturas Tattoo parlor"] = {-201.2236, -43.2465, 1002.2734, 3},
		["Lost San Fierro Tattoo parlor"] = {-202.9381, -6.7006, 1002.2734, 17},
		["24/7 (version 1)"] = {-25.7220, -187.8216, 1003.5469, 17},
		["Diner 1"] = {454.9853, -107.2548, 999.4376, 5},
		["Pizza Stack"] = {372.5565, -131.3607, 1001.4922, 5},
		["Rusty Brown's Donuts"] = {378.026, -190.5155, 1000.6328, 17},
		["Ammu-nation"] = {315.244, -140.8858, 999.6016, 7},
		["Victim"] = {225.0306, -9.1838, 1002.218, 5},
		["Loco Low Co"] = {611.3536, -77.5574, 997.9995, 2},
		["San Fierro Police Department"] = {246.0688, 108.9703, 1003.2188, 10},
		["24/7 (version 2 - large)"] = {6.0856, -28.8966, 1003.5494, 10},
		["Below The Belt Gym (Las Venturas)"] = {773.7318, -74.6957, 1000.6542, 7},
		["Transfenders"] = {621.4528, -23.7289, 1000.9219, 1},
		["World of Coq"] = {445.6003, -6.9823, 1000.7344, 1},
		["Ammu-nation (version 2)"] = {285.8361, -39.0166, 1001.5156, 1},
		["SubUrban"] = {204.1174, -46.8047, 1001.8047, 1},
		["Denise's Bedroom"] = {245.2307, 304.7632, 999.1484, 1},
		["Helena's Barn"] = {290.623, 309.0622, 999.1484, 3},
		["Barbara's Love nest"] = {322.5014, 303.6906, 999.1484, 5},
		["San Fierro Garage"] = {-2041.2334, 178.3969, 28.8465, 1},
		["Oval Stadium"] = {-1402.6613, 106.3897, 1032.2734, 1},
		["8-Track Stadium"] = {-1403.0116, -250.4526, 1043.5341, 7},
		["The Pig Pen (strip club 2)"] = {1204.6689, -13.5429, 1000.9219, 2},
		["Four Dragons"] = {2016.1156, 1017.1541, 996.875, 10},
		["Liberty City"] = {-741.8495, 493.0036, 1371.9766, 1},
		["Ryder's house"] = {2447.8704, -1704.4509, 1013.5078, 2},
		["Sweet's House"] = {2527.0176, -1679.2076, 1015.4986, 1},
		["RC Battlefield"] = {-1129.8909, 1057.5424, 1346.4141, 10},
		["The Johnson House"] = {2496.0549, -1695.1749, 1014.7422, 3},
		["Burger shot"] = {366.0248, -73.3478, 1001.5078, 10},
		["Caligula's Casino"] = {2233.9363, 1711.8038, 1011.6312, 1},
		["Katie's Lovenest"] = {269.6405, 305.9512, 999.1484, 2},
		["Barber Shop 2 (Reece's)"] = {414.2987, -18.8044, 1001.8047, 2},
		["Angel \"Pine Trailer\""] = {1.1853, -3.2387, 999.4284, 2},
		["24/7 (version 3)"] = {-30.9875, -89.6806, 1003.5469, 18},
		["Zip"] = {161.4048, -94.2416, 1001.8047, 18},
		["The Pleasure Domes"] = {-2638.8232, 1407.3395, 906.4609, 3},
		["Madd Dogg's Mansion"] = {1267.8407, -776.9587, 1091.9063, 5},
		["Big Smoke's Crack Palace"] = {2536.5322, -1294.8425, 1044.125, 2},
		["Burning Desire Building"] = {2350.1597, -1181.0658, 1027.9766, 5},
		["Wu-Zi Mu's"] = {-2158.6731, 642.09, 1052.375, 1},
		["Abandoned AC tower"] = {419.8936, 2537.1155, 10.0, 10},
		["Wardrobe/Changing room"] = {256.9047, -41.6537, 1002.0234, 14},
		["Didier Sachs"] = {204.1658, -165.7678, 1000.5234, 14},
		["Casino (Redsands West)"] = {1133.35, -7.8462, 1000.6797, 12},
		["Kickstart Stadium"] = {-1420.4277, 1616.9221, 1052.5313, 14},
		["Club"] = {493.1443, -24.2607, 1000.6797, 17},
		["Atrium"] = {1727.2853, -1642.9451, 20.2254, 18},
		["Los Santos Tattoo Parlor"] = {-202.842, -24.0325, 1002.2734, 16},
		["Safe House group 1"] = {2233.6919, -1112.8107, 1050.8828, 5},
		["Safe House group 2"] = {1211.2484, 1049.0234, 359.941, 6},
		["Safe House group 3"] = {2319.1272, -1023.9562, 1050.2109, 9},
		["Safe House group 4"] = {2261.0977, -1137.8833, 1050.6328, 10},
		["Sherman Dam"] = {-944.2402, 1886.1536, 5.0051, 17},
		["24/7 (version 4)"] = {-26.1856, -140.9164, 1003.5469, 16},
		["Jefferson Motel"] = {2217.281, -1150.5349, 1025.7969, 15},
		["Jet Interior"] = {1.5491, 23.3183, 1199.5938, 1},
		["The Welcome Pump"] = {681.6216, -451.8933, -25.6172, 1},
		["Burglary House X1"] = {234.6087, 1187.8195, 1080.2578, 3},
		["Burglary House X2"] = {225.5707, 1240.0643, 1082.1406, 2},
		["Burglary House X3"] = {224.288, 1289.1907, 1082.1406, 1},
		["Burglary House X4"] = {239.2819, 1114.1991, 1080.9922, 5},
		["Binco"] = {207.5219, -109.7448, 1005.1328, 15},
		["4 Burglary houses"] = {295.1391, 1473.3719, 1080.2578, 15},
		["Blood Bowl Stadium"] = {-1417.8927, 932.4482, 1041.5313, 15},
		["Budget Inn Motel Room"] = {446.3247, 509.9662, 1001.4195, 12},
		["Lil' Probe Inn"] = {-227.5703, 1401.5544, 27.7656, 18},
		["Pair of Burglary Houses"] = {446.626, 1397.738, 1084.3047, 2},
		["Crack Den"] = {227.3922, 1114.6572, 1080.9985, 5},
		["Burglary House X11"] = {227.7559, 1114.3844, 1080.9922, 5},
		["Burglary House X12"] = {261.1165, 1287.2197, 1080.2578, 4},
		["Ammu-nation (version 3)"] = {291.7626, -80.1306, 1001.5156, 4},
		["Jay's Diner"] = {449.0172, -88.9894, 999.5547, 4},
		["24/7 (version 5)"] = {-27.844, -26.6737, 1003.5573, 4},
		["Michelle's Love Nest*"] = {306.1966, 307.819, 1003.3047, 4},
		["Burglary House X14"] = {24.3769, 1341.1829, 1084.375, 10},
		["Sindacco Abatoir"] = {963.0586, 2159.7563, 1011.0303, 1},
		["Burglary House X13"] = {221.6766, 1142.4962, 1082.6094, 4},
		["Unused Safe House"] = {2323.7063, -1147.6509, 1050.7101, 12},
		["Millie's Bedroom"] = {344.9984, 307.1824, 999.1557, 6},
		["Barber Shop"] = {411.9707, -51.9217, 1001.8984, 12},
		["Dirtbike Stadium"] = {-1421.5618, -663.8262, 1059.5569, 4},
		["Cobra Gym"] = {773.8887, -47.7698, 1000.5859, 6},
		["Los Santos Police Department"] = {246.6695, 65.8039, 1003.6406, 6},
		["Los Santos Airport"] = {-1864.9434, 55.7325, 1055.5276, 14},
		["Burglary House X15"] = {-262.1759, 1456.6158, 1084.3672, 4},
		["Burglary House X16"] = {22.861, 1404.9165, 1084.4297, 5},
		["Burglary House X17"] = {140.3679, 1367.8837, 1083.8621, 5},
		["Bike School"] = {1494.8589, 1306.48, 1093.2953, 3},
		["Francis International Airport"] = {-1813.213, -58.012, 1058.9641, 14},
		["Vice Stadium"] = {-1401.067, 1265.3706, 1039.8672, 16},
		["Burglary House X18"] = {234.2826, 1065.229, 1084.2101, 6},
		["Burglary House X19"] = {-68.5145, 1353.8485, 1080.2109, 6},
		["Zero's RC Shop"] = {-2240.1028, 136.973, 1035.4141, 6},
		["Ammu-nation (version 4)"] = {297.144, -109.8702, 1001.5156, 6},
		["Ammu-nation (version 5)"] = {316.5025, -167.6272, 999.5938, 6},
		["Burglary House X20"] = {-285.2511, 1471.197, 1084.375, 15},
		["24/7 (version 6)"] = {-26.8339, -55.5846, 1003.5469, 6},
		["Secret Valley Diner"] = {442.1295, -52.4782, 999.7167, 6},
		["Rosenberg's Office in Caligulas"] = {2182.2017, 1628.5848, 1043.8723, 2},
		["Fanny Batter's Whore House"] = {748.4623, 1438.2378, 1102.9531, 6},
		["Colonel Furhberger's"] = {2807.3604, -1171.7048, 1025.5703, 8},
		["Cluckin' Bell"] = {366.0002, -9.4338, 1001.8516, 9},
		["The Camel's Toe Safehouse"] = {2216.1282, -1076.3052, 1050.4844, 1},
		["Caligula's Roof"] = {2268.5156, 1647.7682, 1084.2344, 1},
		["Old Venturas Strip Casino"] = {2236.6997, -1078.9478, 1049.0234, 2},
		["Driving School"] = {-2031.1196, -115.8287, 1035.1719, 3},
		["Verdant Bluffs Safehouse"] = {2365.1089, -1133.0795, 1050.875, 8},
		["Andromada"] = {315.4544, 976.5972, 1960.8511, 9},
		["Four Dragons' Janitor's Office"] = {1893.0731, 1017.8958, 31.8828, 10},
		["Bar"] = {501.9578, -70.5648, 998.7578, 11},
		["Burglary House X21"] = {-42.5267, 1408.23, 1084.4297, 8},
		["Willowfield Safehouse"] = {2283.3118, 1139.307, 1050.8984, 11},
		["Burglary House X22"] = {84.9244, 1324.2983, 1083.8594, 9},
		["Burglary House X23"] = {260.7421, 1238.2261, 1084.2578, 9}
	},
	["Остальные телепорты"] = {
		["Transfender near Wang Cars in Doherty"] = {-1935.77, 228.79, 34.16, 0},
		["Wheel Archangels in Ocean Flats"] = {-2707.48, 218.65, 4.93, 0},
		["LowRider Tuning Garage in Willowfield"] = {2645.61, -2029.15, 14.28, 0},
		["Transfender in Temple"] = {1041.26, -1036.77, 32.48, 0},
		["Transfender in come-a-lot"] = {2387.55, 1035.70, 11.56, 0},
		["Eight Ball Autos near El Corona"] = {1836.93, -1856.28, 14.13, 0},
		["Welding Wedding Bomb-workshop in Emerald Isle"] = {2006.11, 2292.87, 11.57, 0},
		["Michelles Pay 'n' Spray in Downtown"] = {-1787.25, 1202.00, 25.84, 0},
		["Pay 'n' Spray in Dillimore"] = {720.10, -470.93, 17.07, 0},
		["Pay 'n' Spray in El Quebrados"] = {-1420.21, 2599.45, 56.43, 0},
		["Pay 'n' Spray in Fort Carson"] = {-100.16, 1100.79, 20.34, 0},
		["Pay 'n' Spray in Idlewood"] = {2078.44, -1831.44, 14.13, 0},
		["Pay 'n' Spray in Juniper Hollow"] = {-2426.89, 1036.61, 51.14, 0},
		["Pay 'n' Spray in Redsands East"] = {1957.96, 2161.96, 11.56, 0},
		["Pay 'n' Spray in Santa Maria Beach"] = {488.29, -1724.85, 12.01, 0},
		["Pay 'n' Spray in Temple"] = {1025.08, -1037.28, 32.28, 0},
		["Pay 'n' Spray near Royal Casino"] = {2393.70, 1472.80, 11.42, 0},
		["Pay 'n' Spray near Wang Cars in Doherty"] = {-1904.97, 268.51, 41.04, 0},
		["Player Garage: Verdant Meadows"] = {403.58, 2486.33, 17.23, 0},
		["Player Garage: Las Venturas Airport"] = {1578.24, 1245.20, 11.57, 0},
		["Player Garage: Calton Heights"] = {-2105.79, 905.11 ,77.07, 0},
		["Player Garage: Derdant Meadows"] = {423.69, 2545.99, 17.07, 0},
		["Player Garage: Dillimore "] = {785.79, -513.12, 17.44, 0},
		["Player Garage: Doherty"] = {-2027.34, 141.02, 29.57, 0},
		["Player Garage: El Corona"] = {1698.10, -2095.88, 14.29, 0},
		["Player Garage: Fort Carson"] = {-361.10, 1185.23, 20.49, 0},
		["Player Garage: Hashbury"] = {-2463.27, -124.86, 26.41, 0},
		["Player Garage: Johnson House"] = {2505.64, -1683.72, 14.25, 0},
		["Player Garage: Mulholland"] = {1350.76, -615.56, 109.88, 0},
		["Player Garage: Palomino Creek"] = {2231.64, 156.93, 27.63, 0},
		["Player Garage: Paradiso"] = {-2695.51, 810.70, 50.57, 0},
		["Player Garage: Prickle Pine"] = {1293.61, 2529.54, 11.42, 0},
		["Player Garage: Redland West"] = {1401.34, 1903.08, 11.99, 0},
		["Player Garage: Rockshore West"] = {2436.50, 698.43, 11.60, 0},
		["Player Garage: Santa Maria Beach"] = {322.65, -1780.30, 5.55, 0},
		["Player Garage: Whitewood Estates"] = {917.46, 2012.14, 11.65, 0},
		["Commerce Region Loading Bay"] = {1641.14 ,-1526.87, 14.30, 0},
		["San Fierro Police Garage"] = {-1617.58, 688.69, -4.50, 0},
		["Los Santos Cemetery"] = {837.05, -1101.93, 23.98, 0},
		["Grove Street"] = {2536.08, -1632.98, 13.79, 0},
		["4D casino"] = {1992.93, 1047.31, 10.82, 0},
		["LS Hospital"] = {2033.00, -1416.02, 16.99, 0},
		["SF Hospital"] = {-2653.11, 634.78, 14.45, 0},
		["LV Hospital"] = {1580.22, 1768.93, 10.82, 0},
		["SF Export"] = {-1550.73, 99.29, 17.33, 0},
		["Otto's Autos"] = {-1658.1656, 1215.0002, 7.25, 0},
		["Wang Cars"] = {-1961.6281, 295.2378, 35.4688, 0},
		["Palamino Bank"] = {2306.3826, -15.2365, 26.7496, 0},
		["Palamino Diner"] = {2331.8984, 6.7816, 26.5032, 0},
		["Dillimore Gas Station"] = {663.0588, -573.6274, 16.3359, 0},
		["Torreno's Ranch"] = {-688.1496, 942.0826, 13.6328, 0},
		["Zombotech - lobby area"] = {-1916.1268, 714.8617, 46.5625, 0},
		["Crypt in LS cemetery (temple)"] = {818.7714, -1102.8689, 25.794, 0},
		["Blueberry Liquor Store"] = {255.2083, -59.6753, 1.5703, 0},
		["Warehouse 3"] = {2135.2004, -2276.2815, 20.6719, 0},
		["K.A.C.C. Military Fuels Depot"] = {2548.4807, 2823.7429, 10.8203, 0},
		["Area 69"] = {215.1515, 1874.0579, 13.1406, 0},
		["Bike School"] = {1168.512, 1360.1145, 10.9293, 0}
	}
}

tpListRVRP = {
	["Фракции"] = {
		["LSPD"] = {1543.4442, -1675.2795, 13.5565, 0},
		["SFPD"] = {-1606.9584, 720.8036, 12.2308, 0},
		["LVPD"] = {2287.3582, 2421.3423, 10.8203, 0},
		["Больница LS"] = {1178.7211, -1326.7101, 14.1560, 0},
		["Больница SF"] = {-2662.2585, 625.6224, 14.4531, 0},
		["Больница LV"] = {1632.9490, 1821.7103, 10.8203, 0},
		["ФБР"] = {1046.4518, 1026.6058, 10.9978, 0},
		["Правительство"] = {1407.8854, -1788.0032, 13.5469, 0},
		["Radio LS"] = {760.8872, -1358.9816, 13.5198, 0},
		["Radio LV"] = {947.7136, 1743.1909, 8.8516, 0},
		["Автошкола"] = {-2037.7787, -99.7488, 35.1641, 0},
		["Отдел лицензирования"] = {1910.5309, 2343.3171, 10.8203, 0},
		["Нац. гвардия"] = {312.4188, 1959.1595, 17.6406, 0},
		["Русская мафия"] = {-2723.7395, -313.8499, 7.1860, 0},
		["Якудза"] = {1492.9370, 724.5159, 10.8203, 0},
		["Aztecas"] = {1673.0597, -2113.4204, 13.5469, 0},
		["Grove"] = {2493.1980, -1673.9980, 13.3359, 0},
		["Ballas"] = {2629.8752, -1077.4902, 69.6170, 0},
		["Vagos"] = {2658.0203, -1991.8776, 13.5546, 0},
		["Rifa"] = {2179.6760, -1001.7764, 62.9305, 0},
		["Comrades MC"] = {157.9299, -172.9156, 1.5781, 0},
		["Warlock MC"] = {-862.3333, 1539.7640, 22.5562, 0}
	},
	["Работы"] = {
		["Нефтянная вышка"] = {815.8508, 604.5477, 11.8305, 0},
		["Грузчик"] = {2788.3308, -2437.6555, 13.6335, 0},
		["Автоцех"] = {-49.9263, -277.9673, 5.4297, 0},
		["Автоцех (Интерьер)"] = {-570.5103, -82.4685, 3001.0859, 1},
		["Дальнобойщик"] = {-504.6666, -545.2240, 25.5234, 0},
		["Лесоруб"] = {-555.8159, -189.0762, 78.4063, 0},
		["Мойщик улиц"] = {-2586.7097, 608.1636, 14.4531, 0},
		["Инкасатор"] = {2168.6331, 998.6193, 10.8203, 0}
	},
	["Остальное"] = {
		["Маяк"] = {154.9556, -1939.6304, 3.7734, 0},
		["Колесо обозрения"] = {381.6406, -2044.5220, 7.8359, 0},
		["Банк"] = {1457.3635, -1027.2981, 23.8281, 0},
		["Чиллиад"] = {-2242.5701, -1731.3767, 480.3250, 0},
		["Биржа труда"] = {554.2763, -1500.1908, 14.5191, 0},
		["Черный рынок"] = {341.1162, -97.6198, 1.4143, 0},
		["Автосалон"] = {-2447.2839, 750.6021, 35.1719, 0},
		["БУ рынок"] = {1492.5591, 2809.7349, 10.8203, 0},
		["ЖДЛС"] = {1707.0590, -1895.5723, 13.5685, 0},
		["ЖДСФ"] = {-1975.0864, 141.7100, 27.6873, 0},
		["ЖДЛВ"] = {2839.9119, 1286.1318, 11.3906, 0},
		["Кладбище LS"] = {936.1039, -1101.4722, 24.3431, 0},
		["Торговый центр"] = {1306.2538, -1331.6825, 13.6422, 0},
		["Страховая"] = {2129.5217, -1139.7073, 25.2925, 0},
		["Аренда авто LS"] = {568.2047, -1290.3613, 17.2422, 0},
		["Аренда авто SF"] = {-1972.5128, 257.3625, 35.1719, 0},
		["Аренда авто LV"] = {2257.1780, 2033.8057, 10.8203, 0},
		["Аренда авто LV (Возле казино)"] = {1897.5586, 949.3096, 10.8203, 0},
		["Карьер"] = {626.8690, 853.0729, -42.9609, 0},
		["Автосервис"] = {617.2724, -1520.0159, 15.2100, 0},
		["Департамент администрации"] = {635.7059, -565.4893, 16.3359, 0},
		["Военкомат"] = {-2449.4761, 498.7346, 30.0873, 0},
		["Казино"] = {2031.1218, 1006.4854, 10.8203, 0},
		["Казино-мини"] = {1015.9720, -1127.6450, 23.8574, 0},
		["Разборка LV"] = {-1506.7286, 2623.1606, 55.8359, 0},
		["Разборка LS-SF"] = {-2110.1580, -2431.3657, 30.6250, 0},
		["Заброшенный завод"] = {1044.2622, 2078.8237, 10.8203, 0},
		["Тренировочный комлпекс"] = {2478.8884, -2108.2769, 13.5469, 0},
		["Состязательная арена"] = {1088.4347, -900.3381, 42.7011, 0},
		["Остров \"Невезения\""] = {616.4134, -3549.7146, 86.9716, 0},
		["Экспорт ТС"] = {-1549.0760, 121.4793, 3.5547, 0},
		["Тир"] = {-2689.1277, 0.0403, 6.1328, 0},
		["Трущобы"] = {-2541.6707, 25.9529, 16.4438, 0},
		["Аэропорт LS"] = {1449.0017, -2461.8296, 13.5547, 0},
		["Аэропорт SF"] = {-1654.5244, -173.4216, 14.1484, 0},
		["Аэропорт LV"] = {1337.8947, 1303.8196, 10.8203, 0}
	},
	["Остальное (Интерьеры)"] = {
		["Старый деморган"] = {1281.1638, -1.8006, 1001.0133, 18},
		["Банк"] = {1463.0361, -1009.3804, 34.4652, 0},
		["Биржа труда"] = {1561.1443, -1518.2223, 3001.5188, 15},
		["Черный рынок"] = {1696.5221, -1586.8097, 2875.2939, 1},
		["Черный рынок (пропуск)"] = {1569.4727, 1230.9999, 1055.1804, 1},
		["Автосалон"] = {2489.1558, -1017.1227, 1033.1460, 1},
		["Департамент администрации"] = {-265.7054, 725.4685, 1000.0859, 5},
		["Военкомат"] = {223.4714, 1540.9908, 3001.0859, 1},
		["Казино"] = {1888.7018, 1049.5775, 996.8770, 1},
		["Казино-мини"] = {1411.5062, -586.6498, 1607.3579, 1},
		["Тренировочный комлпекс"] = {2365.9114, -1943.3044, 919.4700, 1},
		["Состязательная арена"] = {825.7631, -1578.9291, 3001.0823, 3},
		["Тир"] = {285.8546, -78.9205, 1001.5156, 4},
		["Торговый центр"] = {1359.7142, -27.9618, 1000.9163, 1},
		["Страховая"] = {1707.3676, 636.4663, 3001.0859, 1}
	}
}
--params
local tag = '{F67B2E}AT {0984d2}- '
local tagwarn = '{F67B2E}AT Warning {0984d2}- '
local enabled = true
local checkAirBrk = false
local airBrkCrds = {}
local checkClickwarp = false
local checkNT = false
local cPuns = false
local cReq = false
local aSp = false
local admins = {}
local stream = true
--params mimgui
local renderWindow = new.bool(false)

local airbrk = new.bool(mainIni.cheats.airbrake)
local airbrkSpeed = new.float(mainIni.cheats.airbrakeSpeed)
local nmtg = new.bool(mainIni.cheats.nametag)
local skeleton = new.bool(mainIni.cheats.skeleton)
local whKey = new.bool(mainIni.cheats.whKey)
local clckwrp = new.bool(mainIni.cheats.clickwarp)
local sh = new.bool(mainIni.cheats.sh)
local shmax = new.float(mainIni.cheats.shMaxSpeed)
local shsmooth = new.int(mainIni.cheats.shSmooth)
local traserbull = new.bool(mainIni.cheats.traserBullets)
local traserbullSpec = new.bool(mainIni.cheats.traserBulletsSpec)
local gmAct = new.bool(mainIni.cheats.GM_actor)
local gmVeh = new.bool(mainIni.cheats.GM_vehicle)
local infammo = new.bool(mainIni.cheats.infammo)
local flip = new.bool(mainIni.cheats.flip)

local aChat = new.bool(mainIni.admintools.Chat)
local WTChat = new.bool(mainIni.admintools.WTChat)
local klistid = new.bool(mainIni.admintools.klistid)
local ancmd = new.bool(mainIni.admintools.NewCmd)
local ascmd = new.bool(mainIni.admintools.ShortCmd)
local aPuns = new.bool(mainIni.admintools.aPuns)
local aReq = new.bool(mainIni.admintools.aReq)
local aSpec = new.bool(mainIni.admintools.aSpec)
local autoSpawn = new.bool(mainIni.admintools.autoSpawn)
local frakOnChat = new.bool(mainIni.admintools.frakOnChat)

local inputPassAdmin = new.char[7](statsIni.stats.passAdmin)
local inputPassAcc = new.char[33](statsIni.stats.passAcc)
local checkALVL = new.char[5](statsIni.stats.ALVL)
local answers = new.int(statsIni.stats.answers)

local usemed = new.bool(false)
local usedrugs = new.bool(false)
local makegun = new.bool(false)
local usemask = new.bool(false)
local getherePm = new.bool(false)
local getherePmSendMessage = new.bool(false)
--others
if not doesDirectoryExist("moonloader\\config\\admintools") then
	createDirectory("moonloader\\config\\admintools")
end

if checkALVL[0] == tonumber(1) then ahelp_dialogArr = {"ALVL {0984d2}1"}
elseif checkALVL[0] == tonumber(2) then ahelp_dialogArr = {"ALVL {0984d2}1", "ALVL {0984d2}2"}
elseif checkALVL[0] == tonumber(3) then ahelp_dialogArr = {"ALVL {0984d2}1", "ALVL {0984d2}2", "ALVL {0984d2}3"}
elseif checkALVL[0] == tonumber(4) then ahelp_dialogArr = {"ALVL {0984d2}1", "ALVL {0984d2}2", "ALVL {0984d2}3", "ALVL {0984d2}4"}
elseif checkALVL[0] == tonumber(5) then ahelp_dialogArr = {"ALVL {0984d2}1", "ALVL {0984d2}2", "ALVL {0984d2}3", "ALVL {0984d2}4", "ALVL {0984d2}5"}
elseif checkALVL[0] == tonumber(6) then ahelp_dialogArr = {"ALVL {0984d2}1", "ALVL {0984d2}2", "ALVL {0984d2}3", "ALVL {0984d2}4", "ALVL {0984d2}5", "ALVL {0984d2}6"}
elseif checkALVL[0] == tonumber(7) then ahelp_dialogArr = {"ALVL {0984d2}1", "ALVL {0984d2}2", "ALVL {0984d2}3", "ALVL {0984d2}4", "ALVL {0984d2}5", "ALVL {0984d2}6", "ALVL {0984d2}7"}
else ahelp_dialogArr = {"ALVL {0984d2}1", "ALVL {0984d2}2", "ALVL {0984d2}3", "ALVL {0984d2}4", "ALVL {0984d2}5", "ALVL {0984d2}6", "ALVL {0984d2}7"} end

local ahelp_dialogStr = ""
for _, str in ipairs(ahelp_dialogArr) do ahelp_dialogStr = ahelp_dialogStr .. str .. "\n" end

function main()
    if not isSampLoaded() and not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(0) end

	if secondIni.server.address ~= nil and secondIni.server.address ~= sampGetCurrentServerAddress() then 
		sampAddChatMessage(tag..'Вы зашли не на основной сервер. Скрипт завершил работу', main_color)
		thisScript():unload()
	else
		sampAddChatMessage(tag..'Скрипт успешно загружен. Версия скрипита: {F67B2E}'..version_script, main_color)
	end

    if not doesFileExist('moonloader/config/admintools/cfg.ini') then
		inicfg.save(mainIni, "..\\config\\admintools\\cfg.ini")
	end
	
	if not doesFileExist('moonloader/config/admintools/stats.ini') then
		inicfg.save(statsIni, "..\\config\\admintools\\stats.ini")
	end

	if not doesFileExist('moonloader/config/admintools/rememberserver.ini') then
		inicfg.save(secondIni, "..\\config\\admintools\\rememberserver.ini")
	end

    clickfont = renderCreateFont("Tahoma", 10, FCR_BOLD + FCR_BORDER)

    _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
    nick = sampGetPlayerNickname(id)

	sampRegisterChatCommand('atmenu', cmd_menu);sampRegisterChatCommand('atreload', cmd_reload);sampRegisterChatCommand('atmark', cmd_setmark);sampRegisterChatCommand('atgotomark', cmd_tpmark)
	sampRegisterChatCommand('sp', cmd_spec);sampRegisterChatCommand('spoff', cmd_specoff);sampRegisterChatCommand('fix', cmd_fixveh);sampRegisterChatCommand('gg', cmd_gg);sampRegisterChatCommand('rvanka', cmd_rvanka)
	sampRegisterChatCommand('hp', cmd_sethpme);sampRegisterChatCommand('ffveh', cmd_FillFixVeh);sampRegisterChatCommand('dellobjs', cmd_deleteobjects);sampRegisterChatCommand('kinv', cmd_kickinvite)
	sampRegisterChatCommand('gh', cmd_gethere);sampRegisterChatCommand('dm', cmd_dm);sampRegisterChatCommand('bike', cmd_bike);sampRegisterChatCommand('dcar', cmd_destroycar);sampRegisterChatCommand('cheat', cmd_cheat)
	sampRegisterChatCommand('fraklvl', cmd_fraklvl);sampRegisterChatCommand('piarask', cmd_piarask);sampRegisterChatCommand('fz', cmd_freeze);sampRegisterChatCommand('ufz', cmd_unfreeze)
	sampRegisterChatCommand('ainv', cmd_ainvite);sampRegisterChatCommand('gc', cmd_getcar);sampRegisterChatCommand('rscars', cmd_rspawncars);sampRegisterChatCommand('ahelp', cmd_ahelp);sampRegisterChatCommand('piarask2', cmd_piarask2)
	sampRegisterChatCommand('ap', cmd_puns);sampRegisterChatCommand('ar', cmd_req);sampRegisterChatCommand('gcid', cmd_gcid)

	repeat
		wait(0)
	until sampIsLocalPlayerSpawned()
	if str(inputPassAdmin) ~= '' then sampSendChat('/a') end
    
    while true do
        wait(0)
        if enabled then
            key_funcs()
            main_funcs()
		end

		local result_d, button, list, input = sampHasDialogRespond(1998)
		if result_d then
			if button == 1 then
				if list == 0 then
					sampShowDialog(1991, 'ALVL {0984d2}1', "/a - админ чат\n/admins - просмотр админов онлайн\n/an - ответить на репорт\n/spec - следить за игроком\n/specoff - перестать следить\n/jail - посадить в тюрьму\n/kick - кикнуть игрока\n/check - просмотр статистики персонажа\n/anames - история ник-неймов\n/tp - телепорт\n/ftp - телепорт к организациям\n/goto - телепорт к игроку\n/fixveh - починить транспорт\n/spawncar - заспавнить ID транспорта (/dl)\n/checkad - проверка объявлений\n/cheaters - игроки у которых установлен собейт\n/getcar - призвать ID транспорта (/dl)\n/aen - проверить вкл/выкл двигатель транспорта\n/hit - проверить урон попаданий игрока, выстрелы\n/zz - как /o, только со скобками и другим цветом\n/2int2 - Тп в другой мир\n/amask - Маска для администратора, работает как обычный /mask\n/google - проверка гуглаунтификатора\n/weekers - владельцы виктайма в сети\n/auron - показывает кому игрок последний раз нанёс урон и от кого получил", 'Закрыть', '', 0)
				elseif list == 1 then
					sampShowDialog(1992, 'ALVL {0984d2}2', "/ban - забанить игрока\n/warn - дать предупреждение\n/mute - дать молчанку\n/spawn - отправить игрока на спавн\n/abizz - просмотр информации про все бизнессы штата\n/ajobs - просмотр трудовой книги игрока\n/biz - тп в биз\n/house - тп в дом\n/garage - тп в гараж\n/destroycar - уничтожить созданный транспорт\n/fillveh - заправить транспорт\n/gethere - тп к себе игрока\n/sban - тихо забанить игрока\n/amembers - проверить онлайн во фракции\n/o - чат видный всем игрокам\n/setsex - смена пола игроку\n/setnat - смена расы игроку", 'Закрыть', '', 0)
				elseif list == 2 then
					sampShowDialog(1993, 'ALVL {0984d2}3', "/mpgo - начать мероприятие\n/ainvite - инвайтнуть себя во фракцию\n/mark - поставить метку\n/gotomark - тп на метку\n/setvehhp - установите хп авто (/dl)\n/unjail - выпустить из тюрьмы\n/sethp - изменить здоровье игроку\n/veh - создать транспорт (не забыть удалить)\n/dellveh - удалить весь созданный транспорт за сервере\n/slap - слапнуть игрока\n/freeze - заморозить игрока\n/unfreeze - разморозить игрока\n/spawncars - заспавнить весь транспорт\n/fuelcars - заправить весь транспорт\n/disarm - обезоружить игрока\n/cc - очистить чат\n/kickjob - уволить с работы\n/mpskin - выдать временный скин\n/rspawncars - заспавнить транспорт в радиусе\n/dmzone - запустить страйкбол\n/deleteobjects - удалить ПД объекты на сервере\n/skick - тихо кикнуть игрока", 'Закрыть', '', 0)
				elseif list == 3 then
					sampShowDialog(1994, 'ALVL {0984d2}4', "/getip - IP игрока\n/alock - открыть транспорт\n/alock2 - закрыть транспорт\n/setname - сменить ник-нейм игроку\n/setnames - заявки на смену ник-нейма\n/agl - выдать лицензию\n/int - сменить интерьер в доме\n/tpto -  игрока к другому игроку\n/kickinvite - уволить с фракции\n/take - отбор лицензий\n/unban - разбанить аккаунт\n/aobject - создать объект (нужен 8 ранг в ПД)\n/razborka1 - перекрасить разборку байкеров\n/unwarn - снять варн", 'Закрыть', '', 0)
				elseif list == 4 then
					sampShowDialog(1995, 'ALVL {0984d2}5', "/apark - припарковать транспорт\n/mole - написать всем игрокам СМС от лица сервера\n/glrp - прослушка чатов\n/agiverank - сменить ранг игроку\n/givegun - дать игроку оружие\n/setarmor - сменить состояние брони игроку\n/explode - взорвать игрока\n/unslot - очистить слоты транспортов игрока\n/weather - сменить погоду\n/sethprad - выдать хп всем в опр. радиусе\n/mpskinrad - выдать всем скин в опр. радиусе\n/givegunrad - выдать всем оружие в опр. радиусе\n/setarmorrad - выдать всех броню в опр. радиусе\n/1gungame - запустить \"Гонку Вооружений\"\n/1race - запустить гонку\n/stopattack - прекратить капт\n/giveport - выдать порт мафии\n/givesklad - дать склад байкерам\n/admtack - cнять кд на капт у банды\n/givegz - дать гангзону другой банде\n/zaprosip - посмотреть аккаунты на опр. IP\n/unbanip - разбанить IP\n/roof1 - передать чр/казино мафиям", 'Закрыть', '', 0)
				elseif list == 5 then
					sampShowDialog(1996, 'ALVL {0984d2}6', "/sethpall - изменить хп всем игрокам\n/alllic - дать все лицензии игроку\n/aengine - отключить систему двигателей на сервере(больше нагрузки, ддос)\n/acapture - отключить захваты(мероприятия и прочее)\n/rasform - полная расформировка гетто (общаки, репутация, количество убийств)\n/rasformbiker - расформировка общаков байкеров\n/giverep - выдать репутацию семье, ID фам в /pass\n/givevip - выдать VIP\n/givepoint - выдать квест-поинты", 'Закрыть', '', 0)
				elseif list == 6 then
					sampShowDialog(1997, 'ALVL {0984d2}7', "/banip - забанить IP\n/asellcar - продать транспорт (авторыночный)\n/asellbiz - продать биз\n/asellsbiz - продать сбиз\n/asellhouse - продать дом\n/kickmarriage - развести игрока\n/noooc - включить OOC чат\n/makedrugs - дать наркотики игроку\n/setskin - выдать скин\n/setskinslot - выдать скин на опр. слот\n/makehelper - выдать хелперку", 'Закрыть', '', 0)
				end
			end
		end

    end
end

--mimgui
function apply_custom_style()	
	imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
	local ImVec4 = imgui.ImVec4
	local ImVec2 = imgui.ImVec2
    style.WindowPadding = imgui.ImVec2(8, 8)
    style.WindowRounding = 6
	style.ChildRounding = 5
	style.FrameBorderSize = 1.0
    style.FramePadding = imgui.ImVec2(5, 3)
    style.FrameRounding = 3.0
    -- style.ItemSpacing = imgui.ImVec2(5, 4)
    -- style.ItemInnerSpacing = imgui.ImVec2(4, 4)
    style.IndentSpacing = 21
    style.ScrollbarSize = 10.0
    style.ScrollbarRounding = 13
    style.GrabMinSize = 8
    style.GrabRounding = 1
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
	style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
	colors[clr.Text]                 = ImVec4(1.00, 1.00, 1.00, 0.78)
    colors[clr.TextDisabled]         = ImVec4(1.00, 1.00, 1.00, 0.55)
    colors[clr.WindowBg]             = ImVec4(0.11, 0.15, 0.17, 1.00)
    colors[clr.ChildBg]        		 = ImVec4(0.15, 0.18, 0.22, 1.00)
    colors[clr.PopupBg]              = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.Border]               = ImVec4(0.43, 0.43, 0.50, 0.50)
    colors[clr.BorderShadow]         = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.FrameBg]              = ImVec4(0.20, 0.25, 0.29, 1.00)
    colors[clr.FrameBgHovered]       = ImVec4(0.12, 0.20, 0.28, 1.00)
    colors[clr.FrameBgActive]        = ImVec4(0.09, 0.12, 0.14, 1.00)
    colors[clr.TitleBg]              = ImVec4(0.53, 0.20, 0.16, 0.65)
    colors[clr.TitleBgActive]        = ImVec4(0.56, 0.14, 0.14, 1.00)
    colors[clr.TitleBgCollapsed]     = ImVec4(0.00, 0.00, 0.00, 0.51)
    colors[clr.MenuBarBg]            = ImVec4(0.15, 0.18, 0.22, 1.00)
    colors[clr.ScrollbarBg]          = ImVec4(0.02, 0.02, 0.02, 0.39)
    colors[clr.ScrollbarGrab]        = ImVec4(0.20, 0.25, 0.29, 1.00)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.18, 0.22, 0.25, 1.00)
    colors[clr.ScrollbarGrabActive]  = ImVec4(0.09, 0.21, 0.31, 1.00)
    colors[clr.CheckMark]            = ImVec4(1.00, 0.28, 0.28, 1.00)
    colors[clr.SliderGrab]           = ImVec4(0.64, 0.14, 0.14, 1.00)
    colors[clr.SliderGrabActive]     = ImVec4(1.00, 0.37, 0.37, 1.00)
    colors[clr.Button]               = ImVec4(0.59, 0.13, 0.13, 1.00)
    colors[clr.ButtonHovered]        = ImVec4(0.69, 0.15, 0.15, 1.00)
    colors[clr.ButtonActive]         = ImVec4(0.67, 0.13, 0.07, 1.00)
    colors[clr.Header]               = ImVec4(0.20, 0.25, 0.29, 0.55)
    colors[clr.HeaderHovered]        = ImVec4(0.98, 0.38, 0.26, 0.80)
    colors[clr.HeaderActive]         = ImVec4(0.98, 0.26, 0.26, 1.00)
    colors[clr.Separator]            = ImVec4(0.50, 0.50, 0.50, 1.00)
    colors[clr.SeparatorHovered]     = ImVec4(0.60, 0.60, 0.70, 1.00)
    colors[clr.SeparatorActive]      = ImVec4(0.70, 0.70, 0.90, 1.00)
    colors[clr.ResizeGrip]           = ImVec4(0.26, 0.59, 0.98, 0.25)
    colors[clr.ResizeGripHovered]    = ImVec4(0.26, 0.59, 0.98, 0.67)
    colors[clr.ResizeGripActive]     = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.PlotLines]            = ImVec4(0.61, 0.61, 0.61, 1.00)
    colors[clr.PlotLinesHovered]     = ImVec4(1.00, 0.43, 0.35, 1.00)
    colors[clr.PlotHistogram]        = ImVec4(0.90, 0.70, 0.00, 1.00)
    colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
    colors[clr.TextSelectedBg]       = ImVec4(0.25, 1.00, 0.00, 0.43)
    colors[clr.ModalWindowDimBg] 	 = ImVec4(1.00, 0.98, 0.95, 0.73)
end

imgui.OnInitialize(function()
	imgui.GetIO().IniFilename = nil
	apply_custom_style()
end)

local newFrame = imgui.OnFrame(
    function() return renderWindow[0] end,
    function(player)
        if not isSampfuncsConsoleActive() and not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() and checkALVL[0] >= tonumber(1) then
            imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            imgui.SetNextWindowSize(imgui.ImVec2(srX, srY), imgui.Cond.FirstUseEver)
            imgui.Begin('Admin Tools | ALVL: '..checkALVL[0]..' | Answers: '..answers[0]..' | Version: ' .. version_script, renderWindow, imgui.WindowFlags.NoResize)
			imgui.BeginChild('##start', imgui.ImVec2(115, srY-40), true)
            if imgui.Button('Admin Tools', imgui.ImVec2(100, 0)) then act1 = 2 end
            if imgui.Button(u8'Читы', imgui.ImVec2(100, 0)) then act1 = 1 end
            if imgui.Button(u8'Телепорты', imgui.ImVec2(100, 0)) then act1 = 4 end
			if imgui.Button(u8'Настройки', imgui.ImVec2(100, 0)) then act1 = 3 end
			if imgui.Button(u8'Помощь', imgui.ImVec2(100, 0)) then act1 = 5 end
			imgui.TextDisabled('\n\nCreator:\nPanSeek')
			imgui.TextDisabled('Thanks:\nWarhhogg; Cosmo;\nfrannya; FYP;\nimring')
            imgui.EndChild()
			imgui.SameLine()
            if act1 == 1 then
                imgui.BeginChild('##cheats', imgui.ImVec2(srX-140, srY-40), true)
                imgui.Checkbox('Airbrake', airbrk)
                imgui.TextQuestion(u8'Используйте: RSHIFT')
				imgui.SameLine()
				imgui.SliderFloat(u8'Скорость', airbrkSpeed, 0.1, 14.9, '%.1f', 1.5)
				imgui.Checkbox('NameTag', nmtg)
				imgui.SameLine()
				imgui.Checkbox(u8'Скелет', skeleton)
				if nmtg[0] or skeleton[0] then
					imgui.SameLine()
					imgui.Checkbox(u8'По клавише', whKey)
					imgui.TextQuestion(u8'Используйте: 1')
				end
                imgui.Checkbox('ClickWarp', clckwrp)
                imgui.TextQuestion(u8'Используйте: MBUTTON')
                imgui.Checkbox('Speedhack', sh)
                imgui.TextQuestion(u8'Используйте: ALT\nЧем выше "Плавность", тем плавнее "SpeedHack"')
				imgui.SameLine()
                imgui.SliderFloat(u8'Макс. скорость', shmax, 80, 300, '%.f', 0.5)
                imgui.Spacing()
                imgui.SameLine(nil, 116)
				imgui.SliderInt(u8'Плавность', shsmooth, 5, 150)
				imgui.Checkbox(u8'Трейсер пуль', traserbull)	
				if traserbull[0] then
					imgui.SameLine()
					imgui.Checkbox(u8'Только в слежке', traserbullSpec)
				end
				imgui.Checkbox(u8'Бесконечные патроны', infammo)
				imgui.Checkbox(u8'Поворот ТС на колеса', flip)
				imgui.TextQuestion(u8'Используйте: Delete')
				imgui.Checkbox(u8'GM на персонажа', gmAct)
				imgui.Checkbox(u8'GM на ТС', gmVeh)
                imgui.EndChild()
            elseif act1 == 4 then
				imgui.BeginChild('##teleports', imgui.ImVec2(srX-140, srY-40), true)
				if imgui.Button(u8'Основные') then act14 = 1 end
				imgui.SameLine()
				if imgui.Button(u8'Серверные') then act14 = 2 end
				imgui.Separator()
				if act14 == 1 then
					for structure, tOrg in pairs(tpListMain) do
						if imgui.CollapsingHeader(u8(structure)) then
							imgui.Columns(3)
							for orgName, tCoords in pairs(tOrg) do
								if imgui.Button(u8(orgName), imgui.ImVec2(-1, 20)) then
									teleportInterior(playerPed, tCoords[1], tCoords[2], tCoords[3], tCoords[4])
								end
								imgui.NextColumn()
							end
							imgui.Columns(1)
						end
					end
				elseif act14 == 2 then
					for structure, tOrg in pairs(tpListRVRP) do
						if imgui.CollapsingHeader(u8(structure)) then
							imgui.Columns(3)
							for orgName, tCoords in pairs(tOrg) do
								if imgui.Button(u8(orgName), imgui.ImVec2(-1, 20)) then
									teleportInterior(playerPed, tCoords[1], tCoords[2], tCoords[3], tCoords[4])
								end
								imgui.NextColumn()
							end
							imgui.Columns(1)
						end
					end
				else act14 = 1 end
                imgui.EndChild()
            elseif act1 == 2 then
                imgui.BeginChild('##admintools', imgui.ImVec2(srX-140, srY-40), true)
                if imgui.Button(u8'Основное') then act12 = 1 end
				imgui.SameLine()
				if imgui.Button(u8'МП/ОПГ') then act12 = 2 end
				if checkALVL[0] >= tonumber(3) then
					imgui.SameLine()
					if imgui.Button(u8'Фракции') then act12 = 3 end
				end
                imgui.Separator()
				if act12 == 1 then
					imgui.Columns(2)
                    imgui.Checkbox(u8'Сокращенные команды', ascmd)
                    imgui.SameLine()
					imgui.Checkbox(u8'Новые команды', ancmd)
					imgui.Checkbox(u8'Административный чат', aChat)
					imgui.TextQuestion(u8'Меняет "Админ %d" на "[A %d]"')
					imgui.Checkbox(u8'ID в /rd', WTChat)
					imgui.TextQuestion(u8'Могут быть вылеты в связи с неправильным ник-неймом\nНапример, Nick_Name, а над головой/TAB\'е NiCk_Name')
					imgui.Checkbox(u8'ID в KillList\'е', klistid)
					imgui.TextQuestion(u8'Для применение функции - нужно перезайти в игру')
					imgui.NextColumn()
					imgui.Checkbox(u8'Авто-спавн', autoSpawn)
					imgui.TextQuestion(u8'Автоматически спавнит после авторизации')
					imgui.Checkbox(u8'Авто-слежка', aSpec)
					imgui.TextQuestion(u8'Когда античит показывает возможного нарушителя, то\nс помощью клавиши Y, вы сможете проследить за подозреваемым')
					if checkALVL[0] >= tonumber(2) then
						imgui.Checkbox(u8'Авто-наказания', aPuns)
						imgui.TextQuestion(u8'Не работает, если включено "Административный чат"\nМладшая администрация когда просит кого-то наказать,\n"/ban 420 3 0 чит" - Вам в чат покажут всю информацию. С помощью\nкоманды, /ap - накажете игрока (/ban 420 3 0 чит | N.Name)')
						imgui.Checkbox(u8'Авто-просьба', aReq)
						imgui.TextQuestion(u8'Не работает, если включено "Административный чат"\nМладшая администрация иногда просит заспавнить и т.п.,\n"/spawn 420" - Вам в чат покажут всю информацию. С помощью\nкоманды, /ar - выполните просьбу (/spawn 420)')
					end
					imgui.Columns(1)
				elseif act12 == 2 then
					if checkALVL[0] >= tonumber(2) then
						imgui.Checkbox(u8'Телепортировать, когда написали в PM "+"', getherePm)
						if not getherePm[0] then imgui.TextQuestion(u8'НЕ ЗАБЫВАЙТЕ ВЫКЛЮЧИТЬ после мероприятия\nДанная функция не сохраняется') end
						if getherePm[0] then
							imgui.SameLine()
							imgui.Checkbox(u8'Написать игроку, когда телепортировали', getherePmSendMessage)
							imgui.TextQuestion(u8'НЕ ЗАБЫВАЙТЕ ВЫКЛЮЧИТЬ после мероприятия\nДанные функции не сохраняются')
						end
						imgui.Separator()
					end
					if not stream then
						if imgui.Button(u8'По чату') then
							stream = not stream
						end
					elseif stream then
						if imgui.Button(u8'В зоне стрима') then
							stream = not stream
						end
						imgui.SameLine()
						imgui.Checkbox(u8'Показывать фракцию', frakOnChat)
						imgui.TextQuestion(u8'Работает только на "В зоне стрима"')
					end
					imgui.Spacing() imgui.Spacing() imgui.Spacing()
					imgui.Checkbox(u8'Использование аптечки', usemed)
					imgui.TextQuestion(u8'Когда игрок использует аптечку, в чате\nнапишется его Nick_Name[id] в виде "Warning"\nДанная функция не сохраняется')
					imgui.Checkbox(u8'Использование наркотиков', usedrugs)
					imgui.TextQuestion(u8'Когда игрок использует наркотики, в чате\nнапишется его Nick_Name[id] в виде "Warning"\nДанная функция не сохраняется')
					imgui.Checkbox(u8'Использование маски', usemask)
					imgui.TextQuestion(u8'Когда игрок использует маску, в чате\nнапишется его Nick_Name[id] в виде "Warning"\nДанная функция не сохраняется')
					imgui.Checkbox(u8'Изготовление оружия', makegun)
					imgui.TextQuestion(u8'Когда игрок изготовит оружие, в чате\nнапишется его Nick_Name[id] в виде "Warning"\nДанная функция не сохраняется')
				elseif act12 == 3 then
					imgui.Text(u8'Выберите фракцию, в которую нужно себя принять')
					if imgui.Button(u8'Никакая') then sampSendChat('/ainvite 0') end
					if imgui.CollapsingHeader(u8'Государственные фракции') then
						if imgui.Button(u8'Полиция ЛС') then sampSendChat('/ainvite 1') end
						imgui.SameLine()
						if imgui.Button(u8'Полиция СФ') then sampSendChat('/ainvite 20') end
						imgui.SameLine()
						if imgui.Button(u8'Полиция ЛВ') then sampSendChat('/ainvite 21') end
						if imgui.Button(u8'Госпиталь ЛС') then sampSendChat('/ainvite 2') end
						imgui.SameLine()
						if imgui.Button(u8'Госпиталь СФ') then sampSendChat('/ainvite 23') end
						imgui.SameLine()
						if imgui.Button(u8'Госпиталь ЛВ') then sampSendChat('/ainvite 24') end
						if imgui.Button(u8'ФБР') then sampSendChat('/ainvite 22') end
						if imgui.Button(u8'Правительство') then sampSendChat('/ainvite 3') end
						if imgui.Button(u8'Нац.гвардия') then sampSendChat('/ainvite 6') end
						if imgui.Button(u8'Лицензеры') then sampSendChat('/ainvite 5') end
						if imgui.Button(u8'СМИ ЛС') then sampSendChat('/ainvite 4') end
						imgui.SameLine()
						if imgui.Button(u8'СМИ ЛВ') then sampSendChat('/ainvite 25') end
					end
					if imgui.CollapsingHeader(u8'ОПГ') then
						if imgui.Button('Grove') then sampSendChat('/ainvite 11') end
						imgui.SameLine()
						if imgui.Button('Ballas') then sampSendChat('/ainvite 12') end
						imgui.SameLine()
						if imgui.Button('Aztecas') then sampSendChat('/ainvite 13') end
						imgui.SameLine()
						if imgui.Button('Vagos') then sampSendChat('/ainvite 14') end
						imgui.SameLine()
						if imgui.Button('Rifa') then sampSendChat('/ainvite 15') end
						if imgui.Button('Comrades MC') then sampSendChat('/ainvite 17') end
						imgui.SameLine()
						if imgui.Button('Warlocks MC') then sampSendChat('/ainvite 18') end
						if imgui.Button(u8'Русская мафия') then sampSendChat('/ainvite 7') end
						imgui.SameLine()
						if imgui.Button(u8'Якудза') then sampSendChat('/ainvite 8') end
					end
				else act12 = 1 end
                imgui.EndChild()
            elseif act1 == 3 then
				imgui.BeginChild('##settings', imgui.ImVec2(srX-140, srY-40), true)
				if secondIni.server.address == sampGetCurrentServerAddress() then
					if imgui.Button(u8(sampGetCurrentServerName()), imgui.ImVec2(400, 0)) then 
						secondIni.server.address = nil
						if inicfg.save(secondIni, "..\\config\\admintools\\rememberserver.ini") then
							secondIni = {
								server = {
									address = nil
								}
							} inicfg.save(secondIni, "..\\config\\admintools\\rememberserver.ini")
						end
					end
				else
					if imgui.Button(u8'Запомнить сервер', imgui.ImVec2(400, 0)) then 
						secondIni.server.address = sampGetCurrentServerAddress()
						if inicfg.save(secondIni, "..\\config\\admintools\\rememberserver.ini") then
							secondIni = {
								server = {
									address = sampGetCurrentServerAddress()
								}
							} inicfg.save(secondIni, "..\\config\\admintools\\rememberserver.ini")
						end
					end
				end
				imgui.TextQuestion(u8'Скрипт запомнит сервер и будет запускаться только на данном сервере')
				imgui.PushItemWidth(150)
				imgui.InputTextWithHint(u8'Админ-пароль', u8'ab1234', inputPassAdmin, sizeof(inputPassAdmin), not showPass1 and imgui.InputTextFlags.Password or 0)
				imgui.PopItemWidth()
				imgui.SameLine(nil, 17)
				if not showPass1 then if imgui.Button(u8'Показать ##1') then showPass1 = not showPass1 end
				else if imgui.Button(u8'Скрыть ##1') then showPass1 = not showPass1 end end
				imgui.SameLine()
				if imgui.Button(u8'Очистить ##1') then imgui.StrCopy(inputPassAdmin, '') end
				imgui.PushItemWidth(150)
				imgui.InputTextWithHint(u8'Аккаунт-пароль', u8'qwe123', inputPassAcc, sizeof(inputPassAcc), not showPass2 and imgui.InputTextFlags.Password or 0)
				imgui.PopItemWidth()
				imgui.SameLine()
				if not showPass2 then if imgui.Button(u8'Показать ##2') then showPass2 = not showPass2 end
				else if imgui.Button(u8'Скрыть ##2') then showPass2 = not showPass2 end end
				imgui.SameLine()
				if imgui.Button(u8'Очистить ##2') then imgui.StrCopy(inputPassAcc, '') end
				imgui.Spacing() imgui.Spacing() imgui.Spacing()
				imgui.Text(u8'Обратная связь:')
				imgui.Text('- Telegram: t.me/panseek')
				if imgui.IsItemClicked() then
					imgui.LogToClipboard()
					imgui.LogText('t.me/panseek')
					imgui.LogFinish()
				end
				imgui.Text(u8'- Тема на Blast.Hack: blast.hk/threads/74437')
				if imgui.IsItemClicked() then
					imgui.LogToClipboard()
					imgui.LogText('blast.hk/threads/74437')
					imgui.LogFinish()
				end
				imgui.Text(u8'- Пожертвования: qiwi.com/n/PANSEEK')
				if imgui.IsItemClicked() then
					imgui.LogToClipboard()
					imgui.LogText('qiwi.com/n/PANSEEK')
					imgui.LogFinish()
				end
				imgui.Text(u8'* Кликните по тексту для скопирования ссылки в буфер обмена')
                imgui.EndChild()
			elseif act1 == 5 then
				imgui.BeginChild('##help', imgui.ImVec2(srX-140, srY-40), true)
				if imgui.CollapsingHeader('AHELP') then
					imgui.Indent(10)
					if imgui.CollapsingHeader('ALVL 1') then
						imgui.Text(u8'/a - админ чат')
						imgui.Text(u8'/admins - просмотр админов онлайн')
						imgui.Text(u8'/an - ответить на репорт')
						imgui.Text(u8'/spec - следить за игроком')
						imgui.Text(u8'/specoff - перестать следить')
						imgui.Text(u8'/jail - посадить в тюрьму')
						imgui.Text(u8'/kick - кикнуть игрока')
						imgui.Text(u8'/check - просмотр статистики персонажа')
						imgui.Text(u8'/anames - история ник-неймов')
						imgui.Text(u8'/tp - телепорт')
						imgui.Text(u8'/ftp - телепорт к организациям')
						imgui.Text(u8'/goto - телепорт к игроку')
						imgui.Text(u8'/fixveh - починить транспорт')
						imgui.Text(u8'/spawncar - заспавнить ID транспорта (/dl)')
						imgui.Text(u8'/checkad - проверка объявлений')
						imgui.Text(u8'/cheaters - игроки у которых установлен собейт')
						imgui.Text(u8'/getcar - призвать ID транспорта (/dl)')
						imgui.Text(u8'/aen - проверить вкл/выкл двигатель транспорта')
						imgui.Text(u8'/hit - проверить урон попаданий игрока, выстрелы')
						imgui.Text(u8'/zz - как /o, только со скобками и другим цветом')
						imgui.Text(u8'/2int2 - Тп в другой мир')
						imgui.Text(u8'/amask - Маска для администратора, работает как обычный /mask')
						imgui.Text(u8'/google - проверка гуглаунтификатора')
						imgui.Text(u8'/weekers - владельцы виктайма в сети')
						imgui.Text(u8'/auron - показывает кому игрок последний раз нанёс урон и от кого получил')
					end
					if imgui.CollapsingHeader('ALVL 2') then
						imgui.Text(u8'/ban - забанить игрока')
						imgui.Text(u8'/warn - дать предупреждение')
						imgui.Text(u8'/mute - дать молчанку')
						imgui.Text(u8'/spawn - отправить игрока на спавн')
						imgui.Text(u8'/abizz - просмотр информации про все бизнессы штата')
						imgui.Text(u8'/ajobs - просмотр трудовой книги игрока')
						imgui.Text(u8'/biz - тп в биз')
						imgui.Text(u8'/house - тп в дом')
						imgui.Text(u8'/garage - тп в гараж')
						imgui.Text(u8'/destroycar - уничтожить созданный транспорт')
						imgui.Text(u8'/fillveh - заправить транспорт')
						imgui.Text(u8'/gethere - тп к себе игрока')
						imgui.Text(u8'/sban - тихо забанить игрока')
						imgui.Text(u8'/amembers - проверить онлайн во фракции')
						imgui.Text(u8'/o - чат видный всем игрокам')
						imgui.Text(u8'/setsex - смена пола игроку')
						imgui.Text(u8'/setnat - смена расы игроку')
					end
					if imgui.CollapsingHeader('ALVL 3') then
						imgui.Text(u8'/mpgo - начать мероприятие')
						imgui.Text(u8'/ainvite - инвайтнуть себя во фракцию')
						imgui.Text(u8'/mark - поставить метку')
						imgui.Text(u8'/gotomark - тп на метку')
						imgui.Text(u8'/setvehhp - установите хп авто (/dl)')
						imgui.Text(u8'/unjail - выпустить из тюрьмы')
						imgui.Text(u8'/sethp - изменить здоровье игроку')
						imgui.Text(u8'/veh - создать транспорт (не забыть удалить)')
						imgui.Text(u8'/dellveh - удалить весь созданный транспорт за сервере')
						imgui.Text(u8'/slap - слапнуть игрока')
						imgui.Text(u8'/freeze - заморозить игрока')
						imgui.Text(u8'/unfreeze - разморозить игрока')
						imgui.Text(u8'/spawncars - заспавнить весь транспорт')
						imgui.Text(u8'/fuelcars - заправить весь транспорт')
						imgui.Text(u8'/disarm - обезоружить игрока')
						imgui.Text(u8'/cc - очистить чат')
						imgui.Text(u8'/kickjob - уволить с работы')
						imgui.Text(u8'/mpskin - выдать временный скин')
						imgui.Text(u8'/rspawncars - заспавнить транспорт в радиусе')
						imgui.Text(u8'/dmzone - запустить страйкбол')
						imgui.Text(u8'/deleteobjects - удалить ПД объекты на сервере')
						imgui.Text(u8'/skick - тихо кикнуть игрока')
					end
					if imgui.CollapsingHeader('ALVL 4') then
						imgui.Text(u8'/getip - IP игрока')
						imgui.Text(u8'/alock - открыть транспорт')
						imgui.Text(u8'/alock2 - закрыть транспорт')
						imgui.Text(u8'/setname - сменить ник-нейм игроку')
						imgui.Text(u8'/setnames - заявки на смену ник-нейма')
						imgui.Text(u8'/agl - выдать лицензию')
						imgui.Text(u8'/int - сменить интерьер в доме')
						imgui.Text(u8'/tpto -  игрока к другому игроку')
						imgui.Text(u8'/kickinvite - уволить с фракции')
						imgui.Text(u8'/take - отбор лицензий')
						imgui.Text(u8'/unban - разбанить аккаунт')
						imgui.Text(u8'/aobject - создать объект (нужен 8 ранг в ПД)')
						imgui.Text(u8'/razborka1 - перекрасить разборку байкеров')
						imgui.Text(u8'/unwarn - снять варн')
					end
					if imgui.CollapsingHeader('ALVL 5') then
						imgui.Text(u8'/apark - припарковать транспорт')
						imgui.Text(u8'/mole - написать всем игрокам СМС от лица сервера')
						imgui.Text(u8'/glrp - прослушка чатов')
						imgui.Text(u8'/agiverank - сменить ранг игроку')
						imgui.Text(u8'/givegun - дать игроку оружие')
						imgui.Text(u8'/setarmor - сменить состояние брони игроку')
						imgui.Text(u8'/explode - взорвать игрока')
						imgui.Text(u8'/unslot - очистить слоты транспортов игрока')
						imgui.Text(u8'/weather - сменить погоду')
						imgui.Text(u8'/sethprad - выдать хп всем в опр. радиусе')
						imgui.Text(u8'/mpskinrad - выдать всем скин в опр. радиусе')
						imgui.Text(u8'/givegunrad - выдать всем оружие в опр. радиусе')
						imgui.Text(u8'/setarmorrad - выдать всех броню в опр. радиусе')
						imgui.Text(u8'/1gungame - запустить "Гонку Вооружений"')
						imgui.Text(u8'/1race - запустить гонку')
						imgui.Text(u8'/stopattack - прекратить капт')
						imgui.Text(u8'/giveport - выдать порт мафии')
						imgui.Text(u8'/givesklad - дать склад байкерам')
						imgui.Text(u8'/admtack - cнять кд на капт у банды')
						imgui.Text(u8'/givegz - дать гангзону другой банде')
						imgui.Text(u8'/zaprosip - посмотреть аккаунты на опр. IP')
						imgui.Text(u8'/unbanip - разбанить IP')
						imgui.Text(u8'/roof1 - передать чр/казино мафиям')
					end
					if imgui.CollapsingHeader('ALVL 6') then
						imgui.Text(u8'/sethpall - изменить хп всем игрокам')
						imgui.Text(u8'/alllic - дать все лицензии игроку')
						imgui.Text(u8'/aengine - отключить систему двигателей на сервере(больше нагрузки, ддос)')
						imgui.Text(u8'/acapture - отключить захваты(мероприятия и прочее)')
						imgui.Text(u8'/rasform - полная расформировка гетто (общаки, репутация, количество убийств)')
						imgui.Text(u8'/rasformbiker - расформировка общаков байкеров')
						imgui.Text(u8'/giverep - выдать репутацию семье, ID фам в /pass')
						imgui.Text(u8'/givevip - выдать VIP')
						imgui.Text(u8'/givepoint - выдать квест-поинты')
					end
					if imgui.CollapsingHeader('ALVL 7') then
						imgui.Text(u8'/banip - забанить IP')
						imgui.Text(u8'/asellcar - продать транспорт (авторыночный)')
						imgui.Text(u8'/asellbiz - продать биз')
						imgui.Text(u8'/asellsbiz - продать сбиз')
						imgui.Text(u8'/asellhouse - продать дом')
						imgui.Text(u8'/kickmarriage - развести игрока')
						imgui.Text(u8'/noooc - включить OOC чат')
						imgui.Text(u8'/makedrugs - дать наркотики игроку')
						imgui.Text(u8'/setskin - выдать скин')
						imgui.Text(u8'/setskinslot - выдать скин на опр. слот')
						imgui.Text(u8'/makehelper - выдать хелперку')
					end
					imgui.Unindent(10)
				end
				if imgui.CollapsingHeader(u8'ID фракций') then
					imgui.Indent(10)
					if imgui.CollapsingHeader(u8'Государственные фракции') then
						imgui.Text(u8'Полиция ЛС - 1')
						imgui.Text(u8'Полиция СФ - 20')
						imgui.Text(u8'Полиция ЛВ - 21')
						imgui.Spacing()
						imgui.Text(u8'Госпиталь ЛС - 2')
						imgui.Text(u8'Госпиталь СФ - 23')
						imgui.Text(u8'Госпиталь ЛВ - 24')
						imgui.Spacing()
						imgui.Text(u8'ФБР - 22')
						imgui.Spacing()
						imgui.Text(u8'Правительство - 3')
						imgui.Spacing()
						imgui.Text(u8'Нац.гвардия - 6')
						imgui.Spacing()
						imgui.Text(u8'Лицензеры - 5')
						imgui.Spacing()
						imgui.Text(u8'СМИ ЛС - 4')
						imgui.Text(u8'СМИ ЛВ - 25')
					end
					if imgui.CollapsingHeader(u8'ОПГ') then
						imgui.Text('Grove - 11')
						imgui.Text('Ballas - 12')
						imgui.Text('Aztecas - 13')
						imgui.Text('Vagos - 14')
						imgui.Text('Rifa - 15')
						imgui.Spacing()
						imgui.Text('Comrades MC - 17')
						imgui.Text('Warlocks MC - 18')
						imgui.Spacing()
						imgui.Text(u8'Русская мафия - 7')
						imgui.Text(u8'Якудза - 8')
					end
					imgui.Unindent(10)
				end
				if imgui.CollapsingHeader(u8'Сокращенные команды') then
					imgui.Text('/sp - /spec')
					imgui.Text('/spoff - /specoff')
					imgui.Text('/fix - /fixveh')
					imgui.Text('/gc - /getcar')
					if checkALVL[0] >= tonumber(2) then
						imgui.Text('/dcar - /destroycar')
						imgui.Text('/gh - /gethere')
					end
					if checkALVL[0] >= tonumber(3) then
						imgui.Text('/deleteobjects - /dellobjs')
						imgui.Text('/fz - /freeze')
						imgui.Text('/ufz - /unfreeze')
						imgui.Text('/ainv - /ainvite')
						imgui.Text('/rscars - /rspawncars')
					end
					if checkALVL[0] >= tonumber(4) then
						imgui.Text('/kinv - /kickinvite')
					end
				end
				if imgui.CollapsingHeader(u8'Новые команды') then
					imgui.Text(u8'/ahelp - Административные команды')
					imgui.Text(u8'/gg [id] - Желаете игроку новогоднее настроение и приятной игры')
					imgui.Text(u8'/fraklvl [id] - Пишет игроку какие фракции с какого уровня')
					imgui.Text(u8'/gcid [id] - Телепортирует ТС где находится игрок (Замена команд /dl -> /getcar [vID])')
					imgui.Text(u8'/dm [id] - Выдает jail игроку на 20 минут с причиной "DM"')
					imgui.Text(u8'/db [id] - Выдает jail игроку на 20 минут с причиной "DB"')
					if checkALVL[0] >= tonumber(2) then
						imgui.Text(u8'/cheat [id] - Выдает ban игроку на 3 дня (без IP бана) с причиной "Чит"')
						imgui.Text(u8'/rvanka [id] - Выдает ban игроку на 91 день (с IP баном) с причиной "Вредоносное ПО"')
						imgui.Text(u8'/ffveh - Чинит и заправляет ТС')
						imgui.Text(u8'/piarask - Пишет в общий чат про хелперов')
					end
					if checkALVL[0] >= tonumber(3) then
						imgui.Text(u8'/hp - Устанавливает Вам 150 единиц здоровья')
						imgui.Text(u8'/bike [num] - Создает велосипед (1 - Mountain; 2 - BMX; 3 - Bike)')
					end
				end
				if imgui.CollapsingHeader(u8'Команды скрипта') then
					imgui.Text(u8'/atmenu - Вызвать меню')
					imgui.Text(u8'/atreload - Перезагрузить скрипт')
					imgui.Text(u8'/atmark - Создать метку')
					imgui.Text(u8'/atgotomark - Телепортироваться к метке')
				end
				if imgui.CollapsingHeader('ChangeLog') then
					imgui.Indent(10)
					if imgui.CollapsingHeader(u8'Версия 1.2 (18.01.2021)') then
						imgui.Text(u8'Добавлена команда "/gcid [id]" - Телепортирует ТС где находится игрок (Замена команд /dl -> /getcar [vID])')
						imgui.Text(u8'Добавлены функции в "Читы" - Бесконечные патроны; Поворот ТС на колеса; Скелет')
						imgui.Text(u8'Добавлены функции в "AdmonTools" - ID в KillList\'е; Авто-просьба; Авто-слежка')
						imgui.Text(u8'Добавлен счетчик ответов (находится в заголовке меню)')
						imgui.Text(u8'Перенесены функции "Аккаунт-пароль" и "Админ-пароль" в "Настройки"')
						imgui.Text(u8'Подвкладка "Мероприятия" изменила название на "МП/ОПГ" в "AdminTools"')
						imgui.Text(u8'Теперь во вкладке "AdminTools" - "МП/ОПГ" есть режимы поиска (По чату; В зоне стрима)\nиспользование аптечки и т.п. Так же вывод фракции, если Вам это нужно')
						imgui.Text(u8'Изменен стиль меню, теперь он красный')
						imgui.Text(u8'Разные исправления')
					end
					if imgui.CollapsingHeader(u8'Версия 1.1 (9.01.2021)') then
						imgui.Text(u8'Добавлены функции в "Читы" - GM на персонажа; GM на ТС')
						imgui.Text(u8'Добавлены функции в "AdminTools" - Автоматическая авторизация в аккаунт; Авто-спавн;\nАвто-наказания; ID в /rd')
						imgui.Text(u8'Теперь в соответствии от Вашего ALVL будут доступны функции')
						imgui.Text(u8'Исправлена работа Airbrake')
						imgui.Text(u8'Мелкие исправления')
					end
					if imgui.CollapsingHeader(u8'Версия 1.0 (31.12.2020)') then
						imgui.Text(u8'Релиз')
					end
					imgui.Unindent(10)
				end
				imgui.EndChild()
			else act1 = 2 end
            imgui.End()
        end
    end
)

function key_funcs()
    if not isSampfuncsConsoleActive() and not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() then
        if isKeyJustPressed(vkeys.VK_F12) then
            renderWindow[0] = not renderWindow[0]
        end
        if airbrk[0] and isKeyJustPressed(vkeys.VK_RSHIFT) then
            checkAirBrk = not checkAirBrk
            if checkAirBrk then
                local posX, posY, posZ = getCharCoordinates(playerPed)
                airBrkCrds = {posX, posY, posZ, 0.0, 0.0, getCharHeading(playerPed)}
            end
		end
		if clckwrp[0] and isKeyJustPressed(vkeys.VK_MBUTTON) then
			checkClickwarp = not checkClickwarp
			if checkClickwarp then sampSetCursorMode(2) else sampSetCursorMode(0) end
		end
		if whKey[0] and isKeyJustPressed(vkeys.VK_1) then
			checkNT = not checkNT
			if checkNT then printStringNow('WH ~g~ON', 1000)
			else printStringNow('WH ~r~OFF', 1000) end
		end
		if aSp and isKeyJustPressed(vkeys.VK_Y) then
			sampSendChat('/spec '..idP)
			aSp = false
		end
    end
end

function main_funcs()
    if not isPauseMenuActive() then
		if (nmtg[0] and not checkNT and not whKey[0]) or (nmtg[0] and whKey[0] and checkNT) then
			nameTagOn()
		else
			nameTagOff()
		end

		if gmAct[0] then
			setCharProofs(playerPed, true, true, true, true, true)
  			writeMemory(0x96916E, 1, 1, false)
		else
			setCharProofs(playerPed, false, false, false, false, false)
			writeMemory(0x96916E, 1, 0, false)
		end

		if gmVeh[0] and isCharInAnyCar(playerPed) then
			setCarProofs(storeCarCharIsInNoSave(playerPed), true, true, true, true, true)
		end

		if infammo[0] then
			mem.setint8(0x969178, 1, false)
		else
			mem.setint8(0x969178, 0, false)
		end

		if flip[0] and isCharInAnyCar(PLAYER_PED) and isKeyJustPressed(vkeys.VK_DELETE) then
			local veh = storeCarCharIsInNoSave(PLAYER_PED)
            local oX, oY, oZ = getOffsetFromCarInWorldCoords(veh, 0.0,  0.0,  0.0)
			setCarCoordinates(veh, oX, oY, oZ)
			markCarAsNoLongerNeeded(veh)
		end

		local oTime = os.time()
		if (traserbull[0] and not traserbullSpec[0]) or (traserbull[0] and traserbullSpec[0] and recon) then
			for i = 1, BulletSync.maxLines do
				if BulletSync[i].enable == true and oTime <= BulletSync[i].time then
					local o, t = BulletSync[i].o, BulletSync[i].t
					if isPointOnScreen(o.x, o.y, o.z) and isPointOnScreen(t.x, t.y, t.z) then
						local sx, sy = convert3DCoordsToScreen(o.x, o.y, o.z)
						local fx, fy = convert3DCoordsToScreen(t.x, t.y, t.z)
						renderDrawLine(sx, sy, fx, fy, 1, BulletSync[i].tType == 0 and 0xFFFFFFFF or 0xFFFFC700)
						renderDrawPolygon(fx, fy-1, 3, 3, 4.0, 10, BulletSync[i].tType == 0 and 0xFFFFFFFF or 0xFFFFC700)
					end
				end
			end
		end

		if (skeleton[0] and not whKey[0]) or (skeleton[0] and whKey[0] and checkNT) then
			for i = 0, sampGetMaxPlayerId() do
				if sampIsPlayerConnected(i) then
					local result, cped = sampGetCharHandleBySampPlayerId(i)
					local color = sampGetPlayerColor(i)
					local aa, rr, gg, bb = explode_argb(color)
					local color = join_argb(255, rr, gg, bb)
					if result then
						if doesCharExist(cped) and isCharOnScreen(cped) then
							local t = {3, 4, 5, 51, 52, 41, 42, 31, 32, 33, 21, 22, 23, 2}
							for v = 1, #t do
								pos1X, pos1Y, pos1Z = getBodyPartCoordinates(t[v], cped)
								pos2X, pos2Y, pos2Z = getBodyPartCoordinates(t[v] + 1, cped)
								pos1, pos2 = convert3DCoordsToScreen(pos1X, pos1Y, pos1Z)
								pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
								renderDrawLine(pos1, pos2, pos3, pos4, 1, color)
							end
							for v = 4, 5 do
								pos2X, pos2Y, pos2Z = getBodyPartCoordinates(v * 10 + 1, cped)
								pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
								renderDrawLine(pos1, pos2, pos3, pos4, 1, color)
							end
							local t = {53, 43, 24, 34, 6}
							for v = 1, #t do
								posX, posY, posZ = getBodyPartCoordinates(t[v], cped)
								pos1, pos2 = convert3DCoordsToScreen(posX, posY, posZ)
							end
						end
					end
				end
			end
		end

        if airbrk[0] and checkAirBrk then
            AirBrakeSpeed = airbrkSpeed[0]
            if isCharInAnyCar(playerPed) then heading = getCarHeading(storeCarCharIsInNoSave(playerPed))
            else heading = getCharHeading(playerPed) end
            local camCoordX, camCoordY, camCoordZ = getActiveCameraCoordinates()
            local targetCamX, targetCamY, targetCamZ = getActiveCameraPointAt()
            local angle = getHeadingFromVector2d(targetCamX - camCoordX, targetCamY - camCoordY)
            if isCharInAnyCar(playerPed) then difference = 0.79 else difference = 1.0 end
            if isKeyDown(vkeys.VK_W) then
                if not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() then
                    airBrkCrds[1] = airBrkCrds[1] + AirBrakeSpeed * math.sin(-math.rad(angle))
                    airBrkCrds[2] = airBrkCrds[2] + AirBrakeSpeed * math.cos(-math.rad(angle))
                    setCharCoordinates(playerPed, airBrkCrds[1], airBrkCrds[2], airBrkCrds[3] - difference)
                    if not isCharInAnyCar(playerPed) then setCharHeading(playerPed, angle)
                    else setCarHeading(storeCarCharIsInNoSave(playerPed), angle) end
                else setCharCoordinates(playerPed, airBrkCrds[1], airBrkCrds[2], airBrkCrds[3] - 1.0) end
            elseif isKeyDown(vkeys.VK_S) then
                if not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() then
                    airBrkCrds[1] = airBrkCrds[1] - AirBrakeSpeed * math.sin(-math.rad(heading))
                    airBrkCrds[2] = airBrkCrds[2] - AirBrakeSpeed * math.cos(-math.rad(heading))
                    setCharCoordinates(playerPed, airBrkCrds[1], airBrkCrds[2], airBrkCrds[3] - difference)
                else setCharCoordinates(playerPed, airBrkCrds[1], airBrkCrds[2], airBrkCrds[3] - 1.0) end
            end
            if isKeyDown(vkeys.VK_A) then
                if not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() then
                    airBrkCrds[1] = airBrkCrds[1] - AirBrakeSpeed * math.sin(-math.rad(heading - 90))
                    airBrkCrds[2] = airBrkCrds[2] - AirBrakeSpeed * math.cos(-math.rad(heading - 90))
                    setCharCoordinates(playerPed, airBrkCrds[1], airBrkCrds[2], airBrkCrds[3] - difference)
                else setCharCoordinates(playerPed, airBrkCrds[1], airBrkCrds[2], airBrkCrds[3] - 1.0) end
            elseif isKeyDown(vkeys.VK_D) then
                if not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() then
                    airBrkCrds[1] = airBrkCrds[1] - AirBrakeSpeed * math.sin(-math.rad(heading + 90))
                    airBrkCrds[2] = airBrkCrds[2] - AirBrakeSpeed * math.cos(-math.rad(heading + 90))
                    setCharCoordinates(playerPed, airBrkCrds[1], airBrkCrds[2], airBrkCrds[3] - difference)
                else setCharCoordinates(playerPed, airBrkCrds[1], airBrkCrds[2], airBrkCrds[3] - 1.0) end
            end
            if isKeyDown(vkeys.VK_UP) then
                if not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() then
                    airBrkCrds[3] = airBrkCrds[3] + AirBrakeSpeed  / 2.0
                    setCharCoordinates(playerPed, airBrkCrds[1], airBrkCrds[2], airBrkCrds[3] - difference)
                else setCharCoordinates(playerPed, airBrkCrds[1], airBrkCrds[2], airBrkCrds[3] - 1.0) end
            end
            if isKeyDown(vkeys.VK_DOWN) and airBrkCrds[3] > -95.0 then
                if not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() then
                    airBrkCrds[3] = airBrkCrds[3] - AirBrakeSpeed  / 2.0
                    setCharCoordinates(playerPed, airBrkCrds[1], airBrkCrds[2], airBrkCrds[3] - difference)
                else setCharCoordinates(playerPed, airBrkCrds[1], airBrkCrds[2], airBrkCrds[3] - 1.0) end
            end
            if not isKeyDown(vkeys.VK_W) and not isKeyDown(vkeys.VK_S) and not isKeyDown(vkeys.VK_A) and not isKeyDown(vkeys.VK_D) and not isKeyDown(vkeys.VK_UP) and not isKeyDown(vkeys.VK_DOWN) then
                setCharCoordinates(playerPed, airBrkCrds[1], airBrkCrds[2], airBrkCrds[3] - 1.0)
            end
		end

		if not isSampfuncsConsoleActive() and not sampIsChatInputActive() and not sampIsDialogActive() then
            if sh[0] and isCharInAnyCar(PLAYER_PED) and isKeyDown(vkeys.VK_LMENU) then
                if getCarSpeed(storeCarCharIsInNoSave(PLAYER_PED)) * 2.01 <= shmax[0] then
                    local cVecX, cVecY, cVecZ = getCarSpeedVector(storeCarCharIsInNoSave(PLAYER_PED))
                    local heading = getCarHeading(storeCarCharIsInNoSave(PLAYER_PED))
                    local turbo = fps_correction() / shsmooth[0]
                    local xforce, yforce, zforce = turbo, turbo, turbo
                    local Sin, Cos = math.sin(-math.rad(heading)), math.cos(-math.rad(heading))
                    if cVecX > -0.01 and cVecX < 0.01 then xforce = 0.0 end
                    if cVecY > -0.01 and cVecY < 0.01 then yforce = 0.0 end
                    if cVecZ < 0 then zforce = -zforce end
                    if cVecZ > -2 and cVecZ < 15 then zforce = 0.0 end
                    if Sin > 0 and cVecX < 0 then xforce = -xforce end
                    if Sin < 0 and cVecX > 0 then xforce = -xforce end
                    if Cos > 0 and cVecY < 0 then yforce = -yforce end
                    if Cos < 0 and cVecY > 0 then yforce = -yforce end
                    applyForceToCar(storeCarCharIsInNoSave(PLAYER_PED), xforce * Sin, yforce * Cos, zforce / 2, 0.0, 0.0, 0.0)
                end
            end
            if clckwrp[0] and checkClickwarp then
                if sampGetCursorMode() == 0 then sampSetCursorMode(2) end
                local sx, sy = getCursorPos()
                local sw, sh = getScreenResolution()
                if sx >= 0 and sy >= 0 and sx < sw and sy < sh then
                    local posX, posY, posZ = convertScreenCoordsToWorld3D(sx, sy, 700.0)
                    local camX, camY, camZ = getActiveCameraCoordinates()
                    local result, colpoint = processLineOfSight(camX, camY, camZ, posX, posY, posZ, true, true, false, true, false, false, false)
                    if result and colpoint.entity ~= 0 then
                        local normal = colpoint.normal
                        local pos = Vector3D(colpoint.pos[1], colpoint.pos[2], colpoint.pos[3]) - (Vector3D(normal[1], normal[2], normal[3]) * 0.1)
                        local zOffset = 300
                        if normal[3] >= 0.5 then zOffset = 1 end
                        local result, colpoint2 = processLineOfSight(pos.x, pos.y, pos.z + zOffset, pos.x, pos.y, pos.z - 0.3,
                            true, true, false, true, false, false, false)
                        if result then
                            pos = Vector3D(colpoint2.pos[1], colpoint2.pos[2], colpoint2.pos[3] + 1)
                            local curX, curY, curZ = getCharCoordinates(PLAYER_PED)
                            local dist = getDistanceBetweenCoords3d(curX, curY, curZ, pos.x, pos.y, pos.z)
                            local hoffs = renderGetFontDrawHeight(clickfont)
                            sy = sy - 2
                            sx = sx - 2
                               renderFontDrawText(clickfont, string.format('Дистанция: %0.2f', dist), sx - (renderGetFontDrawTextLength(clickfont, string.format('Дистанция: %0.2f', dist)) / 2) + 6, sy - hoffs, 0xFFFFFFFF)
                            local tpIntoCar = nil
                            if colpoint.entityType == 2 then
                                local car = getVehiclePointerHandle(colpoint.entity)
                                if doesVehicleExist(car) and (not isCharInAnyCar(PLAYER_PED) or storeCarCharIsInNoSave(PLAYER_PED) ~= car) then
                                    if isKeyJustPressed(vkeys.VK_LBUTTON) and isKeyJustPressed(vkeys.VK_RBUTTON) then tpIntoCar = car end
                                    renderFontDrawText(clickfont, '{0984d2}Зажмите ПКМ чтобы {FFFFFF}сесть в транспорт', sx - (renderGetFontDrawTextLength(clickfont, '{0984d2}Зажмите ПКМ чтобы {FFFFFF}сесть в транспорт') / 2) + 6, sy - hoffs * 2, -1)
                                end
                            end
                            if isKeyJustPressed(vkeys.VK_LBUTTON) then
                                if tpIntoCar then
                                    if not jumpIntoCar(tpIntoCar) then
                                        teleportPlayer(pos.x, pos.y, pos.z)
                                    end
                                else
                                    if isCharInAnyCar(PLAYER_PED) then
                                        local norm = Vector3D(colpoint.normal[1], colpoint.normal[2], 0)
                                        local norm2 = Vector3D(colpoint2.normal[1], colpoint2.normal[2], colpoint2.normal[3])
                                        rotateCarAroundUpAxis(storeCarCharIsInNoSave(PLAYER_PED), norm2)
                                        pos = pos - norm * 1.8
                                        pos.z = pos.z - 1.1
                                    end
                                    teleportPlayer(pos.x, pos.y, pos.z)
                                end
                                sampSetCursorMode(0)
                                checkClickwarp = false
                            end
                        end
                    end
                end
            end

        end
    end
end

--sampev functions
function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
	if dialogId == 20260 and str(inputPassAdmin) ~= '' then
		sampSendDialogResponse(20260, 1, -1, str(inputPassAdmin))
		return false
	end
	if dialogId == 1 and str(inputPassAcc) ~= '' then
		sampSendDialogResponse(1, 1, -1, str(inputPassAcc))
		return false
	end
	if dialogId == 8888 and autoSpawn[0] then
		sampSendDialogResponse(8888, 1, 1)
		return false
	end
end

function sampev.onApplyPlayerAnimation(playerId, animLib, animName, loop, lockX, lockY, freeze, time)
	if stream then
		if usemed[0] and animLib == "FOOD" and animName == "EAT_Burger" then
			if frakOnChat[0] then
				local col = sampGetPlayerColor(id)
				if listColorFrac[col] then
					sampAddChatMessage(tagwarn..'Игрок {F67B2E}'..sampGetPlayerNickname(playerId)..'['..playerId..'] '..listColorFrac[sampGetPlayerColor(playerId)]..' {0984d2}использует аптечку!', main_color)
				else
					sampAddChatMessage(tagwarn..'Игрок {F67B2E}'..sampGetPlayerNickname(playerId)..'['..playerId..'] {ffffff}[CITIZEN] {0984d2}использует аптечку!', main_color)
				end
			else
				sampAddChatMessage(tagwarn..'Игрок {F67B2E}'..sampGetPlayerNickname(playerId)..'['..playerId..'] {0984d2}использует аптечку!', main_color)
			end
		end
		if usedrugs[0] and animLib == "SMOKING" and animName == "M_smk_in" then
			if frakOnChat[0] then
				local col = sampGetPlayerColor(id)
				if listColorFrac[col] then
					sampAddChatMessage(tagwarn..'Игрок {F67B2E}'..sampGetPlayerNickname(playerId)..'['..playerId..'] '..listColorFrac[sampGetPlayerColor(playerId)]..' {0984d2}использует наркотики!', main_color)
				else
					sampAddChatMessage(tagwarn..'Игрок {F67B2E}'..sampGetPlayerNickname(playerId)..'['..playerId..'] {ffffff}[CITIZEN] {0984d2}использует наркотики!', main_color)
				end
			else
				sampAddChatMessage(tagwarn..'Игрок {F67B2E}'..sampGetPlayerNickname(playerId)..'['..playerId..'] {0984d2}использует наркотики!', main_color)
			end
		end
		if makegun[0] and ((animLib == "COLT45" and animName == "colt45_reload") or (animLib == "BUDDY" and animName == "buddy_reload") or (animLib == "UZI" and animName == "UZI_reload")) then
			if frakOnChat[0] then
				local col = sampGetPlayerColor(id)
				if listColorFrac[col] then
					sampAddChatMessage(tagwarn..'Игрок {F67B2E}'..sampGetPlayerNickname(playerId)..'['..playerId..'] '..listColorFrac[sampGetPlayerColor(playerId)]..' {0984d2}изготовил оружие!', main_color)
				else
					sampAddChatMessage(tagwarn..'Игрок {F67B2E}'..sampGetPlayerNickname(playerId)..'['..playerId..'] {ffffff}[CITIZEN] {0984d2}изготовил оружие!', main_color)
				end
			else
				sampAddChatMessage(tagwarn..'Игрок {F67B2E}'..sampGetPlayerNickname(playerId)..'['..playerId..'] {0984d2}изготовил оружие!', main_color)
			end
		end
		if usemask[0] and animLib == "SHOP" and animName == "ROB_shifty" then
			if frakOnChat[0] then
				local col = sampGetPlayerColor(id)
				if listColorFrac[col] then
					sampAddChatMessage(tagwarn..'Игрок {F67B2E}'..sampGetPlayerNickname(playerId)..'['..playerId..'] '..listColorFrac[sampGetPlayerColor(playerId)]..' {0984d2}использует маску!', main_color)
				else
					sampAddChatMessage(tagwarn..'Игрок {F67B2E}'..sampGetPlayerNickname(playerId)..'['..playerId..'] {ffffff}[CITIZEN] {0984d2}использует маску!', main_color)
				end
			else
				sampAddChatMessage(tagwarn..'Игрок {F67B2E}'..sampGetPlayerNickname(playerId)..'['..playerId..'] {0984d2}использует маску!', main_color)
			end
		end
	end
end

function sampev.onServerMessage(color, text)
	local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
	local mynick = sampGetPlayerNickname(myid)

	if not text:find('говорит') and text:find('%{ffffff%}Вы вошли, как администратор %{00ff00%}%d+ %{ffffff%}уровня') then
		local alvl = text:match('%{ffffff%}Вы вошли, как администратор %{00ff00%}(%d+) %{ffffff%}уровня')
		-- statsIni.stats.checkALVL = alvl
		checkALVL[0] = tonumber(alvl)
		statsIni.stats.ALVL = checkALVL[0]
	end

	if text:find(mynick..' ответил (%w+_%w+)%[(%d+)%]: (.+)') then
		local plNick, plID, ans = text:match(mynick..' ответил (%w+_%w+)%[(%d+)%]: (.+)')
		answers[0] = answers[0] + 1
		statsIni.stats.answers = answers[0]
	end

    if aChat[0] and text:find ('Админ (%d+)') then -- color achat = 15180346
		admchat = text:gsub('Админ (%d+)', '[A %1]')
        return {color, admchat}
	end

	if WTChat[0] and text:find('%[РАЦИЯ%] (.+): (.+)') and (not text:find ('говорит') or not text:find('Админ (%d+) ([A-z_]+)%[(%d+)%]: (.+)') or not text:find('[FR] ([A-z_]+)%[(%d+)%]: (.+)') or not text:find('[FR] [Г] ([A-z_]+)%[(%d+)%]: (.+)')) then
		local WT, gNick, match = text:match('(%[РАЦИЯ%]) (.+): (.+)')
		return {color, WT..' '..gNick..'['..sampGetPlayerIdByNickname(gNick)..']: '..match}
	end

	--for auto
	if aPuns[0] then
		if (not text:find('говорит') or not text:find('[FR]')) and text:find('Админ (%d+) ([A-z_]+)%[(%d+)%]: ') and (checkALVL[0] >= tonumber(3) and (text:find('/ofjail (.+)') or text:find('/ofmute (.+)') or text:find('/skick (.+)'))) or (checkALVL[0] >= tonumber(2) and (text:find('/ban (.+)') or text:find('/warn (.+)') or text:find('/mute (.+)') or text:find('/sban (.+)'))) then
			local commands = {'ban', 'warn', 'mute', 'sban', 'skick', 'ofmute', 'ofjail'}
			nick, form = text:match('Админ %d+ ([A-z_]+)%[%d+%]: (.+)')
			if nick and form:match('^/') then
				local cmd = form:match('^/(%a+)')
				for _, v in ipairs(commands) do
					if cmd == v then
						cPuns = true
						aTag = getTagFromNickName(nick)
						out = ('%s | %s'):format(text, aTag)
						sampAddChatMessage(tag..'Используйте: {F67B2E}/ap {0984d2}|{F67B2E} '..form..' | '..aTag, main_color); return
					end
				end
			else cPuns = false end
			return {color, text}
		end
	end

	if aReq[0] then
		if (not text:find('говорит') or not text:find('[FR]')) and (checkALVL[0] >= tonumber(2) and text:find('Админ (%d+) ([A-z_]+)%[(%d+)%]: /spawn (.+)')) or (checkALVL[0] >= tonumber(3) and (text:find('Админ (%d+) ([A-z_]+)%[(%d+)%]: /sethp (.+)') or text:find('Админ (%d+) ([A-z_]+)%[(%d+)%]: /givegun (.+)'))) then
			local commands = {'spawn', 'sethp', 'givegun'}
			nick, formr = text:match('Админ %d+ ([A-z_]+)%[%d+%]: (.+)')
			if nick and formr:match('^/') then
				local cmd = formr:match('^/(%a+)')
				for _, v in ipairs(commands) do
					if cmd == v then
						cReq = true
						sampAddChatMessage(tag..'Используйте: {F67B2E}/ar {0984d2}|{F67B2E} '..formr, main_color); return
					end
				end
			else cReq = false end
			return {color, text}
		end
	end

	if aSpec[0] then
		if (not text:find('говорит') or not text:find('[FR]')) and (text:find(': (%w+_%w+)%[(%d+)%] подозрения на Fly/Speedhack(.+)') or text:find(': (%w+_%w+)%[(%d+)%] подозрения на телепортацию(.+)')) then
			nickP, idP, reason, specID = text:match('(%w+_%w+)%[(%d+)%] подозрения на (.+), используйте /spec (%d+).')
			nickP, idP, mph, reason, specID = text:match(': (%w+_%w+)%[(%d+)%] (%d+) mph Есть подозрения что этот игрок исользует (.+), используйте /spec (%d+).')
			if nickP and idP and reason then
				sampAddChatMessage(tag..'Игрок {F67B2E}'..nickP..'['..idP..'] {0984d2} - подозрения на '..reason..' | {F67B2E}Y {0984d2}- для слежки', main_color)
				aSp = true
			end
			return false
		end
	end

	--for mp
	if not stream then
		if getherePm[0] and not text:find('говорит') and text:find('PM от (%w+_%w+)%[(%d+)%]') and text:find('+') then
			local gNick, gID = text:match('PM от (%w+_%w+)%[(%d+)%]')
			sampSendChat('/gethere ' .. gID)
			if getherePmSendMessage[0] then sampSendChat('/pm ' .. gID .. ' Телепортировал Вас') end
			return {color, text}
		end
		if usedrugs[0] and not text:find('говорит') and text:find('(%w+_%w+) достал странную пробирку, с синим порошком внутри и резко вдохнул содержимое, затем кинул ее в сторону') then
			local gNick = text:match('(%w+_%w+) достал странную пробирку, с синим порошком внутри и резко вдохнул содержимое, затем кинул ее в сторону')
			sampAddChatMessage(tagwarn..'Игрок {F67B2E}'..gNick..'['..sampGetPlayerIdByNickname(gNick)..'] {0984d2}использует наркотики!', main_color)
			return {color, text}
		end
		if usemed[0] and not text:find('говорит') and text:find('(%w+_%w+) использует аптечку') then
			local gNick = text:match('(%w+_%w+) использует аптечку')
			sampAddChatMessage(tagwarn..'Игрок {F67B2E}'..gNick..'['..sampGetPlayerIdByNickname(gNick)..'] {0984d2}использует аптечку!', main_color)
			return {color, text}
		end
		if usemask[0] and not text:find('говорит') and text:find('(%w+_%w+) достал') and text:find('из кармана маску и надел') and text:find('ее на лицо.') then
			local gNick = text:match('(%w+_%w+) достал(.+)')
			sampAddChatMessage(tagwarn..'Игрок {F67B2E}'..gNick..'['..sampGetPlayerIdByNickname(gNick)..'] {0984d2}использует маску!', main_color)
			return {color, text}
		end
		if makegun[0] and not text:find('говорит') and text:find('(%w+_%w+) собрал из материалов и деталей - (.+)') then
			local gNick, gGun = text:match('(%w+_%w+) собрал из материалов и деталей - (.+)')
			sampAddChatMessage(tagwarn..'Игрок {F67B2E}'..gNick..'['..sampGetPlayerIdByNickname(gNick)..'] {0984d2}собрал оружие {F67B2E}'..gGun..'{0984d2}!', main_color)
			return {color, text}
		end
	end
end

function sampev.onTogglePlayerSpectating(state)
	recon = state
end

function sampev.onBulletSync(playerid, data)
	if traserbull[0] then
		if data.target.x == -1 or data.target.y == -1 or data.target.z == -1 then
			return true
		end
		BulletSync.lastId = BulletSync.lastId + 1
		if BulletSync.lastId < 1 or BulletSync.lastId > BulletSync.maxLines then
			BulletSync.lastId = 1
		end
		local id = BulletSync.lastId
		BulletSync[id].enable = true
		BulletSync[id].tType = data.targetType
		BulletSync[id].time = os.time() + 2
		BulletSync[id].o.x, BulletSync[id].o.y, BulletSync[id].o.z = data.origin.x, data.origin.y, data.origin.z
		BulletSync[id].t.x, BulletSync[id].t.y, BulletSync[id].t.z = data.target.x, data.target.y, data.target.z
	end
end

function sampev.onPlayerDeathNotification(killerId, killedId, reason)
	if klistid[0] then
		local kill = ffi.cast('struct stKillInfo*', sampGetKillInfoPtr())
		local _, myid = sampGetPlayerIdByCharHandle(playerPed)

		local n_killer = ( sampIsPlayerConnected(killerId) or killerId == myid ) and sampGetPlayerNickname(killerId) or nil
		local n_killed = ( sampIsPlayerConnected(killedId) or killedId == myid ) and sampGetPlayerNickname(killedId) or nil
		lua_thread.create(function()
			wait(0)
			if n_killer then kill.killEntry[4].szKiller = ffi.new('char[25]', ( n_killer .. '[' .. killerId .. ']' ):sub(1, 24) ) end
			if n_killed then kill.killEntry[4].szVictim = ffi.new('char[25]', ( n_killed .. '[' .. killedId .. ']' ):sub(1, 24) ) end
		end)
	end
end

--terminate
function onScriptTerminate(script, quitGame)
	if script == thisScript() then
        mainIni = {
            cheats = {
                airbrake 				= airbrk[0],
                airbrakeSpeed           = airbrkSpeed[0],
                clickwarp               = clckwrp[0],
				nametag                 = nmtg[0],
				skeleton				= skeleton[0],
				whKey					= whKey[0],
                sh                      = sh[0],
                shMaxSpeed              = shmax[0],
				shSmooth                = shsmooth[0],
				traserBullets			= traserbull[0],
				traserBulletsSpec		= traserbullSpec[0],
				GM_actor				= gmAct[0],
				GM_vehicle				= gmVeh[0],
				infammo					= infammo[0],
				flip 					= flip[0]
            },
            admintools = {
				Chat 					= aChat[0],
				WTChat					= WTChat[0],
				klistid					= klistid[0],
                NewCmd 				    = ancmd[0],
				ShortCmd 				= ascmd[0],
				aPuns					= aPuns[0],
				aReq					= aReq[0],
				aSpec					= aSpec[0],
				autoSpawn				= autoSpawn[0],
				frakOnChat				= frakOnChat[0]
			}
		} inicfg.save(mainIni, "..\\config\\admintools\\cfg.ini")
		statsIni = {
			stats = {
				passAdmin				= str(inputPassAdmin),
				passAcc					= str(inputPassAcc),
				ALVL					= str(checkALVL),
				answers					= answers[0]
			}
		} inicfg.save(statsIni, "..\\config\\admintools\\stats.ini")
        sampAddChatMessage(tag..'Скрипт аварийно завершил работу и сохранил настройки', main_color)
    end
end

function cmd_menu()
    renderWindow[0] = not renderWindow[0]
	sampAddChatMessage(tag..'Для {F67B2E}открытия{0984d2}/{F67B2E}закрытия {0984d2}меню - используйте: {F67B2E}F12', main_color)
end

function cmd_setmark()
	local interiorMark = getActiveInterior(PLAYER_PED)
	intMark = {getActiveInterior(PLAYER_PED)}
	local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
	setmark = {posX, posY, posZ}
	sampAddChatMessage(tag..'Создана метка по координатам: X: {F67B2E}' .. math.floor(setmark[1]) .. '{0984d2} | Y: {F67B2E}' .. math.floor(setmark[2]) .. '{0984d2} | Z: {F67B2E}' .. math.floor(setmark[3]), main_color)
	sampAddChatMessage(tag..'Интерьер: {F67B2E}' .. interiorMark, main_color)
end

function cmd_tpmark()
	if setmark then		
		teleportInterior(PLAYER_PED, setmark[1], setmark[2], setmark[3], intMark[1])	
		sampAddChatMessage(tag..'Вы телепортировались по метке', main_color)
	else
		sampAddChatMessage(tag..'Метка не создана', main_color)
	end
end

function cmd_puns()
	if aPuns[0] then
		if cPuns == true then
			sampSendChat(form..' | '..aTag)
			cPuns = false
		else
			sampAddChatMessage(tagwarn..'Некого наказывать!', main_color)
		end
	end
end

function cmd_req()
	if aReq[0] then
		if cReq == true then
			sampSendChat(formr)
			cReq = false
		else
			sampAddChatMessage(tagwarn..'Нет просьбы!', main_color)
		end
	end
end

function cmd_reload()
	thisScript():reload()
end

function cmd_ahelp()
	if ancmd[0] then
		sampShowDialog(1998, "{0984d2}AHELP", ahelp_dialogStr, "Выбрать", "Закрыть", 2)
	end
end

function cmd_spec(pid)
	if ascmd[0] then
		local id = tonumber(pid)
		if id ~= nil and id >= 0 and id <= 1000 then
			sampSendChat('/spec '..id)
		else
			sampAddChatMessage(tag..'Используйте: {F67B2E}/sp [id]', main_color)
		end
	end
end

function cmd_freeze(pid)
	if ascmd[0] then
		local id = tonumber(pid)
		if id ~= nil and id >= 0 and id <= 1000 then
			sampSendChat('/freeze '..id)
		else
			sampAddChatMessage(tag..'Используйте: {F67B2E}/fz [id]', main_color)
		end
	end
end

function cmd_unfreeze(pid)
	if ascmd[0] then
		local id = tonumber(pid)
		if id ~= nil and id >= 0 and id <= 1000 then
			sampSendChat('/unfreeze '..id)
		else
			sampAddChatMessage(tag..'Используйте: {F67B2E}/ufz [id]', main_color)
		end
	end
end

function cmd_gg(pid)
	local ggans = {' Приятной игры и хорошего настроения на Revent Role Play!',
	' Желаем Вам приятной игры на Revent Role Play!',
	' Хорошего настроения и приятной игры на Revent Role Play!'}
	if ancmd[0] then
		local id = tonumber(pid)
		if id ~= nil and id >= 0 and id <= 1000 then
			math.randomseed(os.time())
			sampSendChat('/an ' .. id .. ggans[math.random(#ggans)])
		else
			sampAddChatMessage(tag..'Используйте: {F67B2E}/gg [id]', main_color)
		end
	end
end

function cmd_fraklvl(pid)
	local flvlmsg = {' ОПГ, больница, нац. гвардия, правительство - 1 LVL 2 EXP. Остальное - 2 LVL',
	' Больница, правительство, нац. гвардия, ОПГ - 1 LVL 2 EXP. Остальное - 2 LVL',
	' Нац. гвардия, больница, ОПГ, правительство - 1 LVL 2 EXP. Остальное - 2 LVL',
	' ОПГ, нац. гвардия, правительство, больница - 1 LVL 2 EXP. Остальное - 2 LVL',
	' Правительство, нац. гвардия, больница, ОПГ - 1 LVL 2 EXP. Остальное - 2 LVL'}
	if ancmd[0] then
		local id = tonumber(pid)
		if id ~= nil and id >= 0 and id <= 1000 then
			math.randomseed(os.time())
			sampSendChat('/an ' .. id .. flvlmsg[math.random(#flvlmsg)])
		else
			sampAddChatMessage(tag..'Используйте: {F67B2E}/fraklvl [id]', main_color)
		end
	end
end

function cmd_gethere(pid)
	if ascmd[0] then
		local id = tonumber(pid)
		if id ~= nil and id >= 0 and id <= 1000 then
			sampSendChat('/gethere '..id)
		else
			sampAddChatMessage(tag..'Используйте: {F67B2E}/gh [id]', main_color)
		end
	end
end

function cmd_kickinvite(param)
	if ascmd[0] then
		local id = tonumber(param)
		if id ~= nil and id >= 0 and id <= 1000 then
			sampSendChat('/kickinvite '..id)
		else
			sampAddChatMessage(tag..'Используйте: {F67B2E}/kinv [id]', main_color)
		end
	end
end

function cmd_getcar(param)
	if ascmd[0] then
		local vId = tonumber(param)
		if vId ~= nil and vId >= 0 and vId <= 2000 then
			sampSendChat('/getcar '..vId)
		else
			sampAddChatMessage(tag..'Используйте: {F67B2E}/gc [vId]', main_color)
		end
	end
end

function cmd_ainvite(param)
	if ascmd[0] then
		local idfrac = tonumber(param)
		if idfrac ~= nil and idfrac >= 0 and idfrac <= 25 then
			sampSendChat('/ainvite '..idfrac)
		else
			sampAddChatMessage(tag..'Используйте: {F67B2E}/ainv [id frac]', main_color)
		end
	end
end

function cmd_gcid(param)
    if tonumber(param) then
        local result, ped = sampGetCharHandleBySampPlayerId(tonumber(param))
        if result and isCharInAnyCar(ped) then
            local car = storeCarCharIsInNoSave(ped)
            local result, carId = sampGetVehicleIdByCarHandle(car)
            if result then
				sampSendChat('/getcar '..carId)
			end
		else
			sampAddChatMessage(tag..'Игрок не в ТС/Вне зоны стрима/Указали свой ID', main_color)
		end
	else
		sampAddChatMessage(tag..'Используйте: {F67B2E}/gcid [id]', main_color)
	end
end

function cmd_dm(param)
	if ancmd[0] then
		local id = tonumber(param)
		if id ~= nil and id >= 0 and id <= 1000 then
			sampSendChat('/jail '..id..' 20 DM')
		else
			sampAddChatMessage(tag..'Используйте: {F67B2E}/dm [id]', main_color)
		end
	end
end

function cmd_db(param)
	if ancmd[0] then
		local id = tonumber(param)
		if id ~= nil and id >= 0 and id <= 1000 then
			sampSendChat('/jail '..id..' 20 DB')
		else
			sampAddChatMessage(tag..'Используйте: {F67B2E}/db [id]', main_color)
		end
	end
end

function cmd_cheat(param)
	if ancmd[0] then
		local id = tonumber(param)
		if id ~= nil and id >= 0 and id <= 1000 then
			sampSendChat('/ban '..id..' 3 0 Чит')
		else
			sampAddChatMessage(tag..'Используйте: {F67B2E}/cheat [id]', main_color)
		end
	end
end

function cmd_rvanka(param)
	if ancmd[0] then
		local id = tonumber(param)
		if id ~= nil and id >= 0 and id <= 1000 then
			sampSendChat('/ban '..id..' 91 1 Вредоносное ПО')
		else
			sampAddChatMessage(tag..'Используйте: {F67B2E}/rvanka [id]', main_color)
		end
	end
end

function cmd_bike(param)
	if ancmd[0] then
		local vid = tonumber(param)
		if vid ~= nil and vid == 1 then sampSendChat('/veh 510 1 1')
		elseif vid ~= nil and vid == 2 then sampSendChat('/veh 481 1 1')
		elseif vid ~= nil and vid == 3 then sampSendChat('/veh 509 1 1')
		else
			sampAddChatMessage(tag..'Используйте: {F67B2E}/bike [num] {0984d2}(1 - Горный; 2 - BMX; 3 - Обычный)', main_color)
		end
	end
end

function cmd_sethpme()
	local isid, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
	local mynick = sampGetPlayerNickname(myid)
	if ancmd[0] and isPlayerPlaying(PLAYER_HANDLE) then
		sampSendChat('/sethp '..myid..' 150')
	end
end

function cmd_piarask()
	local apiar_one = {'Возникли вопросы по игровому процессу? Наши хелперы готовы ответить на Ваши вопросы - /ask',
	'Есть вопросы по игровому моду? Задавайте их нашим хелперам - /ask',
	'Возник вопрос по игровому процессу? Задавайте его нашим хелперам - /ask',
	'Возникли вопросы по игровому процессу? Наши хелперы готовы Вам помочь - /ask'}
	if ancmd[0] then
		math.randomseed(os.time())
		sampSendChat('/o ' .. apiar_one[math.random(#apiar_one)])
	end
end

function cmd_piarask2()
	local apiar_two = {'Что за мероприятие "Резня666" и кто его устраивал? Хелперы помогут Вам - /ask',
	'Кто такой Мирослав Корда и зачем нужны статуэтки, задавайте вопросы нашим хелперам - /ask',
	'Кто такой Десперадо Хэйтт и когда будут контейнеры, задавайте вопросы нашим хелперам - /ask',
	'Кто такой Роберт Браун и когда стрим, задавайте вопросы нашим хелперам - /ask',
	'Кто такой ykы)angelonы) и как сделать оружие, задавайте вопросы нашим хелперам - /ask'}
	if ancmd[0] then
		math.randomseed(os.time())
		sampSendChat('/o ' .. apiar_two[math.random(#apiar_two)])
	end
end

function cmd_rspawncars() if ascmd[0] then sampSendChat('/rspawncars') end end
function cmd_deleteobjects() if ascmd[0] then sampSendChat('/deleteobjects') end end
function cmd_FillFixVeh() if ancmd[0] then sampSendChat('/fixveh') sampSendChat('/fillveh') end end
function cmd_specoff() if ascmd[0] then sampSendChat('/specoff') end end
function cmd_fixveh() if ascmd[0] then sampSendChat('/fixveh') end end
function cmd_destroycar() if ascmd[0] then sampSendChat('/destroycar') end end
--main functions
function nameTagOn()
	local pStSet = sampGetServerSettingsPtr()
	mem.setfloat(pStSet + 39, 500.0)
	mem.setint8(pStSet + 47, 0)
	mem.setint8(pStSet + 56, 1)
end

function nameTagOff()
	local pStSet = sampGetServerSettingsPtr()
	mem.setfloat(pStSet + 39, 40.0)--onShowPlayerNameTag / NTdist
	mem.setint8(pStSet + 47, 1)
	mem.setint8(pStSet + 56, 1)
end

function sampGetPlayerIdByNickname(nick)
    local _, myid = sampGetPlayerIdByCharHandle(playerPed)
    if tostring(nick) == sampGetPlayerNickname(myid) then return myid end
    for i = 0, 1000 do if sampIsPlayerConnected(i) and sampGetPlayerNickname(i) == tostring(nick) then return i end end
end

function getTagFromNickName(nickname)
    local name, surname = nickname:match('(%a+)_(%a+)')
    if name and surname then
        local first = name:sub(1, 1)
        local aTag = ('%s.%s'):format(first, surname)
        return aTag
    end
    return nickname
end

function getBodyPartCoordinates(id, handle)
	local pedptr = getCharPointer(handle)
	local vec = ffi.new("float[3]")
	getBonePosition(ffi.cast("void*", pedptr), vec, id, true)
	return vec[0], vec[1], vec[2]
end

function join_argb(a, r, g, b)
	local argb = b  -- b
	argb = bit.bor(argb, bit.lshift(g, 8))  -- g
	argb = bit.bor(argb, bit.lshift(r, 16)) -- r
	argb = bit.bor(argb, bit.lshift(a, 24)) -- a
	return argb
end
  
function explode_argb(argb)
	local a = bit.band(bit.rshift(argb, 24), 0xFF)
	local r = bit.band(bit.rshift(argb, 16), 0xFF)
	local g = bit.band(bit.rshift(argb, 8), 0xFF)
	local b = bit.band(argb, 0xFF)
	return a, r, g, b
end

--imgui functions
function imgui.TextQuestion(text)
    imgui.SameLine()
    imgui.TextDisabled('(?)')
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.PushTextWrapPos(450)
        imgui.TextUnformatted(text)
        imgui.PopTextWrapPos()
        imgui.EndTooltip()
    end
end

--others functions
function fps_correction()
	return representIntAsFloat(readMemory(0xB7CB5C, 4, false))
end

function teleportInterior(ped, posX, posY, posZ, int)
	setCharInterior(ped, int)
	setInteriorVisible(int)
	setCharCoordinates(ped, posX, posY, posZ)
end

function teleportPlayer(x, y, z)
    if isCharInAnyCar(PLAYER_PED) then setCharCoordinates(PLAYER_PED, x, y, z) end
    setCharCoordinatesDontResetAnim(PLAYER_PED, x, y, z)
end

function setCharCoordinatesDontResetAnim(char, x, y, z)
    local ptr = getCharPointer(char) setEntityCoordinates(ptr, x, y, z)
end

function setEntityCoordinates(entityPtr, x, y, z)
    if entityPtr ~= 0 then
        local matrixPtr = readMemory(entityPtr + 0x14, 4, false)
        if matrixPtr ~= 0 then
            local posPtr = matrixPtr + 0x30
            writeMemory(posPtr + 0, 4, representFloatAsInt(x), false) -- X
            writeMemory(posPtr + 4, 4, representFloatAsInt(y), false) -- Y
            writeMemory(posPtr + 8, 4, representFloatAsInt(z), false) -- Z
        end
    end
end