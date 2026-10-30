--!strict
-- Etiquetas (CollectionService) y atributos con los que los bloques del armador encuentran su parte del
-- mapa. MapKit las pone al armar el mapa; un mapa hecho a mano en Studio funciona igual si usa los
-- mismos nombres (pestaña Tags y Attributes de cada parte). Tabla completa en
-- skills/roblox-game-kits/references/bloques.md.

return {
	-- Bases (Plots): el Model de cada base y sus partes adentro.
	PLOT = "KitPlot",
	SLOT = "KitSlot", -- atributo Index: número del espacio (1, 2, 3...)
	COLLECT_PAD = "KitCollectPad",
	SPAWN = "KitSpawn",
	BARRIER = "KitBarrier", -- láser de la traba (Steal)
	LOCK_BUTTON = "KitLockButton",
	SLOT_SHOP = "KitSlotShop", -- cartel para comprar el siguiente espacio
	-- Cinta (Belt): la parte por la que caminan las unidades, de punta a punta en su eje X.
	BELT = "KitBelt",
	-- Tiradas (Rolls): huevo, dado o puesto de compra. Atributo Roll: id de rolls.list.
	ROLL_STATION = "KitRollStation",
	MERGE_MACHINE = "KitMergeMachine",
	SELL_PAD = "KitSellPad",
	-- Estadísticas: cinta de correr o pesa. Atributos Stat (id) y Gain (cuánto por segundo encima).
	TREADMILL = "KitTreadmill",
	-- Zonas: la puerta (se abre en el cliente de quien la tiene), la región y el teletransporte.
	GATE = "KitGate",
	ZONE = "KitZone",
	TELEPORT = "KitTeleport",
	-- Etapas: cada checkpoint (atributo Stage), la meta y el comienzo.
	CHECKPOINT = "KitCheckpoint",
	WIN_PAD = "KitWinPad",
	STAGE_START = "KitStageStart",
	WATER = "KitWater", -- Pesca: atributo Pool (id de fishing.pools)
	GARDEN_TILE = "KitGardenTile", -- Cultivo: dentro de la base, atributo Index
	PILE = "KitPile", -- Búsqueda: atributo Pile (id de search.piles)
	DEPOSIT_PAD = "KitDepositPad",
	WILD_SPAWN = "KitWildSpawn", -- Salvajes: atributos Zone y Pool (índice en wild.spawns)
	UPGRADE_STATION = "KitUpgradeStation", -- atributo Upgrade (opcional): abre esa mejora
	TYCOON_BUTTON = "KitTycoonButton", -- Tycoon: atributo Building, dentro de la base
	BUILDING = "KitBuilding", -- Tycoon: el edificio que aparece, atributo Building
	-- Lobby: puestos que abren una ventana al acercarse (atributo Window: "Shop", "Sell", "Upgrades",
	-- "Seeds", "Index", "Spin"), tablas de posiciones (atributo Stat) y el cofre del grupo.
	SHOP_STAND = "KitShopStand",
	LEADERBOARD = "KitLeaderboard",
	GROUP_CHEST = "KitGroupChest",

	-- Atributos que pone el servidor.
	OWNER = "Owner", -- UserId del dueño de una base (0 = libre)
	OWNER_NAME = "OwnerName",
}
