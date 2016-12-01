GameRules.quests_table = {}

-- quests_table
-- Holds all the quests, could also be made as a KV table.
-- global quests (for all classes) start from index 1.
-- class quests (hero-specific) start from index 100.

-- When you are doing a chain of quests, use sequential numbers.
-- For random/timed quests, use non-sequential numbers.

-- For an example, hunter has 3 quests with IDs 100, 101 and 110
-- Quests 100 and 101 are sequential, meaning 101 starts automatically after 100 is finished.
-- Quest 110 has a delayed start, and it's not in sequence.
-- This means that it starts automatically after the time has elapsed.

-- If you want a progress bar, have both "from" and "to" in your quest.
-- These are the start and end points for your progress bar.
-- It can go either way, depending how the numbers are.

-- For no progress bar, just don't have "from" and "to" in there.

GameRules.quests_table.all = {
    [1] = { -- Global quests start from 1
        name = "#All_Quest_1",
        title = "#All_Quest_1",
        context = {
            type = "Time",
            track = function(hero, quest, obj)
                local count = 0
                if HasAnItem(hero, "item_stick") then count = count + 1 end
                if HasAnItem(hero, "item_tinder") then count = count + 1 end
                if HasAnItem(hero, "item_flint") then count = count + 1 end
                Quests.UpdateQuest(obj, hero, count, quest.id)
            end,
            from = 0,
            to = 3
        }
    },
    [2] = {
        name = "All_Quest_2",
        title = "#All_Quest_2",
        context = {
            type = "Time",
            track = function(hero, quest, obj)
                if HasAnItem(hero, "item_building_kit_fire_basic") then
                    Quests.End(obj, hero, quest.id)
                end
            end
        }
    },
    [3] = {
        name = "All_Quest_3",
        title = "#All_Quest_3",
        context = {
            type = "Time",
            from = 0,
            to = 60
        }
    },
    [5] = {
        name = "All_Quest_1d",
        title = "#All_Quest_1d",
        context = {
            type = "Time",
            from = 0,
            delay_start = 5,
            to = 45
        }
    },
	
--[7] = {
--       name = "All_Quest_1c",
--       title = "#All_Quest_1c",
--       context = {
--           type = "Time",
--			 track = function(hero, quest, obj)
--                local count = 0
--                if OnItemPickedUp then count = count + 1 end
--               Quests.UpdateQuest(obj, hero, count, quest.id)
--           end,
--            delay_start = 40,
--           from = 0,
--           to = 5
--       }
--   },
--    [8] = {
--        name = "All_Quest_2c",
--        title = "#All_Quest_2c",
--        context = {
--            type = "Time",
--            from = 0,
--            delay_start = 5,
--            to = 15
 --       }
--    },
	
    [10] = {
        name = "All_Quest_1e",
        title = "#All_Quest_1e",
        context = {
            type = "Time",
			 track = function(hero, quest, obj)
                 if hero:GetLevel() >= 2 then
                     Quests.End(obj, hero, quest.id)
                 end
            end,
            delay_start = 50
        }
    },
	[11] = {
        name = "All_Quest_2e",
        title = "#All_Quest_2e",
        context = {
            type = "Time",
			track = function(hero, quest, obj)
                if hero:GetLevel() >= 3 then
                     Quests.End(obj, hero, quest.id)
                end
            end
        }
    },
	[12] = {
        name = "All_Quest_3e",
        title = "#All_Quest_3e",
        context = {
            type = "Time",
			 track = function(hero, quest, obj)
                 if hero:GetLevel() >= 4 then
                     Quests.End(obj, hero, quest.id)
                 end
            end
        }
    },
	[13] = {
        name = "All_Quest_4e",
        title = "#All_Quest_4e",
        context = {
            type = "Time",
			 track = function(hero, quest, obj)
                if hero:GetLevel() >= 5 then
                    Quests.End(obj, hero, quest.id)
                end
            end
        }
    },
	[14] = {
        name = "All_Quest_5e",
        title = "#All_Quest_5e",
        context = {
            type = "Time",
			 track = function(hero, quest, obj)
                if hero:GetLevel() >= 6 then
                    Quests.End(obj, hero, quest.id)
                end
            end
        }
    },
	[15] = {
        name = "All_Quest_6e",
        title = "#All_Quest_6e",
        context = {
            type = "Time",
			track = function(hero, quest, obj)
                local count = 0
                if hero:HasSubClass() then
                    Quests.End(obj, hero, quest.id)
                end
            end
        }
    }
}

