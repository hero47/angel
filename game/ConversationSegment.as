package angel.game {
	import angel.common.Assert;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ConversationSegment {
		// CONSIDER: make Action an interface, with each different action a full class of its own
		// and Action doing its own XML parsing.
		// (It's overkill now, but if we get a lot of action types it would be cleaner, and if
		// we end up wanting actions that take different parameters it would clearly be better.)
		public static const GOTO:int = 1;
		public static const ADD_FLAG:int = 2;
		public static const REMOVE_FLAG:int = 3;
		private static const actionNameToCode:Object = { "goto":GOTO, "add":ADD_FLAG, "remove":REMOVE_FLAG };
		
		public var need:Vector.<String>; // must have these flags
		public var text:String;
		private var actions:Vector.<Action>;
		
		public function ConversationSegment(text:String) {
			this.text = text;
		}
		
		public function addAction(actionCode:int, id:String):void {
			var newAction:Action = new Action(actionCode, id);
			if (actions == null) {
				actions = new Vector.<Action>();
			}
			actions.push(newAction);
		}
		
		public static function createFromXml(xml:XML):ConversationSegment {
			var text:String = xml.@text;
			
			// A \n for newline in XML attribute doesn't translate, and a CRLF looks like two newlines, so fix them
			while (text.indexOf("\\n") >= 0) {
				text = text.replace("\\n", "\n");
			}
			while (text.indexOf("\r") >= 0) {
				text = text.replace("\r", "");
			}
			
			var segment:ConversationSegment = new ConversationSegment(text);
			var children:XMLList = xml.children();
			for each (var child:XML in xml.children()) {
				if (child.name() == "need") {
					if (segment.need == null) {
						segment.need = new Vector.<String>();
					}
					segment.need.push(child.@flag);
				} else {
					segment.addActionFromXml(child);
				}
			}
			return segment;
		}
		
		private function addActionFromXml(actionXml:XML):void {
			var name:String = actionXml.name();
			Assert.assertTrue(actionNameToCode[name] != null, "Bad action " + name);
			var actionCode:int = actionNameToCode[name];
			switch (actionCode) {
				case GOTO:
					addAction(actionCode, actionXml.@id);
				break;
				case ADD_FLAG:
				case REMOVE_FLAG:
					addAction(actionCode, actionXml.@flag);
				break;
			}
		}
		
		public function haveAllNeededFlags():Boolean {
			return Flags.haveAllFlagsIn(need);
		}
		
		public function doActionsAndGetNextEntryId():String {
			if (actions == null) {
				return null;
			}
			var nextEntryId:String;
			for (var i:int = 0; i < actions.length; ++i) {
				var gotoId:String = doAction(actions[i]);
				Assert.assertTrue((gotoId == null) || (nextEntryId == null), "Conversation segment has extra goto, id=" + gotoId);
				if (gotoId != null) {
					nextEntryId = gotoId;
				}
			}
			return nextEntryId;
		}
		
		// returns id if action is "goto"
		private function doAction(action:Action):String {
			switch (action.actionCode) {
				case GOTO:
					return action.id;
				break;
				case ADD_FLAG:
					Flags.setValue(action.id, true);
				break;
				case REMOVE_FLAG:
					Flags.setValue(action.id, false);
				break;
			}
			return null;
		}
		
	}

}

class Action {
	public var actionCode:int;
	public var id:String;
	public function Action(actionCode:int, id:String) {
		this.actionCode = actionCode;
		this.id = id;
	}
}