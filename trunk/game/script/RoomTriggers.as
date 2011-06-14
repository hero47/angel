package angel.game.script {
	import angel.common.Alert;
	import angel.common.Catalog;
	import angel.common.ICleanup;
	import angel.game.event.EntityQEvent;
	import angel.game.event.QEvent;
	import angel.game.Room;
	import angel.game.SaveGame;
	import angel.game.Settings;
	import angel.game.SimpleEntity;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	/* The script section of room XML contains zero or more trigger clauses which look like
	 * <onEnter >
	 * <onMove ids="barbara,nei" spots="a,b" >
	 * <onDeath ids="barbara,nei" >
	 * The parameters serve as filters; if they are present, the enclosed script is only executed if the triggering
	 * event matches those filters.
	 * onEnter uses no filters.
	 * onMove can filter by the entity moving, the spot the entity has moved onto, or a combination of both.
	 * onDeath filters by the entity who died.
	 */
	
	public class RoomTriggers implements ICleanup {
		
		private static const ROOM_ON_DEATH_DEFAULT_XML:XML = <script>
			<onDeath>
				<if>
					<compare op="eq">
						<left alive="enemy" />
						<right int="0" />
					</compare>
					<script>
						<winGame />
					</script>
				</if>
			</onDeath>
		</script>;
		
		public var master:TriggerMaster;
		private var room:Room;
		private var triggers:Object = new Object(); // associative array mapping triggerName to Vector.<TriggeredScript>
		
		public function RoomTriggers(master:TriggerMaster, room:Room, roomXml:XML, filename:String) {
			this.master = master;
			this.room = room;
			var scriptsXml:XMLList = roomXml.script;
			if (scriptsXml.length() == 0) {
				return;
			}
			var scriptXml:XML = scriptsXml[0];
			var rootScriptForErrors:Script = new Script();
			rootScriptForErrors.initErrorList();
			createTriggeredScripts(scriptXml, TriggerMaster.ON_INIT, false, false, rootScriptForErrors);
			createTriggeredScripts(scriptXml, TriggerMaster.ON_MOVE, true, true, rootScriptForErrors);
			createTriggeredScripts(scriptXml, TriggerMaster.ON_DEATH, true, false, rootScriptForErrors);
			/*
			onDeathScripts = createTriggeredScripts( 
					(scriptXml.onDeath.length() > 0 ? scriptXml : ROOM_ON_DEATH_DEFAULT_XML),
					"onDeath", true, false, rootScriptForErrors);
			*/
			//onWinScripts = createTriggeredScripts(scriptXml, "onWin", false, false, rootScriptForErrors);
			//onLoseScripts = createTriggeredScripts(scriptXml, "onLose", false, false, rootScriptForErrors);
			rootScriptForErrors.displayAndClearParseErrors("Script errors in room file " + filename);
			
		}
		
		public function cleanup():void {
			master.triggerEventQueue.removeAllListenersOwnedBy(this);
			//CONSIDER: remove not-yet-executed scripts???
		}
		
		private function createTriggeredScripts(scriptXML:XML, triggerName:String,
								canFilterOnId:Boolean, canFilterOnSpot:Boolean,	rootScript:Script):void {
			var scriptsForThisTrigger:XMLList = scriptXML.children().(name() == triggerName);
			if ((scriptsForThisTrigger == null) || (scriptsForThisTrigger.length() == 0)) {
				return;
			}
			var triggeredScripts:Vector.<TriggeredScript> = new Vector.<TriggeredScript>();
			for each (var xml:XML in scriptsForThisTrigger) {
				var one:TriggeredScript = new TriggeredScript(room);
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
			triggers[triggerName] = triggeredScripts;
			master.triggerEventQueue.addListener(this, master, triggerName, triggerListener);
		}
		
		private function triggerListener(event:QEvent):void {
			var triggeredScripts:Vector.<TriggeredScript> = triggers[event.eventId];
			for each (var triggeredScript:TriggeredScript in triggeredScripts) {
				master.addToRunListIfPassesFilter(triggeredScript);
			}
		}
		
	}

}