-- ############### BEASTMASTER

GameRules.quests_table.beastmaster = { -- Class quests start from 100
    [100] = {
        name = "BM_Quest_1",
        title = "#BM_Quest_1",
        context = {
            type = "Time",
            track = function(hero, quest, obj)
                local count = 0
                if HasAnItem(hero, "item_hide_bear") then count = count + 1 end
                if HasAnItem(hero, "item_hide_bear") then count = count + 1 end
                if HasAnItem(hero, "item_hide_elk") then count = count + 1 end
                if HasAnItem(hero, "item_hide_elk") then count = count + 1 end
                if HasAnItem (hero, "item_hide_wolf") then count = count + 1 end
                if HasAnItem (hero, "item_hide_wolf") then count = count + 1 end
                Quests.UpdateQuest(obj, hero, count, quest.id)
            end,
            delay_start = 35,
            from = 0,
            to = 2
        }	
    },
	
	[101] = {
		name = "BM_Quest_2",
        title = "#BM_Quest_2",
        context = {
            type = "Time",
            from = 0,
            to = 15
        }
    },
	[105] = {
        name = "BM_Quest_1d",
        title = "#BM_Quest_1d",
        context = {
            type = "Hook",
            delay_start = 3,
            event_type = "Standard",
            event_name = "dota_player_used_ability",
            event_func = function(hero, quest, abilityName, obj)
				if abilityName == "ability_beastmaster_tamepet" then
                Quests.UpdateQuest(obj, hero, quest.context.current + 1, quest.id)
			end
			end,			
            from = 0,
            to = 1
        }
    },

	[106] = {
			name = "BM_Quest_2d",
			title = "#BM_Quest_2d",
			context = {
				type = "Hook",
				event_type = "Standard",
				event_name = "dota_player_used_ability",
				event_func = function(hero, quest, abilityName, obj)
					if abilityName == "ability_beastmaster_pet_follow" then
					Quests.UpdateQuest(obj, hero, quest.context.current + 1, quest.id)
				end
				end,			
				from = 0,
				to = 1
			}	
		},
	
	[107] = {
        name = "BM_Quest_3d",
        title = "#BM_Quest_3d",
        context = {
				type = "Hook",
				delay_start = 3,
				event_type = "Standard",
				event_name = "dota_player_used_ability",
				event_func = function(hero, quest, abilityName, obj)
					if abilityName == "ability_beastmaster_pet_stay" then
					Quests.UpdateQuest(obj, hero, quest.context.current + 1, quest.id)
				end
				end,			
				from = 0,
				to = 1
			}	
    },
	
    [108] = {
        name = "BM_Quest_4d",
        title = "#BM_Quest_4d",
        context = {
            type = "Time",
            from = 0,
            to = 50
        }
    },
	
	[109] = {
        name = "BM_Quest_5d",
        title = "#BM_Quest_5d",
       context = {
				type = "Hook",
				delay_start = 3,
				event_type = "Standard",
				event_name = "dota_player_used_ability",
				event_func = function(hero, quest, abilityName, obj)
					if abilityName == "ability_beastmaster_pet_attack" then
					print("used ability",abilityName)
					Quests.UpdateQuest(obj, hero, quest.context.current + 1, quest.id)
				end
				end,			
				from = 0,
				to = 1
			}		
	}
}


-- ############### GATHERER


