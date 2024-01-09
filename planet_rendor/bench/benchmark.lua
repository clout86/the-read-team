function love.load()

function calculateEllipticalOrbit(semiMajorAxis, eccentricity, angle, tiltAngle)
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

function calculateEllipticalOrbit(semiMajorAxis, eccentricity, angle, tiltAngle)
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


    -- Warm-up phase
    for i = 1, 100 do
        calculateEllipticalOrbitOriginal(...)
        calculateEllipticalOrbitOptimized(...)
    end

    -- Benchmark
    local iterations = 10000
    local startTime, endTime

    startTime = love.timer.getTime()
    for i = 1, iterations do
        calculateEllipticalOrbitOriginal(...)
    end
    endTime = love.timer.getTime()
    print("Original Function Time: " .. (endTime - startTime))

    startTime = love.timer.getTime()
    for i = 1, iterations do
        calculateEllipticalOrbitOptimized(...)
    end
    endTime = love.timer.getTime()
    print("Optimized Function Time: " .. (endTime - startTime))
end
