package angel.roomedit {
	import flash.display.Sprite;

	// All of these should extend Sprite, but Actionscript doesn't provide any way to enforce that
	// (Could approach it by personally adding all the Sprite public functions to this interface, but that would
	// then need to be updated if a future release added anything new to Sprite).  The closest thing to a
	// solution I've found in researching this is to have a conversion function as part of the interface,
	// and use that when going through the interface.  This is obviously less efficient than just casting,
	// and bulks out the code, but it's safer so it's arguably better programming practice.
	// I'm doing it here as an experiment and intend to ask Mickey his thoughts.
	public interface IRoomEditorPalette {
		
		function asSprite():Sprite;
		function get tabLabel():String;
		
		function applyToTile(floorTile:FloorTileEdit, remove:Boolean = false):void;
		
		// return true if palette should be applied to each tile during a click-drag
		function paintWhileDragging():Boolean;
	}
	
}