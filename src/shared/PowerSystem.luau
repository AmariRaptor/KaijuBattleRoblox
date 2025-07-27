--!strict
-- PowerSystem.luau
-- Handles all character powers and abilities

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Types
type Character = Model & {
    Humanoid: Humanoid,
    HumanoidRootPart: BasePart,
    Head: BasePart
}

type Power = {
    name: string,
    description: string,
    cooldown: number,
    lastUsed: {[number]: number}, -- playerUserId -> tick()
    execute: (player: Player, character: Character) -> (boolean, string?)
}

type PowerSystem = {
    -- Kaiju Powers
    ["Roar"]: Power,
    ["Stomp"]: Power,
    ["TailWhip"]: Power,
    
    -- Guardian Powers
    ["ShieldBash"]: Power,
    ["ProtectiveAura"]: Power,
    ["HealingWave"]: Power,
    
    -- Engineer Powers
    ["TurretDeploy"]: Power,
    ["Barrier"]: Power,
    ["EMP"]: Power,
    
    -- Methods
    init: (PowerSystem) -> (),
    getPower: (PowerSystem, powerName: string) -> (Power?),
    canUsePower: (PowerSystem, player: Player, powerName: string) -> (boolean, string?),
    usePower: (PowerSystem, player: Player, powerName: string) -> (boolean, string?)
}

local PowerSystem: PowerSystem = {}

-- Helper function to create a visual effect
local function createEffect(name: string, duration: number, position: Vector3, parent: Instance?): Folder
    local effect = Instance.new("Folder")
    effect.Name = name .. "Effect"
    
    -- Create a particle emitter (example effect)
    local particleEmitter = Instance.new("ParticleEmitter")
    particleEmitter.Texture = "rbxassetid://241539689" -- Replace with your texture ID
    particleEmitter.LightEmission = 0.5
    particleEmitter.LightInfluence = 0
    particleEmitter.Size = NumberSequence.new(0.5, 2, 0.5)
    particleEmitter.Transparency = NumberSequence.new(0, 1)
    particleEmitter.Lifetime = NumberRange.new(0.5, 1)
    particleEmitter.Rate = 50
    particleEmitter.Speed = NumberRange.new(5, 10)
    particleEmitter.SpreadAngle = Vector2.new(30, 30)
    particleEmitter.Parent = effect
    
    -- Position the effect
    local attachment = Instance.new("Attachment")
    attachment.WorldPosition = position
    attachment.Parent = effect
    particleEmitter.Attachment0 = attachment
    
    -- Parent the effect
    if parent then
        effect.Parent = parent
    else
        effect.Parent = workspace.Effects or workspace
    end
    
    -- Clean up after duration
    game:GetService("Debris"):AddItem(effect, duration + 0.1)
    return effect
end

-- Kaiju Powers
PowerSystem.Roar = {
    name = "Roar",
    description = "Fearsome roar that stuns nearby enemies for 3 seconds",
    cooldown = 15,
    lastUsed = {},
    
    execute = function(player: Player, character: Character): (boolean, string?)
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return false, "No HumanoidRootPart found" end
        
        -- Create visual effect
        local effect = createEffect("Roar", 1, rootPart.Position, workspace)
        
        -- Play sound
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://138081500"
        sound.Volume = 1
        sound.Parent = rootPart
        sound:Play()
        game:GetService("Debris"):AddItem(sound, 2)
        
        -- Find and stun nearby enemies
        local stunRadius = 20
        local stunDuration = 3
        
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            if otherPlayer ~= player and otherPlayer.Character then
                local humanoid = otherPlayer.Character:FindFirstChild("Humanoid")
                local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                
                if humanoid and otherRoot and (otherRoot.Position - rootPart.Position).Magnitude <= stunRadius then
                    -- Apply stun effect
                    local stunValue = Instance.new("BoolValue")
                    stunValue.Name = "Stunned"
                    stunValue.Parent = humanoid
                    
                    -- Visual effect for stunned players
                    local stunEffect = Instance.new("ParticleEmitter")
                    stunEffect.Texture = "rbxassetid://241539689"
                    stunEffect.Color = ColorSequence.new(Color3.fromRGB(255, 200, 0))
                    stunEffect.LightEmission = 0.5
                    stunEffect.Size = NumberSequence.new(0.5, 1.5)
                    stunEffect.Lifetime = NumberRange.new(0.5, 1)
                    stunEffect.Rate = 20
                    stunEffect.Speed = NumberRange.new(2)
                    
                    local attachment = Instance.new("Attachment")
                    attachment.Parent = otherRoot
                    stunEffect.Parent = attachment
                    
                    -- Remove stun after duration
                    delay(stunDuration, function()
                        if stunValue and stunValue.Parent then
                            stunValue:Destroy()
                        end
                        if attachment and attachment.Parent then
                            attachment:Destroy()
                        end
                    end)
                end
            end
        end
        
        return true
    end
}

