package angel.game.conversation {
	import angel.common.Alert;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ConversationEntry {
		public var npcSegment:ConversationSegment;
		public var pcSegments:Vector.<ConversationSegment>;
		
		public function ConversationEntry() {
			
		}
		
		public static function createFromXml(entryXml:XML, errorPrefix:String = ""):ConversationEntry {
			if (errorPrefix == "") {
				errorPrefix = "Error in conversation XML:\n";
			}
			var entry:ConversationEntry = new ConversationEntry();
			var npcSegmentXmlList:XMLList = entryXml.npc;
			if (npcSegmentXmlList.length() > 1) {
				Alert.show(errorPrefix + "Multiple NPC segments:\n" + entryXml);
			}
			if (npcSegmentXmlList.length() > 0) {
				entry.npcSegment = ConversationSegment.createFromXml(npcSegmentXmlList[0], errorPrefix);
			}
			
			entry.pcSegments = new Vector.<ConversationSegment>();
			for each (var pcSegmentXml:XML in entryXml.pc) {
				entry.pcSegments.push(ConversationSegment.createFromXml(pcSegmentXml, errorPrefix));
			}
			if (entry.pcSegments.length == 0) {
				Alert.show("Missing PC segment:\n" + entryXml);
			}
			
			return entry;
		}
		
		public function start(ui:ConversationInterface):void {
			ui.startSegment(npcSegment, pcSegments);
			if (npcSegment != null) {
				var illegalGoto:Object = npcSegment.doActionsAndGetNextEntryId(ui.doAtEnd);
				if (illegalGoto != null) {
					Alert.show("Error! NPC segment contains goto id " + illegalGoto.id);
				}
			}
		}
		
	}

}