--!strict
-- Tipos de la receta del juego (Config/KitConfig): qué bloques de juego usa y cómo. Solo datos, sin
-- tipos de Roblox (colores en hex), para que tests/Presets.spec.luau valide cada receta con el CLI de
-- Luau. Qué hace cada bloque: skills/roblox-game-kits/references/bloques.md.

local Objectives = require("../Lib/Objectives")
local SharedTypes = require("../Types")

export type Reward = SharedTypes.Reward

-- Precio en una moneda de EconomyConfig.CURRENCIES (o de `currencies` de la receta).
export type Price = { currency: string, amount: number }

-- Un resultado posible de un sorteo (huevo, cinta, pesca, pila, salvajes) y su peso. La suerte
-- multiplica el peso de las unidades desde la rareza `luckyFrom` de la receta.
export type PoolEntry = { unit: string, weight: number }

-- Moneda propia de la receta (victorias, toques, la moneda del evento). Se suma a EconomyConfig.
export type CurrencyDef = {
	id: string,
	symbol: string, -- "$" → "$1.2K"; "" muestra solo el número
	icon: string, -- shared/Icons
	color: string, -- hex ("#FFD23A")
	start: number,
	purchasable: boolean, -- se vende por Robux (lo aleatorio que se paga con ella es aleatorio pago)
}

export type UnitDef = {
	id: string, -- se guarda en los datos: no cambiarlo después de publicar
	name: string, -- lo que ve el jugador (inglés)
	rarity: string, -- RarityConfig.TIERS[].id
	income: number?, -- $/s colocada en la base
	value: number?, -- precio de venta (sin valor no se vende)
	power: number?, -- equipada: suma al multiplicador de equip.stat (0.25 = +25 %)
	tier: number?, -- lugar en la cadena de fusión por nivel (1, 2, 3...)
	zone: string?, -- zona del índice y del mundo
	weight: { min: number, max: number }?, -- kilos (peces): el valor escala con el peso
	requirement: number?, -- salvajes: estadística mínima para capturarla
	price: number?, -- precio en la cinta (sin esto: valor × belt.priceMultiplier)
	icon: string?, -- shared/Icons o rbxassetid de su imagen
	model: string?, -- modelo en ReplicatedStorage.Assets.Units (sin modelo: forma de color)
	color: string?, -- color de la forma de reemplazo (hex)
}

export type IndexZone = { id: string, name: string, image: string?, reward: Reward? }

-- Una unidad del jugador (data.kits.units.list). Normal = sin variant ni size.
export type Unit = {
	uid: number,
	kind: string, -- id de units.list
	variant: string?, -- mutación (RarityConfig.MUTATIONS): "Gold", "Rainbow"
	size: string?, -- tamaño (RarityConfig.SIZES): "Big", "Huge"
	weight: number?, -- kilos (peces)
	slot: number?, -- colocada en ese espacio de su base (Plots)
	equipped: boolean?, -- equipada (Equip)
	locked: boolean?, -- cuidada por el jugador: no se vende ni se fusiona con "todo"
}

-- Lo que ve el cliente del bloque Units (state.kit.units).
export type UnitsState = { list: { Unit }, max: number }

export type UnitsConfig = {
	label: string, -- título del inventario y del índice: "Pets", "Fish", "Critters"
	list: { UnitDef },
	mutations: boolean?, -- variantes de RarityConfig.MUTATIONS (Gold, Diamond, Rainbow, Galaxy)
	sizes: boolean?, -- tamaños de RarityConfig.SIZES (Big, Huge)
	maxInventory: number,
	zones: { IndexZone }?, -- zonas del índice con su premio
	announceFrom: string?, -- desde esta rareza se anuncia a todo el servidor ("Legendary")
	luckyFrom: string?, -- desde esta rareza la suerte las vuelve más probables ("Rare")
}

export type PlotsConfig = {
	label: string?, -- "Base", "Farm", "Pen": el cartel dice "Leo's Base"
	count: number, -- bases por servidor: Max Players del juego tiene que ser este número
	slots: number, -- espacios al empezar
	maxSlots: number,
	slotPrices: { number }?, -- precio de cada espacio extra, en orden (moneda principal)
	collect: "pad" | "auto", -- pisar el pad para cobrar, o directo a la moneda
	autoCollectPass: string?, -- pase (ShopConfig.PASSES) que cobra solo
	offline: boolean?, -- las bases pagan sin conexión (RetentionConfig.OFFLINE)
	lock: { seconds: number, cooldown: number }?, -- traba con láser (juegos de robar)
	autoPlace: boolean?, -- lo que se consigue va solo al primer espacio libre
}

