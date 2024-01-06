local http = require("socket.http")
local ltn12 = require("ltn12")
local json = require("dkjson")

-- Function to fetch data structure from API
local function fetchAPIStructure()
    local response = {}
    local status, code = http.request{
        url = "http://pakemon:pakemon@localhost:8081/api/session/lan",
        sink = ltn12.sink.table(response)
    }

    if status and code == 200 then
        local str_response = table.concat(response)
        local data, _, err = json.decode(str_response)
        if data and data.hosts then
            return data.hosts  -- Return all hosts
        end
    end
    return nil
end

-- Function to run active processing on data
local function runActive (dataTable)
    local function buildLuaTable(dataTable)
        local hostTable = {}
        local semiMajorAxis = 50 -- Starting value
        local angle = 0
        local speed = .8
        local eccentricity = .5

        for _, row in ipairs(dataTable) do
            -- Create a new table for each host, copying the values from the row
            local host = {}
            for key, value in pairs(row) do
                host[key] = value
            end

            -- Add additional properties
            host.semiMajorAxis = semiMajorAxis
            host.angle = angle
            host.speed = speed
            host.eccentricity = eccentricity

            -- Insert the host into the hostTable
            table.insert(hostTable, host)

            -- Update properties for the next host
            angle = math.random() * 360
            semiMajorAxis = semiMajorAxis + math.random(10,35)
            if semiMajorAxis > 400 then semiMajorAxis = math.ceil(math.random(400,500)) end
            eccentricity = math.random(0.09,0.65)
        end
        return hostTable
    end

    return buildLuaTable(dataTable)
end

-- Main execution
local hosts = fetchAPIStructure()
if hosts then
    local processedHosts = runActive(hosts)
    for k,v in ipairs(processedHosts) do 
	    for a, b in pairs(v) do 
		    print(a,b) 
	    end 
    end

end

