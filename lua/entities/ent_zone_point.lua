AddCSLuaFile()
DEFINE_BASECLASS("base_anim")
ENT.PrintName = "Zone Point"
ENT.Author = "Bobblehead"
ENT.Information = "A point in the zone designator."
ENT.Category = "Other"
ENT.Editable = false
ENT.Spawnable = false
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

local vectorUP = Vector(0, 0, 0)

function ENT:Initialize()
    self:SetModel("models/hunter/blocks/cube025x025x025.mdl")
    self:SetCollisionGroup(COLLISION_GROUP_WORLD)
    self:DrawShadow(false)

    if SERVER then
        self:SetUseType(SIMPLE_USE)
        self:PhysicsInit(SOLID_BBOX)

		local phys = self:GetPhysicsObject()
        phys:EnableMotion(false)
        phys:SetMass(1)
    else
		vectorUP.z = self:GetTall()
        self:SetRenderBoundsWS(self:GetPos(), self:GetPos() + vectorUP)
    end
end

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "Next")
    self:NetworkVar("Float", 0, "Tall")
    self:NetworkVar("Int", 0, "ZoneID")
    self:NetworkVar("String", 0, "ZoneClass")
    self:NetworkVar("Int", 1, "AreaNumber")
end

local mat_cable = Material("cable/cable2")
local color1 = Color(255, 255, 255, 80)
local color2 = Color(255, 255, 255, 80)

function ENT:DrawTranslucent()
    local wep = LocalPlayer():GetActiveWeapon()

    if wep:IsValid() and wep:GetClass() == "weapon_zone_designator" and (wep:GetZoneClass() == self:GetZoneClass() or GetConVarNumber("zone_filter") == 0) then
        self:DrawModel()
        local p = self:GetPos()
        p.z = p.z + self:GetTall()

        render.Model({
            model = self:GetModel(),
            pos = p,
            ang = angle_zero
        })

		local pos = self:GetPos()

        render.SetMaterial(mat_cable)
        render.DrawBeam(pos, p, 1, 1, 0, color_white)
        local next = self:GetNext()

        if next and next:IsValid() then
            local class = self:GetZoneClass()
			local nextPos = next:GetPos()
            render.DrawBeam(pos, nextPos, 1, 1, 0, color_white)
            local n = next:GetPos()
            n.z = n.z + next:GetTall()
            render.DrawBeam(p, n, 1, 1, 0, color_white)
            render.SetColorMaterial()
            local col1 = zones.Classes[class]

			-- color1.a = 80
			color1.r = col1.r
			color1.g = col1.g
			color1.b = col1.b

            -- local col2 = { a = 80 }
            color2.r = color1.r * .5
            color2.g = color1.g * .5
            color2.b = color1.b * .5

            render.DrawQuad(p, pos, nextPos, n, color1)
            render.DrawQuad(n, nextPos, pos, p, color2)

            local id = self:GetZoneID()
            local classtxt = id ~= -1 and class .. " (# " .. id .. ")" or class
            local ang = (p - pos):Cross(n - pos):Angle()

            ang:RotateAroundAxis(ang:Right(), 90)
            ang:RotateAroundAxis(ang:Up(), -90)

            cam.Start3D2D((n + pos) / 2, ang, .2)
                draw.SimpleText(classtxt, "DermaLarge", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            cam.End3D2D()

            ang:RotateAroundAxis(vector_up, 180)

            cam.Start3D2D((n + pos) / 2, ang, .2)
                draw.SimpleText(classtxt, "DermaLarge", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            cam.End3D2D()
        end
    end
end

local vectorUP2 = CLIENT and Vector(0, 0, 0)
local color_red = CLIENT and Color(255, 0, 0)
local color_green = CLIENT and Color(0, 0, 255)

function ENT:Think()
    if CLIENT then
        local next = self:GetNext()

        if next and next:IsValid() and next ~= self.resizedto then
			vectorUP2.z = next:GetTall()
            self:SetRenderBoundsWS(self:GetPos(), next:GetPos() + vectorUP2)
            self.resizedto = next
        end

        local wep = LocalPlayer():GetActiveWeapon()

        if wep:IsValid() and wep:GetClass() == "weapon_zone_designator" then
            if LocalPlayer():GetEyeTrace().Entity == self then
                self:SetColor(color_red)
            elseif wep:GetCurrentPoint() == self then
                self:SetColor(color_green)
            else
                self:SetColor(color_white)
            end
        end
    else
        if IsValid(self.Resizing) then
            self:SetTall((self.Resizing:GetEyeTrace().HitPos - self:GetPos()).z)
        end
    end
end

function ENT:OnRemove()
    if SERVER and IsValid(self:GetNext()) then
        self:GetNext():Remove()
    end
end