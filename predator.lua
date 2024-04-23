-- Constants
local MAX_SPEED = 10 -- Maximum wheel speed for robots
local IMMOBILIZATION_DIST = 10 -- Distance threshold to immobilize the prey
local MAX_DIST = 100 -- Maximum initial target distance between robots
local MIN_DIST = 8 -- Minimum target distance when close to prey
local MAX_IMPORTANCE = 150000 -- Maximum importance of prey
local MIN_IMPORTANCE = 100 -- Minimum importance when prey is far
local ALPHA = 0.09 -- Sensitivity factor for distance adjustment
local BETA = 0.09 -- Sensitivity factor for importance adjustment
local Max_strength = 30
local Min_strength = 10
local IMMOBILIZATION_PHASE = 55 -- Distance threshold to tighten formation
local Max_turn = 30
local Min_turn = 10

-- New Constants for Slower Updates
local ALPHA_SLOW = 0.009 -- Reduced sensitivity for distance adjustment during move-toward phase
local BETA_SLOW = 0.009 -- Reduced sensitivity for importance adjustment during move-toward phase

-- Variables with initial values
local desireDist = MAX_DIST -- Initial target distance between robots
local preyImportance = MIN_IMPORTANCE -- Initial influence of prey on movement direction
local epsilon = Max_strength -- Initial depth of the potential well, affects force strength
local turn_rate = Min_turn

-- Initialize simulation by enabling sensors and initializing data
function init()
    robot.colored_blob_omnidirectional_camera.enable()
    robot.leds.set_all_colors("black") -- Initial color indicating ready state
end

-- Function to update distance and importance based on prey distance
function updateParameters(preyDistance, ALPHA, BETA)
    desireDist = MAX_DIST - (MAX_DIST - MIN_DIST) * (1 - math.exp(-ALPHA * preyDistance))
    preyImportance = MIN_IMPORTANCE + (MAX_IMPORTANCE - MIN_IMPORTANCE) * (1 - math.exp(-BETA * preyDistance))  
    epsilon = Max_strength - (Max_strength - Min_strength) * (1 - math.exp(-ALPHA * preyDistance)) 
    turn_rate = Min_turn + (Max_turn - Min_turn) * (1 - math.exp(-BETA * preyDistance)) 
    
end

-- Main control loop
function step()
    local preyDetected, preyAngle, preyDistance = detectPrey()
    if preyDetected then
        if preyDistance <= IMMOBILIZATION_PHASE then
            -- Use faster update when close to immobilization phase
            robot.leds.set_all_colors("green") -- Indicate immobilizing action
            updateParameters(preyDistance, ALPHA, BETA)
        elseif preyDistance > IMMOBILIZATION_PHASE then
            -- Use slower update during general move-toward phase
            robot.leds.set_all_colors("yellow") -- Indicate mobilizing action
            updateParameters(preyDistance, ALPHA_SLOW, BETA_SLOW)
        end

        if preyDistance < IMMOBILIZATION_DIST then
            -- Stop the robot if close enough to the prey
            robot.wheels.set_velocity(0, 0)
            robot.leds.set_all_colors("blue") -- Indicate complete immobilization
        else
            -- Move towards prey
            local target_angle = computeOptimalAngle(preyAngle, 0, true, false)
            local speeds = computeWheelSpeeds(turn_rate, target_angle)
            robot.wheels.set_velocity(speeds[1], speeds[2])
            robot.range_and_bearing.set_data(1, 2) -- Indicate active pursuit
        end
    else
        followLeader()
    end

    robot.range_and_bearing.clear_data() -- Clear communication data for the next step
end

