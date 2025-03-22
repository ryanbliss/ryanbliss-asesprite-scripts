-- Ensure we can use UI stuff
if not app.isUIAvailable then
    return
end

-- Ensure a sprite is loaded
if app.activeSprite == nil then
    app.alert("You must open a sprite first to use this script!")
    return
end

-- Ensure the current layer is a valid one
if not app.activeLayer.isImage or not app.activeLayer.isEditable then
    app.alert("You must have an editable image layer selected!")
    return
end

-- Determines if a pixel has any data in it
local function pixelHasData(pixel)
    if pixel >= 0 then
        return true
    end
    local rgbaAlpha = app.pixelColor.rgbaA(pixel)
    local grayAlpha = app.pixelColor.grayaA(pixel)

    return rgbaAlpha ~= 0 or grayAlpha ~= 0
end

-- Polyfil for active frame
local function activeFrameNumber()
    local f = app.activeFrame
    if f == nil then
        return 1
    else
        return f
    end
end

-- Returns the cel in the given layer and frame
local function getActiveCel(layer, frame)
    -- Loop through cels
    for i, cel in ipairs(layer.cels) do

        -- Find the cell in the given frame
        if cel.frame == frame then
            return cel
        end
    end
end

-- Prepare the dialog
local dlg = Dialog()

-- Buttons
dlg:button{
    id = "currentLayer",
    text = "Apply"
}
dlg:button{
    id = "cancel",
    text = "Cancel"
}

-- Show the dialog
dlg:show()

-- Get dialog data
local data = dlg.data

-- Stop on cancel
if data.cancel then
    return
end

-- Stop on X
if not data.currentLayer and not data.newLayer then
    return
end



-- Number of colors per category in the palette (e.g., dark - light in blue)
local numColorsPerCategory = 6
-- The top index of a color category range
local endOfColorCategoryIndex = numColorsPerCategory - 1
-- The start index of the color category range to use for our normalized value
local numCategories = 8
-- Color category index for the normalized color category
local normalizeRowStartIndex = 7
local normalizeStartColorIndex = normalizeRowStartIndex * numColorsPerCategory

local text = ""

local function getRgbaColorPaletteIndex(color)
    local index = 0
    while index < numCategories * numColorsPerCategory do
        local c = Color {
            index = index
        }
        if c.rgbaPixel == color then
            return index
        else
            -- text = text .. c.rgbaPixel .. "\n"
        end
        index = index + 1
    end
    return -1
end


-- Overwrite the pixels on the clone
local hasWrittenData = false

local function NormalizeLayer(layer)
    for i, sublayer in ipairs(layer.layers) do
        sublayer.isVisible = true

        if sublayer.isGroup then
            NormalizeLayer(sublayer)
        else
            
            -- Get image
            for celIndex, cel in ipairs(sublayer.cels) do
                -- Get original image coordinates
                local imageCoords = {
                    x = cel.bounds.x,
                    y = cel.bounds.y
                }
                text = text .. "i" .. celIndex

                -- Get the original image and clone it
                local image = cel.image
                local copy = image:clone()
                for it in copy:pixels() do
                    local pixel = it()
                
                    -- Only overwrite a pixel if it has data in it
                    if pixelHasData(pixel) then
                        -- app.alert("Current color: " .. currentColor.r .. ", " .. currentColor.g .. ", " .. currentColor.b)
                        local paletteIndex = getRgbaColorPaletteIndex(pixel)
                        if paletteIndex >= 0 then
                            hasWrittenData = true
                            local relIndex = paletteIndex % numColorsPerCategory
                            local pixelColor = Color {
                                index = normalizeStartColorIndex + relIndex
                            }
                            copy:putPixel(it.x, it.y, pixelColor.rgbaPixel)
                            cel.image:putImage(copy)
                        else
                            text = text .. pixel .. ", "
                        end
                    end
                end
            end
        end
    end
end

app.command.ChangePixelFormat {
    format = "rgb"
}

-- Replace the original with a copy in a transaction
app.transaction(function()
    NormalizeLayer(app.activeSprite)
    -- If no pixels were written, alert the user
    if not hasWrittenData then
        app.alert("No pixels were written to the image" .. text)
        return
    end
end)
