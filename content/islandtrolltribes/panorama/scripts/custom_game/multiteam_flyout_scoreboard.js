"use strict";

var g_ScoreboardHandle = null;
var nextPressActivatesScoreboard = true;
var holding_down = false;

function UpdateScoreboardTimer() {
	if (!nextPressActivatesScoreboard) {
		ScoreboardUpdater_SetScoreboardActive( g_ScoreboardHandle, true );
	}
	$.Schedule(1,UpdateScoreboardTimer);
}

function SetFlyoutScoreboardVisible(bVisible)
{
	// Gotta skip the release button event
	// ^ It's skipping it now.
	if ( bVisible && holding_down )
	{
		holding_down = false;
		if (nextPressActivatesScoreboard)
		{
			// set values to true, and next press will deactivate
			ScoreboardUpdater_SetScoreboardActive( g_ScoreboardHandle, true );
			$.GetContextPanel().SetHasClass( "flyout_scoreboard_visible", true );
			nextPressActivatesScoreboard = false
		}
		else
		{
			ScoreboardUpdater_SetScoreboardActive( g_ScoreboardHandle, false );
			$.GetContextPanel().SetHasClass( "flyout_scoreboard_visible", false );
			nextPressActivatesScoreboard = true
		}
	}
	holding_down = true;
}


function HeatUpdate(args) {
	g_ScoreboardHandle.scoreboardConfig.heatInfo = args.players;
}

(function()
{
	if ( ScoreboardUpdater_InitializeScoreboard === null ) { $.Msg( "WARNING: This file requires shared_scoreboard_updater.js to be included." ); }

	var scoreboardConfig =
	{
		"teamXmlName" : "file://{resources}/layout/custom_game/multiteam_flyout_scoreboard_team.xml",
		"playerXmlName" : "file://{resources}/layout/custom_game/multiteam_flyout_scoreboard_player.xml",
	};
	g_ScoreboardHandle = ScoreboardUpdater_InitializeScoreboard( scoreboardConfig, $( "#TeamsContainer" ) );

	SetFlyoutScoreboardVisible( false );

	GameEvents.Subscribe("scoreboard_heat_update", HeatUpdate);
	$.RegisterEventHandler( "DOTACustomUI_SetFlyoutScoreboardVisible", $.GetContextPanel(), SetFlyoutScoreboardVisible );
	UpdateScoreboardTimer();
})();
