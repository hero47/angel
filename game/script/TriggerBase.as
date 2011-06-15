package angel.game.script {
	import angel.game.event.EntityQEvent;
	import angel.game.event.QEvent;
	import angel.game.Settings;
	import angel.game.SimpleEntity;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class TriggerBase {
		
		protected var me:Object;
		protected var triggers:Object = new Object(); // associative array mapping triggerName to Vector.<TriggeredScript>
		
		public function TriggerBase(me:Object) {
			this.me =  me;
		}
		
		public function cleanup():void {
			Settings.gameEventQueue.removeAllListenersOwnedBy(this);
			//CONSIDER: remove not-yet-executed scripts???
			triggers = null;
			me = null;
		}
		
		protected function addTriggeredScriptsFromXmlList(me:Object, source:Object, xmlList:XMLList,
								triggerName:String, indexBy:String,
								canFilterOnId:Boolean, canFilterOnSpot:Boolean,	rootScript:Script):void {
			var triggeredScripts:Vector.<TriggeredScript> = new Vector.<TriggeredScript>();
			for each (var xml:XML in xmlList) {
				var one:TriggeredScript = new TriggeredScript();
				var idsParam:String = xml.@ids;
				var spotsParam:String = xml.@spots;
				if (idsParam != "") {
					if (canFilterOnId) {
						one.setEntityIds(idsParam);
					} else {
						rootScript.addError("Warning: ids ignored in " + triggerName);
					}
				}
				if (spotsParam != "") {
					if (canFilterOnSpot) {
						one.spotIds = Vector.<String>(spotsParam.split(","));
					} else {
						rootScript.addError("Warning: spots ignored in " + triggerName);
					}
				}
				one.script = new Script(xml, rootScript);
				if (one.script != null) {
					triggeredScripts.push(one);
				}
			}
			rootScript.endErrorSection(triggerName);
			
			if (triggeredScripts != null) {
				if (triggers[indexBy] == null) {
					triggers[indexBy] = triggeredScripts;
				} else {
					triggers[indexBy] = triggers[indexBy].concat(triggeredScripts);
				}
				var gameEventName:String = TriggerMaster.TRIGGER_NAME_TO_GAME_EVENT[triggerName];
				Settings.gameEventQueue.addListener(this, source, gameEventName, triggerListener, indexBy);
			}
		}
		
		private function triggerListener(event:QEvent):void {
			var indexBy:String = String(event.listenerParam);
			var triggeredScripts:Vector.<TriggeredScript> = triggers[indexBy];
			for each (var triggeredScript:TriggeredScript in triggeredScripts) {
				Settings.triggerMaster.addToRunListIfPassesFilter(triggeredScript, me, (event.source as SimpleEntity));
			}
		}
		
	}

}