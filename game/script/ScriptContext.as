package angel.game.script {
	import angel.game.Room;
	import angel.game.SimpleEntity;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ScriptContext {
		private var triggeringEntity:SimpleEntity;
		private var scriptRoom:Room;
		private var doAtEnd:Vector.<Function> = new Vector.<Function>();
		
		public function ScriptContext(room:Room, triggeringEntity:SimpleEntity = null) {
			this.triggeringEntity = triggeringEntity;
			this.scriptRoom = room;
		}
		
		public function entityWithScriptId(entityId:String):SimpleEntity {
			if (entityId == Script.TRIGGERING_ENTITY_ID) {
				return triggeringEntity;
			} else {
				return room.entityInRoomWithId(entityId);
			}
		}
		
		public function get room():Room {
			return scriptRoom;
		}
		
		// f should be a function that takes this ScriptContext as a parameter.
		// These functions will be called (in the order added) after all script actions are processed.
		public function doThisAtEnd(f:Function):void {
			doAtEnd.push(f);
		}
		
		public function endOfScriptActions():void {
			while (doAtEnd.length > 0) {
				var f:Function = doAtEnd.shift();
				f(this); // No, this is not a comment on my satisfaction with the code!
			}
		}
		
		public function hasEndOfScriptActions():Boolean {
			return (doAtEnd.length > 0);
		}
		
	}

}