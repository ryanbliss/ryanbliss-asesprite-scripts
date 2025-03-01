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
        local count = 0
        if sub_common_names[sublayer.name] == nil then
            count = 0
        else
            count = sub_common_names[sublayer.name]
        end
        sub_common_names[sublayer.name] = count + 1
        data[depth] = sub_common_names

        if depth > 0 then
            sublayer.isVisible = false
         end

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
    for key, count in pairs(subnames) do
        dlg:check{
            id = "checkbox-" .. key,
            label = key,
            selected = false,
        }
    end
end

dlg:button{id = "ok", text = "Toggle"}
dlg:button{id = "cancel", text = "Cancel"}
dlg:show()

if not dlg.data.ok then return 0 end

local function ToggleVisibilityForName(layer, layerName)
    for _, sublayer in ipairs(layer.layers) do
        if sublayer.name == nil then
            -- do nothing
        elseif sublayer.name == layerName then
            sublayer.isVisible = true
        end
    
        if sublayer.isGroup then
            ToggleVisibilityForName(sublayer, layerName)
        end
    end
end

for key, value in pairs(dlg.data) do
    if string.find(key, "checkbox") and value == true then
        local layerName = string.sub(key, 10)
        ToggleVisibilityForName(app.activeSprite, layerName)
    end
end

return 0
