--!strict
-- Avisos entre servicios sin que se requieran en círculo:
-- - track(player, stat, amount): progreso para misiones y objetivos ("Spin", "Rebirth", "MoneyEarned").
--   Los kits mandan los suyos ("Steal", "Hatch", "CatchFish", "Steps").
-- - dirty(player): cambió algo que el jugador ve; PlayerStateService manda un estado nuevo (agrupado).

local Signals = {}

local tracked = Instance.new("BindableEvent")
local dirtied = Instance.new("BindableEvent")

-- (player, stat, amount)
Signals.Tracked = tracked.Event
-- (player)
Signals.Dirtied = dirtied.Event

function Signals.track(player: Player, stat: string, amount: number?)
	tracked:Fire(player, stat, amount or 1)
end

function Signals.dirty(player: Player)
	dirtied:Fire(player)
end

return Signals
