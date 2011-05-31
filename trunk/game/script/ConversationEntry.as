package angel.game.script {
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
				Alert.show(errorPrefix + "Multiple NPC segments:\n" + entryXml.toXMLString());
			}
			if (npcSegmentXmlList.length() > 0) {
				entry.npcSegment = ConversationSegment.createFromXml(npcSegmentXmlList[0], errorPrefix);
			}
			
			entry.pcSegments = new Vector.<ConversationSegment>();
			for each (var pcHeaderSegmentXml:XML in entryXml.pcHeader) {
				var segment:ConversationSegment = ConversationSegment.createFromXml(pcHeaderSegmentXml, errorPrefix);
				segment.header = true;
				entry.pcSegments.push(segment);
			}
			for each (var pcSegmentXml:XML in entryXml.pc) {
				entry.pcSegments.push(ConversationSegment.createFromXml(pcSegmentXml, errorPrefix));
			}
			
			if ((entry.npcSegment == null) && (entry.pcSegments.length == 0)) {
				Alert.show(errorPrefix + "Empty entry.");
				entry.npcSegment = ConversationSegment.createFromXml(<npc text="" />, errorPrefix);
			}
			
			return entry;
		}
		
		public function start(ui:ConversationInterface):void {
			ui.startEntry(npcSegment, pcSegments);
		}
		
	}

}