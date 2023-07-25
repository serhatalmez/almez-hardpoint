Scaleform = { }
Scaleform.__index = Scaleform

local _scaleformPool = { }

-- TODO: Simplify me
local function scaleform_render_timed(scaleform, time, renderFunc, ...)
	local startTime = GetGameTimer()
	local transOutTime = 500

	while GetTimeDifference(GetGameTimer(), startTime) < time + transOutTime do
		Citizen.Wait(0)

		if GetGameTimer() - startTime > time then
			scaleform:call('SHARD_ANIM_OUT', 1, 0.33)
			startTime = startTime + transOutTime

			while GetGameTimer() - startTime < time + transOutTime do
				Citizen.Wait(0)
				renderFunc(scaleform, ...)
			end

			break
		end

		renderFunc(scaleform, ...)
	end
end

function Scaleform.NewAsync(name)
	if _scaleformPool[name] then
		return _scaleformPool[name]
	end

	local self = { }
	setmetatable(self, Scaleform)

	self._name = name

	self._scaleform = RequestScaleformMovie(name)
	while not HasScaleformMovieLoaded(self._scaleform) do
		Citizen.Wait(0)
	end

	_scaleformPool[name] = self
	return self
end

function Scaleform.SetAsNoLongerNeeded(name)
	if _scaleformPool[name] then
		SetScaleformMovieAsNoLongerNeeded(_scaleformPool[name]._scaleform)
		_scaleformPool[name] = nil
	end
end

function Scaleform:call(func, ...)
	PushScaleformMovieFunction(self._scaleform, func)

	local params = { ... }
	table.iforeach(params, function(param)
		local paramType = type(param)

		if paramType == 'string' then
			PushScaleformMovieFunctionParameterString(param)
		elseif paramType == 'number' then
			if math.is_integer(param) then
				PushScaleformMovieFunctionParameterInt(param)
			else
				PushScaleformMovieFunctionParameterFloat(param)
			end
		elseif paramType == 'boolean' then
			PushScaleformMovieFunctionParameterBool(param)
		end
	end)

	PopScaleformMovieFunctionVoid()
end

function Scaleform:render(x, y, w, h, r, g, b, a)
	DrawScaleformMovie(self._scaleform, x, y, w, h, r or 255, g or 255, b or 255, a or 255)
end

function Scaleform:renderFullscreen(r, g, b, a)
	DrawScaleformMovieFullscreen(self._scaleform, r or 255, g or 255, b or 255, a or 255)
end

function Scaleform:renderTimed(time, x, y, w, h, r, g, b, a)
	scaleform_render_timed(self, time, self.render, x, y, w, h, r, g, b, a)
end

function Scaleform:renderFullscreenTimed(time, r, g, b, a)
	scaleform_render_timed(self, time, self.renderFullscreen, r, g, b, a)
end

function table.iforeach(t, func)
	for k, v in ipairs(t) do
		func(v, k)
	end
end

function math.is_integer(value)
	return type(value) == 'number' and math.tointeger(value)
end

Gui = { }
Gui.__index = Gui

local _barWidth = 0.225
local _barHeight = 0.035
local _barSpacing = 0

local _barProgressWidth = _barWidth / 2.65
local _barProgressHeight = _barHeight / 3.25

local _barTexture = 'all_black_bg'
local _barTextureDict = 'timerbars'

function Gui.DrawBar(title, text, barPosition, color, isPlayerText, isMonospace)
	RequestStreamedTextureDict(_barTextureDict)
	if not HasStreamedTextureDictLoaded(_barTextureDict) then
		return
	end

	HideHudComponentThisFrame(6) -- VEHICLE_NAME
	HideHudComponentThisFrame(7) -- AREA_NAME
	HideHudComponentThisFrame(8) -- VEHICLE_CLASS
	HideHudComponentThisFrame(9) -- STREET_NAME

	local x = SafeZone.Right() - _barWidth / 2

	local y = SafeZone.Bottom() - _barHeight / 1 - (barPosition - 1) * (_barHeight + _barSpacing)
	-- if Prompt.IsDisplaying() or not Player.Settings.disableTips then
	-- 	y = y - 0.05
	-- end

	local color = color or { r = 240, g = 240, b = 240, a = 255 }
	local font = isPlayerText and 4 or 0
	local scale = isPlayerText and 0.5 or 0.3
	local margin = isPlayerText and 0.015 or 0.007

	DrawSprite(_barTextureDict, _barTexture, x, y, _barWidth, _barHeight, 0.0, 255, 255, 255, 160)

	Gui.SetTextParams(font, color, scale, isPlayerText, false, false)
	Gui.DrawText(title, { x = SafeZone.Right() - (_barWidth / 1.4), y = y - margin }, SafeZone.Size() - _barWidth / 2)
	Gui.SetTextParams(isMonospace and 5 or 0, color, 0.5, false, false, false)
	Gui.DrawText(text, { x = SafeZone.Right(), y = y - 0.0175 }, _barWidth / 1)