GameRules.quests_table.gatherer = {
    [100] = {
        name = "Gatherer_Quest_1",
        title = "#Gatherer_Quest_1",
		context = {
            type = "Hook",
            delay_start = 3,
            event_type = "Standard",
            event_name = "dota_player_used_ability",
            event_func = function(hero, quest, abilityName, obj)
				if abilityName == "ability_gatherer_itemradar" then
                Quests.UpdateQuest(obj, hero, quest.context.current + 1, quest.id)
			end
			end,			
            from = 0,
            to = 1
        }
    },
		
	[101] = {
        name = "Gatherer_Quest_1",
        title = "#Gatherer_Quest_1a",
        context = {
            type = "Time",
            from = 0,
            to = 10
        }
    },
		
	    [102] = {
        name = "Gatherer_Quest_2",
        title = "#Gatherer_Quest_2",
        context = {
            type = "Hook",
            delay_start = 1,
            from = 0,
            to = 2,
            event_type = "Standard",
            event_name = "dota_player_used_ability",
			event_func = function(hero, quest, abilityName, obj)
			local count =  quest.context.current
			if abilityName == "ability_gatherer_findhide" then count = count + 1 end
			if abilityName == "ability_gatherer_findclayballcookedmeatorbone" then count = count + 1 end
			if abilityName == "ability_gatherer_findmushroomstickortinder" then count = count + 1 end
                Quests.UpdateQuest(obj, hero, count, quest.id)
			end
        }
    },
	
	
	[103] = {
        name = "Gatherer_Quest_3",
        title = "#Gatherer_Quest_3",
        context = {
            type = "Time",
            from = 0,
            to = 10
        }
    },
	
	[104] = {
        name = "Gatherer_Quest_4",
        title = "#Gatherer_Quest_4",
		context = {
            type = "Hook",
            delay_start = 1,
            from = 0,
            to = 1,
            event_type = "Standard",
            event_name = "dota_player_used_ability",
			event_func = function(hero, quest, abilityName, obj)
			if abilityName == "item_building_kit_itempen" then
                Quests.UpdateQuest(obj, hero, quest.context.current + 1, quest.id)
            end
			end,
        }
    },
	
	[105] = {
        name = "Gatherer_Quest_5",
        title = "#Gatherer_Quest_5",
        context = {
            type = "Time",
            from = 0,
            to = 10
        }
    },
	[106] = {
        name = "Gatherer_Quest_6",
        title = "#Gatherer_Quest_6",
        context = {
            type = "Time",
            from = 0,
            to = 10
        }
    },
	[107] = {
        name = "Gatherer_Quest_7",
        title = "#Gatherer_Quest_7",
        context = {
            type = "Time",
            from = 0,
            to = 10
        }
    },
	[108] = {
        name = "Gatherer_Quest_8",
        title = "#Gatherer_Quest_8",
        context = {
            type = "Time",
            from = 0,
            to = 10
        }
    },
	
	
	[109] = {
        name = "Gatherer_Quest_9",
        title = "#Gatherer_Quest_9",
        context = {
            type = "Time",
            track = function(hero, quest, obj)
                local count = 0
                if HasAnItem(hero, "item_flint") then count = count + 1 end
                if HasAnItem(hero, "item_stone") then count = count + 1 end
                if HasAnItem(hero, "item_stone") then count = count + 1 end
                if HasAnItem(hero, "item_stone") then count = count + 1 end
                Quests.UpdateQuest(obj, hero, count, quest.id)
            end,
            from = 0,
            to = 4
        }	
    },
	[110] = {
        name = "Gatherer_Quest_10",
        title = "#Gatherer_Quest_10",
        context = {
            type = "Time",
            track = function(hero, quest, obj)
                local count = 0
                if HasAnItem(hero, "item_building_kit_armory") then count = count + 1 end
                Quests.UpdateQuest(obj, hero, count, quest.id)
            end,
            from = 0,
            to = 1
        }	
    },
	[111] = {
        name = "Gatherer_Quest_11",
        title = "#Gatherer_Quest_11",
        context = {
            type = "Time",
            from = 0,
            to = 10
        }
    },
	[112] = {
        name = "Gatherer_Quest_12",
        title = "#Gatherer_Quest_12",
        context = {
            type = "Time",
            from = 0,
            to = 15
        }
    },	
	[113] = {
        name = "Gatherer_Quest_13",
        title = "#Gatherer_Quest_13",
        context = {
            type = "Time",
            from = 0,
            to = 15
        }
    },	
	
	[114] = {
        name = "Gatherer_Quest_14",
        title = "#Gatherer_Quest_14",
        context = {
            type = "Time",
            track = function(hero, quest, obj)
                local count = 0
                if HasAnItem(hero, "item_flint") then count = count + 1 end
                if HasAnItem(hero, "item_flint") then count = count + 1 end
                if HasAnItem(hero, "item_stone") then count = count + 1 end
                if HasAnItem(hero, "item_stone") then count = count + 1 end
                Quests.UpdateQuest(obj, hero, count, quest.id)
            end,
            from = 0,
            to = 4
        }	
    },
	[115] = {
        name = "Gatherer_Quest_15",
        title = "#Gatherer_Quest_15",
        context = {
            type = "Time",
            from = 0,
            to = 15
        }
    },	
	[116] = {
        name = "Gatherer_Quest_16",
        title = "#Gatherer_Quest_16",
        context = {
        -- Hook for crafting two iron ingots
            type = "Time",
            track = function(hero, quest, obj)
			local count =  quest.context.current
                if HasAnItem(hero, "item_ingot_iron") then count = count + 1 end
                Quests.UpdateQuest(obj, hero, count, quest.id)
            end,
            from = 0,
            to = 2
        }
    },
	[117] = {
        name = "Gatherer_Quest_17",
        title = "#Gatherer_Quest_17",
        context = {
            type = "Time",
            from = 0,
            to = 10
        }
    },
	[118] = {
        name = "Gatherer_Quest_18",
        title = "#Gatherer_Quest_18",
        context = {
            -- Hook for crafting iron axe
            type = "Time",
            track = function(hero, quest, obj)
                local count = 0
                if HasAnItem(hero, "item_axe_iron") then count = count + 1 end
                Quests.UpdateQuest(obj, hero, count, quest.id)
            end,
            from = 0,
            to = 1
        }
    },	
	[120] = {
        name = "Gatherer_Quest_1d",
        title = "#Gatherer_Quest_1d",
        context = {
            type = "Time",
			delay_start = 300,
            from = 0,
            to = 10
        }
    },
	
}

