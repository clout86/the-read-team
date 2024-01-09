local rdb = {}
-- Database function is self contained and you can delete
function rdb:runDatabase ()
    local luasql = require("luasql.sqlite3")
    local env = luasql.sqlite3()
    local conn = env:connect('netmap.db')
 
    local function getAllData()
    	local cursor = assert(conn:execute("SELECT id, ipv4, mac, hostname, alias, vendor, first_seen, last_seen FROM your_table"))
    	return cursor
    end

    local function buildLuaTable()
    	local cursor = getAllData()
    	local hostTable = {}
    	local semiMajorAxis = 50
    	local angle = 0
    	local speed = .8
    	local eccentricity = .5
    	-- Iterate through each row in the database
    	local row = cursor:fetch({}, "a")
    	while row do
            table.insert(hostTable, {
                name = row.hostname,
                semiMajorAxis = semiMajorAxis,
                id = row.id,
                ipv4 = row.ipv4,
                mac = row.mac,
                alias = row.alias,
                vendor = row.vendor,
                first_seen = row.first_seen,
                last_seen = row.last_seen,
                angle = angle,
                speed = speed,
                eccentricity = eccentricity
            })
	    -- place to define orbit props per host
            angle = math.random() * 360 
	    -- speed = speed - math.random(0.13,0.17)
	    -- if speed <= 0 then speed = math.random(0.09,0.13) end
	    semiMajorAxis = semiMajorAxis + math.random(10,35)
	    if semiMajorAxis > 400 then semiMajorAxis = math.ceil(math.random(400,500)) end
	    eccentricity = math.random(0.09,0.65)
            row = cursor:fetch(row, "a") -- Fetch the next row
    	end
    	cursor:close()
    	return hostTable
    end
    local hostTable = buildLuaTable()
    conn:close()
    env:close()
    return hostTable
end

return rdb