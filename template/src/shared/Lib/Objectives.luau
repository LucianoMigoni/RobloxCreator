--!strict
-- Cadena de objetivos arriba al centro ("Earn $14/$100" → "Steal the Animal" → "Buy a Trail"): es el
-- tutorial sin pantallas de los hits y nunca termina. Primero la cadena fija del juego; después,
-- objetivos que se generan solos y crecen. Sin Roblox (tests/Objectives.spec.luau).

local Objectives = {}

export type Def = {
	id: string,
	text: string, -- en inglés; %s = objetivo formateado ("Earn $%s")
	stat: string, -- evento que lo hace avanzar
	target: number,
	money: boolean?, -- el objetivo se muestra como plata ("$1.2K")
}

export type Endless = {
	text: string,
	stat: string,
	base: number, -- objetivo del primero que se genera
	growth: number, -- cada uno siguiente multiplica el objetivo por esto
	money: boolean?,
}

export type State = { index: number, progress: number }

-- El objetivo actual (el de la cadena o uno generado).
function Objectives.current(chain: { Def }, endless: Endless?, state: State): Def?
	local def = chain[state.index]
	if def then
		return def
	end
	if not endless then
		return nil
	end
	local n = state.index - #chain -- 1, 2, 3...
	return {
		id = "endless_" .. n,
		text = endless.text,
		stat = endless.stat,
		target = math.floor(endless.base * endless.growth ^ (n - 1)),
		money = endless.money,
	}
end

-- Suma progreso al objetivo actual si el evento coincide. Devuelve el objetivo completado (o nil) y
-- deja el estado apuntando al siguiente.
function Objectives.track(chain: { Def }, endless: Endless?, state: State, stat: string, amount: number): Def?
	local def = Objectives.current(chain, endless, state)
	if not def or def.stat ~= stat then
		return nil
	end
	state.progress = math.min(def.target, state.progress + math.max(0, amount))
	if state.progress >= def.target then
		state.index += 1
		state.progress = 0
		return def
	end
	return nil
end

return Objectives
