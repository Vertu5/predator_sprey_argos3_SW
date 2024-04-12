--[[ 
  Hexagonal Pattern Formation with Prey Targeting and Visual Feedback
  This script enables robots to autonomously arrange into a hexagonal pattern using Lennard-Jones potential.
  Robots adjust their movement to approach and potentially immobilize detected prey while maintaining the formation.
  Visual feedback via LED colors indicates different robot states.
]]

-- Constants
local IMMOBILIZATION_PHASE = 95-- Distance threshold to tighten formation
local IMMOBILIZATION_DIST = 10 -- Distance threshold to immobilize the prey
local MAX_SPEED = 10 -- Maximum wheel speed for robots
local MAX_TURN_RATE = 15

-- Variables with initial values
local targetDist = 300 -- Initial target distance between robots in cm for hexagonal pattern
local epsilon = 10 -- Initial depth of the potential well, affects force strength
local preyImportance = 90000 -- Initial influence of prey on movement direction

-- Initialize simulation by enabling sensors and initializing data
function init()
    robot.colored_blob_omnidirectional_camera.enable()
    robot.leds.set_all_colors("black") -- Initial color indicating ready state

end

-- Main control loop
function step()
    local preyDetected, preyAngle, preyDistance = detectPrey()
    if preyDetected then
        if preyDistance <= IMMOBILIZATION_PHASE then
            -- Envoyer un signal pour changer targetDist à 10 pour tous les robots
            
            robot.leds.set_all_colors("green") -- Indicate immobilizing action
            
            if preyDistance < IMMOBILIZATION_DIST then
                targetDist = 20
                MAX_TURN_RATE = 7
                -- Stop the robot if close enough to the prey
                robot.wheels.set_velocity(0, 0)
                robot.leds.set_all_colors("blue") -- Indicate complete immobilization
            else
                moveTowardsPrey(preyAngle)
            end
        else
            UpdateTarget()
            local target_angle = computeOptimalAngle(preyAngle, 0, true, false) 
            local speeds = computeWheelSpeeds(target_angle)
            robot.wheels.set_velocity(speeds[1], speeds[2])
            robot.leds.set_all_colors("yellow")  -- Indiquer le déplacement vers la proie
            robot.range_and_bearing.set_data(1, 2) -- Indicate active pursuit
        end
    else
        followLeader()
    end

    robot.range_and_bearing.clear_data()  -- Effacer les données de communication pour la prochaine étape
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
        local speeds = computeWheelSpeeds(target_angle)
        robot.wheels.set_velocity(speeds[1]/1.5, speeds[2]/1.5)
        robot.leds.set_all_colors("magenta")  -- following leader
    else
        local target_angle = computeOptimalAngle(0, 0, false, false)
        local speeds = computeWheelSpeeds(target_angle)
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

function UpdateTarget()
       
    for i, blob in ipairs(robot.colored_blob_omnidirectional_camera) do
        -- Detect blu color as a predator
        if blob.color.red == 0 and blob.color.green == 0 and blob.color.blue > 240 then
            targetDist = 20
            return 
        end
    end
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
function computeLennardJonesForce(distance)
    local r_ratio = targetDist / distance
    return -4 * epsilon * (math.pow(r_ratio, 12) - math.pow(r_ratio, 6)) / distance
end

-- Compute wheel speeds based on the target angle to steer the robot
function computeWheelSpeeds(target_angle)
    local forward_component = math.cos(target_angle)
    local angular_velocity = 20 * target_angle
    local wheels_distance = 14 -- distance between wheels in cm

    return {
        forward_component * MAX_SPEED - angular_velocity * wheels_distance / 2,
        forward_component * MAX_SPEED + angular_velocity * wheels_distance / 2
    }
end

-- Function to move towards the detected prey
function moveTowardsPrey(angle)
    local turnRate = calculateTurnRate(angle)

    -- Adjust velocities based on the turn rate to steer towards the prey
    if angle > 0 then
        robot.wheels.set_velocity(MAX_SPEED - turnRate, MAX_SPEED)
    else
        robot.wheels.set_velocity(MAX_SPEED, MAX_SPEED - turnRate)
    end
end

-- Function to calculate the turn rate based on the angle to the prey
function calculateTurnRate(angle)
    -- This function maps the angle to a turn rate, ensuring smoother turning
    -- The mapping can be adjusted based on testing and desired behavior
    return MAX_TURN_RATE * math.abs(angle) / math.pi  -- Proportional to the absolute angle
end

-- Reset function to clear any persistent state
function reset()
    robot.range_and_bearing.clear_data()
    targetDist = 300
end

-- Cleanup resources on simulation end
function destroy()
    -- Any necessary cleanup code
end