-- ############### MAGE
GameRules.quests_table.mage = {
   [100] = { 
        name = "Mage_Quest_1",
        title = "#Mage_Quest_1",
        context = {
            type = "Time",
            track = function(hero, quest, obj)
                local count = 0
                if HasAnItem(hero, "item_tinder") then count = count + 1 end
                if HasAnItem(hero, "item_tinder") then count = count + 1 end
                Quests.UpdateQuest(obj, hero, count, quest.id)
            end,
            from = 0,
            to = 2
        }
    },
    [101] = {
        name = "Mage_Quest_2",
        title = "#Mage_Quest_2",
        context = {
            type = "Time",
            track = function(hero, quest, obj)
                if HasAnItem(hero, "item_net_hunting") then
                    Quests.End(obj, hero, quest.id)
                end
            end
        }
    },
    [102] = {
        name = "Mage_Quest_3",
        title = "#Mage_Quest_3",
		context = {
            type = "Hook",
            delay_start = 1,
            from = 0,
            to = 3,
            event_type = "Standard",
            event_name = "dota_player_used_ability",
			event_func = function(hero, quest, abilityName, obj)
			if abilityName == "item_net_hunting" then
                Quests.UpdateQuest(obj, hero, quest.context.current + 1, quest.id)
            end
			end,
        }
    },
	
    [103] = {
        name = "Mage_Quest_5",
        title = "#Mage_Quest_5",
        context = {
            type = "Time",
			 track = function(hero, quest, obj)
                 if hero:GetLevel() >= 2 then
                     Quests.End(obj, hero, quest.id)
                 end
            end,
        }
    },
    [104] = {
        name = "Mage_Quest_6",
        title = "#Mage_Quest_6",
        context = {
            type = "Hook",
            delay_start = 1,
            from = 0,
            to = 10,
            event_type = "Standard",
            event_name = "dota_player_used_ability",
			event_func = function(hero, quest, abilityName, obj)
			local count =  quest.context.current
			if abilityName == "ability_mage_negativeblast" then count = count + 1 end
			if abilityName == "item_net_hunting" then count = count + 1 end
			if abilityName == "ability_mage_flamespray" then count = count + 1 end
                Quests.UpdateQuest(obj, hero, count, quest.id)
			end
        }
    },
	
}

