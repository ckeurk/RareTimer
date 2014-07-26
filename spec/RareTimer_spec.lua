require("busted")
local TestUnit = {
    GetHealth = function() return 1234 end,
    GetMaxHealth = function() return 1234 end,
}

describe("RareTimer tests", function()
    describe("GetHealth 100%", function ()
        assert.truthy(RareTimer:GetHealth(TestUnit) == 100)
    end)
end)
