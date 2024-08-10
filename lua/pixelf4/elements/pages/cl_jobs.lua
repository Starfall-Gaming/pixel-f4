
--[[
    PIXEL F4
    Copyright (C) 2021 Tom O'Sullivan (Tom.bat)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License.
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]

local PANEL = {}

function PANEL:Init()
    self:Populate(self.Scroller:GetCanvas())
end

function PANEL:Populate(canvas, searchTerm)
    canvas:Clear()
    table.Empty(self.Categories)

    self.LimitedJobs = {}

    local teams = {}
    for k,v in pairs(team.GetAllTeams()) do
        teams[v.Name] = k
    end

    local localPly = LocalPlayer()
    for k,v in SortedPairsByMemberValue(ix.faction.indices, "sortOrder") do
        local cat = vgui.Create("PIXEL.F4.ItemCategory", canvas)
        cat:SetTitle(v.name)
        cat:Dock(TOP)
        cat:SetExpanded(true)

        cat.SetExtraItemData = function(s, item, itemData)
            local teamNo = itemData.index

            item.DoClick = function()
                self:SelectJob(itemData, itemData.index)
            end

            item:SetTeamNo(teamNo)

            if itemData.limit == 0 then
                item:SetSlotText("∞")
                return
            end

            self.LimitedJobs[teamNo] = {panel = item, maxSlots = itemData.limit}
        end

        cat:SetItemType("Job")

        self.classes = {}
        for i, class in SortedPairsByMemberValue(ix.class.list, "sortOrder") do
            if class.faction ~= k then continue end
            self.classes[i] = class
        end
        cat:SetItems(self.classes, searchTerm)


        if #cat.Items < 1 then cat:Remove() continue end

        table.insert(self.Categories, cat)
    end
    self:UpdateJobSlots()

    timer.Create("PIXEL.F4.CalculateJobSlots", 2, 0, function()
        if not IsValid(self) then
            timer.Remove("PIXEL.F4.CalculateJobSlots")
            return
        end

        self:UpdateJobSlots()
    end)
end

function PANEL:UpdateJobSlots()
    local teamPlayers = {}

    for _, ply in player.Iterator() do
        local char = ply:GetCharacter()
        if not char then continue end
        local class = char:GetClass()
        teamPlayers[class] = (teamPlayers[class] or 0) + 1
    end

    for k,v in pairs(self.LimitedJobs) do
        v.panel:SetSlotText((teamPlayers[k] or 0) .. "/" .. v.maxSlots)
    end
end

function PANEL:SelectJob(jobData, teamNo)
    self.SelectedOverlay = vgui.Create("PIXEL.F4.SelectedJob", self)
    self.SelectedOverlay:SetZPos(1000)
    self.SelectedOverlay:SelectJob(jobData, teamNo)
end

function PANEL:DeSelectJob()
    self.SelectedOverlay:Remove()
end

function PANEL:LayoutExtra(w, h)
    if not IsValid(self.SelectedOverlay) then return end
    self.SelectedOverlay:SetSize(w, h)
end

vgui.Register("PIXEL.F4.Jobs", PANEL, "PIXEL.F4.ItemPage")