function followLeader()
    local leaderFound = false
    local leaderAngle = 0
    local leaderDistance = math.huge
    local bestColorPriority = math.huge  -- Lower means higher priority

    for i, blob in ipairs(robot.colored_blob_omnidirectional_camera) do
        local colorPriority = getColorPriority(blob.color)
        if colorPriority < bestColorPriority then
            leaderFound = true
            leaderDistance = blob.distance
            leaderAngle = blob.angle
            bestColorPriority = colorPriority
        elseif colorPriority == bestColorPriority and blob.distance < leaderDistance then
            leaderDistance = blob.distance
            leaderAngle = blob.angle
        end
    end
    
    if leaderFound then
        local target_angle = computeOptimalAngle(0, leaderAngle, false, true)
        local speeds = computeWheelSpeeds(1, target_angle)
        robot.wheels.set_velocity(speeds[1], speeds[2])
        robot.leds.set_all_colors("orange")  -- following leader
    else
        local target_angle = computeOptimalAngle(0, 0, false, false)
        local speeds = computeWheelSpeeds(1, target_angle)
        robot.wheels.set_velocity(speeds[1], speeds[2])
        robot.leds.set_all_colors("purple")  -- maintaining formation
    end
end

-- Define a function to assign priority to colors
function getColorPriority(color)
    if color.red == 0 and color.green == 0 and color.blue > 240 then
        return 1  -- Highest priority: Blue, immobilization state
    elseif color.red > 240 and color.green > 240 and color.blue < 5 then
        return 2  -- Medium priority: Yellow, active movement
    elseif color.red == 0 and color.green > 240 and color.blue == 0 then
        return 3  -- Lower priority: Purple, formation state
    end
    return 1000  -- Default for unrecognized colors
end

-- Detect the prey based on color and return its angle and distance
function detectPrey()
    local preyDetected = false
    local closestPreyAngle = 0
    local closestPreyDistance = math.huge

    for i, blob in ipairs(robot.colored_blob_omnidirectional_camera) do
        if blob.color.red > 240 and blob.color.green < 5 and blob.color.blue < 5 then
            preyDetected = true
            if blob.distance < closestPreyDistance then
                closestPreyDistance = blob.distance
                closestPreyAngle = blob.angle
            end
        end
    end
    return preyDetected, closestPreyAngle, closestPreyDistance
end

-- Compute the optimal movement direction using Lennard-Jones potential
function computeOptimalAngle(preyAngle, leaderAngle, preyDetected, isFollowing)
    local sum_vector = {x = 0, y = 0}

    for i, message in ipairs(robot.range_and_bearing) do
        local lj_force = computeLennardJonesForce(message.range)
        sum_vector.x = sum_vector.x + math.cos(message.horizontal_bearing) * lj_force
        sum_vector.y = sum_vector.y + math.sin(message.horizontal_bearing) * lj_force
    end
    
    if isFollowing then
        sum_vector.x = sum_vector.x + math.cos(leaderAngle)
        sum_vector.y = sum_vector.y + math.sin(leaderAngle)
    end

    if preyDetected then
        sum_vector.x = sum_vector.x + preyImportance * math.cos(preyAngle)
        sum_vector.y = sum_vector.y + preyImportance * math.sin(preyAngle)
    end

    return math.atan2(sum_vector.y, sum_vector.x)
end

-- Compute Lennard-Jones force based on the dynamically adjusted distance from another robot
function computeLennardJonesForce(real_distance)
    local r_ratio = desireDist / real_distance
    return -4 * epsilon * (math.pow(r_ratio, 12) - math.pow(r_ratio, 6)) / real_distance
end

-- Compute wheel speeds based on the target angle to steer the robot
function computeWheelSpeeds(rate, target_angle)
    local forward_component = math.cos(target_angle)
    local angular_velocity = rate * target_angle
    
    return {
        forward_component * MAX_SPEED - angular_velocity,
        forward_component * MAX_SPEED + angular_velocity
    }
end

-- Reset function to clear any persistent state
function reset()
    desireDist = MAX_DIST
    preyImportance = MIN_IMPORTANCE
    turn_rate = Min_turn
    epsilon = Max_strength
    robot.range_and_bearing.clear_data()
end

-- Cleanup resources on simulation end
function destroy()
    -- Any necessary cleanup code
end