-- ############### PRIEST

GameRules.quests_table.priest = {
    [100] = {
        name = "Test_Name",
        title = "Test_Title",
        context = {
            type = "Time",
            from = 0,
            to = 10
        }
    }
}

-- ############### SCOUT

GameRules.quests_table.scout = {
    [100] = {
        name = "Test_Name",
        title = "Test_Title",
        context = {
            type = "Time",
            from = 0,
            to = 10
        }
    }
}

-- ############### THIEF

GameRules.quests_table.thief = {
   [100] = { 
        name = "Thief_Quest_1",
        title = "#Thief_Quest_1.",
        context = {
            type = "Time",
            track = function(hero, quest, obj)
                local count = 0
                if HasAnItem(hero, "item_tinder") then count = count + 1 end
                if HasAnItem(hero, "item_tinder") then count = count + 1 end
                Quests.UpdateQuest(obj, hero, count, quest.id)
            end,
            from = 0,
            to = 2
        }
    },
    [101] = {
        name = "Thief_Quest_2",
        title = "#Thief_Quest_2",
        context = {
            type = "Time",
            track = function(hero, quest, obj)
                if HasAnItem(hero, "item_net_hunting") then
                    Quests.End(obj, hero, quest.id)
                end
            end
        }
    },
    [102] = {
        name = "Thief_Quest_3",
        title = "#Thief_Quest_3",
        context = {
            type = "Hook",
            delay_start = 1,
            from = 0,
            to = 3,
            event_type = "Standard",
            event_name = "dota_player_used_ability",
			event_func = function(hero, quest, abilityName, obj)
			if abilityName == "item_net_hunting" then
                Quests.UpdateQuest(obj, hero, quest.context.current + 1, quest.id)
            end
			end,
        }
    },
}

-- ############### HUNTER

GameRules.quests_table.hunter = {
    
	[100] = {
        name = "Hunter_Quest_1",
        title = "#Hunter_Quest_1",
        context = context = {
            type = "Hook",
            delay_start = 3,
            event_type = "Standard",
            event_name = "dota_player_used_ability",
            event_func = function(hero, quest, abilityName, obj)
				if abilityName == "ability_hunter_ensnare" then
                Quests.UpdateQuest(obj, hero, quest.context.current + 1, quest.id)
			end
			end,			
            from = 0,
            to = 1
        }
    },
	[101] = {
        name = "Hunter_Quest_2",
        title = "#Hunter_Quest_2",
        context = {
            type = "Time",
			 track = function(hero, quest, obj)
                 if hero:GetLevel() == 2 then
                     Quests.End(obj, hero, quest.id)
                 end
            end,
            delay_start = 50
        }
    },
	[102] = {
        name = "Hunter_Quest_3",
        title = "#Hunter_Quest_3",
        context = context = {
            type = "Hook",
            delay_start = 3,
            event_type = "Standard",
            event_name = "dota_player_used_ability",
            event_func = function(hero, quest, abilityName, obj)
				if abilityName == "ability_hunter_track" then
                Quests.UpdateQuest(obj, hero, quest.context.current + 1, quest.id)
			end
			end,			
            from = 0,
            to = 1
        }
    },
	[105] = { 
        name = "Hunter_Quest_1d",
        title = "#Hunter_Quest_1d",
        context = {
            type = "Time",
            delay_start = 40,
            from = 0,
            to = 15
        }
    },
}
