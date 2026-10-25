--!strict
-- Arranque del servidor: cada servicio expone start() y se inicia acá, en orden.

local DataService = require("./Data/DataService")
local Remotes = require("./Net/Remotes")

Remotes.start()
DataService.start()
