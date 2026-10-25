--!strict
-- Mini framework de tests para la lógica pura de src/ (sin Roblox).
-- Correr: luau tests/<Nombre>.spec.luau  (tools/check.py corre todos).

local TestKit = {}

local function show(value: any): string
	if typeof(value) == "string" then
		return string.format("%q", value)
	end
	return tostring(value)
end

function TestKit.equal(actual: any, expected: any, label: string?)
	if actual ~= expected then
		error(string.format("%sesperado %s, obtenido %s", if label then label .. ": " else "", show(expected), show(actual)), 2)
	end
end

function TestKit.truthy(value: any, label: string?)
	if not value then
		error((label or "se esperaba un valor verdadero") .. ", obtenido " .. show(value), 2)
	end
end

function TestKit.falsy(value: any, label: string?)
	if value then
		error((label or "se esperaba un valor falso") .. ", obtenido " .. show(value), 2)
	end
end

-- Corre los casos en orden alfabético y falla al final si alguno falló, para ver todos los errores juntos.
function TestKit.run(suite: string, cases: { [string]: () -> () })
	local names = {}
	for name in cases do
		table.insert(names, name)
	end
	table.sort(names)
	local failed = 0
	for _, name in names do
		local ok, err = pcall(cases[name] :: () -> ...any)
		if not ok then
			failed += 1
			print(string.format("  FALLA %s > %s: %s", suite, name, tostring(err)))
		end
	end
	if failed > 0 then
		error(string.format("%s: %d de %d casos fallaron", suite, failed, #names), 0)
	end
	print(string.format("%s: %d casos OK", suite, #names))
end

return TestKit
