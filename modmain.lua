local RPC = GLOBAL.RPC
local SendRPCToServer = GLOBAL.SendRPCToServer
local FRAMES = GLOBAL.FRAMES

local last_recipe, last_skin = nil
local rope_recipe = GLOBAL.GetValidRecipe("rope")
local torch_recipe = GLOBAL.GetValidRecipe("torch")

local function InGame()
	return GLOBAL.ThePlayer and GLOBAL.ThePlayer.HUD and not GLOBAL.ThePlayer.HUD:HasInputFocus()
end

local function ActionCanceler()
	local builder = GLOBAL.ThePlayer.replica.builder 
	
	if last_recipe and builder:CanBuild(last_recipe.name) then
		builder:MakeRecipeFromMenu(last_recipe, last_skin)
	elseif builder:CanBuild("torch") then
		builder:MakeRecipeFromMenu(torch_recipe, nil)
	elseif builder:CanBuild("rope") then 
		builder:MakeRecipeFromMenu(rope_recipe, nil)
	else
		return 
	end

	GLOBAL.ThePlayer:DoTaskInTime(FRAMES*5, function(inst) SendRPCToServer(RPC.DirectWalking, 0.1, 0.1) end)
	GLOBAL.ThePlayer:DoTaskInTime(FRAMES*7, function(inst) SendRPCToServer(RPC.StopWalking) end)

	return
end

local lastFrame = nil

local function CheckMount()
	local ThePlayer = GLOBAL.ThePlayer

	if ThePlayer.AnimState:IsCurrentAnimation("buck") then 
		ActionCanceler()
	-- elseif ThePlayer.AnimState:IsCurrentAnimation("bucked") then 
	-- 	ActionCanceler()
	-- elseif ThePlayer.AnimState:IsCurrentAnimation("buck_pst") then
	-- 	ActionCanceler()
	elseif ThePlayer.AnimState:IsCurrentAnimation("dismount") then
		ActionCanceler()
	elseif ThePlayer.AnimState:IsCurrentAnimation("mount") then
		ActionCanceler()
	end
	
end

AddPlayerPostInit(function(inst)
	inst:DoPeriodicTask(0.1, CheckMount)
end)

local swap = true

AddPlayerPostInit(function(inst)
    inst:ListenForEvent("isridingdirty", function(inst)
        if inst.replica.rider:IsRiding() then
            inst.task = inst:DoPeriodicTask(GLOBAL.FRAMES*15, function(inst)
           
				if inst.replica.rider:IsMountHurt() then
					if swap then GLOBAL.ThePlayer.components.talker:Say("♥버팔로 개딸피♥") 
					else GLOBAL.ThePlayer.components.talker:Say("♡버팔로 개딸피♡") end

					swap = not swap
				end
            end)
        else
            inst.task:Cancel()
        end

    end)
end)

AddClassPostConstruct("components/builder_replica", function(self)
    local BuilderReplicaMakeRecipeFromMenu = self.MakeRecipeFromMenu
    self.MakeRecipeFromMenu = function(self, recipe, skin)
        last_recipe, last_skin = recipe, skin
        BuilderReplicaMakeRecipeFromMenu(self, recipe, skin)
    end
end)



