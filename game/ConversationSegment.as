package angel.game {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.game.action.Action;
	import angel.game.action.IAction;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ConversationSegment {
		
		public var need:Vector.<String>; // must have these flags
		public var text:String;
		private var actions:Vector.<IAction>;
		
		public function ConversationSegment(text:String) {
			this.text = text;
		}
		
		public function addAction(newAction:IAction):void {
			if (actions == null) {
				actions = new Vector.<IAction>();
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
					segment.addAction(Action.createFromXml(child));
				}
			}
			return segment;
		}
		
		public function haveAllNeededFlags():Boolean {
			return Flags.haveAllFlagsIn(need);
		}
		
		public function doActionsAndGetNextEntryId():Object {
			if (actions == null) {
				return null;
			}
			var nextEntryReference:Object;
			for (var i:int = 0; i < actions.length; ++i) {
				var gotoReference:Object = actions[i].doAction();
				if ((gotoReference != null) && (nextEntryReference != null)) {
					Alert.show("Conversation segment has extra goto, id=" + gotoReference.id);
				}
				if (gotoReference != null) {
					nextEntryReference = gotoReference;
				}
			}
			return nextEntryReference;
		}
		
	}

}