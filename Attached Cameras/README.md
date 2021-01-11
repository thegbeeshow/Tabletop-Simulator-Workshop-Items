# Attached Cameras

[Link](https://steamcommunity.com/sharedfiles/filedetails/?id=2355005122)

## Description
**Attached Cameras** is a tool that lets you attach a player camera to any object. The camera will follow the object until it is detached. Several **Quick Tokens** are provided to facilitate ease of use.

There are three different versions available for different camera modes.
1. Third-Person
2. First-Person
3. Top-Down

## Usage
### Attached Camera
1. Adjust the height setting using the provided input box.
2. Select the object you want to attach to.
3. Press 'Attach'.
4. To detach, press 'X'.

To move around, just grab your token and slowly move it in the direction you want to go.

### Quick Token
1. Adjust the height setting using the provided input box. The default values will usually work for this.
2. Press 'A' to attach to the token.
3. To detach, press 'X'.

To move around, just grab your token and slowly move it in the direction you want to go.

## Camera Height Setting
The camera height setting does something different for each camera mode.
### Third-Person
The camera height setting will adjust the height offset of the center of the third-person mode. For most small tokens, a value of '0'. For taller tokens, you may want to increase the setting between '1.0'-'5.0'.

**Typical Value:** '0.0'

### First-Person
The camera height setting will adjust the height of the first-person view. It is recommended to adjust the setting until it is just above the top of the figurine.

**Typical Value:** '2.0'

### Top-Down
The camera height setting will adjust the distance from the figure. There is a minimum value of 10 in TTS unless the user middle-clicks the figurine which will reduce the minimum to 5.

**Typical Value:** 20

## Developers Guide
The only adjustable value is CAMERA_MODE which will select how the Attached Camera behaves. You can change this manually or just use the provided variants in the workshop item.

```CAMERA_MODE = 0``` -> Third-Person  
```CAMERA_MODE = 1``` -> First-Person  
```CAMERA_MODE = 2``` -> Top-Down

Additionally, the script on the **Quick Tokens** can be copy-pasted onto another object to make them quickly attachable.
