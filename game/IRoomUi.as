package angel.game {
	import angel.common.FloorTile;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public interface IRoomUi {
		
		// listeners from IRoomUi are enabled/disabled by caller; this enable/disable are just for the extra
		// bits unique to this particular UI
		function enable(player:ComplexEntity):void;
		function disable():void;
		function suspend():void;
		function resume():void;
		function get currentPlayer():ComplexEntity;
		
		// Generic keys are handled by caller; this is just for the ones unique to this mode
		function keyDown(keyCode:uint):void;
		
		// WARNING: tile can be null on this one! (Because we use this for fake cursor, which we want to move outside floor)
		function mouseMove(tile:FloorTile):void;
		
		function mouseClick(tile:FloorTile):void;
		
		// Return null if no pie menu should be displayed for a right-click on this tile
		function pieMenuForTile(tile:FloorTile):Vector.<PieSlice>;
		
	}
	
}