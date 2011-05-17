package angel.game.script {
	import angel.common.Alert;
	import angel.game.EntityEvent;
	import angel.game.Room;
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
	
	public class RoomScripts {
		private var room:Room;
		private var onEnterScripts:Vector.<TriggeredScript>;
		private var onMoveScripts:Vector.<TriggeredScript>;
		private var onDeathScripts:Vector.<TriggeredScript>;
		
		public function RoomScripts(room:Room, roomXml:XML, filename:String) {
			this.room = room;
			var scriptsXml:XMLList = roomXml.script;
			if (scriptsXml.length() == 0) {
				return;
			}
			var scriptXml:XML = scriptsXml[0];
			var errorPrefix:String =  "in room file " + filename;
			onEnterScripts = createTriggeredScripts(scriptXml.onEnter, false, false, errorPrefix + " onEnter");
			onMoveScripts = createTriggeredScripts(scriptXml.onMove, true, true, errorPrefix + " onMove");
			onDeathScripts = createTriggeredScripts(scriptXml.onDeath, true, false, errorPrefix + " onDeath");
			
			if (onMoveScripts != null) {
				room.addEventListener(EntityEvent.FINISHED_ONE_TILE_OF_MOVE, moveListener);
			}
			if (onDeathScripts != null) {
				room.addEventListener(EntityEvent.DEATH, deathListener);
			}
		}
		
		public function cleanup():void {
			room.removeEventListener(EntityEvent.FINISHED_ONE_TILE_OF_MOVE, moveListener);
			room.removeEventListener(EntityEvent.DEATH, deathListener);
		}
		
		public function runOnEnter():void {
			if (onEnterScripts != null) {
				runTriggeredScripts(onEnterScripts, null);
			}
		}
		
		private function createTriggeredScripts(scriptsForThisTrigger:XMLList, canFilterOnId:Boolean, canFilterOnSpot:Boolean,
												errorLocation:String):Vector.<TriggeredScript> {
			if ((scriptsForThisTrigger == null) || (scriptsForThisTrigger.length() == 0)) {
				return null;
			}
			var triggeredScripts:Vector.<TriggeredScript> = new Vector.<TriggeredScript>();
			for each (var xml:XML in scriptsForThisTrigger) {
				var one:TriggeredScript = new TriggeredScript();
				var idsParam:String = xml.@ids;
				var spotsParam:String = xml.@spots;
				if (idsParam != "") {
					if (canFilterOnId) {
						one.entityIds = idsParam;
					} else {
						Alert.show("Warning: ids ignored " + errorLocation);
					}
				}
				if (spotsParam != "") {
					if (canFilterOnSpot) {
						one.spotIds = spotsParam;
					} else {
						Alert.show("Warning: spots ignored " + errorLocation);
					}
				}
				one.script = new Script(xml, "Script error " + errorLocation + ":\n");
				if (one.script != null) {
					triggeredScripts.push(one);
				}
			}
			return triggeredScripts;
		}
		
		private function runTriggeredScripts(scripts:Vector.<TriggeredScript>, entityWhoTriggered:SimpleEntity):void {
			for each (var thisScript:TriggeredScript in scripts) {
				if (passesIdFilter(thisScript, entityWhoTriggered) && passesSpotFilter(thisScript, entityWhoTriggered)) {
					thisScript.script.run(entityWhoTriggered);
				}
			}
		}
		
		private function passesIdFilter(thisScript:TriggeredScript, entity:SimpleEntity):Boolean {
			if (thisScript.entityIds == null) {
				return true;
			}
			return (thisScript.entityIds.indexOf(entity.id) >= 0);
		}
		
		private function passesSpotFilter(thisScript:TriggeredScript, entity:SimpleEntity):Boolean {
			if (thisScript.spotIds == null) {
				return true;
			}
			
			var spotsThisEntityIsOn:Vector.<String> = room.spotsMatchingLocation(entity.location);
			for each (var spotId:String in spotsThisEntityIsOn) {
				if (thisScript.spotIds.indexOf(spotId) >= 0) {
					return true;
				}
			}
			return false;
		}
		
		
		private function moveListener(event:EntityEvent):void {
			runTriggeredScripts(onMoveScripts, event.entity);
		}
		
		private function deathListener(event:EntityEvent):void {
			runTriggeredScripts(onDeathScripts, event.entity);
		}
		
	}

}

import angel.game.script.Script;
class TriggeredScript {
	public var script:Script;
	public var entityIds:String;
	public var spotIds:String;
	public function TriggeredScript() {
		
	}
}