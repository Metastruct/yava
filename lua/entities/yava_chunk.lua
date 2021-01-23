AddCSLuaFile()

ENT.Type   = "anim"

function ENT:SetupDataTables()
	self:NetworkVar("Vector",0,"ChunkPos")
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

function ENT:Initialize()
    
    self:SetRenderMode(RENDERMODE_NONE)
end

function ENT:SetupCollisions(soup)
    local old_physobj = self:GetPhysicsObject()
    if IsValid(old_physobj) then
        self:SetCollisionGroup(COLLISION_GROUP_WORLD)
        old_physobj:EnableCollisions(false)
        old_physobj:RecheckCollisionFilter()
    end

    self:PhysicsFromMesh(soup)
    self:GetPhysicsObject():EnableMotion(false)

    self:EnableCustomCollisions(true)
    
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)    --- <= MIGHT only need this.
    self:SetMoveType(MOVETYPE_NONE)

    self:SetCollisionGroup(COLLISION_GROUP_NONE)
end

--[[function ENT:TestCollision() 
    if SERVER then
        print("!!!",self:GetCollisionBounds())
    end
end]]

function ENT:Think()
    if yava._offset then
        local chunk_pos = self:GetChunkPos()
        local correct_mins = yava._offset + chunk_pos*yava._scale*32
        local correct_maxs = correct_mins + Vector(32,32,32)*yava._scale

        self:SetCollisionBounds(correct_mins, correct_maxs)
    end

    if CLIENT then
        if not self.setup then
            local chunk_pos = self:GetChunkPos()        
            local chunk = yava._chunks[yava._chunkKey(chunk_pos.x,chunk_pos.y,chunk_pos.z)]
            if chunk then
                chunk.collider_ent = self
                if chunk.fresh_collider_soup then
                    self:SetupCollisions(chunk.fresh_collider_soup)
                    chunk.fresh_collider_soup = nil
                end
                self.setup = true
            end
        end
        -- do this crap way less often on the client
        self:SetNextClientThink(CurTime()+1)
    end
end

function ENT:Draw()
    -- should never be called
end

-- Very buggy, all blocks are destroyable also
function ENT:OnTakeDamage( dmg )
	if not yava.disableDamage then return end
	local att = dmg:GetAttacker()
	local infl = dmg:GetInflictor()
	if not att:IsPlayer() then
		return
	end
	if not infl:IsWeapon() and not infl:IsPlayer() then
		--return -- weird bugs on some weapons
	end
	
	-- maybe recoverable somehow?
	local dpos = dmg:GetDamagePosition()
	if dpos:LengthSqr()<10 then return end
	
	local dforce = dmg:GetDamageForce()
	
	if dmg:IsExplosionDamage() then
		local x,y,z = yava.worldPosToBlockCoords(dpos)
		yava.setSphere(x,y,z,4,"void")
	else
		if dforce:LengthSqr()<10 then return end
		dforce:Normalize()
		minecraft(dpos+dforce*5,false)
	end
end
