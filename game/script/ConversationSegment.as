package angel.game.script {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.game.Flags;
	import angel.game.script.action.ActionFactory;
	import angel.game.script.action.IAction;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ConversationSegment {
		
		public var need:Vector.<String>; // must have these flags
		public var text:String;
		public var header:Boolean;
		private var script:Script;
		
		public function ConversationSegment(text:String) {
			this.text = text;
		}
		
		public function addAction(newAction:IAction):void {
			if (script == null) {
				script = new Script();
			}
			script.addAction(newAction);
		}
		
		public static function createFromXml(xml:XML, rootScript:Script):ConversationSegment {
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
					segment.addAction(ActionFactory.createFromXml(child, rootScript));
				}
			}
			return segment;
		}
		
		public function haveAllNeededFlags():Boolean {
			return Flags.haveAllFlagsIn(need);
		}
		
		public function doActionsAndGetNextEntryId(context:ScriptContext):Object {
			if (script == null) {
				return null;
			}
			return script.doActionsForConversationSegment(context);
		}
		
	}

}