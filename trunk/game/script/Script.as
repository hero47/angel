package angel.game.script {
	import angel.common.Alert;
	import angel.common.LoaderWithErrorCatching;
	import angel.common.Util;
	import angel.game.combat.RoomCombat;
	import angel.game.Room;
	import angel.game.script.action.ActionFactory;
	import angel.game.script.action.ConversationAction;
	import angel.game.script.action.IAction;
	import angel.game.script.action.IActionToBeMergedWithPreviousIf;
	import angel.game.script.action.IfAction;
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
		
		
		public function Script(xml:XML = null, errorPrefix:String = "") {
			if (xml != null) {
				initializeFromXml(xml, errorPrefix);
			}
		}
		
		public function initializeFromXml(xml:XML, errorPrefix:String = ""):void {
			if ((xml == null) || (xml.length() == 0)) {
				return;
			}
			//UNDONE - placeholder until entity script files have more than one trigger.
			if (xml.onFrob.length() > 0) {
				xml = xml.onFrob[0];
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
					addAction(ActionFactory.createFromXml(child, errorPrefix));
				}
			}
		}
		
		// Loads data from specified file.
		// NOTE: File must be in the same directory that we're running from!
		// UNDONE: Currently (May 2011) this is a single script, to be executed when entity is frobbed.
		// I'm anticipating that eventually it will contain multiple triggered scripts, like the script section of
		// a room file.
		public function loadEntityScriptFromXmlFile(filename:String):void {
			LoaderWithErrorCatching.LoadFile(filename, entityScriptXmlLoaded);
		}
		
		private function entityScriptXmlLoaded(event:Event, filename:String):void {
			var xml:XML = Util.parseXml(event.target.data, filename);
			if (xml != null) {
				//UNDONE - temporary - remove this once old files have been upgraded
				if ((xml.name() != "conversations") && (xml.onFrob.length() == 0)) {
					Alert.show("Please change script file " + filename + "\nto use onFrob element inside outer script.\nThis will allow adding more triggers later.");
				}
				initializeFromXml(xml, "Error in script file " + filename + ":\n");
			}
		}
		
		public function run(room:Room, triggeredBy:SimpleEntity = null):void {
			var context:ScriptContext = new ScriptContext(room, triggeredBy);
			
			doActions(context);
			context.endOfScriptActions();
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
		
		public function doActions(context:ScriptContext):void {
			if (actions == null) {
				return;
			}
			for (var i:int = 0; i < actions.length; ++i) {
				var gotoReference:Object = actions[i].doAction(context);
				if (gotoReference != null) {
					Alert.show("Error! 'goto' only valid in Conversation");
				}
			}
		}
		
		public function doActionsForConversationSegment(context:ScriptContext):Object {
			if (actions == null) {
				return null;
			}
			var nextEntryReference:Object;
			for (var i:int = 0; i < actions.length; ++i) {
				var gotoReference:Object = actions[i].doAction(context);
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