-- Ensure we can use UI stuff
if not app.isUIAvailable then
    return
end

-- Ensure a sprite is loaded
if app.activeSprite == nil then
    app.alert("You must open a sprite first to use this script!")
    return
end

local function GetSubgroupNames(data, layer, depth)
    local sub_common_names = {}
    if data[depth] == nil then
        data[depth] = sub_common_names
    else
        sub_common_names = data[depth]
    end
    for i, sublayer in ipairs(layer.layers) do
        local defaultChecked = string.find(sublayer.data, "defaultChecked=true") ~= nil;
        sub_common_names[sublayer.name] = defaultChecked;
        data[depth] = sub_common_names

        if sublayer.isGroup then
            GetSubgroupNames(data, sublayer, depth + 1)
        end
    end
end


-- Open main dialog.
local dlg = Dialog("Toggle Layer Visibility")
local data = {}
GetSubgroupNames(data, app.activeSprite, 0)
for blah, subnames in ipairs(data) do
    for key, defaultChecked in pairs(subnames) do
        dlg:check{
            id = "checkbox-" .. key,
            label = key,
            selected = defaultChecked,
        }
    end
end

dlg:button{id = "ok", text = "Toggle"}
dlg:button{id = "cancel", text = "Cancel"}
dlg:show()

if not dlg.data.ok then return 0 end

local function ToggleVisibilityForName(layer, layerName, enabled, depth)
    for i, sublayer in ipairs(layer.layers) do
        if sublayer.name ~= nil and sublayer.name == layerName then
            sublayer.isVisible = enabled
        end
    
        if sublayer.isGroup then
            ToggleVisibilityForName(sublayer, layerName, enabled, depth + 1)
        end
    end
end

for key, value in pairs(dlg.data) do
    if string.find(key, "checkbox") then
        local layerName = string.sub(key, 10)
        ToggleVisibilityForName(app.activeSprite, layerName, value, 0)
    end
end

return 0
