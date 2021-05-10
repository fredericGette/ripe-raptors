# ripe-raptors
Generated by [Rojo](https://github.com/rojo-rbx/rojo) 6.1.0.

## Getting Started
To build the place from scratch, use:

```bash
rojo build -o "ripe-raptors.rbxlx"
```

Next, open `ripe-raptors.rbxlx` in Roblox Studio and start the Rojo server:

```bash
rojo serve
```

For more help, check out [the Rojo documentation](https://rojo.space/docs).

------------------------

Center-Attachement--CylindricalConstraint--Attachment-Anchor--WeldConstraint--HumanoidRootPart--RootMotor--Torso

!! Parent of the StartCharacter has to be Workspace to edit the position of the parts !!

Center is at the center of the Workspace.
CylindricalConstraint is created by function onCharacterAdded of server script PlayerShipHandler.
RootMotor changes direction of the plane (z: 0 or pi).
HumanoidRootPart is inside the Torso.
Anchor is 127 z away from HumanoidRootPart (i.e ~1/2 of grass size).
HumanoidRootPart is the root part of the assembly 



Object position		x,		y,		z
Center 				0,		10,		0
Attachement			0, 		0.5, 	0 (relative to Center)
Anchor				7.8,	18.6,	92
Attachement			0,		0,		0 (relative to Anchor)
HumanoidRootPart	7.7,	18.6,	-35
Torso				7.7,	18.6,	-35
Grass				0,		9.2,	0

Object rotation		x°,		y°,		z°
Center 				0,		0,		0
Attachement			0,		0,		90 (relative to Center)
Anchor				0,		0,		0
Attachement			0,		0,		90 (relative to Anchor)
HumanoidRootPart	0,		0,		0
Torso				0,		0,		0
Grass				0,		0,		-90

Object size			x,		y,		z
Center 				1,		1,		1
Anchor				1,		1,		1
HumanoidRootPart	1,		1,		1
Torso				2,		1,		1
Grass				0.5,	256,	256