export type BeltConfig = {
	pool: { PoolEntry },
	spawnEvery: number, -- segundos entre unidades
	walkSeconds: number, -- lo que tarda en cruzar
	priceMultiplier: number?, -- precio = valor × esto, si la unidad no tiene `price`
	maxOnBelt: number?,
}

export type StealConfig = {
	holdSeconds: number, -- mantener el prompt para robar
	carrySpeed: number, -- multiplicador de velocidad mientras lleva algo (0.7)
	protectNewSeconds: number, -- los jugadores nuevos no pierden nada al principio
	recentSeconds: number, -- lo recién robado no se puede volver a robar enseguida
	pushRange: number,
	protectBest: boolean?, -- lo más valioso de cada base no se roba
}

export type RollAmount = { count: number, pass: string? } -- pass: ShopConfig.PASSES (Triple, Octo)

export type RollDef = {
	id: string,
	name: string, -- "Common Egg"
	price: Price?, -- sin precio: gratis cada `cooldown` segundos
	cooldown: number?,
	pool: { PoolEntry },
	amounts: { RollAmount }, -- {1, 3, 8} (huevos) o {1, 5, 25, 100} (puestos de compra)
	zone: string?,
	paidRandom: boolean?, -- se paga con moneda comprada con Robux: PolicyService y probabilidades
	look: string?, -- "egg", "dice", "chest", "pad": cómo se ve en el mundo y al revelar
	toBase: boolean?, -- lo que sale va directo a la base (puestos de Chicken Farm)
}

export type RollsConfig = {
	list: { RollDef },
	autoPass: string?, -- pase de tirada automática
	luckStat: string?, -- estadística de suerte de BoostService ("Luck")
}

export type MergeConfig = {
	mode: "tier" | "variant", -- tier: N iguales → el siguiente nivel; variant: N normales → 1 dorado...
	count: number, -- cuántos iguales hacen falta
	mutationChance: number?, -- tier: chance de que el resultado salga con mutación
	variantChain: { string }?, -- variant: "Normal" → "Gold" → "Diamond" → "Rainbow"
	seconds: number?, -- el resultado tarda en estar listo ("Finish Now" lo adelanta)
	machine: boolean?, -- máquina en el mundo (KitMergeMachine); el botón del inventario está siempre
}

export type SellConfig = {
	currency: string?, -- moneda que se cobra (la principal si falta)
	multiplier: number?,
	keepFrom: string?, -- "Sell all" no vende desde esta rareza
	stat: string?, -- multiplicador de BoostService que se aplica (Money)
}

export type EquipConfig = {
	slots: number,
	maxSlots: number,
	stat: string, -- lo que multiplican las equipadas (Money, Taps, Speed, Luck)
	follow: boolean?, -- las equipadas siguen al jugador
	slotPass: string?, -- pase que suma espacios
	passSlots: number?,
}

export type StatDef = {
	id: string, -- "Speed", "Strength", "Taps"
	label: string, -- se ve en el HUD
	icon: string?,
	currency: string?, -- las ganancias van a esta moneda (toques que se gastan) en vez de a la estadística
	perStep: number?, -- por stud caminado (+1 Speed por paso)
	perSecond: number?, -- por segundo, siempre
	perClick: number?, -- por toque del botón de acción
	clickRate: number?, -- toques por segundo como máximo
	autoPass: string?, -- pase que toca solo
	walkSpeed: { base: number, per: number, max: number }?, -- la estadística mueve al personaje
	resetOnRebirth: boolean?,
	multiplier: string?, -- estadística de BoostService que la multiplica (por defecto, su id)
}

export type ZoneDef = {
	id: string,
	name: string, -- "Lake"
	difficulty: string?, -- emoji sobre el nombre ("😐", "😟")
	price: Price?, -- se compra
	stat: { id: string, value: number }?, -- se abre sola al llegar ("Required ⚡ 3.7M")
	rebirths: number?,
	order: number,
}

export type ZonesConfig = { list: { ZoneDef } }

export type StagesConfig = {
	count: number,
	reward: Price, -- por llegar al final
	stat: string?, -- estadística que piden las etapas (velocidad para saltar los huecos)
	requirements: { number }?, -- valor mínimo por etapa
	run: { freeRevives: number, reviveProduct: string? }?, -- corrida con resumen y revivir
	returnToStart: boolean?, -- al ganar vuelve al principio
}

export type FishingRod = { id: string, name: string, luck: number, speed: number, price: Price? }

export type FishingPool = { id: string, zone: string?, entries: { PoolEntry } }

