package angel.game.inventory {
	import flash.display.Sprite;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public interface CanBeInInventory {
		function get id():String;
		function get displayName():String;
		function get iconClass():Class;
		function stacksWith(other:CanBeInInventory):Boolean;
	}
	
	// Inventory singletons should implement static getCopy
	
}