package angel.common {
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class MessageCollector {
		private var messages:Vector.<String>; // used to accumulate parse errors for display at end of script creation
		private var lengthAtSectionEnd:int;
		
		public function MessageCollector() {
			messages = new Vector.<String>();
			lengthAtSectionEnd = 0;
			
		}
		
		// Either show the error message in an alert, or add it to a collection to be shown en masse later.
		public static function collectOrShowMessage(collect:MessageCollector, message:String):void {
			if (collect == null) {
				Alert.show(message);
			} else {
				collect.add(message);
			}
		}
		
		public function add(text:String):void {
			messages.push(text);
		}
		
		//If the section had any messages, insert section header above them.
		public function endSection(sectionHeader:String):void {
			if (messages.length > lengthAtSectionEnd) {
				messages.splice(lengthAtSectionEnd, 0, sectionHeader);
				lengthAtSectionEnd = messages.length;
			}
		}
		
		public function displayIfNotEmpty(messageHeader:String = null, alertOptions:Object = null):void {
			if (messages.length > 0) {
				if (messageHeader != null) {
					messages.unshift(messageHeader);
				}
				Alert.showMulti(messages, alertOptions);
			}
		}
		
		public function empty():Boolean {
			return messages.length == 0;
		}
		
		public function clear():void {
			messages.length = 0;
			lengthAtSectionEnd = 0;
		}
		
	}

}