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
	
	public class RoomTriggers extends TriggerBase implements ICleanup {
		
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
		
		private var room:Room;
		
		public function RoomTriggers(master:TriggerMaster, room:Room, roomXml:XML, filename:String) {
			super(master);
			this.room = room;
			var scriptsXml:XMLList = roomXml.script;
			if (scriptsXml.length() == 0) {
				return;
			}
			var scriptXml:XML = scriptsXml[0];
			var rootScriptForErrors:Script = new Script();
			rootScriptForErrors.initErrorList();
			createTriggeredScripts(room, scriptXml, TriggerMaster.ON_INIT, false, false, rootScriptForErrors);
			createTriggeredScripts(room, scriptXml, TriggerMaster.ON_MOVE, true, true, rootScriptForErrors);
			createTriggeredScripts(room, scriptXml, TriggerMaster.ON_DEATH, true, false, rootScriptForErrors);
			/*
			onDeathScripts = createTriggeredScripts( 
					(scriptXml.onDeath.length() > 0 ? scriptXml : ROOM_ON_DEATH_DEFAULT_XML),
					"onDeath", true, false, rootScriptForErrors);
			*/
			//onWinScripts = createTriggeredScripts(scriptXml, "onWin", false, false, rootScriptForErrors);
			//onLoseScripts = createTriggeredScripts(scriptXml, "onLose", false, false, rootScriptForErrors);
			rootScriptForErrors.displayAndClearParseErrors("Script errors in room file " + filename);
			
		}
		
		private function createTriggeredScripts(me:Object, scriptXML:XML, triggerName:String,
								canFilterOnId:Boolean, canFilterOnSpot:Boolean,	rootScript:Script):void {
			var scriptsForThisTrigger:XMLList = scriptXML.children().(name() == triggerName);
			if ((scriptsForThisTrigger == null) || (scriptsForThisTrigger.length() == 0)) {
				return;
			}
			addTriggeredScriptsFromXmlList(me, me, scriptsForThisTrigger, triggerName, canFilterOnId, canFilterOnSpot, rootScript);
		}
		
	}

}
