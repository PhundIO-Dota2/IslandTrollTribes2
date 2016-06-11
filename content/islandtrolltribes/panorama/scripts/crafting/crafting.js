// Create a section to hold a list of crafting items
function CreateCraftingSection (name, table, panel, bFold, entity) {
    //$.Msg("CreateCraftingSection ",name)
    var section = $.CreatePanel("Panel", panel, name)
    section.name = name
    section.bFold = bFold //Whether the panel starts initially folded
    //section.BLoadLayout("file://{resources}/layout/custom_game/crafting/crafting_section.xml", false, false);
    section.BLoadLayoutSnippet("Crafting_Section");

    // Create the recipes in order
    for (var i in table)
    {
        var subtable = table[i]  
        for (var item_result in subtable)
        {
            var ingredients = []
            for (var ingredient in subtable[item_result])
            {
                var times = subtable[item_result][ingredient]
                for (var i = 0; i < times; i++) {
                    ingredients.push(ingredient)
                }
            }
            //$.Msg(ingredients)
            CreateCraftingRecipe(section, item_result, ingredients, subtable[item_result], name, entity)
        }
    }

    // Hide elements if the panel should start fold
    if (section.bFold)
    {
        var childNum = section.GetChildCount()
        for (var i = 0; i < childNum; i++) {
            var child = section.GetChild( i )
            if (child.id !="Toggle")
                child.visible = false
        };
    }

    return section
}

// Create a crafting recipe panel
function CreateCraftingRecipe (section, result, ingredients, table, name, entity) {
    var crafting_item = $.CreatePanel("Panel", section, result)
    crafting_item.section_name = name
    crafting_item.itemname = result
    crafting_item.ingredients = ingredients
    crafting_item.table = table
    crafting_item.entity = entity
    //crafting_item.BLoadLayout("file://{resources}/layout/custom_game/crafting/crafting_recipe.xml", false, false);
    crafting_item.BLoadLayoutSnippet("Crafting_Recipe")
}

var crafting_currentSelected
var iPlayerID = Players.GetLocalPlayer();
function Crafting_OnUpdateSelectedUnits() {
    var selectedEntities = Players.GetSelectedEntities( iPlayerID );
    var mainSelected = selectedEntities[0]
    if (crafting_currentSelected == mainSelected)
        GameUI.CustomUIConfig().HideCraftingList()
    else
        crafting_currentSelected = mainSelected
}

(function () {
    GameEvents.Subscribe( "dota_player_update_selected_unit", Crafting_OnUpdateSelectedUnits );
})();