export type FishingConfig = {
	pools: { FishingPool },
	wait: { min: number, max: number }, -- segundos hasta la picada
	reelSeconds: number, -- tiempo para recoger después de la picada
	rods: { FishingRod }, -- la primera es la que se tiene al empezar
	castRange: number?, -- distancia máxima al agua
}

export type Seed = {
	id: string,
	name: string,
	unit: string, -- lo que se cosecha
	price: Price,
	grow: number, -- segundos hasta estar lista
	stock: { min: number, max: number }, -- cuántas trae cada reposición
	chance: number?, -- probabilidad de aparecer en la reposición (semillas raras)
}

export type GardenConfig = {
	seeds: { Seed },
	restock: number, -- segundos entre reposiciones de la tienda (reloj real)
	tiles: number, -- parcelas al empezar
	maxTiles: number,
	tilePrices: { number }?,
	mutationChance: number?,
}

export type Pile = {
	id: string,
	zone: string?,
	entries: { PoolEntry },
	findChance: number, -- chance de encontrar algo en cada golpe con poder 1
	coins: Price?, -- monedas sueltas por golpe
}

export type SearchTool = { id: string, name: string, power: number, cooldown: number, price: Price? }

export type SearchConfig = {
	piles: { Pile },
	tools: { SearchTool }, -- la primera es la que se tiene al empezar
	bag: number, -- capacidad al empezar
	depositCurrency: string?,
}

export type WildSpawn = { zone: string?, entries: { PoolEntry }, max: number, respawn: number }

export type WildConfig = {
	spawns: { WildSpawn },
	stat: string?, -- estadística que se compara con `requirement` de la unidad
	captureSeconds: number,
	toBase: boolean?,
}

export type UpgradeDef = {
	id: string,
	name: string,
	desc: string, -- "+25% Money per level" (inglés)
	icon: string?,
	-- Qué mejora: "stat:<Stat>" (multiplicador de BoostService: Money, Luck, Speed...) o uno de
	-- Lib/KitCheck.EFFECTS: "slots", "equip", "inventory", "bag", "power", "tiles", "grow",
	-- "walkSpeed", "reel", "capture".
	effect: string,
	per: number, -- cuánto suma cada nivel (en grow, reel y capture: fracción de tiempo menos)
	kind: ("add" | "mult")?, -- para "stat:": suma (+per por nivel) o multiplica (×per por nivel)
	maxLevel: number,
	prices: { number }?, -- escalera explícita
	base: number?, -- o precio = base × growth ^ nivel
	growth: number?,
	currency: string?,
	robux: boolean?, -- se sube con productos "Upgrade:<id>" (escalera de Chicken Farm)
}

export type Building = { id: string, name: string, price: Price, income: number, after: string? }

export type TycoonConfig = { buildings: { Building } }

export type ItemDef = { id: string, name: string, icon: string, boost: string, seconds: number }

export type ItemsConfig = { list: { ItemDef }, maxStack: number }

export type Quest = {
	id: string,
	text: string, -- %s = objetivo
	stat: string,
	target: number,
	money: boolean?,
	reward: Reward,
}

export type MapConfig = {
	theme: string, -- "meadow", "beach", "candy", "farm", "jungle", "snow", "desert", "space"
	season: string?, -- "halloween", "christmas", "summer"
	shops: { string }?, -- tiendas del lobby: "Shop", "Sell", "Upgrades", "Seeds", "Robux"
	spin: boolean?, -- ruleta en el mundo
	leaderboard: boolean?, -- tablas de posiciones
	groupChest: boolean?,
	nextUpdate: string?, -- texto del cartel NEXT UPDATE ("Saturday 3PM EST")
}

export type KitConfig = {
	name: string, -- receta ("StealAndPlace") o nombre del juego
	currencies: { CurrencyDef }?,
	leaderstats: { string }?,
	units: UnitsConfig?,
	plots: PlotsConfig?,
	belt: BeltConfig?,
	steal: StealConfig?,
	rolls: RollsConfig?,
	merge: MergeConfig?,
	sell: SellConfig?,
	equip: EquipConfig?,
	stats: { StatDef }?,
	zones: ZonesConfig?,
	stages: StagesConfig?,
	fishing: FishingConfig?,
	garden: GardenConfig?,
	search: SearchConfig?,
	wild: WildConfig?,
	upgrades: { UpgradeDef }?,
	tycoon: TycoonConfig?,
	items: ItemsConfig?,
	objectives: { Objectives.Def }?, -- reemplaza ObjectiveConfig.CHAIN
	quests: { Quest }?, -- reemplaza el pool de RetentionConfig.QUESTS
	map: MapConfig?,
}

return {}
