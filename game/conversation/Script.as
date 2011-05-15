package angel.game.conversation {
	import angel.common.Alert;
	import angel.common.LoaderWithErrorCatching;
	import angel.game.action.Action;
	import angel.game.action.ConversationAction;
	import angel.game.action.IAction;
	import angel.game.combat.RoomCombat;
	import angel.game.Settings;
	import flash.events.Event;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class Script {
		private var actions:Vector.<IAction>;
		
		public static const FROBBED_ENTITY_ID:String = "**frobbed**";
		
		public function Script() {
		
		}
		
		public function initializeFromXml(xml:XML, errorPrefix:String = ""):void {
			if (xml.name() == "conversations") {
				// As a shorthand/convenience, if a script file has the enclosing topic "conversations" we turn its contents
				// into a conversation action with the frobbed entity
				var data:ConversationData = new ConversationData();
				data.initializeFromXml(xml, errorPrefix);
				addAction(new ConversationAction(data, FROBBED_ENTITY_ID));
			} else {
				var children:XMLList = xml.children();
				for each (var child:XML in xml.children()) {
					addAction(Action.createFromXml(child, errorPrefix));
				}
			}
		}
		
		// Loads data from specified file.
		// NOTE: File must be in the same directory that we're running from!
		public function loadFromXmlFile(filename:String):void {
			LoaderWithErrorCatching.LoadFile(filename, scriptXmlLoaded);
		}
		
		private function scriptXmlLoaded(event:Event, filename:String):void {
			try {
				initializeFromXml(new XML(event.target.data), "Error in script file " + filename + ":\n");
			} catch (error:Error) {
				Alert.show("Error in file " + filename + " --> " + error);
			}
		}
		
		public function run():void {
			var doAtEnd:Vector.<Function> = new Vector.<Function>();
			
			doActions(doAtEnd);
			
			while (doAtEnd.length > 0) {
				var f:Function = doAtEnd.shift();
				f();
			}
			if (Settings.currentRoom.mode is RoomCombat) {
				RoomCombat(Settings.currentRoom.mode).checkForCombatOver();
			}
		}
		
		public function addAction(newAction:IAction):void {
			if (newAction != null) {
				if (actions == null) {
					actions = new Vector.<IAction>();
				}
				actions.push(newAction);
			}
		}
		
		public function doActions(doAtEnd:Vector.<Function>):void {
			if (actions == null) {
				return;
			}
			for (var i:int = 0; i < actions.length; ++i) {
				var gotoReference:Object = actions[i].doAction(doAtEnd);
				if (gotoReference != null) {
					Alert.show("Error! 'goto' only valid in Conversation");
				}
			}
		}
		
		public function doActionsForConversationSegment(doAtEnd:Vector.<Function>):Object {
			if (actions == null) {
				return null;
			}
			var nextEntryReference:Object;
			for (var i:int = 0; i < actions.length; ++i) {
				var gotoReference:Object = actions[i].doAction(doAtEnd);
				if ((gotoReference != null) && (nextEntryReference != null)) {
					Alert.show("Script has extra goto, id=" + gotoReference.id);
				}
				if (gotoReference != null) {
					nextEntryReference = gotoReference;
				}
			}
			return nextEntryReference;
		}
		
		
	}

}