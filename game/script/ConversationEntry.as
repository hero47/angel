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
		
		public static function createFromXml(entryXml:XML, rootScript:Script):ConversationEntry {
			var entry:ConversationEntry = new ConversationEntry();
			var npcSegmentXmlList:XMLList = entryXml.npc;
			if (npcSegmentXmlList.length() > 1) {
				rootScript.addError("conversation entry " + entryXml.@id + ": Multiple NPC segments");
			}
			if (npcSegmentXmlList.length() > 0) {
				entry.npcSegment = ConversationSegment.createFromXml(npcSegmentXmlList[0], rootScript);
			}
			
			entry.pcSegments = new Vector.<ConversationSegment>();
			for each (var pcHeaderSegmentXml:XML in entryXml.pcHeader) {
				var segment:ConversationSegment = ConversationSegment.createFromXml(pcHeaderSegmentXml, rootScript);
				segment.header = true;
				entry.pcSegments.push(segment);
			}
			for each (var pcSegmentXml:XML in entryXml.pc) {
				entry.pcSegments.push(ConversationSegment.createFromXml(pcSegmentXml, rootScript));
			}
			
			if ((entry.npcSegment == null) && (entry.pcSegments.length == 0)) {
				rootScript.addError("conversation entry " + entryXml.@id + ": Empty entry.");
				entry.npcSegment = ConversationSegment.createFromXml(<npc text="" />, rootScript);
			}
			
			return entry;
		}
		
		public function start(ui:ConversationInterface):void {
			ui.startEntry(npcSegment, pcSegments);
		}
		
	}

}