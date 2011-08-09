require "libbl"
require "libsteam"
require "util.io"

function main(...)
    -- initialize Steam
    local path = io.prompt("Steam location (drag-and drop steam.exe): ")
    
    local steam,err = steam.open(path)
    if not steam then
        io.eprintf("Couldn't read Steam directory: %s\n", err)
        return 1
    end
    
    io.printf("Found Steam account %s\n\n", tostring(steam))
    
    -- initialize Backloggery
    local user = io.prompt("Backloggery username: ")
    local pass = io.prompt("Backloggery password: ")
    
    local cookie,err = bl.login(user,pass)
    
    if not cookie then
        io.eprintf("Couldn't log in: %s\n", err)
        return 1
    else
        io.printf("Logged in to Backloggery as %s.\n\n", user)
    end
    
    io.printf("Loading Steam game lists:"); io.flush()
    io.printf(" games"); io.flush(); steam:games()
    io.printf(" wishlist"); io.flush(); steam:wishlist()
    io.printf(" done.\nLoading Backloggery game lists:"); io.flush()
    io.printf(" games"); io.flush(); cookie:games()
    io.printf(" wishlist"); io.flush(); cookie:wishlist()
    io.printf(" done.\n")
    
    io.printf("Filtering games:"); io.flush()
    local games = {}
    local count = 0
    for _,game in pairs(steam:games()) do
        count = count+1
        if not cookie:hasgame(game.name) then
            games[#games+1] = {
                name = game.name;
                status = "unfinished";
            }
        end
    end
    io.printf(" %d owned games,", count); io.flush(); count = 0
    for _,game in pairs(steam:wishlist()) do
        count = count+1
        if not cookie:hasgame(game.name) then
            games[#games+1] = {
                name = game.name;
                status = "wishlist";
            }
        end
    end
    io.printf(" %d wishlisted games,", count); io.flush()
    io.printf(" %d games to add.\n", #games)
    
    io.output("backloggery.txt")
    io.write [[
    # This is a list of all of the games steam2backloggery is going to add to your
    # backloggery account.
    # Please edit this list as you see fit, then save and exit. In particular, you
    # probably want to at least:
    # * change "unfinished" to "beaten", "complete", "mastered", or "null" as needed
    # * delete DLC from the list
    # Lines starting with '#' will be ignored.
    # If you decide that you've made a terrible mistake and don't want to upload
    # *anything* to your backloggery account, just erase everything in this file
    # and then save and exit.
    ]]
    for _,game in ipairs(games) do
        io.printf("%-16s%s\n", game.status, game.name)
    end
    io.close()
    
    io.output(io.stdout)
    io.printf("Launching editor so you can can review the game list..."); io.flush()
    if os.execute("notepad backloggery.txt") > 0 then
        io.eprintf("\nError executing editor! Aborting.")
        return 1
    end
    io.printf("done.\n")
    
    -- now, we read the contents of the edited file so that we can upload the games
    -- to backloggery.
    for line in io.lines("backloggery.txt") do
        if not line:match("^#") then
            local status,name = line:match("(%w+)%s+(.*)")
            local wishlist
            if status == "wishlist" then
                status = "unfinished"
                wishlist = 1
            end
            
            if not bl.completecode(status) then
                io.eprintf("Warning: skipping game '%s': unknown status '%s'\n", name, status)
            else
                io.printf("Adding %s game '%s'%s\n", status, name, wishlist and " to wishlist" or "") 
                cookie:addgame {
                    name = name:trim();
                    console = "PC";
                    complete = status;
                    wishlist = wishlist;
                }
            end
        end
    end
    
    io.printf("Backloggery updated. Have a nice day!\n")
end

local r,e = pcall(main(...))
if not r then
    io.eprintf("An error occurred! Please report this to the developer.\n%s\n", e)
end

io.printf("\nPress enter to quit...\n")
io.read()
