package angel.game.test {
	import angel.common.LoaderWithErrorCatching;
	import angel.common.Util;
	import angel.game.event.QEvent;
	import angel.game.Room;
	import angel.game.script.ConversationData;
	import angel.game.script.Script;
	import angel.game.Settings;
	import flash.events.Event;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ConversationNonAutoTest {
		private static var frobScript:Script;
		private var room:Room;
		
		public function ConversationNonAutoTest(room:Room) {
			this.room = room;
			if (frobScript == null) {
				LoaderWithErrorCatching.LoadFile("testActions.xml", dataLoaded);
			} else {
				doTest();
			}
		}
		
		private function dataLoaded(event:Event, param:Object, filename:String):void {
			var xml:XML = Util.parseXml(event.target.data, filename);
			if (xml != null) {
				var rootScriptForErrors:Script = new Script();
				rootScriptForErrors.initErrorList();
				var newXml:XML = <script>
				</script>;
				
				newXml.appendChild(xml);
				frobScript = new Script();
				frobScript.initializeFromXml(newXml);
				rootScriptForErrors.displayAndClearParseErrors(filename);
				doTest();
			}
		}
		
		private function doTest():void {
			frobScript.run(room, room.mainPlayerCharacter);
		}
		
	}

}