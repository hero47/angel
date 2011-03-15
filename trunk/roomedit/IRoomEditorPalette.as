package angel.roomedit {
	import flash.display.Sprite;

	public interface IRoomEditorPalette {
		
		function applyToTile(floorTile:FloorTileEdit):void;
		
		// return true if palette should be applied to each tile during a click-drag
		function paintWhileDragging():Boolean;
	}
	
}