package angel.game.script {
	import angel.game.event.QEvent;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class TriggerBase {
		
		public var master:TriggerMaster;
		protected var triggers:Object = new Object(); // associative array mapping triggerName to Vector.<TriggeredScript>
		
		public function TriggerBase(master:TriggerMaster) {
			this.master = master;
		}
		
		public function cleanup():void {
			master.triggerEventQueue.removeAllListenersOwnedBy(this);
			//CONSIDER: remove not-yet-executed scripts???
		}
		
		protected function addTriggeredScriptsFromXmlList(me:Object, sourceIfNotCurrentRoom:Object, xmlList:XMLList,
								triggerName:String, 
								canFilterOnId:Boolean, canFilterOnSpot:Boolean,	rootScript:Script):void {
			addTriggeredScriptsComplicated(me, sourceIfNotCurrentRoom, xmlList,
				triggerName, triggerName,
				canFilterOnId, canFilterOnSpot, rootScript, null);
		}
		
		protected function addTriggeredScriptsComplicated(me:Object, sourceIfNotCurrentRoom:Object, xmlList:XMLList,
								triggerName:String, indexBy:String,
								canFilterOnId:Boolean, canFilterOnSpot:Boolean,	rootScript:Script, otherListener:Function):void {
			var triggeredScripts:Vector.<TriggeredScript> = new Vector.<TriggeredScript>();
			for each (var xml:XML in xmlList) {
				var one:TriggeredScript = new TriggeredScript(me);
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
				master.addTrigger(this, sourceIfNotCurrentRoom, triggerName, (otherListener == null ? triggerListener : otherListener));
			}
		}
		
		private function triggerListener(event:QEvent):void {
			var triggeredScripts:Vector.<TriggeredScript> = triggers[event.eventId];
			for each (var triggeredScript:TriggeredScript in triggeredScripts) {
				master.addToRunListIfPassesFilter(triggeredScript);
			}
		}
		
	}

}