package angel.game.script {
	import angel.common.Alert;
	import angel.common.LoaderWithErrorCatching;
	import angel.common.Util;
	import angel.game.action.Action;
	import angel.game.action.ConversationAction;
	import angel.game.action.IAction;
	import angel.game.action.IActionToBeMergedWithPreviousIf;
	import angel.game.action.IfAction;
	import angel.game.combat.RoomCombat;
	import angel.game.Settings;
	import angel.game.SimpleEntity;
	import flash.events.Event;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class Script {
		private var actions:Vector.<IAction>;
		private var lastActionAddedIfItWasAnIf:IfAction;
		
		public static const TRIGGERING_ENTITY_ID:String = "*this";
		
		public static var triggeringEntity:SimpleEntity;
		
		public function Script(xml:XML = null, errorPrefix:String = "") {
			if (xml != null) {
				initializeFromXml(xml, errorPrefix);
			}
		}
		
		public function initializeFromXml(xml:XML, errorPrefix:String = ""):void {
			if ((xml == null) || (xml.length() == 0)) {
				return;
			}
			if (xml.name() == "conversations") {
				// As a shorthand/convenience, if a script file has the enclosing topic "conversations" we turn its contents
				// into a conversation action with the frobbed entity
				var data:ConversationData = new ConversationData();
				data.initializeFromXml(xml, errorPrefix);
				addAction(new ConversationAction(data, TRIGGERING_ENTITY_ID));
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
			var xml:XML = Util.parseXml(event.target.data, filename);
			if (xml != null) {
				initializeFromXml(xml, "Error in script file " + filename + ":\n");
			}
		}
		
		public function run(triggeredBy:SimpleEntity = null):void {
			var doAtEnd:Vector.<Function> = new Vector.<Function>();
			
			//CONSIDER: is this something we need to handle?
			var previousTrigger:SimpleEntity = Script.triggeringEntity;
			if ((Script.triggeringEntity != null) && (triggeredBy != null)) {
				Alert.show("Error -- nested triggered scripts");
			}
			Script.triggeringEntity = triggeredBy;
			doActions(doAtEnd);
			while (doAtEnd.length > 0) {
				var f:Function = doAtEnd.shift();
				f();
			}
			Script.triggeringEntity = previousTrigger;
			
			if (Settings.currentRoom.mode is RoomCombat) {
				RoomCombat(Settings.currentRoom.mode).checkForCombatOver();
			}
		}
		
		public function addAction(newAction:IAction):void {
			if (newAction != null) {
				if (actions == null) {
					actions = new Vector.<IAction>();
				}
				if (newAction is IActionToBeMergedWithPreviousIf) {
					if (lastActionAddedIfItWasAnIf != null) {
						lastActionAddedIfItWasAnIf.addCase(newAction as IActionToBeMergedWithPreviousIf);
					} else {
						Alert.show("Error! Else/Elseif can only follow an If action");
					}
				} else {
					actions.push(newAction);
					lastActionAddedIfItWasAnIf = (newAction as IfAction);
				}
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
		
		public static function entityWithScriptId(entityId:String):SimpleEntity {
			if (entityId == TRIGGERING_ENTITY_ID) {
				return triggeringEntity;
			} else {
				return Settings.currentRoom.entityInRoomWithId(entityId);
			}
		}
		
		
	}

}