PowerSystem.Stomp = {
    name = "Stomp",
    description = "Powerful stomp that damages and knocks back nearby enemies",
    cooldown = 10,
    lastUsed = {},
    
    execute = function(player: Player, character: Character): (boolean, string?)
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return false, "No HumanoidRootPart found" end
        
        -- Create shockwave effect
        local shockwave = Instance.new("Part")
        shockwave.Shape = Enum.PartType.Cylinder
        shockwave.Size = Vector3.new(0.2, 1, 1)
        shockwave.CFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, 0, math.rad(90))
        shockwave.Anchored = true
        shockwave.CanCollide = false
        shockwave.Transparency = 0.5
        shockwave.Material = Enum.Material.Neon
        shockwave.Color = Color3.fromRGB(255, 100, 100)
        shockwave.Parent = workspace.Effects or workspace
        
        -- Animate the shockwave
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local goal = {
            Size = Vector3.new(0.2, 30, 30),
            Transparency = 1
        }
        
        local tween = TweenService:Create(shockwave, tweenInfo, goal)
        tween:Play()
        game:GetService("Debris"):AddItem(shockwave, 0.6)
        
        -- Damage and knockback
        local damage = 30
        local knockbackForce = 50
        local radius = 30
        
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            if otherPlayer ~= player and otherPlayer.Character then
                local humanoid = otherPlayer.Character:FindFirstChild("Humanoid")
                local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                
                if humanoid and otherRoot then
                    local distance = (otherRoot.Position - rootPart.Position).Magnitude
                    if distance <= radius then
                        -- Calculate damage falloff
                        local damageFalloff = 1 - (distance / radius)
                        local actualDamage = damage * damageFalloff
                        
                        -- Apply damage
                        humanoid:TakeDamage(actualDamage)
                        
                        -- Apply knockback
                        local direction = (otherRoot.Position - rootPart.Position).Unit
                        local bodyVelocity = Instance.new("BodyVelocity")
                        bodyVelocity.Velocity = direction * knockbackForce * damageFalloff
                        bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
                        bodyVelocity.Parent = otherRoot
                        
                        -- Remove knockback after a short time
                        game:GetService("Debris"):AddItem(bodyVelocity, 0.2)
                    end
                end
            end
        end
        
        return true
    end
}

-- Kaiju: Tail Whip
PowerSystem.TailWhip = {
    name = "Tail Whip",
    description = "Swing your tail in a wide arc, damaging enemies behind you",
    cooldown = 8,
    lastUsed = {},
    
    execute = function(player: Player, character: Character): (boolean, string?)
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return false, "No HumanoidRootPart found" end
        
        -- Create tail whip effect
        local arc = Instance.new("Part")
        arc.Shape = Enum.PartType.Block
        arc.Size = Vector3.new(5, 5, 10)
        arc.CFrame = rootPart.CFrame * CFrame.new(0, 0, -5) * CFrame.Angles(0, math.rad(45), 0)
        arc.Anchored = true
        arc.CanCollide = false
        arc.Transparency = 0.7
        arc.Material = Enum.Material.Neon
        arc.Color = Color3.fromRGB(255, 150, 150)
        arc.Parent = workspace.Effects or workspace
        
        -- Animate the arc
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local goal = {
            CFrame = arc.CFrame * CFrame.Angles(0, math.rad(270), 0),
            Transparency = 1
        }
        
        local tween = TweenService:Create(arc, tweenInfo, goal)
        tween:Play()
        game:GetService("Debris"):AddItem(arc, 0.4)
        
        -- Damage enemies in arc
        local damage = 40
        local arcAngle = math.rad(90) -- 90 degree arc
        
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            if otherPlayer ~= player and otherPlayer.Character then
                local humanoid = otherPlayer.Character:FindFirstChild("Humanoid")
                local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                
                if humanoid and otherRoot then
                    local toEnemy = (otherRoot.Position - rootPart.Position)
                    local distance = toEnemy.Magnitude
                    
                    -- Check if enemy is within range and in the arc
                    if distance <= 15 then -- Max range of tail whip
                        local forward = rootPart.CFrame.LookVector
                        local direction = toEnemy.Unit
                        local angle = math.acos(forward:Dot(direction))
                        
                        if angle <= arcAngle / 2 then
                            -- Enemy is in the arc, apply damage
                            humanoid:TakeDamage(damage)
                            
                            -- Apply knockback
                            local bodyVelocity = Instance.new("BodyVelocity")
                            bodyVelocity.Velocity = direction * 30 -- Knockback force
                            bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
                            bodyVelocity.Parent = otherRoot
                            game:GetService("Debris"):AddItem(bodyVelocity, 0.2)
                        end
                    end
                end
            end
        end
        
        return true
    end
}

