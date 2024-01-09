function love.load()
    -- Define the original and optimized versions of the function here
    -- function calculateEllipticalOrbitOriginal(...) end
    -- function calculateEllipticalOrbitOptimized(...) end


function calculateEllipticalOrbitOriginal(semiMajorAxis, eccentricity, angle, tiltAngle)
    local semiMinorAxis = semiMajorAxis * math.sqrt(1 - eccentricity^2)
    local r = semiMajorAxis * (1 - eccentricity^2) / (1 + eccentricity * math.cos(angle))
    local x = r * math.cos(angle)
    local y = r * math.sin(angle) * (semiMinorAxis / semiMajorAxis)

    -- Apply rotation for the tilt
    local tiltRadian = math.rad(tiltAngle)
    local rotatedX = x * math.cos(tiltRadian) - y * math.sin(tiltRadian)
    local rotatedY = x * math.sin(tiltRadian) + y * math.cos(tiltRadian)

    return rotatedX, rotatedY -- x and y coods 
end
-- Precompute constants outside the function if they remain constant for all function calls
local math_sqrt = math.sqrt
local math_cos = math.cos
local math_sin = math.sin
local math_rad = math.rad

function calculateEllipticalOrbitOptimized(semiMajorAxis, eccentricity, angle, tiltAngle)
    -- Precompute values that are invariant in the context of a single call
    local eccentricitySquared = eccentricity^2
    local semiMinorAxis = semiMajorAxis * math_sqrt(1 - eccentricitySquared)
    local oneMinusEccentricitySquared = 1 - eccentricitySquared
    local cosAngle = math_cos(angle)
    local sinAngle = math_sin(angle)
    
    local r = semiMajorAxis * oneMinusEccentricitySquared / (1 + eccentricity * cosAngle)
    local x = r * cosAngle
    local y = r * sinAngle * (semiMinorAxis / semiMajorAxis)

    -- Calculate the tilt only if necessary
    if tiltAngle ~= 0 then
        local tiltRadian = math_rad(tiltAngle)
        local cosTilt = math_cos(tiltRadian)
        local sinTilt = math_sin(tiltRadian)

        local rotatedX = x * cosTilt - y * sinTilt
        local rotatedY = x * sinTilt + y * cosTilt

        return rotatedX, rotatedY
    else
        return x, y
    end
end

    
local planets = {
      { name = "Mercury", semiMajorAxis = 200, angle = 25, speed = 1.01, eccentricity = 0.6056 },
      { name = "Venus", semiMajorAxis = 350, angle = 30, speed = 0.808, eccentricity = 0.6068 },
      { name = "Earth", semiMajorAxis = 400, angle = 35, speed = 0.505, eccentricity = 0.6167 },
      { name = "Mars", semiMajorAxis = 450, angle = 40, speed = 0.303, eccentricity = 0.5934 },
      { name = "Jupiter", semiMajorAxis = 600, angle = 45, speed = 0.202, eccentricity = 0.6484 },
      { name = "Saturn", semiMajorAxis = 650, angle = 50, speed = 0.101, eccentricity = 0.6541 },
      { name = "Uranus", semiMajorAxis = 700, angle = 55, speed = 0.25, eccentricity = 0.6472 },
      { name = "Neptune", semiMajorAxis = 250, angle = 60, speed = 0.35, eccentricity = 0.6086 },
      { name = "Pluto", semiMajorAxis = 400, angle = 65, speed = 0.45, eccentricity = 0.6488 },
      { name = "1 Ceres", semiMajorAxis = 450, angle = 70, speed = 0.55, eccentricity = 0.5758 },
      { name = "4 Vesta", semiMajorAxis = 500, angle = 75, speed = 0.65, eccentricity = 0.5887 },
      { name = "10 Hygiea", semiMajorAxis = 250, angle = 25, speed = 0.75, eccentricity = 0.6146 },
      { name = "Makemake", semiMajorAxis = 100, angle = 30, speed = 0.85, eccentricity = 0.6559 },
      { name = "Haumea", semiMajorAxis = 150, angle = 35, speed = 0.95, eccentricity = 0.6887 },
      { name = "2 Pallas", semiMajorAxis = 120, angle = 40, speed = 0.99, eccentricity = 0.6313 },
      { name = "3 Juno", semiMajorAxis = 115, angle = 45, speed = 0.97, eccentricity = 0.6555 },
      { name = "324 Bamberga", semiMajorAxis = 1200, angle = 50, speed = 0.96, eccentricity = 0.6400 },
      { name = "Eris", semiMajorAxis = 125, angle = 55, speed = 0.95, eccentricity = 0.6407 },
      { name = "Nereid", semiMajorAxis = 130, angle = 60, speed = 0.94, eccentricity = 0.6507 } }
    -- Convert the angle to radians for each planet
    for i, planet in ipairs(planets) do
        planet.angle = math.rad(planet.angle) -- Convert to radians
    end

    -- Warm-up phase
    for i = 1, 100 do
        for _, planet in ipairs(planets) do
            calculateEllipticalOrbitOriginal(planet.semiMajorAxis, planet.eccentricity, planet.angle, 0)
            calculateEllipticalOrbitOptimized(planet.semiMajorAxis, planet.eccentricity, planet.angle, 0)
        end
    end

    -- Benchmark
    local iterations = 1000 -- Adjust the number of iterations if needed
    local startTime, endTime

    startTime = love.timer.getTime()
    for i = 1, iterations do
        for _, planet in ipairs(planets) do
            calculateEllipticalOrbitOriginal(planet.semiMajorAxis, planet.eccentricity, planet.angle, 0)
        end
    end
    endTime = love.timer.getTime()
    print("Original Function Time: " .. (endTime - startTime))

    startTime = love.timer.getTime()
    for i = 1, iterations do
        for _, planet in ipairs(planets) do
            calculateEllipticalOrbitOptimized(planet.semiMajorAxis, planet.eccentricity, planet.angle, 0)
        end
    end
    endTime = love.timer.getTime()
    print("Optimized Function Time: " .. (endTime - startTime))
end
