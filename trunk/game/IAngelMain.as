package angel.game {
	import flash.display.DisplayObjectContainer;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public interface IAngelMain {
		function get currentRoom():Room;
		function startRoom(room:Room):void;
		function get asDisplayObjectContainer():DisplayObjectContainer;
	}
	
}