-- Guardian Powers
PowerSystem.ShieldBash = {
    name = "Shield Bash",
    description = "Charges forward, damaging and stunning the first enemy hit",
    cooldown = 8,
    lastUsed = {},
    
    execute = function(player: Player, character: Character): (boolean, string?)
        local humanoid = character:FindFirstChild("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not rootPart then return false, "Missing required character parts" end
        
        -- Create shield bash effect
        local shield = Instance.new("Part")
        shield.Shape = Enum.PartType.Cylinder
        shield.Size = Vector3.new(0.5, 3, 3)
        shield.CFrame = rootPart.CFrame * CFrame.new(0, 0, -2) * CFrame.Angles(0, 0, math.rad(90))
        shield.Anchored = false
        shield.CanCollide = false
        shield.Transparency = 0.5
        shield.Material = Enum.Material.Neon
        shield.Color = Color3.fromRGB(100, 150, 255)
        shield.Parent = workspace.Effects or workspace
        
        -- Weld shield to character
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = rootPart
        weld.Part1 = shield
        weld.Parent = shield
        
        -- Charge forward
        local chargeSpeed = 100
        local chargeTime = 0.5
        local startTime = tick()
        
        -- Store original walkspeed
        local originalWalkSpeed = humanoid.WalkSpeed
        humanoid.WalkSpeed = chargeSpeed
        
        -- Create charge effect
        local chargeEffect = Instance.new("ParticleEmitter")
        chargeEffect.Texture = "rbxassetid://241539689"
        chargeEffect.LightEmission = 0.5
        chargeEffect.Size = NumberSequence.new(0.5, 2)
        chargeEffect.Lifetime = NumberRange.new(0.5, 1)
        chargeEffect.Rate = 50
        chargeEffect.Speed = NumberRange.new(5, 10)
        
        local attachment = Instance.new("Attachment")
        attachment.Parent = rootPart
        chargeEffect.Parent = attachment
        
        -- Check for hits in a loop
        local connection
        connection = game:GetService("RunService").Heartbeat:Connect(function()
            if tick() - startTime >= chargeTime then
                connection:Disconnect()
                humanoid.WalkSpeed = originalWalkSpeed
                shield:Destroy()
                attachment:Destroy()
                return
            end
            
            -- Check for enemies in front
            local params = RaycastParams.new()
            params.FilterDescendantsInstances = {character}
            params.FilterType = Enum.RaycastFilterType.Blacklist
            
            local rayOrigin = rootPart.Position
            local rayDirection = rootPart.CFrame.LookVector * 5
            local raycastResult = workspace:Raycast(rayOrigin, rayDirection, params)
            
            if raycastResult then
                local hitPart = raycastResult.Instance
                local hitCharacter = hitPart:FindFirstAncestorOfClass("Model")
                local hitPlayer = Players:GetPlayerFromCharacter(hitCharacter)
                
                if hitPlayer and hitPlayer ~= player then
                    local hitHumanoid = hitCharacter:FindFirstChild("Humanoid")
                    if hitHumanoid then
                        -- Apply damage and stun
                        hitHumanoid:TakeDamage(25)
                        
                        local stun = Instance.new("BoolValue")
                        stun.Name = "Stunned"
                        stun.Parent = hitHumanoid
                        
                        -- Visual effect for stun
                        local stunEffect = Instance.new("ParticleEmitter")
                        stunEffect.Texture = "rbxassetid://241539689"
                        stunEffect.Color = ColorSequence.new(Color3.fromRGB(255, 200, 0))
                        stunEffect.LightEmission = 0.5
                        stunEffect.Size = NumberSequence.new(0.5, 1.5)
                        stunEffect.Lifetime = NumberRange.new(0.5, 1)
                        stunEffect.Rate = 20
                        stunEffect.Speed = NumberRange.new(2)
                        
                        local hitAttachment = Instance.new("Attachment")
                        hitAttachment.Parent = hitCharacter:FindFirstChild("HumanoidRootPart") or hitCharacter:FindFirstChild("Head") or hitCharacter:FindFirstChild("Torso") or hitCharacter:GetChildren()[1]
                        stunEffect.Parent = hitAttachment
                        
                        -- Remove stun after duration
                        delay(2, function()
                            if stun and stun.Parent then
                                stun:Destroy()
                            end
                            if hitAttachment and hitAttachment.Parent then
                                hitAttachment:Destroy()
                            end
                        end)
                        
                        -- End charge early
                        connection:Disconnect()
                        humanoid.WalkSpeed = originalWalkSpeed
                        shield:Destroy()
                        attachment:Destroy()
                        return
                    end
                end
            end
        end)
        
        -- Clean up after charge
        delay(chargeTime + 0.1, function()
            if connection.Connected then
                connection:Disconnect()
            end
            humanoid.WalkSpeed = originalWalkSpeed
            shield:Destroy()
            attachment:Destroy()
        end)
        
        return true
    end
}

-- Guardian: Protective Aura
PowerSystem.ProtectiveAura = {
    name = "Protective Aura",
    description = "Creates a damage-reducing aura around you that affects nearby allies",
    cooldown = 25,
    lastUsed = {},
    
    execute = function(player: Player, character: Character): (boolean, string?)
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return false, "No HumanoidRootPart found" end
        
        -- Create aura effect
        local aura = Instance.new("Part")
        aura.Shape = Enum.PartType.Ball
        aura.Size = Vector3.new(1, 1, 1)
        aura.CFrame = rootPart.CFrame
        aura.Anchored = false
        aura.CanCollide = false
        aura.Transparency = 0.7
        aura.Material = Enum.Material.Neon
        aura.Color = Color3.fromRGB(100, 200, 255)
        
        -- Weld aura to character
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = rootPart
        weld.Part1 = aura
        weld.Parent = aura
        
        -- Animate aura expansion
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local goal = {
            Size = Vector3.new(30, 30, 30),
            Transparency = 0.9
        }
        
        local tween = TweenService:Create(aura, tweenInfo, goal)
        tween:Play()
        
        -- Add to workspace
        aura.Parent = workspace.Effects or workspace
        
        -- Apply damage reduction to nearby allies
        local auraRadius = 15
        local damageReduction = 0.5 -- 50% damage reduction
        local duration = 10 -- seconds
        
        local allies = {}
        
        -- Find all nearby allies
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            if otherPlayer ~= player and otherPlayer.Team == player.Team and otherPlayer.Character then
                local humanoid = otherPlayer.Character:FindFirstChild("Humanoid")
                local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                
                if humanoid and otherRoot and (otherRoot.Position - rootPart.Position).Magnitude <= auraRadius then
                    -- Apply damage reduction
                    local damageModifier = Instance.new("NumberValue")
                    damageModifier.Name = "DamageReduction"
                    damageModifier.Value = damageReduction
                    damageModifier.Parent = humanoid
                    
                    -- Visual effect for protected allies
                    local protectionEffect = Instance.new("ParticleEmitter")
                    protectionEffect.Texture = "rbxassetid://241539689"
                    protectionEffect.Color = ColorSequence.new(Color3.fromRGB(100, 200, 255))
                    protectionEffect.LightEmission = 0.5
                    protectionEffect.Size = NumberSequence.new(0.5, 1)
                    protectionEffect.Lifetime = NumberRange.new(0.5, 1)
                    protectionEffect.Rate = 10
                    protectionEffect.Speed = NumberRange.new(1)
                    
                    local attachment = Instance.new("Attachment")
                    attachment.Parent = otherRoot
                    protectionEffect.Parent = attachment
                    
                    -- Store for cleanup
                    table.insert(allies, {
                        humanoid = humanoid,
                        modifier = damageModifier,
                        attachment = attachment
                    })
                end
            end
        end
        
        -- Remove aura effect after duration
        delay(duration, function()
            -- Remove damage reduction from all affected allies
            for _, ally in ipairs(allies) do
                if ally.modifier and ally.modifier.Parent then
                    ally.modifier:Destroy()
                end
                if ally.attachment and ally.attachment.Parent then
                    ally.attachment:Destroy()
                end
            end
            
            -- Fade out aura
            local fadeTween = TweenService:Create(aura, TweenInfo.new(0.5), {Transparency = 1})
            fadeTween:Play()
            fadeTween.Completed:Connect(function()
                aura:Destroy()
            end)
        end)
        
        return true
    end
}

-- Guardian: Healing Wave
PowerSystem.HealingWave = {
    name = "Healing Wave",
    description = "Sends out a wave that heals allies in a line in front of you",
    cooldown = 15,
    lastUsed = {},
    
    execute = function(player: Player, character: Character): (boolean, string?)
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return false, "No HumanoidRootPart found" end
        
        -- Create wave effect
        local wave = Instance.new("Part")
        wave.Shape = Enum.PartType.Block
        wave.Size = Vector3.new(2, 2, 1)
        wave.CFrame = rootPart.CFrame * CFrame.new(0, 0, -2)
        wave.Anchored = true
        wave.CanCollide = false
        wave.Transparency = 0.5
        wave.Material = Enum.Material.Neon
        wave.Color = Color3.fromRGB(100, 255, 100)
        wave.Parent = workspace.Effects or workspace
        
        -- Animate wave
        local distance = 50
        local speed = 100 -- studs per second
        local duration = distance / speed
        
        local startTime = tick()
        local startPos = wave.Position
        local direction = rootPart.CFrame.LookVector
        
        -- Track healed players to avoid double healing
        local healedPlayers = {}
        
        -- Update wave position
        local connection
        connection = game:GetService("RunService").Heartbeat:Connect(function()
            local elapsed = tick() - startTime
            if elapsed >= duration then
                connection:Disconnect()
                wave:Destroy()
                return
            end
            
            -- Move wave forward
            local newPos = startPos + (direction * speed * elapsed)
            wave.CFrame = CFrame.new(newPos) * CFrame.Angles(0, 0, 0)
            
            -- Check for allies in wave path
            for _, otherPlayer in ipairs(Players:GetPlayers()) do
                if otherPlayer.Team == player.Team and not healedPlayers[otherPlayer.UserId] and otherPlayer.Character then
                    local humanoid = otherPlayer.Character:FindFirstChild("Humanoid")
                    local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                    
                    if humanoid and otherRoot then
                        local toAlly = (otherRoot.Position - newPos)
                        -- Check if ally is in front of the wave and close to the center line
                        if toAlly.Magnitude <= 5 and direction:Dot(toAlly.Unit) > 0.8 then
                            -- Heal ally
                            humanoid.Health = math.min(humanoid.Health + 30, humanoid.MaxHealth)
                            healedPlayers[otherPlayer.UserId] = true
                            
                            -- Show healing effect
                            local healEffect = Instance.new("ParticleEmitter")
                            healEffect.Texture = "rbxassetid://241539689"
                            healEffect.Color = ColorSequence.new(Color3.fromRGB(100, 255, 100))
                            healEffect.LightEmission = 0.5
                            healEffect.Size = NumberSequence.new(0.5, 1.5)
                            healEffect.Lifetime = NumberRange.new(0.5, 1)
                            healEffect.Rate = 20
                            healEffect.Speed = NumberRange.new(5)
                            
                            local attachment = Instance.new("Attachment")
                            attachment.Parent = otherRoot
                            healEffect.Parent = attachment
                            
                            -- Clean up
                            delay(1, function()
                                attachment:Destroy()
                            end)
                        end
                    end
                end
            end
        end)
        
        -- Clean up after duration
        delay(duration + 0.1, function()
            if connection.Connected then
                connection:Disconnect()
            end
            if wave and wave.Parent then
                wave:Destroy()
            end
        end)
        
        return true
    end
}
-- Engineer Powers
PowerSystem.TurretDeploy = {
    name = "Deploy Turret",
    description = "Deploys an automated turret that attacks enemies",
    cooldown = 30,
    lastUsed = {},
    maxTurrets = 2,
    turretDuration = 30,
    turretDamage = 10,
    turretRange = 50,
    turretFireRate = 0.5,
    
    execute = function(self, player: Player, character: Character): (boolean, string?)
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return false, "No HumanoidRootPart found" end
        
        -- Count existing turrets from this player
        local turretCount = 0
        local turrets = {}
        
        -- Find all turrets belonging to this player
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj.Name == "EngineerTurret" and obj:GetAttribute("Owner") == player.UserId then
                table.insert(turrets, obj)
                turretCount = turretCount + 1
            end
        end
        
        -- Remove oldest turret if at max
        if turretCount >= self.maxTurrets and #turrets > 0 then
            local oldestTurret = turrets[1]
            if oldestTurret then
                local emitter = oldestTurret:FindFirstChild("TurretEmitter")
                if emitter then
                    emitter.Enabled = false
                end
                oldestTurret:Destroy()
            end
        end
        
        -- Calculate spawn position in front of the player
        local spawnPos = rootPart.Position + (rootPart.CFrame.LookVector * 5) + Vector3.new(0, -2.5, 0)
        
        -- Create turret base
        local turret = Instance.new("Part")
        turret.Name = "EngineerTurret"
        turret.Anchored = true
        turret.CanCollide = true
        turret.Size = Vector3.new(3, 1, 3)
        turret.Position = spawnPos
        turret.BrickColor = BrickColor.new("Bright blue")
        turret.Material = Enum.Material.Metal
        turret:SetAttribute("Owner", player.UserId)
        
        -- Add turret head
        local head = Instance.new("Part")
        head.Name = "TurretHead"
        head.Size = Vector3.new(2, 2, 3)
        head.Position = spawnPos + Vector3.new(0, 2, 0)
        head.BrickColor = BrickColor.new("Bright blue")
        head.Material = Enum.Material.Metal
        head.Anchored = true
        head.CanCollide = false
        
        -- Weld head to base
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = turret
        weld.Part1 = head
        weld.Parent = head
        
        -- Add turret barrel
        local barrel = Instance.new("Part")
        barrel.Name = "Barrel"
        barrel.Size = Vector3.new(0.5, 0.5, 2)
        barrel.CFrame = head.CFrame * CFrame.new(0, 0, -2.5)
        barrel.BrickColor = BrickColor.new("Really black")
        barrel.Material = Enum.Material.Metal
        barrel.Anchored = true
        barrel.CanCollide = false
        
        local barrelWeld = Instance.new("WeldConstraint")
        barrelWeld.Part0 = head
        barrelWeld.Part1 = barrel
        barrelWeld.Parent = barrel
        
        -- Add turret light
        local light = Instance.new("PointLight")
        light.Name = "TurretLight"
        light.Color = Color3.fromRGB(0, 170, 255)
        light.Range = 10
        light.Brightness = 1
        light.Parent = head
        
        -- Add turret emitter
        local emitter = Instance.new("ParticleEmitter")
        emitter.Name = "TurretEmitter"
        emitter.Texture = "rbxassetid://241539689"
        emitter.Color = ColorSequence.new(Color3.fromRGB(0, 170, 255))
        emitter.LightEmission = 0.5
        emitter.Size = NumberSequence.new(0.5, 1)
        emitter.Lifetime = NumberRange.new(0.5)
        emitter.Rate = 0
        emitter.Speed = NumberRange.new(5)
        emitter.Parent = barrel
        
        -- Add turret script
        local turretScript = Instance.new("Script")
        turretScript.Name = "TurretAI"
        turretScript.Source = [[
            local turret = script.Parent
            local head = turret:FindFirstChild("TurretHead")
            local barrel = head and head:FindFirstChild("Barrel")
            local emitter = barrel and barrel:FindFirstChild("TurretEmitter")
            
            if not (turret and head and barrel and emitter) then
                script:Destroy()
                return
            end
            
            local TARGET_RANGE = ]] .. self.turretRange .. [[
            local DAMAGE = ]] .. self.turretDamage .. [[
            local FIRE_RATE = ]] .. self.turretFireRate .. [[
            local DURATION = ]] .. self.turretDuration .. [[
            
            local Players = game:GetService("Players")
            local RunService = game:GetService("RunService")
            
            local ownerId = turret:GetAttribute("Owner")
            local owner = ownerId and Players:GetPlayerByUserId(ownerId)
            local ownerTeam = owner and owner.Team
            
            if not owner then
                turret:Destroy()
                return
            end
            
            local function findTarget()
                local bestTarget = nil
                local bestDistance = math.huge
                
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= owner and player.Team ~= ownerTeam and player.Character then
                        local humanoid = player.Character:FindFirstChild("Humanoid")
                        local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                        
                        if humanoid and humanoid.Health > 0 and rootPart then
                            local distance = (rootPart.Position - turret.Position).Magnitude
                            if distance < TARGET_RANGE and distance < bestDistance then
                                bestTarget = {
                                    player = player,
                                    humanoid = humanoid,
                                    rootPart = rootPart,
                                    distance = distance
                                }
                                bestDistance = distance
                            end
                        end
                    end
                end
                
                return bestTarget
            end
            
            local function fireAtTarget(target)
                if not target or not target.rootPart or not target.humanoid or target.humanoid.Health <= 0 then
                    return false
                end
                
                -- Point barrel at target
                head.CFrame = CFrame.lookAt(head.Position, Vector3.new(
                    target.rootPart.Position.X,
                    head.Position.Y,
                    target.rootPart.Position.Z
                ))
                
                -- Create projectile
                local projectile = Instance.new("Part")
                projectile.Size = Vector3.new(0.3, 0.3, 0.3)
                projectile.Shape = Enum.PartType.Ball
                projectile.Material = Enum.Material.Neon
                projectile.BrickColor = BrickColor.new("Bright blue")
                projectile.CanCollide = false
                projectile.Anchored = true
                projectile.CFrame = barrel.CFrame * CFrame.new(0, 0, -1)
                projectile.Parent = workspace.Effects or workspace
                
                -- Add light
                local light = Instance.new("PointLight")
                light.Color = Color3.fromRGB(0, 170, 255)
                light.Range = 10
                light.Brightness = 2
                light.Parent = projectile
                
                -- Emit particles
                emitter:Emit(5)
                
                -- Animate projectile
                local startPos = projectile.Position
                local endPos = target.rootPart.Position + Vector3.new(0, 2, 0)
                local direction = (endPos - startPos).Unit
                local distance = (endPos - startPos).Magnitude
                local speed = 100 -- studs per second
                local duration = distance / speed
                
                local startTime = tick()
                
                local connection
                connection = RunService.Heartbeat:Connect(function()
                    local elapsed = tick() - startTime
                    local progress = elapsed / duration
                    
                    if progress >= 1 or not target.rootPart or not target.rootPart.Parent then
                        -- Hit or missed
                        if projectile and projectile.Parent then
                            -- Create impact effect
                            local impact = Instance.new("ParticleEmitter")
                            impact.Texture = "rbxassetid://241539689"
                            impact.Color = ColorSequence.new(Color3.fromRGB(0, 170, 255))
                            impact.LightEmission = 0.5
                            impact.Size = NumberSequence.new(0.5, 1.5)
                            impact.Lifetime = NumberRange.new(0.5, 1)
                            impact.Rate = 20
                            impact.Speed = NumberRange.new(5)
                            
                            local attachment = Instance.new("Attachment")
                            attachment.Position = projectile.Position
                            attachment.Parent = workspace.Effects or workspace
                            impact.Parent = attachment
                            
                            impact:Emit(10)
                            game:GetService("Debris"):AddItem(attachment, 1)
                            
                            -- Apply damage if hit
                            if progress < 1.1 and target.humanoid and target.humanoid.Parent then
                                target.humanoid:TakeDamage(DAMAGE)
                            end
                            
                            projectile:Destroy()
                        end
                        
                        if connection then
                            connection:Disconnect()
                        end
                        return
                    end
                    
                    -- Update position
                    local newPos = startPos + (direction * distance * progress)
                    projectile.Position = newPos
                end)
                
                return true
            end
            
            -- Main turret loop
            local lastFireTime = 0
            local startTime = tick()
            
            while turret.Parent and (tick() - startTime) < DURATION do
                local target = findTarget()
                
                if target and (tick() - lastFireTime) >= (1 / FIRE_RATE) then
                    if fireAtTarget(target) then
                        lastFireTime = tick()
                    end
                end
                
                wait(0.1)
            end
            
            -- Turret expired
            emitter.Enabled = false
            wait(1) -- Allow particles to finish
            turret:Destroy()
        ]]
        turretScript.Parent = turret
        
        -- Parent all parts
        turret.Parent = workspace
        head.Parent = turret
        barrel.Parent = head
        
        -- Add to cleanup list
        game:GetService("Debris"):AddItem(turret, self.turretDuration + 1)
        
        return true
    end
}

PowerSystem.Barrier = {
    name = "Barrier",
    description = "Creates a temporary barrier that blocks enemy attacks",
    cooldown = 25,
    lastUsed = {},
    barrierDuration = 15,
    barrierHealth = 500,
    barrierSize = Vector3.new(10, 10, 1),
    
    execute = function(self, player: Player, character: Character): (boolean, string?)
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return false, "No HumanoidRootPart found" end
        
        -- Calculate barrier position in front of the player
        local lookVector = rootPart.CFrame.LookVector
        local barrierPos = rootPart.Position + (lookVector * 5)
        
        -- Create barrier
        local barrier = Instance.new("Part")
        barrier.Name = "EngineerBarrier"
        barrier.Size = self.barrierSize
        barrier.Anchored = true
        barrier.CanCollide = true
        barrier.Transparency = 0.7
        barrier.Material = Enum.Material.ForceField
        barrier.Color = Color3.fromRGB(0, 170, 255)
        barrier.CFrame = CFrame.lookAt(barrierPos, barrierPos + lookVector) * CFrame.new(0, 0, 0)
        
        -- Add health
        local health = Instance.new("NumberValue")
        health.Name = "Health"
        health.Value = self.barrierHealth
        health.Parent = barrier
        
        -- Add force field effect
        local forceField = Instance.new("ForceField")
        forceField.Visible = false
        forceField.Parent = barrier
        
        -- Add glow effect
        local glow = Instance.new("ParticleEmitter")
        glow.Texture = "rbxassetid://241539689"
        glow.Color = ColorSequence.new(Color3.fromRGB(0, 170, 255))
        glow.LightEmission = 0.5
        glow.Size = NumberSequence.new(0.5, 1)
        glow.Lifetime = NumberRange.new(0.5, 1)
        glow.Rate = 20
        glow.Speed = NumberRange.new(1)
        
        local attachment = Instance.new("Attachment")
        attachment.Parent = barrier
        glow.Parent = attachment
        
        -- Add hit detection
        local touched = false
        
        local function onTouch(hit: BasePart)
            if touched then return end
            
            local hitCharacter = hit.Parent
            local hitPlayer = game:GetService("Players"):GetPlayerFromCharacter(hitCharacter)
            
            -- Only take damage from enemies
            if hitPlayer and hitPlayer.Team ~= player.Team then
                touched = true
                
                -- Create impact effect
                local impact = Instance.new("ParticleEmitter")
                impact.Texture = "rbxassetid://241539689"
                impact.Color = ColorSequence.new(Color3.fromRGB(255, 100, 100))
                impact.LightEmission = 0.5
                impact.Size = NumberSequence.new(0.5, 1.5)
                impact.Lifetime = NumberRange.new(0.5, 1)
                impact.Rate = 30
                impact.Speed = NumberRange.new(5)
                
                local hitPos = hit.Position
                local hitAttachment = Instance.new("Attachment")
                hitAttachment.WorldPosition = hitPos
                hitAttachment.Parent = workspace.Effects or workspace
                impact.Parent = hitAttachment
                
                impact:Emit(10)
                game:GetService("Debris"):AddItem(hitAttachment, 1)
                
                -- Apply damage to barrier
                health.Value = health.Value - 50
                
                -- Flash white to indicate damage
                local originalColor = barrier.Color
                barrier.Color = Color3.new(1, 1, 1)
                delay(0.1, function()
                    if barrier and barrier.Parent then
                        barrier.Color = originalColor
                    end
                end)
                
                touched = false
            end
        end
        
        barrier.Touched:Connect(onTouch)
        
        -- Monitor barrier health
        local connection
        connection = game:GetService("RunService").Heartbeat:Connect(function()
            if not barrier.Parent or health.Value <= 0 then
                if connection then
                    connection:Disconnect()
                end
                
                -- Break effect
                local breakEffect = Instance.new("ParticleEmitter")
                breakEffect.Texture = "rbxassetid://241539689"
                breakEffect.Color = ColorSequence.new(Color3.fromRGB(0, 170, 255))
                breakEffect.LightEmission = 0.5
                breakEffect.Size = NumberSequence.new(0.5, 1.5)
                breakEffect.Lifetime = NumberRange.new(0.5, 1)
                breakEffect.Rate = 50
                breakEffect.Speed = NumberRange.new(10)
                
                local breakAttachment = Instance.new("Attachment")
                breakAttachment.WorldPosition = barrier.Position
                breakAttachment.Parent = workspace.Effects or workspace
                breakEffect.Parent = breakAttachment
                
                breakEffect:Emit(20)
                game:GetService("Debris"):AddItem(breakAttachment, 1)
                
                if barrier and barrier.Parent then
                    barrier:Destroy()
                end
                return
            end
            
            -- Update transparency based on health
            local healthPercent = health.Value / self.barrierHealth
            barrier.Transparency = 0.7 + (0.3 * (1 - healthPercent))
        end)
        
        -- Add to workspace
        barrier.Parent = workspace
        
        -- Auto-destroy after duration
        delay(self.barrierDuration, function()
            if connection then
                connection:Disconnect()
            end
            if barrier and barrier.Parent then
                barrier:Destroy()
            end
        end)
        
        return true
    end
}

PowerSystem.EMP = {
    name = "EMP Blast",
    description = "Releases an EMP that disables enemy abilities and slows them",
    cooldown = 45,
    lastUsed = {},
    empRadius = 20,
    disableDuration = 5,
    slowAmount = 0.5, -- 50% slow
    damage = 30,
    
    execute = function(self, player: Player, character: Character): (boolean, string?)
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return false, "No HumanoidRootPart found" end
        
        -- Create EMP effect
        local emp = Instance.new("Part")
        emp.Name = "EMPBlast"
        emp.Shape = Enum.PartType.Ball
        emp.Size = Vector3.new(1, 1, 1)
        emp.Position = rootPart.Position
        emp.Anchored = true
        emp.CanCollide = false
        emp.Transparency = 0.5
        emp.Material = Enum.Material.Neon
        emp.Color = Color3.fromRGB(0, 200, 255)
        emp.Parent = workspace.Effects or workspace
        
        -- Animate EMP expansion
        local tweenInfo = TweenInfo.new(
            0.5, -- Time
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        )
        
        local goal = {
            Size = Vector3.new(self.empRadius * 2, self.empRadius * 2, self.empRadius * 2),
            Transparency = 1
        }
        
        local tween = TweenService:Create(emp, tweenInfo, goal)
        tween:Play()
        
        -- Create shockwave effect
        local shockwave = Instance.new("ParticleEmitter")
        shockwave.Texture = "rbxassetid://241539689"
        shockwave.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 170, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 200, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 230, 255))
        })
        shockwave.LightEmission = 0.8
        shockwave.LightInfluence = 1
        shockwave.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(0.5, self.empRadius * 0.5),
            NumberSequenceKeypoint.new(1, self.empRadius)
        })
        shockwave.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(0.7, 0.8),
            NumberSequenceKeypoint.new(1, 1)
        })
        shockwave.Lifetime = NumberRange.new(0.5)
        shockwave.Rate = 0
        shockwave.Speed = NumberRange.new(0)
        shockwave.Shape = Enum.ParticleEmitterShape.Sphere
        shockwave.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
        shockwave.SpreadAngle = Vector2.new(180, 180)
        
        local attachment = Instance.new("Attachment")
        attachment.Position = rootPart.Position
        attachment.Parent = workspace.Effects or workspace
        shockwave.Parent = attachment
        
        -- Emit shockwave
        shockwave:Emit(30)
        
        -- Find and affect enemies in radius
        local affected = {}
        
        for _, enemy in ipairs(game:GetService("Players"):GetPlayers()) do
            if enemy ~= player and enemy.Team ~= player.Team and enemy.Character then
                local enemyRoot = enemy.Character:FindFirstChild("HumanoidRootPart")
                local humanoid = enemy.Character:FindFirstChild("Humanoid")
                
                if enemyRoot and humanoid and humanoid.Health > 0 then
                    local distance = (enemyRoot.Position - rootPart.Position).Magnitude
                    
                    if distance <= self.empRadius then
                        -- Apply damage
                        humanoid:TakeDamage(self.damage * (1 - (distance / self.empRadius)))
                        
                        -- Apply slow
                        local originalSpeed = humanoid.WalkSpeed
                        humanoid.WalkSpeed = humanoid.WalkSpeed * self.slowAmount
                        
                        -- Disable abilities
                        local disabled = Instance.new("BoolValue")
                        disabled.Name = "EMPDisabled"
                        disabled.Parent = humanoid
                        
                        -- Visual effect
                        local effect = Instance.new("ParticleEmitter")
                        effect.Texture = "rbxassetid://241539689"
                        effect.Color = ColorSequence.new(Color3.fromRGB(0, 170, 255))
                        effect.LightEmission = 0.5
                        effect.Size = NumberSequence.new(0.5, 1)
                        effect.Lifetime = NumberRange.new(0.5, 1)
                        effect.Rate = 10
                        effect.Speed = NumberRange.new(1)
                        
                        local effectAttachment = Instance.new("Attachment")
                        effectAttachment.Parent = enemyRoot
                        effect.Parent = effectAttachment
                        
                        -- Store for cleanup
                        table.insert(affected, {
                            humanoid = humanoid,
                            originalSpeed = originalSpeed,
                            attachment = effectAttachment,
                            effect = effect
                        })
                    end
                end
            end
        end
        
        -- Clean up after duration
        delay(self.disableDuration, function()
            -- Restore enemy speeds and remove effects
            for _, data in ipairs(affected) do
                if data.humanoid and data.humanoid.Parent then
                    -- Remove disabled status
                    local disabled = data.humanoid:FindFirstChild("EMPDisabled")
                    if disabled then
                        disabled:Destroy()
                    end
                    
                    -- Restore speed
                    data.humanoid.WalkSpeed = data.originalSpeed
                end
                
                -- Clean up effects
                if data.attachment and data.attachment.Parent then
                    data.attachment:Destroy()
                end
            end
            
            -- Clean up EMP effect
            if emp and emp.Parent then
                emp:Destroy()
            end
            
            if attachment and attachment.Parent then
                attachment:Destroy()
            end
        end)
        
        -- Clean up shockwave
        game:GetService("Debris"):AddItem(attachment, 1)
        
        return true
    end
}

