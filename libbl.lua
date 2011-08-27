require "socket.http"
require "util.http"
require "ltn12"
require "util.string"

bl = {}

-- set of platforms permitted by Backloggery.
bl.platforms = {
    ["32X"] = "32X";
    ["3DO"] = "3DO";
    ["AMG"] = "Amiga";
    ["CD32"] = "Amiga CD32";
    ["AMS"] = "Amstrad CPC";
    ["GX4k"] = "Amstrad GX4000";
    ["Droid"] = "Android";
    ["APF"] = "APF-M1000";
    ["AppII"] = "Apple II";
    ["Pippin"] = "Apple Bandai Pippin";
    ["ARC"] = "Arcade";
    ["2600"] = "Atari 2600";
    ["5200"] = "Atari 5200";
    ["7800"] = "Atari 7800";
    ["Atr8b"] = "Atari 8-bit";
    ["AtrST"] = "Atari ST";
    ["Astro"] = "Bally Astrocade";
    ["BBC"] = "BBC Micro";
    ["Brwsr"] = "Browser";
    ["CALC"] = "Calculator";
    ["CDi"] = "CD-i";
    ["CD32X"] = "CD32X";
    ["Adam"] = "Coleco Adam";
    ["CV"] = "ColecoVision";
    ["C64"] = "Commodore 64";
    ["VIC20"] = "Commodore VIC-20";
    ["CBoy"] = "Cougar Boy";
    ["Desura"] = "Desura";
    ["Dragon"] = "Dragon 32/64";
    ["DC"] = "Dreamcast";
    ["DSiW"] = "DSiWare";
    ["Arc2k1"] = "Emerson Arcadia 2001";
    ["ChF"] = "Fairchild Channel F";
    ["FDS"] = "Famicom Disk System";
    ["FMT"] = "FM Towns";
    ["FM7"] = "Fujitsu Micro 7";
    ["Gamate"] = "Gamate";
    ["GW"] = "Game &amp; Watch";
    ["GG"] = "Game Gear";
    ["GBC"] = "Game Boy/Color";
    ["GBA"] = "Game Boy Advance";
    ["eRdr"] = "e-Reader";
    ["GWFES"] = "Game Wave Family Entertainment System";
    ["GCN"] = "GameCube";
    ["G4W"] = "Games For Windows";
    ["GCOM"] = "Game.com";
    ["GEN"] = "Genesis / Mega Drive";
    ["Gizm"] = "Gizmondo";
    ["GOG"] = "Good Old Games";
    ["Wiz"] = "GP2X Wiz";
    ["HprScn"] = "HyperScan";
    ["Imp"] = "Impulse";
    ["IntVis"] = "Intellivision";
    ["iOS"] = "iOS";
    ["iPad"] = "iPad";
    ["iPod"] = "iPod";
    ["iPhone"] = "iPhone";
    ["JAG"] = "Jaguar";
    ["JagCD"] = "Jaguar CD";
    ["Lynx"] = "Lynx";
    ["Mac"] = "Mac";
    ["SMS"] = "Master System";
    ["Micvis"] = "Microvision";
    ["Misc"] = "Miscellaneous";
    ["Mobile"] = "Mobile";
    ["MSX"] = "MSX";
    ["NGage"] = "N-Gage";
    ["PC88"] = "NEC PC-8801";
    ["PC98"] = "NEC PC-9801";
    ["NG"] = "Neo Geo";
    ["NGCD"] = "Neo Geo CD";
    ["NGPC"] = "Neo Geo Pocket/Color";
    ["3DS"] = "Nintendo 3DS";
    ["3DSDL"] = "3DS Downloads";
    ["NDS"] = "Nintendo DS";
    ["N64"] = "Nintendo 64";
    ["64DD"] = "Nintendo 64DD";
    ["NES"] = "Nintendo Entertainment System";
    ["Nuon"] = "Nuon";
    ["Ody2"] = "Odyssey&sup2; / Videopac";
    ["OnLive"] = "OnLive";
    ["Origin"] = "Origin";
    ["Pndra"] = "Pandora";
    ["PC"] = "PC";
    ["PCDL"] = "PC Downloads";
    ["PC50X"] = "PC-50X";
    ["PCFX"] = "PC-FX";
    ["PB"] = "Pinball";
    ["PS"] = "PlayStation";
    ["PS2"] = "PlayStation 2";
    ["PS3"] = "PlayStation 3";
    ["PSN"] = "PlayStation Network";
    ["PS1C"] = "PSOne Classics";
    ["PSmini"] = "PlayStation minis";
    ["PSP"] = "PlayStation Portable";
    ["PSVita"] = "PlayStation Vita";
    ["PnP"] = "Plug-and-Play";
    ["PktStn"] = "PocketStation";
    ["PkMini"] = "Pok&eacute;mon Mini";
    ["RZN"] = "R-Zone";
    ["RCAS2"] = "RCA Studio II";
    ["SAM"] = "SAM Coup&eacute;";
    ["Saturn"] = "Saturn";
    ["SCD"] = "Sega CD";
    ["Pico"] = "Sega Pico";
    ["SG1000"] = "Sega SG-1000";
    ["X1"] = "Sharp X1";
    ["X68k"] = "Sharp X68000";
    ["Steam"] = "Steam";
    ["SNES"] = "Super Nintendo Entertainment System";
    ["TI99"] = "TI-99/4A";
    ["Tiger"] = "Tiger Handhelds";
    ["TDuo"] = "TurboDuo";
    ["TG16"] = "TurboGrafx-16";
    ["TRS80"] = "TRS-80";
    ["VECT"] = "Vectrex";
    ["VB"] = "Virtual Boy";
    ["VC"] = "Virtual Console";
    ["VCH"] = "VC (Handheld)";
    ["SVis"] = "Watara Supervision";
    ["Wii"] = "Wii";
    ["WW"] = "WiiWare";
    ["WiiU"] = "Wii U";
    ["WinP7"] = "Windows Phone 7";
    ["WSC"] = "WonderSwan/Color";
    ["Xbox"] = "Xbox";
    ["360"] = "Xbox 360";
    ["XBLA"] = "Xbox LIVE Arcade";
    ["XNA"] = "XNA Indie Games";
    ["XbxGoD"] = "Xbox 360 Games on Demand";
    ["Zeebo"] = "Zeebo";
    ["Zune"] = "Zune";
    ["ZXS"] = "ZX Spectrum";
}

