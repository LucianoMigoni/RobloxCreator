--!strict
-- Validadores de argumentos para lo que llega del cliente. Sin dependencias de Roblox: se prueba con tests/.
-- Todo lo que manda el cliente es sospechoso: tipos cambiados, NaN, infinito, textos enormes, tablas raras.

export type Validator = (value: unknown) -> (boolean, string?)

local Validate = {}

function Validate.number(opts: { min: number?, max: number?, integer: boolean? }?): Validator
	local min = if opts then opts.min else nil
	local max = if opts then opts.max else nil
	local integer = if opts then opts.integer else nil
	return function(value)
		if typeof(value) ~= "number" then
			return false, "no es número"
		end
		local n = value :: number
		-- NaN no es igual a sí mismo y pasa cualquier comparación de rango; infinito rompe cuentas de monedas.
		if n ~= n or n == math.huge or n == -math.huge then
			return false, "NaN o infinito"
		end
		if integer and n % 1 ~= 0 then
			return false, "no es entero"
		end
		if min and n < min then
			return false, "menor que " .. min
		end
		if max and n > max then
			return false, "mayor que " .. max
		end
		return true
	end
end

-- maxLength es obligatorio: un texto sin tope es memoria y ancho de banda gratis para un atacante.
function Validate.string(opts: { maxLength: number, minLength: number?, pattern: string? }): Validator
	return function(value)
		if typeof(value) ~= "string" then
			return false, "no es texto"
		end
		local s = value :: string
		if #s > opts.maxLength then
			return false, "texto de más de " .. opts.maxLength .. " bytes"
		end
		if opts.minLength and #s < opts.minLength then
			return false, "texto de menos de " .. opts.minLength .. " bytes"
		end
		if utf8.len(s) == nil then
			return false, "UTF-8 inválido"
		end
		if opts.pattern and not string.find(s, opts.pattern) then
			return false, "no coincide con el formato"
		end
		return true
	end
end

function Validate.boolean(): Validator
	return function(value)
		if typeof(value) ~= "boolean" then
			return false, "no es booleano"
		end
		return true
	end
end

-- Uno de los valores permitidos (ids de ítems, nombres de pestañas...).
function Validate.oneOf(allowed: { any }): Validator
	local set = {}
	for _, v in allowed do
		set[v] = true
	end
	return function(value)
		if value == nil or set[value] == nil then
			return false, "valor no permitido"
		end
		return true
	end
end

function Validate.optional(inner: Validator): Validator
	return function(value)
		if value == nil then
			return true
		end
		return inner(value)
	end
end

-- Instancia de cierta clase. Ojo: que sea del tipo correcto no prueba que el jugador pueda usarla;
-- el handler igual tiene que verificar pertenencia o distancia.
function Validate.instance(className: string): Validator
	return function(value)
		if typeof(value) ~= "Instance" then
			return false, "no es instancia"
		end
		if not (value :: Instance):IsA(className) then
			return false, "no es " .. className
		end
		return true
	end
end

-- Lista secuencial (1..n) de hasta maxCount elementos, todos válidos.
function Validate.array(item: Validator, maxCount: number): Validator
	return function(value)
		if typeof(value) ~= "table" then
			return false, "no es lista"
		end
		local t = value :: { [any]: any }
		local count = 0
		for _ in t do
			count += 1
			if count > maxCount then
				return false, "más de " .. maxCount .. " elementos"
			end
		end
		if count ~= #t then
			return false, "no es una lista secuencial"
		end
		for i = 1, count do
			local ok, err = item(t[i])
			if not ok then
				return false, "elemento " .. i .. ": " .. (err or "inválido")
			end
		end
		return true
	end
end

-- Valida la lista completa de argumentos de un remote: cantidad exacta y cada uno con su validador.
function Validate.args(validators: { Validator }): (...unknown) -> (boolean, string?)
	return function(...)
		local count = select("#", ...)
		if count > #validators then
			return false, "sobran argumentos (" .. count .. " de " .. #validators .. ")"
		end
		for i, validator in validators do
			local ok, err = validator((select(i, ...)))
			if not ok then
				return false, "argumento " .. i .. ": " .. (err or "inválido")
			end
		end
		return true
	end
end

return Validate
