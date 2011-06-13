package angel.game.script {
	import angel.common.Alert;
	import angel.common.Catalog;
	import angel.game.event.EntityQEvent;
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
	
	public class RoomScripts {
		
		private static const ON_DEATH_DEFAULT_XML:XML = <script>
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
		private var onEnterScripts:Vector.<TriggeredScript>;
		private var onMoveScripts:Vector.<TriggeredScript>;
		private var onDeathScripts:Vector.<TriggeredScript>;
	//	private var onWinScripts:Vector.<TriggeredScript>;
	//	private var onLoseScripts:Vector.<TriggeredScript>;
		private var anyMoveScriptCaresAboutSpots:Boolean;
		
		public function RoomScripts(room:Room, roomXml:XML, filename:String) {
			this.room = room;
			var scriptsXml:XMLList = roomXml.script;
			if (scriptsXml.length() == 0) {
				return;
			}
			var scriptXml:XML = scriptsXml[0];
			var rootScriptForErrors:Script = new Script();
			rootScriptForErrors.initErrorList();
			onEnterScripts = createTriggeredScripts(scriptXml, "onEnter", false, false, rootScriptForErrors);
			onMoveScripts = createTriggeredScripts(scriptXml, "onMove", true, true, rootScriptForErrors);
			onDeathScripts = createTriggeredScripts(scriptXml, "onDeath", true, false, rootScriptForErrors);
			/*
			onDeathScripts = createTriggeredScripts( 
					(scriptXml.onDeath.length() > 0 ? scriptXml : ON_DEATH_DEFAULT_XML),
					"onDeath", true, false, rootScriptForErrors);
			*/
			//onWinScripts = createTriggeredScripts(scriptXml, "onWin", false, false, rootScriptForErrors);
			//onLoseScripts = createTriggeredScripts(scriptXml, "onLose", false, false, rootScriptForErrors);
			rootScriptForErrors.displayAndClearParseErrors("Script errors in room file " + filename);
			
			if (onMoveScripts != null) {
				Settings.gameEventQueue.addListener(this, room, EntityQEvent.FINISHED_ONE_TILE_OF_MOVE, moveListener);
				for each (var thisScript:TriggeredScript in onMoveScripts) {
					if (thisScript.spotIds != null) {
						anyMoveScriptCaresAboutSpots = true;
						break;
					}
				}
			}
			if (onDeathScripts != null) {
				Settings.gameEventQueue.addListener(this, room, EntityQEvent.DEATH, deathListener);
			}
		}
		
		public function cleanup():void {
			Settings.gameEventQueue.removeAllListenersOwnedBy(this);
		}
		
		public function runOnEnter():void {
			if (onEnterScripts != null) {
				runTriggeredScripts(onEnterScripts, null, false);
			}
		}
		
		/*
		public function runWinOrLose(win:Boolean):void {
			var scripts:Vector.<TriggeredScript> = (win ? onWinScripts : onLoseScripts);
			if (scripts != null) {
				runTriggeredScripts(scripts, null, false);
			}
		}
		*/
		
		private function createTriggeredScripts(scriptXML:XML, triggerName:String, canFilterOnId:Boolean, canFilterOnSpot:Boolean,
												rootScript:Script):Vector.<TriggeredScript> {
			var scriptsForThisTrigger:XMLList = scriptXML.children().(name() == triggerName);
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
						one.setEntityIds(idsParam);
					} else {
						rootScript.addError("Warning: ids ignored");
					}
				}
				if (spotsParam != "") {
					if (canFilterOnSpot) {
						one.spotIds = Vector.<String>(spotsParam.split(","));
					} else {
						rootScript.addError("Warning: spots ignored");
					}
				}
				one.script = new Script(xml, rootScript);
				if (one.script != null) {
					triggeredScripts.push(one);
				}
			}
			rootScript.endErrorSection(triggerName);
			return triggeredScripts;
		}
		
		private function runTriggeredScripts(scripts:Vector.<TriggeredScript>, entityWhoTriggered:SimpleEntity, anyoneCaresAboutSpots:Boolean):void {
			var context:ScriptContext = new ScriptContext(room, room.activePlayer(), entityWhoTriggered);
			var spotsThisEntityIsOn:Vector.<String>;
			if (anyoneCaresAboutSpots) {
				spotsThisEntityIsOn = room.spotsMatchingLocation(entityWhoTriggered.location);
			}
			for each (var thisScript:TriggeredScript in scripts) {
				thisScript.run(context, entityWhoTriggered, spotsThisEntityIsOn);
			}
			context.endOfScriptActions();
		}
		
		private function moveListener(event:EntityQEvent):void {
			runTriggeredScripts(onMoveScripts, event.simpleEntity, anyMoveScriptCaresAboutSpots);
		}
		
		private function deathListener(event:EntityQEvent):void {
			runTriggeredScripts(onDeathScripts, event.complexEntity, false);
		}
		
	}

}

import angel.common.Util;
import angel.game.script.Script;
import angel.game.script.ScriptContext;
import angel.game.SimpleEntity;
internal class TriggeredScript {
	public var script:Script;
	public var entityIds:Vector.<String>;
	public var entitySpecialIds:Vector.<String>;
	public var spotIds:Vector.<String>;
	
	public function TriggeredScript() {
		
	}
	
	public function setEntityIds(idsParam:String):void {
		if (Util.nullOrEmpty(idsParam)) {
			return;
		}
		entityIds = Vector.<String>(idsParam.split(","));
		entitySpecialIds = new Vector.<String>();
		for (var i:int = entityIds.length - 1; i >= 0; --i) {
			if (entityIds[i].charAt(0) == "*") {
				entitySpecialIds.push(entityIds.splice(i, 1));
			}
		}
	}
			
	public function passesIdFilter(context:ScriptContext, entity:SimpleEntity):Boolean {
		if (entityIds == null) {
			return true;
		}
		if (entityIds.indexOf(entity.id) >= 0) {
			return true;
		}
		for (var i:int = 0; i < entitySpecialIds.length; ++i) {
			if (context.entityWithScriptId(entitySpecialIds[i]) == entity) {
				return true;
			}
		}
		return false;
	}
		
	public function passesSpotFilter(spotsThisEntityIsOn:Vector.<String>):Boolean {
		if (spotIds == null) {
			return true;
		}
		
		for each (var spotId:String in spotsThisEntityIsOn) {
			if (spotIds.indexOf(spotId) >= 0) {
				return true;
			}
		}
		return false;
	}
		
	public function run(context:ScriptContext, entityWhoTriggered:SimpleEntity, spotsIfAnyoneCares:Vector.<String>):void {
		if (passesIdFilter(context, entityWhoTriggered)) {
			if ((spotsIfAnyoneCares == null) || passesSpotFilter(spotsIfAnyoneCares)) {
				script.doActions(context);
			}
		}
	}
		
}