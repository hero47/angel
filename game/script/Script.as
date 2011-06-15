package angel.game.script {
	import angel.common.Alert;
	import angel.common.Catalog;
	import angel.common.LoaderWithErrorCatching;
	import angel.common.MessageCollector;
	import angel.common.Util;
	import angel.game.combat.RoomCombat;
	import angel.game.event.QEvent;
	import angel.game.Room;
	import angel.game.SaveGame;
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
		private var errors:MessageCollector; // used to accumulate parse errors for display at end of script creation
		
		public static const TRIGGERING_ENTITY_ID:String = "*it";
		public static const ACTIVE_PLAYER_ID:String = "*pc";
		public static const SELF_ID:String = "*me";
		
//UNDONE: check if initializeFromXml and loadEntityScriptFromXmlFile should be static functions
		public function Script(xml:XML = null, rootScript:Script = null) {
			if (xml != null) {
				initializeFromXml(xml, rootScript);
			}
		}
		
		public function initializeFromXml(xml:XML, rootScript:Script = null):void {
			var displayErrorsAfterParse:Boolean;
			if (rootScript == null) {
				rootScript = this;
				initErrorList();
				displayErrorsAfterParse = true;
			}
			if ((xml == null) || (xml.length() == 0)) {
				return;
			}
			
			var children:XMLList = xml.children();
			for each (var child:XML in xml.children()) {
				addAction(ActionFactory.createFromXml(child, rootScript));
			}
			
			if (displayErrorsAfterParse) {
				errors.displayIfNotEmpty("Script errors:");
			}
		}
		
		public function run(room:Room, triggeredBy:SimpleEntity = null):void {
			var context:ScriptContext = new ScriptContext(room, (room == null ? null : room.activePlayer()), triggeredBy);
			
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
		
		/**************************************************/
		// Parse error stuff
		
		// Return true and add an error to the list (for display at end of parsing)
		// if the xml doesn't contain the required attribute
		public function requires(from:String, attribute:String, xml:XML):Boolean {
			if (String(xml.@[attribute]) == "") {
				errors.add(from + " requires " + attribute);
				return true;
			}
			return false;
		}
		
		public function addError(text:String):void {
			errors.add(text);
		}
		
		public function endErrorSection(sectionName:String):void {
			errors.endSection("** in " + sectionName + " **");
		}
		
		public function initErrorList():void {
			errors = new MessageCollector();
		}
		
		public function displayAndClearParseErrors(scriptLocation:String = null):void {
			if (errors != null) {
				errors.displayIfNotEmpty(scriptLocation != null ? scriptLocation : "Script errors:");
			}
			errors = null;
		}
		
	}

}