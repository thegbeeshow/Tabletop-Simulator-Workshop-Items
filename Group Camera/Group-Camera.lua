--[[
    Group Camera v1.0.0

    
    Description:
    Group Camera is a mod that allows you to save a camera point-of-view and
    force all players into that point-of-view. By combining multiple Group Cameras
    and using them sequentially, you can construct small cinematic sequences.
    You can also use Group Camera to force all players to look at a specific table,
    area, or object.



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

--[[ ===== TABLETOP SIMULATOR EVENTS ===== --]]

--[[
    Occurs when the object is loaded.
--]]

function onLoad(save_state)
    -- Load previous object state.
    if save_state == nil or save_state == "" then
        script_state = {
            camera_token_guid = nil,
            camera_setting = nil
        }
    else
        script_state = JSON.decode(save_state)
    end

    -- Create the user interface.
    createUserInterface()
end

--[[
    Occurs when the object is saved.
--]]
function onSave()
    saved_data = JSON.encode(script_state)
    return saved_data
end


--[[ ===== UI FUNCTONS ===== --]]

--[[
    Creates the user interface based on the current state.
--]]
function createUserInterface()
    -- Remove all existing buttons.
    local num_buttons = getNumItems(self.getButtons())
    if num_buttons > 0 then
        for idx = 0,(num_buttons-1) do
            self.removeButton(idx)
        end
    end

    if script_state.camera_setting == nil then
        -- Create UI when no camera is saved.
        self.createButton({
            label          = "Set", 
            click_function = "onSetClick", 
            function_owner = self,
            tooltip        = "Set",
            position       = {0,0.1, 0}, 
            rotation       = {0,0,0}, 
            height         = 500, 
            width          = 1000,
            font_size      = 150,
            color          = {1,1,1}, 
            font_color     = {0,0,0}
        })
    else
        -- Create UI when a camera has been saved.
        self.createButton({
            label          = script_state.camera_setting.name, 
            click_function = "onViewClick", 
            function_owner = self,
            tooltip        = "Force all players to position. Right-click to delete.",
            position       = {0,0.1, -0.25}, 
            rotation       = {0,0,0}, 
            height         = 250, 
            width          = 1000,
            font_size      = 150,
            color          = script_state.camera_setting.tint, 
            font_color     = {0,0,0}
        })

        self.createButton({
            label          = "View", 
            click_function = "onViewSelfClick", 
            function_owner = self,
            tooltip        = "See the view for yourself.",
            position       = {-0.5,0.1, 0.25}, 
            rotation       = {0,0,0}, 
            height         = 250, 
            width          = 500,
            font_size      = 150,
            color          = {1,1,1}, 
            font_color     = {0,0,0}
        })

        self.createButton({
            label          = "Edit", 
            click_function = "onEditClick", 
            function_owner = self,
            tooltip        = "Edit",
            position       = {0.5,0.1, 0.25}, 
            rotation       = {0,0,0}, 
            height         = 250, 
            width          = 500,
            font_size      = 150,
            color          = {1,1,1}, 
            font_color     = {0,0,0}
        })
    end
    
end

--[[
    Occurs when the 'Set' button is clicked.
    Creates a camera token that the user can use to save a camera position.
--]]
function onSetClick(obj, color, alt)
    if script_state.camera_token_guid ~= nil then
        deleteCameraToken()
    end

    spawnCameraToken(Player[color])
end

--[[
    Occurs when the camera name is clicked.
    Moves all players (except the clicking player) to the saved view.
    If right-clicked, it resets the object.addTorque(undefined, undefined)
--]]
function onViewClick(obj, color, alt)
    if not alt then
        -- Move all players except this player.
        for _, player in ipairs(Player.getPlayers()) do
            if player.color ~= color then
               player.lookAt({
                   position = script_state.camera_setting.position,
                   pitch    = script_state.camera_setting.pitch,
                   distance = script_state.camera_setting.distance,
                   yaw = script_state.camera_setting.yaw,
               })

               broadcastToColor("Your camera position has been set by " .. color .. ".", player.color, {1,1,1})
           end
        end

        broadcastToColor("Camera position set for all players!", color, {1,1,1})
    else
        -- Reset Group Camera.
        script_state.camera_setting = nil
        createUserInterface()
    end
end

--[[
    Occurs when the 'View' button is clicked.
    Will move the clicking player to the saved view.
--]]
function onViewSelfClick(obj,color,alt)
    Player[color].lookAt({
        position = script_state.camera_setting.position,
        pitch    = script_state.camera_setting.pitch,
        distance = script_state.camera_setting.distance,
        yaw = script_state.camera_setting.yaw,
    })
end

--[[
    Occurs when the 'Edit' button is clicked.
    Will spawn a camera token at the saved location so that it can be changed.
--]]
function onEditClick(obj, color, alt)
    if script_state.camera_token_guid ~= nil then
        deleteCameraToken()
    end

    spawnCameraToken(Player[color])
end

--[[
    Occurs when the 'View' button on the camera token is clicked.
    Gives the user a preview of the current setting.
--]]
function onCameraTokenView(obj, color, alt)
    local settings = getCameraSettingsFromDescription(obj.getDescription())
    Player[color].lookAt({
        position = obj.getPosition(),
        pitch = settings.pitch,
        distance = settings.distance,
        yaw = obj.getRotation().y + 180
    })
end

--[[
    Occurs when the 'Save' button on the camera token is clicked.
    Saves the camera setting and returns the user to the main object.
--]]
function onCameraTokenSave(obj, color, alt)
    local values = split(obj.getDescription(), ",")
    local pitch = tonumber(values[1])
    local distance = tonumber(values[2])
    local yaw = obj.getRotation().y + 180

    script_state.camera_setting = {
        name = obj.getName(),
        position = obj.getPosition(),
        pitch = pitch,
        yaw = yaw,
        distance = distance,
        tint = obj.getColorTint()
    }

    createUserInterface()

    --[[
        It's important to wait one frame before moving the camera since
        the player camera will still be attached on the frame it is removed.
    --]]
    deleteCameraToken()
    Wait.frames(function()
        Player[color].lookAt
        {
            position = self.getPosition(),
            pitch = 60,
            distance = 40,
            yaw = self.getRotation().y + 180
        }
    end, 1)
end

--[[
    Occurs when the 'Cancel' button on the camera token is clicked.
    Removes the camera token and returns the user to the main object.
--]]
function onCameraTokenCancel(obj, color, alt)

    --[[
        It's important to wait one frame before moving the camera since
        the player camera will still be attached on the frame it is removed.
    --]]
    deleteCameraToken()
    Wait.frames(function()
        Player[color].lookAt
        {
            position = self.getPosition(),
            pitch = 60,
            distance = 40,
            yaw = self.getRotation().y + 180
        }
    end, 1)
end

--[[ ===== CORE FUNCTIONS ===== --]]

--[[
    Spawn a camera token with a built-in UI.
--]]
function spawnCameraToken(player)
    --[[
        Create Camera Token.
        Pay attention closely here, there is a lot going on in the callback_function.
        Many things cannot be done until the object is confirmed created. For example,
        the camera cannot be attached until it is ready. Also, the GUID is not generated
        until the object is fully created.
    --]]
    local token = spawnObject({
        type = "reversi_chip",
        position = {self.getPosition().x, self.getPosition().y + 2, self.getPosition().z},
        rotation = {0, 180, 0},
        callback_function = function(obj)
            script_state.camera_token_guid = obj.getGUID()
            player.attachCameraToObject({
                object = obj
            })

            if script_state.camera_setting == nil then
                player.lookAt({
                    position = obj.getPosition(),
                    pitch = 45,
                    yaw = 0,
                    distance = 40
                })
            else
                obj.setPosition(script_state.camera_setting.position)
                obj.setRotation({0, script_state.camera_setting.yaw - 180, 0})
                player.lookAt({
                    position = obj.getPosition(),
                    pitch = script_state.camera_setting.pitch,
                    yaw = script_state.camera_setting.yaw,
                    distance = script_state.camera_setting.distance
                })
            end
        end,
    })
    
    -- Set the token info.
    if script_state.camera_setting == nil then
        token.setName("[No Name]")
        token.setDescription("45,40")
        token.setColorTint({1,1,1})
    else
        token.setName(script_state.camera_setting.name)
        token.setDescription(script_state.camera_setting.pitch .. "," .. script_state.camera_setting.distance)
        token.setColorTint(script_state.camera_setting.tint)
    end

    -- Create Camera Token UI.
    token.createButton({
        label          = "View", 
        click_function = "onCameraTokenView", 
        function_owner = self,
        tooltip        = "Save",
        position       = {0,0.1, 1.2}, 
        rotation       = {0,0,0}, 
        height         = 300, 
        width          = 800,
        font_size      = 250,
        color          = {1,1,1}, 
        font_color     = {0,0,0}
    })

    token.createButton({
        label          = "Save", 
        click_function = "onCameraTokenSave", 
        function_owner = self,
        tooltip        = "Save",
        position       = {0,0.1, 2}, 
        rotation       = {0,0,0}, 
        height         = 300, 
        width          = 800,
        font_size      = 250,
        color          = {1,1,1}, 
        font_color     = {0,0,0}
    })

    token.createButton({
        label          = "Cancel", 
        click_function = "onCameraTokenCancel", 
        function_owner = self,
        tooltip        = "Cancel",
        position       = {0,0.1, 2.8}, 
        rotation       = {0,0,0}, 
        height         = 300, 
        width          = 800,
        font_size      = 250,
        color          = {1,1,1}, 
        font_color     = {0,0,0}
    })
end

--[[
    Deletes the camera token if it exists.
--]]
function deleteCameraToken()
    if script_state.camera_token_guid ~= nil then
        local token = retrieveCameraToken()
        if token ~= nil then
            token.destruct()
        end

        script_state.camera_token_guid = nil
    end
end

--[[
    Gets the camera token object from the stored GUID.
--]]
function retrieveCameraToken()
    return getObjectFromGUID(script_state.camera_token_guid)
end


--[[ ===== UTILITY FUNCTIONS ===== --]]

--[[
    Gets the number of items in a table.
--]]
function getNumItems(list)
    if list == nil then return 0 end

    local count = 0
    for _,_ in ipairs(list) do
        count = count + 1
    end

    return count
end

--[[
    Parses the object description into pitch and distance.
--]]
function getCameraSettingsFromDescription(desc)
    local splits = split(desc, ",")
    local values = {
        pitch = tonumber(splits[1]),
        distance = tonumber(splits[2])
    }
    return values
end

--[[
    Splits a string into a table with a given seperator.

    Credit to: Adrian Mole whole provided their solution on
    Stack Overflow for this problem.

    https://stackoverflow.com/questions/1426954/split-string-in-lua
--]]
function split (inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end