--[[

Description:
A script to save all different layers in different files.

Originally made by Gaspi. Modified by ryanbliss.
   - Itch.io: https://gaspi.itch.io/
   - Twitter: @_Gaspi
Further Contributors:
    - Levy E ("StoneLabs")
    - David Höchtl ("DavidHoechtl")
    - Demonkiller8973
--]] -- Identify operative system.


-- Auxiliary functions

-- Path handling.

-- Return the path to the dir containing a file.
-- Source: https://stackoverflow.com/questions/9102126/lua-return-directory-path-from-path
function Dirname(str)
    return str:match("(.*" .. Sep .. ")")
 end
 
 -- Return the name of a file given its full path..
 -- Source: https://codereview.stackexchange.com/questions/90177/get-file-name-with-extension-and-get-only-extension
 function Basename(str)
    return str:match("^.*" .. Sep .. "(.+)$") or str
 end
 
 -- Return the name of a file excluding the extension, this being, everything after the dot.
 -- Source: https://stackoverflow.com/questions/18884396/extracting-filename-only-with-pattern-matching
 function RemoveExtension(str)
    return str:match("(.+)%..+")
 end
 
 -- Sprite handling.
 
 -- Hides all layers and sub-layers inside a group, returning a list with all
 -- initial states of each layer's visibility.
 function HideLayers(sprite)
    local data = {} -- Save visibility status of each layer here.
    for i,layer in ipairs(sprite.layers) do
       if layer.isGroup then
          -- Recursive for groups.
          data[i] = HideLayers(layer)
       else
          data[i] = layer.isVisible
          layer.isVisible = false
       end
    end
    return data
 end
 
 -- Restore layers visibility.
 function RestoreLayersVisibility(sprite, data)
    for i,layer in ipairs(sprite.layers) do
       if layer.isGroup then
          -- Recursive for groups.
          RestoreLayersVisibility(layer, data[i])
       else
          layer.isVisible = data[i]
       end
    end
 end
 
 -- Dialog
 function MsgDialog(title, msg)
    local dlg = Dialog(title)
    dlg:label{
       id = "msg",
       text = msg
    }
    dlg:newrow()
    dlg:button{id = "close", text = "Close", onclick = function() dlg:close() end }
    return dlg
 end
 
 -- Other
 
 function CopyTable(original)
    local copy = {}
    for i, value in ipairs(original) do
        copy[i] = value
    end
    return copy
 end
 
 -- Current sprite.
 Sprite = app.activeSprite
 if Sprite == nil then
    -- Show error, no sprite active.
    local dlg = MsgDialog("Error", "No sprite is currently active. Please, open a sprite first and run again.")
    dlg:show()
    return 1
 end
 
 -- Identify operative system.
 Sep = string.sub(Sprite.filename, 1, 1) == "/" and "/" or "\\"
 
 if Dirname(Sprite.filename) == nil then
    -- Error, can't identify OS when the sprite isn't saved somewhere.
    local dlg = MsgDialog("Error", "Current sprite is not associated to a file. Please, save your sprite and run again.")
    dlg:show()
    return 1
 end

-- Variable to keep track of the number of layers exported.
local n_layers = 0

-- Function to calculate the bounding box of the non-transparent pixels in a layer
local function calculateBoundingBox(layer)
    local minX, minY, maxX, maxY = nil, nil, nil, nil
    for _, cel in ipairs(layer.cels) do
        local image = cel.image
        local position = cel.position

        for y = 0, image.height - 1 do
            for x = 0, image.width - 1 do
                if image:getPixel(x, y) ~= 0 then -- Non-transparent pixel
                    local pixelX = position.x + x
                    local pixelY = position.y + y
                    if not minX or pixelX < minX then
                        minX = pixelX
                    end
                    if not minY or pixelY < minY then
                        minY = pixelY
                    end
                    if not maxX or pixelX > maxX then
                        maxX = pixelX
                    end
                    if not maxY or pixelY > maxY then
                        maxY = pixelY
                    end
                end
            end
        end
    end
    return Rectangle(minX, minY, maxX - minX + 1, maxY - minY + 1)
end

-- Exports every layer individually.
local function exportLayers(sprite, root_layer, filename, group_sep, data)
    for _, layer in ipairs(root_layer.layers) do
        local filename = filename
        if layer.isGroup then
            -- Recursive for groups.
            local previousVisibility = layer.isVisible
            layer.isVisible = true
            filename = filename:gsub("{layergroups}", layer.name .. group_sep .. "{layergroups}")
            exportLayers(sprite, layer, filename, group_sep, data)
            layer.isVisible = previousVisibility
        else
            -- Individual layer. Export it.
            layer.isVisible = true
            filename = filename:gsub("{layergroups}", "")
            filename = filename:gsub("{layername}", layer.name)
            os.execute("mkdir \"" .. Dirname(filename) .. "\"")
            if data.spritesheet then
                local sheettype = SpriteSheetType.HORIZONTAL
                if (data.tagsplit == "To Rows") then
                    sheettype = SpriteSheetType.ROWS
                elseif (data.tagsplit == "To Columns") then
                    sheettype = SpriteSheetType.COLUMNS
                end
                app.command.ExportSpriteSheet {
                    ui = false,
                    askOverwrite = false,
                    type = sheettype,
                    columns = 0,
                    rows = 0,
                    width = 0,
                    height = 0,
                    bestFit = false,
                    textureFilename = filename,
                    dataFilename = "",
                    dataFormat = SpriteSheetDataFormat.JSON_HASH,
                    borderPadding = 0,
                    shapePadding = 0,
                    innerPadding = 0,
                    trimSprite = data.trimSprite,
                    trim = data.trimCells,
                    trimByGrid = data.trimByGrid,
                    mergeDuplicates = data.mergeDuplicates,
                    extrude = false,
                    openGenerated = false,
                    layer = "",
                    tag = "",
                    splitLayers = false,
                    splitTags = (data.tagsplit ~= "No"),
                    listLayers = layer,
                    listTags = true,
                    listSlices = true
                }
            elseif data.trim then -- Trim the layer
                local boundingRect = calculateBoundingBox(layer)
                -- make a selection on the active layer
                app.activeLayer = layer;
                sprite.selection = Selection(boundingRect);

                -- create a new sprite from that selection
                app.command.NewSpriteFromSelection()

                -- save it as png
                app.command.SaveFile {
                    ui = false,
                    filename = filename
                }
                app.command.CloseFile()

                app.activeSprite = layer.sprite -- Set the active sprite to the current layer's sprite
                sprite.selection = Selection();
            else
                sprite:saveCopyAs(filename)
            end
            layer.isVisible = false
            n_layers = n_layers + 1
        end
    end
