package angel.game {
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
		
		public static function createFromXml(entryXml:XML):ConversationEntry {
			var entry:ConversationEntry = new ConversationEntry();
			var npcSegmentXmlList:XMLList = entryXml.npc;
			if (npcSegmentXmlList.length() > 1) {
				Alert.show("Error! Multiple NPC segments:\n" + entryXml);
			}
			if (npcSegmentXmlList.length() > 0) {
				entry.npcSegment = ConversationSegment.createFromXml(npcSegmentXmlList[0]);
			}
			
			entry.pcSegments = new Vector.<ConversationSegment>();
			for each (var pcSegmentXml:XML in entryXml.pc) {
				entry.pcSegments.push(ConversationSegment.createFromXml(pcSegmentXml));
			}
			if (entry.pcSegments.length == 0) {
				Alert.show("Error! Missing PC segment:\n" + entryXml);
			}
			
			return entry;
		}
		
		public function start(ui:ConversationInterface):void {
			ui.startSegment(npcSegment, pcSegments);
			if (npcSegment != null) {
				var illegalGoto:Object = npcSegment.doActionsAndGetNextEntryId();
				if (illegalGoto != null) {
					Alert.show("Error! NPC segment contains goto id " + illegalGoto.id);
				}
			}
		}
		
	}

}