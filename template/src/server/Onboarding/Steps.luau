--!strict
-- Avance del embudo de onboarding, sin Roblox (se prueba en tests/).
-- Un paso de servidor puede saltear pasos de cliente que no llegaron (un cliente que no avisa no
-- frena el embudo). Un paso de cliente solo cuenta si es exactamente el siguiente.

export type Step = { name: string, source: "server" | "client" }

local Steps = {}

-- Índice del paso al que se avanza, o nil si no corresponde avanzar.
function Steps.advance(steps: { Step }, current: number, name: string, source: "server" | "client"): number?
	for index = current + 1, #steps do
		local step = steps[index]
		if step.name == name then
			if step.source ~= source then
				return nil
			end
			if source == "client" and index ~= current + 1 then
				return nil
			end
			return index
		end
	end
	return nil
end

return Steps