end

-- Open main dialog.
local dlg = Dialog("Export layers")
dlg:file{
    id = "directory",
    label = "Output directory:",
    filename = app.activeSprite.filename,
    open = false
}
dlg:entry{
    id = "filename",
    label = "File name format:",
    text = "{layergroups}{layername}"
}
dlg:combobox{
    id = 'format',
    label = 'Export Format:',
    option = 'png',
    options = {'png', 'gif', 'jpg'}
}
dlg:combobox{
    id = 'group_sep',
    label = 'Group separator:',
    option = "_",
    options = {Sep, '-', '_'}
}
dlg:slider{
    id = 'scale',
    label = 'Export Scale:',
    min = 1,
    max = 10,
    value = 1
}
local startExportSelected = true
dlg:check{
    id = "spritesheet",
    label = "Export as spritesheet:",
    selected = startExportSelected,
    onclick = function()
        -- Hide these options when spritesheet is checked.
        dlg:modify{
            id = "trim",
            visible = not dlg.data.spritesheet
        }
        -- Show these options when spritesheet is checked.
        dlg:modify{
            id = "trimSprite",
            visible = dlg.data.spritesheet
        }
        dlg:modify{
            id = "trimCells",
            visible = dlg.data.spritesheet
        }
        dlg:modify{
            id = "mergeDuplicates",
            visible = dlg.data.spritesheet
        }
        dlg:modify{
            id = "tagsplit",
            visible = dlg.data.spritesheet
        }
    end
}
dlg:check{
    id = "trim",
    label = "Trim:",
    selected = false,
    visible = not startExportSelected
}
dlg:check{
    id = "trimSprite",
    label = "  Trim Sprite:",
    selected = false,
    visible = startExportSelected,
    onclick = function()
        dlg:modify{
            id = "trimByGrid",
            visible = dlg.data.trimSprite or dlg.data.trimCells
        }
    end
}
dlg:check{
    id = "trimCells",
    label = "  Trim Cells:",
    selected = false,
    visible = startExportSelected,
    onclick = function()
        dlg:modify{
            id = "trimByGrid",
            visible = dlg.data.trimSprite or dlg.data.trimCells
        }
    end
}
dlg:check{
    id = "trimByGrid",
    label = "  Trim Grid:",
    selected = false,
    visible = false
}
dlg:combobox{ -- Spritesheet export only option
    id = "tagsplit",
    label = "  Split Tags:",
    visible = startExportSelected,
    option = 'No',
    options = {'No', 'To Rows', 'To Columns'}
}
dlg:check{ -- Spritesheet export only option
    id = "mergeDuplicates",
    label = "  Merge duplicates:",
    selected = false,
    visible = startExportSelected
}
dlg:check{
    id = "save",
    label = "Save sprite:",
    selected = false
}
dlg:button{
    id = "ok",
    text = "Export"
}
dlg:button{
    id = "cancel",
    text = "Cancel"
}
dlg:show()

if not dlg.data.ok then
    return 0
end

-- Get path and filename
local output_path = Dirname(dlg.data.directory)
local filename = dlg.data.filename .. "." .. dlg.data.format

if output_path == nil then
    local dlg = MsgDialog("Error", "No output directory was specified.")
    dlg:show()
    return 1
end

local group_sep = dlg.data.group_sep
filename = filename:gsub("{spritename}", RemoveExtension(Basename(app.activeSprite.filename)))
filename = filename:gsub("{groupseparator}", group_sep)

-- Finally, perform everything.
app.activeSprite:resize(app.activeSprite.width * dlg.data.scale, app.activeSprite.height * dlg.data.scale)
local layers_visibility_data = HideLayers(app.activeSprite)
exportLayers(app.activeSprite, app.activeSprite, output_path .. filename, group_sep, dlg.data)
RestoreLayersVisibility(app.activeSprite, layers_visibility_data)
app.activeSprite:resize(app.activeSprite.width / dlg.data.scale, app.activeSprite.height / dlg.data.scale)

-- Save the original file if specified
if dlg.data.save then
    app.activeSprite:saveAs(dlg.data.directory)
end

-- Success dialog.
local dlg = MsgDialog("Success!", "Exported " .. n_layers .. " layers.")
dlg:show()

return 0