end

function Gui.DrawText(text, position, width)
	BeginTextCommandDisplayText('STRING')
	Gui.AddText(text)

	if width then
		SetTextRightJustify(true)
		SetTextWrap(position.x - width, position.x)
	end

	EndTextCommandDisplayText(position.x, position.y)
end


function Gui.AddText(text)
	local str = tostring(text)
	local strLen = string.len(str)
	local maxStrLength = 99

	for i = 1, strLen, maxStrLength + 1 do
		if i > strLen then
			return
		end

		AddTextComponentString(string.sub(str, i, i + maxStrLength))
	end
end


function Gui.DrawTimerBar(text, ms, barPosition, isPlayerText, color, highAccuracy)
	if ms < 0 then
		return
	end

	if not color then
		color = ms <= 10000 and { r = 240, g = 240, b = 240, a = 255 } or  { r = 240, g = 240, b = 240, a = 255 }
	end

	Gui.DrawBar(text, string.from_ms(ms, highAccuracy), barPosition, color, isPlayerText, true)
end

function string.from_ms(ms, highAccuracy)
	local roundMs = ms / 1000

	local minutes = math.floor(roundMs / 60)
	local seconds = math.floor(roundMs % 60)

	local result = string.format('%02.f', minutes)..':'..string.format('%02.f', math.floor(seconds))
	if highAccuracy then
		result = result..'.'..string.format('%02.f', math.floor((ms - (minutes * 60000) - (seconds * 1000)) / 10))
	end

	return result
end

function Gui.DrawProgressBar(title, progress, barPosition, color)
	RequestStreamedTextureDict(_barTextureDict)
	if not HasStreamedTextureDictLoaded(_barTextureDict) then
		return
	end

	local x = SafeZone.Right() - _barWidth / 2

	local y = SafeZone.Bottom() - _barHeight / 2 - (barPosition - 1) * (_barHeight + _barSpacing)
	-- if Prompt.IsDisplaying() or not Player.Settings.disableTips then
	-- 	y = y - 0.05
	-- end

	DrawSprite(_barTextureDict, _barTexture, x, y, _barWidth, _barHeight, 0.0, 255, 255, 255, 160)

	Gui.SetTextParams(0,  { r = 240, g = 240, b = 240, a = 255 }, 0.3, false, false, false)
	Gui.DrawText(title, { x = SafeZone.Right() - _barWidth / 2, y = y - 0.011 }, SafeZone.Size() - _barWidth / 2)

	local color = color or { r = 255, g = 255, b = 255 }
	local progressX = x + _barWidth / 2 - _barProgressWidth / 2 - 0.00285 * 2
	DrawRect(progressX, y, _barProgressWidth, _barProgressHeight, color.r, color.g, color.b, 96)

	local progress = math.max(0.0, math.min(1.0, progress))
	local progressWidth = _barProgressWidth * progress
	DrawRect(progressX - (_barProgressWidth - progressWidth) / 2, y, progressWidth, _barProgressHeight, color.r, color.g, color.b, 255)
end

function Gui.SetTextParams(font, color, scale, shadow, outline, center)
	SetTextFont(font)
	SetTextColour(color.r, color.g, color.b, color.a or 255)
	SetTextScale(scale, scale)

	if shadow then
		SetTextDropShadow()
	end

	if outline then
		SetTextOutline()
	end

	if center then
		SetTextCentre(true)
	end
end



SafeZone = { }
SafeZone.__index = SafeZone

function SafeZone.Size()
	return GetSafeZoneSize()
end

function SafeZone.Left()
	return (1.0 - SafeZone.Size()) * 0.5
end

function SafeZone.Right()
	return 1.015 - SafeZone.Left()
end

SafeZone.Top = SafeZone.Left

function SafeZone.Bottom()
	return 0.70 - SafeZone.Left()
end
