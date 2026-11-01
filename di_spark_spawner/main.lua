-- Original, testing mod. No Alice data, progression or archive overrides.
local visible=true
local count=1
local sequence=0
local message='Native adapter loads at game startup. F10 toggles this panel.'
local names={'Blue sparks','Orange XP','Green health','Purple super meter'}
local function spawn(kind)
    if Crabe.Plugins.get('di.pickups.ready')~='yes' then
        message='Native adapter unavailable. Restart after installing the mod; check loader.log.'
        return
    end
    if Crabe.Plugins.get('di.pickups.request') then message='A request is already pending';return end
    local ok,err=pcall(function()
        local handle=Game.GetAvatarHandle()
        assert(type(handle)=='number' and handle~=0 and handle~=-1,'Load a playable character first')
        local x,y,z=Game.ActorPosition(handle)
        assert(type(x)=='number' and type(y)=='number' and type(z)=='number','Player position unavailable')
        -- World-space offset to the side and above the player, not a guessed forward vector.
        sequence=sequence+1
        Crabe.Plugins.set('di.pickups.request',string.format('%u %d %d %.6f %.6f %.6f',sequence,kind,count,x+1.5,y+0.75,z))
        -- Existing harmless getter delivers the request on this same script thread.
        Game.GetSparks()
        message=Crabe.Plugins.get('di.pickups.status') or 'Request submitted'
    end)
    if not ok then
        Crabe.Plugins.set('di.pickups.request',nil)
        message='Spawn failed: '..tostring(err)
    end
end
Crabe.Mod.register({
    name='DI Pickup Spawner',
    onInit=function()
        -- Survives Lua F4 reload without reusing the last sequence number.
        sequence=tonumber(Crabe.Plugins.get('di.pickups.sequence')) or 0
        Crabe.Events.on('keyDown',function(vk,repeated)
            if vk==0x79 and not repeated then visible=not visible end
        end)
    end,
    onDraw=function()
        if not visible then return end
        local ui=Crabe.ImGui
        local open=ui.Begin('DI Pickup Spawner')
        if open~=false then
            ui.Text('F10: show/hide. Use Insert to interact with the overlay.')
            ui.Text('Creates physical pickups beside the current player.')
            ui.Text('Count per click: '..count..' (maximum 20)')
            if ui.Button('-##pickup-count') then count=math.max(1,count-1) end
            ui.SameLine()
            if ui.Button('+##pickup-count') then count=math.min(20,count+1) end
            for kind,label in ipairs(names) do
                if ui.Button('Spawn '..label) then
                    spawn(kind)
                    Crabe.Plugins.set('di.pickups.sequence',tostring(sequence))
                end
            end
            ui.Text(message)
            ui.Text('Collecting currency or XP may change your saved progress.')
        end
        ui.End()
    end,
    onShutdown=function() Crabe.Plugins.set('di.pickups.request',nil) end,
})
