--[[
    Attached Camera v1.0.0
    Variant: Third-Person Camera
    
    Description:

    'Attached Cameras' is a tool that lets you attach a player camera to any object. The camera will follow the object until it is detached.

    All the code is commented and MIT licensed, so feel free to make copies and modify.



    Changelog:
    None

    License (MIT):

    Copyright 2021 GBee

    Permission is hereby granted, free of charge, to any person obtaining a copy of
    this software and associated documentation files (the "Software"), to deal in 
    the Software without restriction, including without limitation the rights to
    use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
    of the Software, and to permit persons to whom the Software is furnished to do 
    so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all 
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
    THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
    THE SOFTWARE.
--]]

--[[
    All the options are included in this script to make it easier to
    update in the future.
    0 = Third-Person
    1 = First-Person
    2 = Top-Down
--]]
CAMERA_MODE = 0

--[[ ===== TABLETOP SIMULATOR EVENTS ===== --]]

--[[
    Occurs when the bag is loaded.
--]]
function onLoad(save_state)
    -- Load previous object state.
    if save_state == nil or save_state == "" then
        script_state = {
            camera_height = 0.0
        }
    else
        script_state = JSON.decode(save_state)
    end

    -- Create the user interface.
    createUserInterface()
end

--[[
    Occurs when the bag is saved.
--]]
function onSave()
    saved_data = JSON.encode(script_state)
    return saved_data
end

--[[ ===== USER INTERFACE ====== --]]

--[[
    Creates one input field and one button on the tile.
    See core functions below for the description of each feature.
--]]
function createUserInterface()
    self.createInput({
        label          = "Height",
        function_owner = self,
        input_function = "onAdjustHeight",
        tooltip        = "Height of camera when attached to object.",
        value          = script_state.camera_height,
        position       = {0,0.5,-0.5}, 
        rotation       = {0,0,0}, 
        height         = 350, 
        width          = 850,
        font_size      = 250,
        alignment      = 3, -- Center
        validation     = 3  -- Float
    })

    self.createButton({
        label          = "Attach", 
        click_function = "onAttachCamera", 
        function_owner = self,
        tooltip        = "Attach",
        position       = {0,0.5,0.5}, 
        rotation       = {0,0,0}, 
        height         = 350, 
        width          = 850,
        font_size      = 250, 
        color          = {1,1,1}, 
        font_color     = {0,0,0}
    })
end

function createLocalObjectUI(obj)
    obj.createInput({
        label          = "Height",
        function_owner = self,
        input_function = "onAdjustHeightLocal",
        tooltip        = "Height of camera when attached to object.",
        value          = script_state.camera_height,
        position       = {0, 0.1, -1}, 
        rotation       = {0, 180, 0}, 
        height         = 110, 
        width          = 150,
        font_size      = 80,
        alignment      = 3, -- Center
        validation     = 3  -- Float
    })

    obj.createButton({
        label          = "X", 
        click_function = "onDetachCamera", 
        function_owner = self,
        tooltip        = "Detach",
        position       = {-0.25, 0.1, -1}, 
        rotation       = {0, 180, 0}, 
        height         = 100, 
        width          = 100,
        font_size      = 100, 
        color          = {1, 1, 1}, 
        font_color     = {0, 0, 0}
    })
end


--[[ ===== CORE FUNCTIONS ===== --]]
--[[
  Gets called whenever the height input field is changed.
  This function saves the new height to the script state.  
--]]
function onAdjustHeight(obj, color, input, stillEditing)
    if not stillEditing then
        script_state.camera_height = tonumber(input)
    end
end

