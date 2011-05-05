package angel.game {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.LoaderWithErrorCatching;
	import flash.events.Event;
	import flash.events.EventDispatcher;

	
	public class ConversationData extends EventDispatcher {
		
		private var topics:Object = new Object; // associative array mapping topic id to topic
		
		private var currentTopic:Topic;
		private var currentEntry:ConversationEntry;
		
		public function ConversationData() {
			
		}
		
		// Loads data from specified file.
		// NOTE: File must be in the same directory that we're running from!
		public function loadFromXmlFile(filename:String):void {
			LoaderWithErrorCatching.LoadFile(filename, conversationXmlLoaded);
		}
		
		private function conversationXmlLoaded(event:Event, filename:String):void {
			var xml:XML = new XML(event.target.data);
			var errorPrefix:String = "Error in conversation file " + filename + ":\n";
			if (xml.topic.length() == 0) {
				Alert.show(errorPrefix + "No topics (or missing root element that contains the topics).");
			}
			for each (var topicXml:XML in xml.topic) {
				var topic:Topic = new Topic();
				var topicId:String = topicXml.@id;
				
				for each (var needXml:XML in topicXml.need) {
					if (topic.need == null) {
						topic.need = new Vector.<String>();
					}
					topic.need.push(needXml.@flag);
				}
				
				topic.entries = new Object();
				for each (var entryXml:XML in topicXml.entry) {
					topic.entries[entryXml.@id] = ConversationEntry.createFromXml(entryXml, errorPrefix);
				}
				if (topic.entries["start"] == null) {
					Alert.show(errorPrefix + "Topic " + topicId + " has no start entry.");
					topic.entries["start"] = ConversationEntry.createFromXml(topicXml.entry[0], errorPrefix);
				}
				
				topics[topicId] = topic;
			}
		}
		
		private function findValidTopic():Topic {
			var max:int = -1;
			var topicIdWithMax:String = null;
			var possibleError:String = "";
			for (var topicId:String in topics) {
				var topic:Topic = topics[topicId];
				var length:int = (topic.need == null ? 0 : topic.need.length);
				if ((length > max) && Flags.haveAllFlagsIn(topic.need)) {
					max = length;
					topicIdWithMax = topicId;
					possibleError = "";
				} else if ((length == max) && Flags.haveAllFlagsIn(topic.need)) {
					possibleError += " " + topicId;
				}
			}
			
			if (possibleError != "") {
				Alert.show("Error! Two or more topics tied for flags: " + topicIdWithMax + possibleError);
			}
			
			return (topicIdWithMax == null ? null : topics[topicIdWithMax]);
		}
		
		public function runConversation(ui:ConversationInterface):void {
			currentTopic = findValidTopic();
			if (currentTopic == null) {
				Alert.show("Error! No valid topic.");
				ui.cleanup()
				return;
			}
			
			currentEntry = currentTopic.entries["start"];
			
			ui.addEventListener(ConversationEvent.SEGMENT_FINISHED, segmentFinished);
			currentEntry.start(ui);
		}
		
		private function segmentFinished(event:ConversationEvent):void {
			if (event.choice == currentEntry.npcSegment) {
				// We get called for NPC segment finished because Wm is convinced that it's a user-friendly UI to require
				// user to click on the NPC box before we will display the PC box.  I think this is a poor decision, and
				// I'm not going to any effort to clean the code for this because I'm hoping he'll change his mind.
				return;
			}
			var ui:ConversationInterface = ConversationInterface(event.currentTarget);
			var nextEntryReference:Object = event.choice.doActionsAndGetNextEntryId(ui.doAtEnd);
			currentEntry = null;
			if (nextEntryReference != null) {
				if (nextEntryReference.topic != null) {
					currentTopic = topics[nextEntryReference.topic];
					if (currentTopic == null) {
						Alert.show("Error: Missing topic id " + nextEntryReference.topic);
					}
				}
				currentEntry = currentTopic.entries[nextEntryReference.id];
				if (currentEntry == null) {
					Alert.show("Error: Missing entry id " + nextEntryReference.id);
				}
			}
			
			if (currentEntry == null) {
				ui.removeEventListener(ConversationEvent.SEGMENT_FINISHED, segmentFinished);
				ui.cleanup();
			} else {
				currentEntry.start(ui);
			}
		}
		
	} // end class ConversationData

}

class Topic {
	public var need:Vector.<String>; // must have these flags
	public var entries:Object; // associative array mapping entry id to entry
}
