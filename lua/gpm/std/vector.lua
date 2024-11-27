--[[

    TODO: Make vector class
    TODO: https://wiki.facepunch.com/gmod/gui.ScreenToVector ( Vector.FromScreen(X,Y) )

    https://wiki.facepunch.com/gmod/util.AimVector

    https://wiki.facepunch.com/gmod/Global.Vector
    https://wiki.facepunch.com/gmod/Global.LerpVector

    https://wiki.facepunch.com/gmod/Global.LocalToWorld
    https://wiki.facepunch.com/gmod/Global.WorldToLocal

    https://wiki.facepunch.com/gmod/Global.OrderVectors

    https://wiki.facepunch.com/gmod/util.IsInWorld

    https://wiki.facepunch.com/gmod/util.IntersectRayWithOBB

    https://wiki.facepunch.com/gmod/util.IntersectRayWithPlane

    https://wiki.facepunch.com/gmod/util.IntersectRayWithSphere

    https://wiki.facepunch.com/gmod/util.IsBoxIntersectingSphere

    https://wiki.facepunch.com/gmod/util.IsOBBIntersectingOBB

    https://wiki.facepunch.com/gmod/util.IsPointInCone

    https://wiki.facepunch.com/gmod/util.IsRayIntersectingRay

    https://wiki.facepunch.com/gmod/util.IsSkyboxVisibleFromPoint

    https://wiki.facepunch.com/gmod/util.IsSphereIntersectingCone

    https://wiki.facepunch.com/gmod/util.IsSphereIntersectingSphere

]]

local _G = _G

---@class gpm.std.vector
local vector = {
    localToWorld = _G.LocalToWorld,
    worldToLocal = _G.WorldToLocal
}

return vector