--[[
    Attaches the camera to the selected object.
--]]
function onAttachCamera(obj, color, alt_click)
    local selected_objects = Player[color].getSelectedObjects()

    if tableIsEmpty(selected_objects) then
        broadcastToColor("[Attached Cameras] No object selected!", "White", {0, 1.0, 0.0})
        return
    end

    -- Get the first selected object.
    local selected_obj = first(selected_objects)

    -- Attach the camera.
    if CAMERA_MODE == 0 then
        attachThirdPerson(Player[color], selected_obj, script_state.camera_height)
    elseif CAMERA_MODE == 1 then
        attachFirstPerson(Player[color], selected_obj, script_state.camera_height)
    elseif CAMERA_MODE == 2 then
        attachTopDown(Player[color], selected_obj, script_state.camera_height)
    end
    
    -- Create the objects UI.
    createLocalObjectUI(selected_obj)
end
 
--[[
    Occurs when the user changes the input field on the attached object.
    This allows changing the camera height while the camera is attached.
--]]
function onAdjustHeightLocal(obj, color, input, stillEditing)
    if not stillEditing then
        local camera_height = tonumber(input)

        if CAMERA_MODE == 0 then
            attachThirdPerson(Player[color], obj, camera_height)
        elseif CAMERA_MODE == 1 then
            attachFirstPerson(Player[color], obj, camera_height)
        elseif CAMERA_MODE == 2 then
            attachTopDown(Player[color], obj, camera_height)
        end
    end
end

--[[
    Detaches the camera from the object.
--]]
function onDetachCamera(obj, color, alt_click)
    --[[ 
        TTS camera can be a bit crazy when changing the camera around.
        To make detaching more stable, the camera gets attached in third-person
        to the base of the object first, and then it is detached.
    --]]
    attachThirdPerson(Player[color], obj, 0)

    --[[
        Unforunately, the only way to remove the camera attachment to an object
        is to destroy the object. So here we just clone the object and destroy the old one. This will also destroy any UI on the object.
    --]]
    obj.clone({
        position = obj.getPosition()
    })
    obj.destruct()
end


--[[ ===== WHERE THE MAGIC HAPPENS ===== --]]

--[[
    Attaches the camera in Third-Person mode.
--]]
function attachThirdPerson(player, obj, height)
    -- Attach the camera to the object. This will force the camera mode into "FirstPerson" mode.
    player.attachCameraToObject({
        object = obj,
        offset = {0, height, 0}
    })
    
    -- Force the camera mode back into "ThirdPerson" and look at the object from a nice angle.
    player.lookAt({
        position = obj.getPosition(),
        pitch = 45,
        distance = 40,
        yaw = 0,
    })
    
    -- This is added just in case the API changes in the future and lookAt no longer forces third-person.
    player.setCameraMode("ThirdPerson")
end

--[[
    Attaches the camera in First-Person mode.
--]]
function attachFirstPerson(player, obj, height)
    -- Attach the camera to the object. This will force the camera mode into "FirstPerson" mode.
    player.attachCameraToObject({
        object = obj,
        offset = {0, height, 0}
    })
    
    -- This is added just in case the API changes in the future and attachCameraToObject no longer forces first-person.
    player.setCameraMode("FirstPerson")
end

--[[
    Attaches the camera in Top-Down mode.
--]]
function attachTopDown(player, obj, height)
    -- Attach the camera to the object. This will force the camera mode into "FirstPerson" mode.
    player.attachCameraToObject({
        object = obj,
        offset = {0, height, 0}
    })
    
    -- Adjusts the camera to the correct distance from the object. This has the side-effect that it forces the camera into "ThirdPerson" mode.
    player.lookAt({
        position = obj.getPosition(),
        pitch = 90,
        distance = height,
        yaw = 0,
    })
    
    -- Set the camera mode to "TopDown".
    player.setCameraMode("TopDown")
end


--[[ ===== UTILITY FUNCTIONS ===== --]]

--[[
    Returns true if the table is empty.
--]]
function tableIsEmpty(tab)
    return tab == nil or next(tab) == nil
end

--[[
    Returns the first object in a table.
    It is necessary to do it in this weird way because Lua tables
    are not always indexed by integer. This will return the first object
    regardless of the indexing.
--]]
function first(tbl)
    for k,v in ipairs(tbl) do
        return v
    end
end