bl.__index = bl
function bl:__tostring()
    return "backloggery:"..self.user
end

-- log in to Backloggery and return a cookie that the caller can use to
-- interact with the site
function bl.login(user, pass)
    local post = socket.http.mkpost {
        username = user;
        password = pass;
        duration = "hour";
    }
    local body,code,headers = socket.http.request("http://backloggery.com/login.php", post)
    
    if code ~= 302 then
        err = body:match [[div class="update%-r">([^<]+)]] or "unknown error"
        return nil,err
    end
    
    local cookies = { user = user }
    for crumb in headers["set-cookie"]:gmatch("c_%w+=[^;]+") do
        cookies[#cookies+1] = crumb
    end
    
    return setmetatable(cookies, bl)
end

local function request(self, fields, method, url)
    local body = socket.http.mkpost(fields)
    
    local headers = {
        ["referer"] = "http://backloggery.com/newgame.php?user="..self.user;
        ["cookie"] = table.concat(self, "; ")
    }

    if method == "POST" then
        headers["content-type"] = "application/x-www-form-urlencoded"
        headers["content-length"] = tostring(#body)
    end

    local response = {}
    local request = {
        method = method;
        url = url;
        headers = headers;
        sink = ltn12.sink.table(response);
    }
    
    if method == "POST" then
        request.source = ltn12.source.string(body)
    else
        request.url = url.."?"..body
    end

    local r,e = socket.http.request(request)
    socket.sleep(1)
    
    if r then
        return table.concat(response)
    else
        return nil,e
    end
end

-- add a game to a backloggery account. Required fields are "name", "console",
-- and "complete". Other fields are optional.
function bl:addgame(game)
    local fields = {
        name = false; -- to be filled in
        comp = "";
        console = false; -- to be filled in
        orig_console = "";
        region = "0";
        own = "1";
        complete = false; -- to be filled in
        achieve1 = "";
        achieve2 = "";
        online = "";
        note = "";
        rating = "8";
        submit1 = "Add Game";
        --wishlist = "1"; -- caller needs to set this if they want it
    }
    
    for k,v in pairs(game) do
        fields[k] = v
    end
    
    fields.complete = bl.completecode(fields.complete)
    
    assert(fields.name and fields.complete, "invalid argument to bl:addgame - name and completion status required")
    assert(bl.platforms[fields.console], "invalid argument to bl:addgame - platform '"..tostring(fields.console).."' is not supported by backloggery")
    
    if self:hasgame(fields.name) then
        return nil,"game '%s' is already in this Backloggery" % fields.name
    end

    local r,e = request(self, fields, "POST", "http://backloggery.com/newgame.php?user="..self.user)
    
    if not r then
        return nil,tostring(e)
    end
    
    if r:match([[<div class="update%-r">(.-)</div>]]) then
        return nil,r:match([[<div class="update%-r">(.-)</div>]])
    end

    return r:match([[<div class="update%-g">(.-)</div>]]) or true
end

-- returns true if the user has a game of this name, and false otherwise
function bl:hasgame(game)
    return self:games()[game] ~= nil or self:wishlist()[game] ~= nil
end

function bl:info(game)
    return self:games()[game] or self:wishlist()[game]
end

local function getAllGames(self, wishlist, key)
    local games = {}
    
    local id, temp_sys, aj_id, total = 1, "ZZZ", 0, 0
    local function getMoreGames(wishlist)
        local fields = {
            user = self.user;
            temp_sys = temp_sys;
            total = total;
            aid = id;
            ajid = aj_id;
            search = ""; console = ""; rating = ""; status = ""; own = "";
            region = ""; region_u = 0; wish = wishlist and "1" or ""; alpha = "";
        }
        
        local body = request(self, fields, "GET", "http://backloggery.com/ajax_moregames.php")
        
        for type,gamebox in body:gmatch([[<section class="gamebox([^"]*)">(.-)</section>]]) do
            if type == "" or type == " nowplaying" then
                local info = {}
                info.console,info.complete,info.name = gamebox:match("games%.php.-console=([^&]+).-status=(%d+).-<b>(.-)</b>")
                info.complete = bl.completestring(tonumber(info.complete))
                info.console_name = bl.platforms[info.console]
                info.note = gamebox:match([[<div class="gamerow">([^<]+)</div>$]]) or ""
                info.wishlist = wishlist
                info.nowplaying = type == " nowplaying"
                info.id = tonumber(gamebox:match([[gameid=(%d+)]]))
                games[info[key]] = info
            end
        end
        
        id,temp_sys,aj_id,total = body:match([[getMoreGames%((%d+),%s*'(.-)',%s*'(%d+)',%s*(%d+)%)]])
    end
    
    repeat getMoreGames(wishlist) until not id
    
    return games
end
    
function bl:games(key)
    if not self._games then
        self._games = getAllGames(self, false, key or "id")
    end
    
    return self._games
end

function bl:wishlist()
    if not self._wishlist then
        self._wishlist = getAllGames(self, true, key or "id")
    end
    
    return self._wishlist
end

-- translate a completion string into a numeric completion code
function bl.completecode(complete)
    if type(complete) == "number" and complete >= 1 and complete <= 5 then
        return complete
    end
    
    local code = {
        "unfinished",
        "beaten finished done",
        "completed",
        "mastered",
        "null casual multiplayer sandbox"
    }
    
    for i,v in ipairs(code) do
        if v:match(complete:lower()) then
            return i
        end
    end
    
    return nil
end

function bl.completestring(code)
    local complete = { "unfinished", "beaten", "completed", "mastered", "null" }
    return complete[code]
end