-- Power System Methods
function PowerSystem:init()
    -- Initialize any required services or connections
    if not workspace:FindFirstChild("Effects") then
        local effects = Instance.new("Folder")
        effects.Name = "Effects"
        effects.Parent = workspace
    end
end

function PowerSystem:getPower(powerName: string): Power?
    return self[powerName]
end

function PowerSystem:canUsePower(player: Player, powerName: string): (boolean, string?)
    local power = self:getPower(powerName)
    if not power then
        return false, "Power not found"
    end
    
    local userId = player.UserId
    local lastUsed = power.lastUsed[userId] or 0
    local cooldownRemaining = (lastUsed + power.cooldown) - tick()
    
    if cooldownRemaining > 0 then
        return false, string.format("Power on cooldown for %.1f seconds", cooldownRemaining)
    end
    
    -- Add any additional checks here (e.g., energy, requirements)
    return true
end

function PowerSystem:usePower(player: Player, powerName: string): (boolean, string?)
    local canUse, reason = self:canUsePower(player, powerName)
    if not canUse then
        return false, reason or "Cannot use power"
    end
    
    local character = player.Character
    if not character then
        return false, "No character found"
    end
    
    local power = self:getPower(powerName)
    if not power then
        return false, "Power not found"
    end
    
    -- Execute the power
    local success, result = pcall(function()
        return power:execute(player, character)
    end)
    
    if success and result then
        -- Update last used time
        power.lastUsed[player.UserId] = tick()
        return true
    else
        return false, result or "Failed to execute power"
    end
end

-- Initialize the power system
PowerSystem:init()

return PowerSystem
