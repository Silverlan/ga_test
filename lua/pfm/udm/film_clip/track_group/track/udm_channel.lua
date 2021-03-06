--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/udm/film_clip/actor/components/animation_set/udm_log.lua")
include("/pfm/udm/film_clip/actor/components/animation_set/udm_graph_curve.lua")
fudm.ELEMENT_TYPE_PFM_CHANNEL = fudm.register_element("PFMChannel")
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_CHANNEL,"log",fudm.PFMLog())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_CHANNEL,"fromAttribute",fudm.String())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_CHANNEL,"fromElement",fudm.ELEMENT_TYPE_ANY)
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_CHANNEL,"toAttribute",fudm.String())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_CHANNEL,"toElement",fudm.ELEMENT_TYPE_ANY)
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_CHANNEL,"graphCurve",fudm.PFMGraphCurve())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_CHANNEL,"expression",fudm.String())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_CHANNEL,"targetPath",fudm.String())

fudm.PFMChannel.ENABLE_ALL_CHANNELS = false
fudm.PFMChannel.set_all_channels_enabled = function(b) fudm.PFMChannel.ENABLE_ALL_CHANNELS = b end
function fudm.PFMChannel:IsBoneTransformChannel()
	if(self.m_cacheIsBoneTransformChannel ~= nil) then return self.m_cacheIsBoneTransformChannel end
	self.m_cacheIsBoneTransformChannel = false
	local toElement = self:GetToElement()
	if(toElement == nil) then return false end
	local type = toElement:GetType()
	if(type == fudm.ELEMENT_TYPE_PFM_CONSTRAINT_SLAVE) then
		self.m_cacheIsBoneTransformChannel = true
		return true
	end
	if(toElement:GetType() ~= fudm.ELEMENT_TYPE_TRANSFORM) then return false end
	local parent = toElement:FindParentElement(function(el) return el:GetType() == fudm.ELEMENT_TYPE_PFM_BONE end)
	self.m_cacheIsBoneTransformChannel = (parent ~= nil)
	return self.m_cacheIsBoneTransformChannel
end

function fudm.PFMChannel:IsFlexControllerChannel()
	local toElement = self:GetToElement()
	return (toElement ~= nil and toElement:GetType() == fudm.ELEMENT_TYPE_PFM_GLOBAL_FLEX_CONTROLLER_OPERATOR) -- TODO: Is this reliable?
end

function fudm.PFMChannel:SetPlaybackOffset(offset)
	-- TODO: Remove this function once skeletal animations have been transitioned to new animation system

	-- Note: This function will grab the appropriate value from the log
	-- and assign it to the 'toElement'. If no log values exist, the
	-- 'fromAttribute' value of the 'fromElement' element will be used instead.
	if(self.m_bnChannel == nil) then
		self.m_bnChannel = self:IsBoneTransformChannel() or self:IsFlexControllerChannel()
	end
	if(fudm.PFMChannel.ENABLE_ALL_CHANNELS == false and self.m_bnChannel ~= true) then return end
	local toElement = self:GetToElement()
	if(toElement == nil) then return end
	local toAttribute = self:GetToAttribute()
	local el = toElement:GetChild(toAttribute)
	if(el ~= nil) then
		local log = self:GetLog()
		local value = log:SetPlaybackOffset(offset)
		local property = toElement:GetProperty(toAttribute)
		if(property ~= nil) then
			if(value ~= nil) then
				property:SetValue(value)
				-- TODO: Also set 'time' property of toElement if it exists? (e.g. for expression operator)
			else
				local fromElement = self:GetFromElement()
				local fromProperty = (fromElement ~= nil) and fromElement:GetProperty(self:GetFromAttribute()) or nil
				if(fromProperty ~= nil) then
					property:SetValue(fromProperty:GetValue())
				end
			end
		end
	else
		-- pfm.log("Invalid to-attribute '" .. toAttribute .. "' of element '" .. toElement:GetName() .. "'!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
	end
end
