--!strict
local TestKit = require("./TestKit")
local Validate = require("../src/server/Net/Validate")

local equal, truthy, falsy = TestKit.equal, TestKit.truthy, TestKit.falsy

TestKit.run("Validate", {
	["number rechaza NaN, infinito y otros tipos"] = function()
		local v = Validate.number()
		falsy((v(0 / 0)), "NaN")
		falsy((v(math.huge)), "+inf")
		falsy((v(-math.huge)), "-inf")
		falsy((v("5")), "texto numérico")
		falsy((v(nil)), "nil")
		truthy((v(3.5)), "decimal")
	end,

	["number respeta min, max y entero"] = function()
		local v = Validate.number({ min = 1, max = 10, integer = true })
		truthy((v(1)), "mínimo")
		truthy((v(10)), "máximo")
		falsy((v(0)), "bajo el mínimo")
		falsy((v(11)), "sobre el máximo")
		falsy((v(2.5)), "no entero")
	end,

	["string exige tope, UTF-8 válido y formato"] = function()
		local v = Validate.string({ maxLength = 5, minLength = 2, pattern = "^%a+$" })
		truthy((v("abc")), "válido")
		falsy((v("abcdef")), "largo")
		falsy((v("a")), "corto")
		falsy((v("ab1")), "formato")
		falsy((v("\255\255")), "UTF-8 inválido")
		falsy((v(12)), "no texto")
	end,

	["boolean solo acepta booleanos"] = function()
		local v = Validate.boolean()
		truthy((v(false)), "false")
		falsy((v(0)), "cero")
		falsy((v(nil)), "nil")
	end,

	["oneOf acepta solo valores de la lista"] = function()
		local v = Validate.oneOf({ "Sword", "Shield", 3 })
		truthy((v("Sword")), "texto permitido")
		truthy((v(3)), "número permitido")
		falsy((v("Bow")), "no permitido")
		falsy((v(nil)), "nil")
		falsy((v(0 / 0)), "NaN")
	end,

	["optional deja pasar nil y valida lo demás"] = function()
		local v = Validate.optional(Validate.number({ max = 5 }))
		truthy((v(nil)), "nil")
		truthy((v(5)), "válido")
		falsy((v(6)), "inválido")
	end,

	["instance rechaza lo que no es Instance"] = function()
		local v = Validate.instance("Part")
		falsy((v({})), "tabla")
		falsy((v("Part")), "texto")
	end,

	["array exige lista secuencial con tope"] = function()
		local v = Validate.array(Validate.number({ integer = true }), 3)
		truthy((v({ 1, 2, 3 })), "válida")
		truthy((v({})), "vacía")
		falsy((v({ 1, 2, 3, 4 })), "más de 3")
		falsy((v({ 1, 2.5 })), "elemento inválido")
		falsy((v({ a = 1 })), "diccionario")
		falsy((v({ [1] = 1, [3] = 3 })), "con huecos")
		falsy((v("123")), "texto")
	end,

	["args controla cantidad y cada argumento"] = function()
		local check = Validate.args({ Validate.string({ maxLength = 10 }), Validate.number({ min = 1 }) })
		truthy((check("Sword", 2)), "válidos")
		falsy((check("Sword")), "falta el segundo")
		falsy((check("Sword", 2, "extra")), "sobra uno")
		falsy((check(2, "Sword")), "orden cambiado")
		local ok, err = check("Sword", 0)
		falsy(ok, "fuera de rango")
		equal(err, "argumento 2: menor que 1", "mensaje")
	end,

	["args sin validadores no acepta argumentos"] = function()
		local check = Validate.args({})
		truthy((check()), "sin argumentos")
		falsy((check(nil, nil)), "nil explícitos también cuentan")
	end,
})
