package angel.game.script {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.LoaderWithErrorCatching;
	import angel.common.Util;
	import angel.game.event.QEvent;
	import angel.game.Flags;
	import angel.game.Settings;
	import flash.events.Event;

	
	public class ConversationData {
		
		private var topics:Object = new Object; // associative array mapping topic id to topic
		
		private var currentTopic:Topic;
		private var currentEntry:ConversationEntry;
		
		//UNDONE can we initialize from xml in constructor now?
		public function ConversationData() {
			
		}
			
		public function initializeFromXml(xml:XML, rootScript:Script):void {
			if (xml.topic.length() == 0) {
				rootScript.addError("conversation: No topics (or missing root element that contains the topics).");
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
					topic.entries[entryXml.@id] = ConversationEntry.createFromXml(entryXml, rootScript);
				}
				if (topic.entries["start"] == null) {
					rootScript.addError("conversation: Topic " + topicId + " has no start entry.");
					topic.entries["start"] = ConversationEntry.createFromXml(topicXml.entry[0], rootScript);
				}
				
				topics[topicId] = topic;
			}
		}
		
		//UNDONE: allow context-sensitive flags in "need" list
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
			
			Settings.gameEventQueue.addListener(this, ui, ConversationBox.CONVERSATION_ENTRY_FINISHED, entryFinished);
			currentEntry.start(ui);
		}
		
		private function entryFinished(event:QEvent):void {
			var ui:ConversationInterface = ConversationInterface(event.currentSource);
			var choice:ConversationSegment = ConversationSegment(event.param);
			var nextEntryReference:Object;
			if (choice != null) {
				nextEntryReference = choice.doActionsAndGetNextEntryId(ui.context);
			}
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
				Settings.gameEventQueue.removeListener(ui, ConversationBox.CONVERSATION_ENTRY_FINISHED, entryFinished);
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
