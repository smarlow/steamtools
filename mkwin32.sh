enceladus -t ~/bin/enceladus.exe -o embed.exe steam2backloggery.lua app.lua libbl.lua libsteam.lua libsteam/vdf.lua util/* config.lua html.lua lib/*.lua lib/socket/*.lua
mv steam2backloggery.lua-embed.exe bin/steam2backloggery.exe

enceladus -t ~/bin/enceladus.exe -o embed.exe categories.lua app.lua libsteam.lua libsteam/vdf.lua util/* config.lua html.lua lib/*.lua lib/socket/*.lua
mv categories.lua-embed.exe bin/categories.exe